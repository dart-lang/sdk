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

/// Translates a [FlowGraph] (CFG IR) to WebAssembly bytecode.
abstract base class CfgToWasm {
  final FlowGraph graph;
  final w.InstructionsBuilder b;
  final CfgLog? cfgLog;

  Map<Instruction, InstructionTextPosition>? _textPositions;

  final Map<Definition, w.Local> locals = {};
  final Map<Block, w.Label> _blockLabels = {};
  final Map<Block, w.Label> _loopContinueLabels = {};

  CfgToWasm(this.graph, this.b, {this.cfgLog});

  @nonVirtual
  ast.Member get member => graph.function.member;

  WasmInstructionLowerer get lowerer;

  @nonVirtual
  void generate() {
    _textPositions = cfgLog?.append(member, graph);

    // TODO(dart2wasm): The following translation currently assumes reducible
    // control flow graph. To add support irreducable control flow we can use
    // node splitting / block duplication.
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
      if (instr is! ControlFlowInstruction) {
        setDebugPosition(instr);
        instr.accept(lowerer);
      }
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
        setDebugPosition(phi, inputIndex: predIndex);
        final inputDef = phi.inputDefAt(predIndex);
        final inputLocal = getLocal(inputDef);
        final phiLocal = getLocal(phi);
        b.local_get(inputLocal);
        convertType(inputLocal.type, phiLocal.type);
        lastPhi = phi;
      }

      for (Instruction? instr = lastPhi; instr is Phi; instr = instr.previous) {
        setDebugPosition(instr, inputIndex: predIndex);
        final phiLocal = getLocal(instr);
        b.local_set(phiLocal);
      }
      setDebugPosition(from.lastInstruction);
    }
  }

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
  w.Local getLocal(Definition def) {
    return locals[def] ??= _allocateLocal(def);
  }

  w.Local _allocateLocal(Definition def) {
    final wasmType = translateType(def.type).withNullability(true);
    return b.addLocal(wasmType);
  }

  w.ValueType translateType(CType type);

  void convertType(w.ValueType from, w.ValueType to);

  @nonVirtual
  w.ValueType? get returnType {
    final outputs = b.outputs;
    return outputs.isEmpty ? null : outputs.single;
  }
}

abstract base class WasmInstructionLowerer<T extends CfgToWasm>
    extends DefaultInstructionVisitor<void> {
  final T gen;

  WasmInstructionLowerer(this.gen);

  @nonVirtual
  w.InstructionsBuilder get b => gen.b;

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
    if (!instr.hasUses) return;
    if (instr.value.isTypeArgumentsConstant) {
      // Any use of of a [TypeArgumentsConstant] in the SSA graph will need to
      // handle it there, for example passing the individual type arguments
      // to a generic function invocation.
      // => So there's no need to try to materialize an object in a wasm local
      // for a [TypeArgumentsConstant] here.
      return;
    }
    final local = gen.getLocal(instr);
    instantiateConstant(instr, local.type);
    b.local_set(local);
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
    final leftLocal = gen.getLocal(instr.left);
    final rightLocal = gen.getLocal(instr.right);
    final resultLocal = gen.getLocal(instr);

    switch (instr.op) {
      case ComparisonOpcode.equal:
      case ComparisonOpcode.notEqual:
      case ComparisonOpcode.identical:
      case ComparisonOpcode.notIdentical:
        final isNegated =
            instr.op == ComparisonOpcode.notEqual ||
            instr.op == ComparisonOpcode.notIdentical;
        if (instr.right.type is NullType) {
          if (leftLocal.type.nullable) {
            b.local_get(leftLocal);
            b.ref_is_null();
            if (isNegated) b.i32_eqz();
          } else {
            b.i32_const(isNegated ? 1 : 0);
          }
          b.local_set(resultLocal);
          return;
        }
        if (instr.left.type is NullType) {
          if (rightLocal.type.nullable) {
            b.local_get(rightLocal);
            b.ref_is_null();
            if (isNegated) b.i32_eqz();
          } else {
            b.i32_const(isNegated ? 1 : 0);
          }
          b.local_set(resultLocal);
          return;
        }
        if (!instr.left.type.canBeNum && !instr.right.type.canBeNum) {
          const eqRefType = w.RefType.eq(nullable: true);
          b.local_get(leftLocal);
          gen.convertType(leftLocal.type, eqRefType);
          b.local_get(rightLocal);
          gen.convertType(rightLocal.type, eqRefType);
          b.ref_eq();
          if (isNegated) b.i32_eqz();
          b.local_set(resultLocal);
          return;
        }
        throw UnimplementedError(
          'Comparison ${instr.op} on (${instr.left.type}, ${instr.right.type})',
        );
      default:
        break;
    }

    b.local_get(leftLocal);
    b.local_get(rightLocal);

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

    b.local_set(resultLocal);
  }

  @override
  @nonVirtual
  void visitBinaryIntOp(BinaryIntOp instr) {
    final leftLocal = gen.getLocal(instr.left);
    final rightLocal = gen.getLocal(instr.right);
    final resultLocal = gen.getLocal(instr);

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

    b.local_set(resultLocal);
  }

  @override
  @nonVirtual
  void visitUnaryIntOp(UnaryIntOp instr) {
    final operandLocal = gen.getLocal(instr.operand);
    final resultLocal = gen.getLocal(instr);

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

    b.local_set(resultLocal);
  }

  @override
  @nonVirtual
  void visitUnaryBoolOp(UnaryBoolOp instr) {
    final operandLocal = gen.getLocal(instr.operand);
    final resultLocal = gen.getLocal(instr);

    switch (instr.op) {
      case UnaryBoolOpcode.not:
        b.local_get(operandLocal);
        gen.convertType(operandLocal.type, w.NumType.i32);
        b.i32_eqz();
    }

    b.local_set(resultLocal);
  }

  @override
  @nonVirtual
  void visitTypeCast(TypeCast instr) {
    assert(!instr.isChecked);
    if (!instr.hasUses) return;
    final operandLocal = gen.getLocal(instr.operand);
    final resultLocal = gen.getLocal(instr);
    b.local_get(operandLocal);
    gen.convertType(operandLocal.type, resultLocal.type);
    b.local_set(resultLocal);
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
