// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:cfg/ir/visitor.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:wasm_builder/wasm_builder.dart' as w;

import '../reference_extensions.dart';
import '../translator.dart';

/// Translates a [FlowGraph] (CFG IR) to WebAssembly bytecode.
class CfgToWasm {
  final Translator translator;
  final w.FunctionType functionType;
  final ast.Member member;
  final FlowGraph graph;
  final w.InstructionsBuilder b;
  final List<w.Local> paramLocals;
  final w.Label? returnLabel;
  final EntryPoint kind;

  final Map<Definition, w.Local> _locals = {};
  final Map<Block, w.Label> _blockLabels = {};
  final Map<Block, w.Label> _loopContinueLabels = {};

  CfgToWasm(
    this.translator,
    this.functionType,
    this.member,
    this.graph,
    this.b,
    this.paramLocals,
    this.returnLabel, [
    this.kind = EntryPoint.normal,
  ]);

  bool canTranslate() {
    if (returnLabel != null) return false;
    if (kind != EntryPoint.normal) return false;
    if (member is! ast.Procedure) return false;
    final procedure = member as ast.Procedure;
    if (procedure.isInstanceMember) return false;

    for (final block in graph.preorder) {
      for (final instr in block) {
        if (!_WasmInstructionLowerer.canHandle(instr)) {
          return false;
        }
      }
    }
    return true;
  }

  void generate() {
    final entry = graph.entryBlock;
    _setupParameters(entry);

    // TODO(dart2wasm): The following translation currently assumes reducible
    // control flow graph. To add support irreducable control flow we can use
    // node splitting / block duplication.
    final lowerer = _WasmInstructionLowerer(this);
    _generateSubtree(entry, lowerer);

    b.end();
  }

  void _setupParameters(EntryBlock entry) {
    var paramIndex = 0;
    for (final instr in entry) {
      if (instr is Parameter) {
        if (paramIndex >= paramLocals.length) {
          throw StateError('Parameter index out of range for paramLocals');
        }
        final paramLocal = paramLocals[paramIndex++];
        final expectedType = _wasmTypeOf(instr);
        if (translator.needsConversion(paramLocal.type, expectedType)) {
          final convertedLocal = b.addLocal(expectedType);
          b.local_get(paramLocal);
          translator.convertType(b, paramLocal.type, expectedType);
          b.local_set(convertedLocal);
          _locals[instr] = convertedLocal;
        } else {
          _locals[instr] = paramLocal;
        }
      }
    }
    assert(paramIndex == paramLocals.length);
  }

