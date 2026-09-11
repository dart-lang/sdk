// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
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
    if (member is! ast.Procedure) return false;
    final procedure = member as ast.Procedure;
    if (procedure.isInstanceMember) return false;

    // In this initial commit, only support single-block graphs ending in Return.
    if (graph.preorder.length != 1) return false;
    if (graph.entryBlock.lastInstruction is! Return) return false;

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
    final lowerer = _WasmInstructionLowerer(this);
    for (final instr in graph.entryBlock) {
      instr.accept(lowerer);
    }
    b.end();
  }

  w.ValueType get returnType {
    final outputs = functionType.outputs;
    return outputs.isEmpty ? translator.voidMarker : outputs.single;
  }

  w.Local getLocal(Definition def) {
    return _locals[def] ??= _allocateLocal(def);
  }

  w.Local _allocateLocal(Definition def) {
    final wasmType = translator.translateType(def.type.dartType);
    return b.addLocal(wasmType);
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
      Constant() => true,
      Return() => true,
      Unreachable() => true,
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
