// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:wasm_builder/wasm_builder.dart' as w;

import '../../cfg/to_wasm.dart';
import '../../intrinsics.dart';
import '../../param_info.dart';
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
      UnaryBoolOp() => true,
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
    // TODO(nshahan): Support type arguments that depend on type parameters
    // (`TypeArguments` instruction).
    if (instr.hasTypeArguments && instr.typeArguments is! Constant) {
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
    _pushArguments(instr, signature, paramInfo);

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

  /// Pushes the arguments of [instr] onto the stack in the order and with the
  /// types expected by [signature], filling in the default values from
  /// [paramInfo] for omitted optional parameters.
  void _pushArguments(
    DirectCall instr,
    w.FunctionType signature,
    ParameterInfo paramInfo,
  ) {
    assert(
      signature.inputs.length ==
          paramInfo.typeParamCount + paramInfo.paramCount,
    );
    // Nothing to push, e.g. for getters and functions without parameters.
    if (signature.inputs.isEmpty) return;

    final argumentsShape = instr.argumentsShape;
    // Index of the first instruction input after the type arguments.
    int inputOffset = 0;
    // Index of the first signature input after the type arguments.
    int signatureOffset = 0;

    // Push the type arguments. They are passed as a single input but each type
    // argument is a separate function parameter.
    if (instr.hasTypeArguments) {
      final typeArguments =
          (instr.typeArguments as Constant).value.constant
              as TypeArgumentsConstant;
      assert(typeArguments.types.length == paramInfo.typeParamCount);
      for (int i = 0; i < typeArguments.types.length; ++i) {
        // TODO(nshahan): Support type arguments that depend on type parameters
        // (`TypeArguments` instruction).
        assert(translator.types.isTypeConstant(typeArguments.types[i]));
        translator.constants.instantiateConstant(
          b,
          ast.TypeLiteralConstant(typeArguments.types[i]),
          signature.inputs[i],
        );
      }
      // The CFG instruction packs all type arguments together into the input
      // at offset 0. Positional parameters start after that.
      inputOffset = 1;
      signatureOffset = typeArguments.types.length;
    }

    // Push the provided positional arguments.
    for (int i = 0; i < argumentsShape.positional; ++i) {
      final argLocal = gen.getLocal(instr.inputDefAt(inputOffset + i));
      b.local_get(argLocal);
      translator.convertType(
        b,
        argLocal.type,
        signature.inputs[signatureOffset + i],
      );
    }
    // Push default values for any remaining optional positional parameters.
    for (
      int i = argumentsShape.positional;
      i < paramInfo.positional.length;
      ++i
    ) {
      translator.constants.instantiateConstant(
        b,
        paramInfo.positional[i]!,
        signature.inputs[signatureOffset + i],
        dummyValueIfIncompatible: true,
      );
    }
    // Evaluate named arguments in the order they appear at the call site.
    final Map<String, w.Local> namedLocals = {
      for (int i = 0; i < argumentsShape.named.length; ++i)
        argumentsShape.named[i]: gen.getLocal(
          instr.inputDefAt(inputOffset + argumentsShape.positional + i),
        ),
    };
    // Re-order named arguments and push default values for optional named
    // parameters.
    for (var name in paramInfo.names) {
      final namedLocal = namedLocals[name];
      final type =
          signature.inputs[signatureOffset + paramInfo.nameIndex[name]!];
      if (namedLocal != null) {
        b.local_get(namedLocal);
        translator.convertType(b, namedLocal.type, type);
      } else {
        translator.constants.instantiateConstant(
          b,
          paramInfo.named[name]!,
          type,
          dummyValueIfIncompatible: true,
        );
      }
    }
  }
}