  void _generateSubtree(Block u, _WasmInstructionLowerer lowerer) {
    final isLoopHeader = graph.loops[u]?.header == u;

    if (isLoopHeader) {
      final continueLabel = b.loop();
      _loopContinueLabels[u] = continueLabel;
    }

    for (final instr in u) {
      if (instr is! ControlFlowInstruction) {
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

  void assignPhis(Block from, Block to) {
    if (to is JoinBlock && to.hasPhis) {
      final predIndex = to.predecessors.indexOf(from);
      assert(predIndex >= 0);

      Phi? lastPhi;
      for (final phi in to.phis) {
        final inputDef = phi.inputDefAt(predIndex);
        final inputLocal = getLocal(inputDef);
        final phiLocal = getLocal(phi);
        b.local_get(inputLocal);
        translator.convertType(b, inputLocal.type, phiLocal.type);
        lastPhi = phi;
      }

      for (Instruction? instr = lastPhi; instr is Phi; instr = instr.previous) {
        final phiLocal = getLocal(instr);
        b.local_set(phiLocal);
      }
    }
  }

  w.Label targetLabel(Block to) {
    final continueLabel = _loopContinueLabels[to];
    if (continueLabel != null) return continueLabel;
    final label = _blockLabels[to];
    if (label == null) {
      throw StateError('No label found for target block B${to.preorderNumber}');
    }
    return label;
  }

  w.Local getLocal(Definition def) {
    return _locals[def] ??= _allocateLocal(def);
  }

  w.Local _allocateLocal(Definition def) {
    final wasmType = _wasmTypeOf(def).withNullability(true);
    return b.addLocal(wasmType);
  }

  w.ValueType _wasmTypeOf(Definition def) {
    final ctype = def.type;
    if (ctype is TopType) {
      return translator.topType;
    }
    return translator.translateType(ctype.dartType);
  }

  w.ValueType get returnType {
    final outputs = functionType.outputs;
    return outputs.isEmpty ? translator.voidMarker : outputs.single;
  }
}

class _WasmInstructionLowerer extends DefaultInstructionVisitor<void> {
  final CfgToWasm gen;

  _WasmInstructionLowerer(this.gen);

  Translator get translator => gen.translator;
  w.InstructionsBuilder get b => gen.b;

  static bool canHandle(Instruction instr) {
    return switch (instr) {
      EntryBlock() => true,
      TargetBlock() => true,
      JoinBlock() => true,
      Parameter() => true,
      Phi() => true,
      Constant() => true,
      Return() => true,
      Unreachable() => true,
      Branch() => true,
      Goto() => true,
      Comparison(:final op) => switch (op) {
        ComparisonOpcode.intEqual ||
        ComparisonOpcode.intNotEqual ||
        ComparisonOpcode.intLess ||
        ComparisonOpcode.intLessOrEqual ||
        ComparisonOpcode.intGreater => true,
        _ => false,
      },
      BinaryIntOp(:final op) =>
        !instr.canThrow &&
            op != BinaryIntOpcode.truncatingDiv &&
            op != BinaryIntOpcode.mod &&
            op != BinaryIntOpcode.rem,
      UnaryIntOp(:final op) =>
        op == UnaryIntOpcode.neg || op == UnaryIntOpcode.bitNot,
      _ => false,
    };
  }

  @override
  void defaultInstruction(Instruction instr) {
    throw UnimplementedError('Unsupported instruction: ${instr.runtimeType}');
  }

  @override
  void visitEntryBlock(EntryBlock instr) {}

  @override
  void visitTargetBlock(TargetBlock instr) {}

  @override
  void visitJoinBlock(JoinBlock instr) {}

  @override
  void visitParameter(Parameter instr) {}

  @override
  void visitPhi(Phi instr) {}

  @override
  void visitConstant(Constant instr) {
    if (!instr.hasUses) return;
    final local = gen.getLocal(instr);
    translator.constants.instantiateConstant(
      b,
      instr.value.constant,
      local.type,
    );
    b.local_set(local);
  }

  @override
  void visitBranch(Branch instr) {
    final condLocal = gen.getLocal(instr.condition);
    b.local_get(condLocal);
    translator.convertType(b, condLocal.type, w.NumType.i32);
    b.br_if(gen.targetLabel(instr.trueSuccessor));
    b.br(gen.targetLabel(instr.falseSuccessor));
  }

  @override
  void visitGoto(Goto instr) {
    gen.assignPhis(instr.block!, instr.target);
    b.br(gen.targetLabel(instr.target));
  }

  @override
  void visitComparison(Comparison instr) {
    final leftLocal = gen.getLocal(instr.left);
    final rightLocal = gen.getLocal(instr.right);
    final resultLocal = gen.getLocal(instr);

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
      default:
        throw UnimplementedError('Comparison ${instr.op}');
    }

    b.local_set(resultLocal);
  }

  @override
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
  void visitReturn(Return instr) {
    final valueDef = instr.value;
    final valueLocal = gen.getLocal(valueDef);
    final returnType = gen.returnType;

    if (returnType != translator.voidMarker) {
      b.local_get(valueLocal);
      translator.convertType(b, valueLocal.type, returnType);
    }

    if (gen.returnLabel != null) {
      b.br(gen.returnLabel!);
    } else {
      b.return_();
    }
  }

  @override
  void visitUnreachable(Unreachable instr) {
    b.unreachable();
  }
}
