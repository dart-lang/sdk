// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/ir_to_text.dart';
import 'package:cfg/ir/source_position.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/ir/visitor.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:meta/meta.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'ir_log.dart';
import 'utils.dart';
import 'wasm_local_allocator.dart';

/// Translates a [FlowGraph] (CFG IR) to WebAssembly bytecode.
abstract base class CfgToWasm {
  final FlowGraph graph;
  final w.InstructionsBuilder b;
  final CfgLog? cfgLog;

  Map<Instruction, InstructionTextPosition>? _textPositions;

  late final WasmLocalAllocator localAllocator;
  final Map<Block, w.Label> _blockLabels = {};
  final Map<Block, w.Label> _loopContinueLabels = {};

  CfgToWasm(this.graph, this.b, {this.cfgLog});

  @nonVirtual
  ast.Member get member => graph.function.member;

  WasmInstructionLowerer get lowerer;

  @nonVirtual
  void generate() {
    _textPositions = cfgLog?.append(member, graph);

    assert(
      graph.isReducible,
      'CFG should have been lowered to reducible control flow',
    );
    localAllocator = WasmLocalAllocator(
      graph,
      b,
      translateType: translateType,
      functionParameterLocal: functionParameterLocal,
    );
    _generateSubtree(graph.entryBlock, lowerer);

    b.end();
  }

  void _generateSubtree(Block u, WasmInstructionLowerer lowerer) {
    setDebugPosition(u);
    final isLoopHeader = graph.loops[u]?.header == u;

    if (isLoopHeader) {
      final continueLabel = b.loop();
      _loopContinueLabels[u] = continueLabel;
    }

    for (final instr in u) {
      assert(instr is! Block);
      if (instr is Phi) {
        // Predecessors move phi inputs into the phi's Wasm local in
        // `assignPhis`.
        assert(u is JoinBlock);
        continue;
      }
      if (instr is ControlFlowInstruction) {
        // This must be the last instruction in the block and is handled
        // specially below.
        assert(u.lastInstruction == instr);
        break;
      }
      if (instr is Definition &&
          !instr.hasUses &&
          !instr.hasSideEffects &&
          !instr.canThrow) {
        // Unused pure non-throwing instruction has no observable effect.
        assert(!localAllocator.hasLocal(instr));
        continue;
      }
      setDebugPosition(instr);
      instr.accept(lowerer);
    }

    final children = u.dominatedBlocks.toList()
      ..sort((a, b) => a.postorderNumber.compareTo(b.postorderNumber));

    for (final v in children) {
      final label = b.block();
      _blockLabels[v] = label;
    }

    final terminal = u.lastInstruction;
    assert(terminal is ControlFlowInstruction);
    setDebugPosition(terminal);
    terminal.accept(lowerer);

    for (final v in children.reversed) {
      b.end();
      _blockLabels.remove(v);
      _generateSubtree(v, lowerer);
    }

    if (isLoopHeader) {
      b.end();
      _loopContinueLabels.remove(u);
      b.unreachable();
    }
  }

  @nonVirtual
  void assignPhis(Block from, Block to) {
    if (to is JoinBlock && to.hasPhis) {
      final predIndex = to.predecessors.indexOf(from);
      assert(predIndex >= 0);

      Phi? lastPhi;
      for (final phi in to.phis) {
        if (!phi.hasUses) continue;
        final inputDef = phi.inputDefAt(predIndex);
        if (localAllocator.isPhiMoveNoOp(phi, inputDef)) continue;
        setDebugPosition(phi, inputIndex: predIndex);
        final phiLocal = getLocal(phi);
        if (isUndefined(inputDef)) {
          // This value will never be observed. Reset value to default to not
          // retain stale references.
          _pushDefaultValue(phiLocal.type);
        } else {
          final inputLocal = getLocal(inputDef);
          b.local_get(inputLocal);
          convertType(inputLocal.type, phiLocal.type);
        }
        lastPhi = phi;
      }

      if (lastPhi == null) return;
      for (Instruction? instr = lastPhi; instr is Phi; instr = instr.previous) {
        if (!instr.hasUses) continue;
        final inputDef = instr.inputDefAt(predIndex);
        if (localAllocator.isPhiMoveNoOp(instr, inputDef)) continue;
        setDebugPosition(instr, inputIndex: predIndex);
        final phiLocal = getLocal(instr);
        b.local_set(phiLocal);
      }
      setDebugPosition(from.lastInstruction);
    }
  }

  void _pushDefaultValue(w.ValueType type) {
    switch (type) {
      case w.NumType.i32:
        b.i32_const(0);
      case w.NumType.i64:
        b.i64_const(0);
      case w.NumType.f32:
        b.f32_const(0);
      case w.NumType.f64:
        b.f64_const(0);
      case w.NumType.v128:
        b.v128_const_i32x4(0, 0, 0, 0);
      case w.RefType(:final heapType, nullable: true):
        b.ref_null(heapType.bottomType);
      default:
        throw StateError('Non-defaultable phi local type: $type');
    }
  }

  /// Whether [def] is the undefined constant, i.e. a placeholder for a value
  /// which is never observed on the given path.
  @nonVirtual
  bool isUndefined(Definition def) => WasmLocalAllocator.isUndefined(def);

  /// Updates the current debug position in the emitted wasm bytecode stream.
  ///
  /// While we generate code for a given IR instruction we use it's associated
  /// source position as debug position in the wasm bytecode we emit. If we emit
  /// code specific to an input of the [instr], we may (if [inputIndex] is
  /// given and it has associated source position) use the instruction input
  /// source position instead.
  @nonVirtual
  void setDebugPosition(Instruction instr, {int? inputIndex}) {
    if (!b.recordDebugInfo) return;
    final textPositions = _textPositions;
    if (textPositions != null) {
      final pos = textPositions[instr]!;
      b.setSourcePosition(
        CfgLog.defaultUri,
        pos.line,
        inputIndex != null ? pos.inputColumns[inputIndex] : pos.column,
        member.name.text,
      );
      return;
    }
    var sourcePos = instr.sourcePosition;
    if (inputIndex != null) {
      final inputPos = instr.inputDefAt(inputIndex).sourcePosition;
      if (inputPos != noPosition) {
        sourcePos = inputPos;
      }
    }
    if (sourcePos != noPosition) {
      final fileOffset = sourcePos.fileOffset;
      if (fileOffset != ast.TreeNode.noOffset) {
        final source = member.enclosingComponent?.uriToSource[member.fileUri];
        if (source != null && source.fileUri != null) {
          final location = source.getLocation(source.fileUri!, fileOffset);
          b.setSourcePosition(
            source.fileUri!,
            location.line - 1,
            location.column - 1,
            member.name.text,
          );
          return;
        }
      }
    }
    b.clearSourcePosition();
  }

  @nonVirtual
  w.Label targetLabel(Block to) {
    final continueLabel = _loopContinueLabels[to];
    if (continueLabel != null) return continueLabel;
    final label = _blockLabels[to];
    if (label == null) {
      throw StateError('No label found for target block B${to.preorderNumber}');
    }
    return label;
  }

  @nonVirtual
  w.Local getLocal(Definition def) => localAllocator.localOf(def);

  /// Returns the incoming Wasm parameter local for function parameter [instr]
  /// if it can be used directly (not shared via [WasmLocalAllocator]'s reusable
  /// pool), or `null` if a separate local must be allocated.
  w.Local? functionParameterLocal(Parameter instr);

  w.ValueType translateType(CType type);

  void convertType(w.ValueType from, w.ValueType to);

  @nonVirtual
  w.ValueType? get returnType {
    final outputs = b.outputs;
    return outputs.isEmpty ? null : outputs.single;
  }
}

