// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:wasm_builder/wasm_builder.dart' as w;

import '../../cfg/to_wasm.dart';
import '../../intrinsics.dart';
import '../../reference_extensions.dart';
import '../../translator.dart';

/// Translates a [FlowGraph] (CFG IR) to WebAssembly bytecode for the
/// production compiler.
final class ProdCfgToWasm extends CfgToWasm {
  final Translator translator;
  final List<w.Local> paramLocals;
  final EntryPoint kind;

  @override
  late final ProdWasmInstructionLowerer lowerer = ProdWasmInstructionLowerer(
    this,
  );

  ProdCfgToWasm(
    this.translator,
    super.graph,
    super.b,
    this.paramLocals, {
    this.kind = EntryPoint.normal,
  }) : super(cfgLog: translator.cfgLog);

  bool canTranslate() {
    if (kind != EntryPoint.normal) return false;
    if (member is! ast.Procedure) return false;
    final procedure = member as ast.Procedure;
    if (procedure.isInstanceMember) return false;

    for (final block in graph.preorder) {
      for (final instr in block) {
        if (!lowerer.canHandle(instr)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  w.ValueType translateType(CType type) {
    if (type is TopType) {
      return translator.topType;
    }
    return translator.translateType(type.dartType);
  }

  @override
  void convertType(w.ValueType from, w.ValueType to) {
    translator.convertType(b, from, to);
  }
}

final class ProdWasmInstructionLowerer
    extends WasmInstructionLowerer<ProdCfgToWasm> {
  ProdWasmInstructionLowerer(super.gen);

  Translator get translator => gen.translator;

  bool canHandle(Instruction instr) {
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
        ComparisonOpcode.intGreater ||
        ComparisonOpcode.intGreaterOrEqual ||
        ComparisonOpcode.doubleEqual ||
        ComparisonOpcode.doubleNotEqual ||
        ComparisonOpcode.doubleLess ||
        ComparisonOpcode.doubleLessOrEqual ||
        ComparisonOpcode.doubleGreater ||
        ComparisonOpcode.doubleGreaterOrEqual => true,
        _ => false,
      },
      BinaryIntOp(:final op) =>
        !instr.canThrow &&
            op != BinaryIntOpcode.truncatingDiv &&
            op != BinaryIntOpcode.mod &&
            op != BinaryIntOpcode.rem,
      UnaryIntOp(:final op) =>
        op == UnaryIntOpcode.neg || op == UnaryIntOpcode.bitNot,
      DirectCall() => _canHandleDirectCall(instr),
      _ => false,
    };
  }

  bool _canHandleDirectCall(DirectCall instr) {
    final target = instr.target;
    // TODO(nshahan): Support generative constructors (paired with
    // AllocateObject) and super calls.
    if (target is! RegularFunction &&
        target is! GetterFunction &&
        target is! SetterFunction) {
      return false;
    }
    final member = target.member;
    if (member is! ast.Procedure || member.isInstanceMember) return false;
    // TODO(nshahan): Support generic calls (TypeArguments input).
    if (target.hasFunctionTypeParameters) return false;
    // TODO(nshahan): Support named parameters.
    final function = member.function;
    final shape = instr.argumentsShape;
    if (function.namedParameters.isNotEmpty || shape.named.isNotEmpty) {
      return false;
    }
    // TODO(nshahan): Support intrinsics and external effects (see
    // `CodeGenerator.visitStaticInvocation`).
    if (member.isExternal ||
        member.hasExternalEffectPragma ||
        StaticIntrinsic.fromProcedure(translator.coreTypes, member) != null) {
      return false;
    }
    return true;
  }

  @override
  void visitParameter(Parameter instr) {
    assert(instr.isFunctionParameter);
    final paramLocal = gen.paramLocals[instr.variable.index];
    final expectedType = gen.translateType(instr.type);
    if (translator.needsConversion(paramLocal.type, expectedType)) {
      final convertedLocal = b.addLocal(expectedType);
      b.local_get(paramLocal);
      translator.convertType(b, paramLocal.type, expectedType);
      b.local_set(convertedLocal);
      gen.locals[instr] = convertedLocal;
    } else {
      gen.locals[instr] = paramLocal;
    }
  }

  @override
  void instantiateConstant(Constant instr, w.ValueType expectedType) {
    translator.constants.instantiateConstant(
      b,
      instr.value.constant,
      expectedType,
    );
  }

  @override
  void visitDirectCall(DirectCall instr) {
    final reference = instr.target.member.reference;
    final signature = translator.signatureForDirectCall(reference);
    final paramInfo = translator.paramInfoForDirectCall(reference);
    // TODO(nshahan): Needs adjustment when adding support for type arguments
    // and named parameters.
    assert(signature.inputs.length == paramInfo.positional.length);
    for (int i = 0; i < instr.inputCount; ++i) {
      final argLocal = gen.getLocal(instr.inputDefAt(i));
      b.local_get(argLocal);
      // Ensure the argument types match the expected funcction parameter types.
      translator.convertType(b, argLocal.type, signature.inputs[i]);
    }
    // Push default values for omitted optional positional parameters.
    for (int i = instr.inputCount; i < paramInfo.positional.length; ++i) {
      translator.constants.instantiateConstant(
        b,
        paramInfo.positional[i]!,
        signature.inputs[i],
        dummyValueIfIncompatible: true,
      );
    }

    final outputs = translator.callReference(reference, b);

    if (!instr.hasUses) {
      // Cleanup stack if results of the call are not used.
      for (int i = 0; i < outputs.length; ++i) {
        b.drop();
      }
      return;
    }

    // `callReference` emitted `unreachable` because the call never returns.
    if (outputs.isEmpty) return;

    assert(outputs.length == 1);
    final resultLocal = gen.getLocal(instr);
    translator.convertType(b, outputs.single, resultLocal.type);
    b.local_set(resultLocal);
  }
}