/// Lowers individual CFG instructions to Wasm bytecode.
///
/// Code generation for an instruction has to consume all inputs and be done
/// with them before writing the result (as inputs and result may share the
/// same Wasm local).
abstract base class WasmInstructionLowerer<T extends CfgToWasm>
    extends DefaultInstructionVisitor<void> {
  final T gen;

  WasmInstructionLowerer(this.gen);

  @nonVirtual
  w.InstructionsBuilder get b => gen.b;

  /// Stores the top-of-stack value (of [stackType]) into [instr]'s Wasm local,
  /// or drops it if [instr] has no uses.
  @nonVirtual
  void storeResult(Definition instr, w.ValueType stackType) {
    if (instr.hasUses) {
      final resultLocal = gen.getLocal(instr);
      gen.convertType(stackType, resultLocal.type);
      b.local_set(resultLocal);
    } else {
      b.drop();
    }
  }

  @override
  @nonVirtual
  void defaultInstruction(Instruction instr) {
    throw UnimplementedError('Unsupported instruction: ${instr.runtimeType}');
  }

  @override
  @nonVirtual
  void visitEntryBlock(EntryBlock instr) {}

  @override
  @nonVirtual
  void visitTargetBlock(TargetBlock instr) {}

  @override
  @nonVirtual
  void visitJoinBlock(JoinBlock instr) {}

  @override
  @nonVirtual
  void visitPhi(Phi instr) {}

  @override
  @nonVirtual
  void visitConstant(Constant instr) {
    assert(instr.hasUses);
    if (instr.value.isTypeArgumentsConstant) {
      // Any use of of a [TypeArgumentsConstant] in the SSA graph will need to
      // handle it there, for example passing the individual type arguments
      // to a generic function invocation.
      // => So there's no need to try to materialize an object in a wasm local
      // for a [TypeArgumentsConstant] here.
      return;
    }
    if (gen.isUndefined(instr)) {
      // The undefined value can only be used as inputs on `Phi`s and we have a
      // guarantee the value will not be observed. The `Phi` block's
      // predecessors will populate it to the default value of the wasm local in
      // `assignPhis`.
      assert(instr.inputUses.every((u) => u.getInstruction(gen.graph) is Phi));
      return;
    }
    final expectedType = gen.localAllocator.wasmTypeOf(instr);
    instantiateConstant(instr, expectedType);
    storeResult(instr, expectedType);
  }

  void instantiateConstant(Constant instr, w.ValueType expectedType);

  @override
  @nonVirtual
  void visitBranch(Branch instr) {
    final condLocal = gen.getLocal(instr.condition);
    b.local_get(condLocal);
    gen.convertType(condLocal.type, w.NumType.i32);
    b.br_if(gen.targetLabel(instr.trueSuccessor));
    b.br(gen.targetLabel(instr.falseSuccessor));
  }

  @override
  @nonVirtual
  void visitGoto(Goto instr) {
    gen.assignPhis(instr.block!, instr.target);
    b.br(gen.targetLabel(instr.target));
  }

  @override
  @nonVirtual
  void visitComparison(Comparison instr) {
    switch (instr.op) {
      case ComparisonOpcode.equal:
      case ComparisonOpcode.notEqual:
      case ComparisonOpcode.identical:
      case ComparisonOpcode.notIdentical:
        final isNegated =
            instr.op == ComparisonOpcode.notEqual ||
            instr.op == ComparisonOpcode.notIdentical;
        if (instr.right.type is NullType) {
          _emitEqualsNull(instr.left, isNegated: isNegated);
          storeResult(instr, w.NumType.i32);
          return;
        }
        if (instr.left.type is NullType) {
          _emitEqualsNull(instr.right, isNegated: isNegated);
          storeResult(instr, w.NumType.i32);
          return;
        }
        if (!instr.left.type.canBeNum && !instr.right.type.canBeNum) {
          const eqRefType = w.RefType.eq(nullable: true);
          final leftLocal = gen.getLocal(instr.left);
          final rightLocal = gen.getLocal(instr.right);
          b.local_get(leftLocal);
          gen.convertType(leftLocal.type, eqRefType);
          b.local_get(rightLocal);
          gen.convertType(rightLocal.type, eqRefType);
          b.ref_eq();
          if (isNegated) b.i32_eqz();
          storeResult(instr, w.NumType.i32);
          return;
        }
        throw UnimplementedError(
          'Comparison ${instr.op} on (${instr.left.type}, ${instr.right.type})',
        );
      default:
        break;
    }

    b.local_get(gen.getLocal(instr.left));
    b.local_get(gen.getLocal(instr.right));

    switch (instr.op) {
      case ComparisonOpcode.intEqual:
        b.i64_eq();
      case ComparisonOpcode.intNotEqual:
        b.i64_ne();
      case ComparisonOpcode.intLess:
        b.i64_lt_s();
      case ComparisonOpcode.intLessOrEqual:
        b.i64_le_s();
      case ComparisonOpcode.intGreater:
        b.i64_gt_s();
      case ComparisonOpcode.intGreaterOrEqual:
        b.i64_ge_s();
      case ComparisonOpcode.doubleEqual:
        b.f64_eq();
      case ComparisonOpcode.doubleNotEqual:
        b.f64_ne();
      case ComparisonOpcode.doubleLess:
        b.f64_lt();
      case ComparisonOpcode.doubleLessOrEqual:
        b.f64_le();
      case ComparisonOpcode.doubleGreater:
        b.f64_gt();
      case ComparisonOpcode.doubleGreaterOrEqual:
        b.f64_ge();
      default:
        throw UnimplementedError('Comparison ${instr.op}');
    }

    storeResult(instr, w.NumType.i32);
  }

  void _emitEqualsNull(Definition operand, {required bool isNegated}) {
    if (operand.type is NullType) {
      b.i32_const(isNegated ? 0 : 1);
      return;
    }
    final local = gen.getLocal(operand);
    if (local.type.nullable) {
      b.local_get(local);
      b.ref_is_null();
      if (isNegated) b.i32_eqz();
    } else {
      b.i32_const(isNegated ? 1 : 0);
    }
  }

  @override
  @nonVirtual
  void visitBinaryIntOp(BinaryIntOp instr) {
    final leftLocal = gen.getLocal(instr.left);
    final rightLocal = gen.getLocal(instr.right);

    switch (instr.op) {
      case BinaryIntOpcode.add:
        b.local_get(leftLocal);
        b.local_get(rightLocal);
        b.i64_add();
      case BinaryIntOpcode.sub:
        b.local_get(leftLocal);
        b.local_get(rightLocal);
        b.i64_sub();
      case BinaryIntOpcode.mul:
        b.local_get(leftLocal);
        b.local_get(rightLocal);
        b.i64_mul();
      case BinaryIntOpcode.bitAnd:
        b.local_get(leftLocal);
        b.local_get(rightLocal);
        b.i64_and();
      case BinaryIntOpcode.bitOr:
        b.local_get(leftLocal);
        b.local_get(rightLocal);
        b.i64_or();
      case BinaryIntOpcode.bitXor:
        b.local_get(leftLocal);
        b.local_get(rightLocal);
        b.i64_xor();
      case BinaryIntOpcode.shiftLeft:
        final right = instr.right;
        if (right is Constant && right.value.intValue < 64) {
          b.local_get(leftLocal);
          b.local_get(rightLocal);
          b.i64_shl();
        } else {
          b.i64_const(0);
          b.local_get(leftLocal);
          b.local_get(rightLocal);
          b.i64_shl();
          b.local_get(rightLocal);
          b.i64_const(64);
          b.i64_ge_u();
          b.select(w.NumType.i64);
        }
      case BinaryIntOpcode.shiftRight:
        final right = instr.right;
        if (right is Constant && right.value.intValue < 64) {
          b.local_get(leftLocal);
          b.local_get(rightLocal);
          b.i64_shr_s();
        } else {
          b.local_get(leftLocal);
          b.i64_const(63);
          b.i64_shr_s();
          b.local_get(leftLocal);
          b.local_get(rightLocal);
          b.i64_shr_s();
          b.local_get(rightLocal);
          b.i64_const(64);
          b.i64_ge_u();
          b.select(w.NumType.i64);
        }
      case BinaryIntOpcode.unsignedShiftRight:
        final right = instr.right;
        if (right is Constant && right.value.intValue < 64) {
          b.local_get(leftLocal);
          b.local_get(rightLocal);
          b.i64_shr_u();
        } else {
          b.i64_const(0);
          b.local_get(leftLocal);
          b.local_get(rightLocal);
          b.i64_shr_u();
          b.local_get(rightLocal);
          b.i64_const(64);
          b.i64_ge_u();
          b.select(w.NumType.i64);
        }
      default:
        throw UnimplementedError('BinaryIntOp ${instr.op}');
    }

    storeResult(instr, w.NumType.i64);
  }

  @override
  @nonVirtual
  void visitUnaryIntOp(UnaryIntOp instr) {
    final operandLocal = gen.getLocal(instr.operand);

    switch (instr.op) {
      case UnaryIntOpcode.neg:
        b.i64_const(0);
        b.local_get(operandLocal);
        b.i64_sub();
      case UnaryIntOpcode.bitNot:
        b.local_get(operandLocal);
        b.i64_const(-1);
        b.i64_xor();
      default:
        throw UnimplementedError('UnaryIntOp ${instr.op}');
    }

    storeResult(instr, w.NumType.i64);
  }

  @override
  @nonVirtual
  void visitUnaryBoolOp(UnaryBoolOp instr) {
    final operandLocal = gen.getLocal(instr.operand);

    switch (instr.op) {
      case UnaryBoolOpcode.not:
        b.local_get(operandLocal);
        gen.convertType(operandLocal.type, w.NumType.i32);
        b.i32_eqz();
    }

    storeResult(instr, w.NumType.i32);
  }

  @override
  @nonVirtual
  void visitTypeCast(TypeCast instr) {
    assert(!instr.isChecked);
    assert(instr.hasUses);
    final operandLocal = gen.getLocal(instr.operand);
    b.local_get(operandLocal);
    storeResult(instr, operandLocal.type);
  }

  @override
  @nonVirtual
  void visitReturn(Return instr) {
    final returnType = gen.returnType;

    if (returnType != null) {
      final valueLocal = gen.getLocal(instr.value);
      b.local_get(valueLocal);
      gen.convertType(valueLocal.type, returnType);
    }

    b.return_();
  }

  @override
  @nonVirtual
  void visitUnreachable(Unreachable instr) {
    b.unreachable();
  }
}
