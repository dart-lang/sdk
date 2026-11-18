// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/field.dart';
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
import '../../types.dart';

/// Translates a [FlowGraph] (CFG IR) to WebAssembly bytecode for the
/// production compiler.
final class ProdCfgToWasm extends CfgToWasm {
  final Translator translator;
  final EntryPoint kind;
  final List<w.Local> paramLocals;

  /// The locals holding the type arguments built for each [TypeArguments]
  /// instruction.
  ///
  /// Each list has one element per type argument. The element is `null` for
  /// constant type arguments, which are instantiated where they are used.
  final Map<TypeArguments, List<w.Local?>> typeArgumentLocals = {};

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
    final member = this.member;
    switch (member) {
      case ast.Procedure():
        if (member.isInstanceMember) return false;
      case ast.Field():
        if (!member.isInstanceMember) return false;
        if (member.enclosingClass!.typeParameters.isNotEmpty) return false;
      default:
        return false;
    }

    for (final block in graph.preorder) {
      for (final instr in block) {
        if (!lowerer.canHandle(instr)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Returns the wasm local holding the incoming value for the SSA [instr]
  /// Parameter.
  w.Local wasmParameter(Parameter instr) {
    assert(instr.isFunctionParameter);
    assert(!instr.variable.isFunctionTypeParametersVariable);
    final typeParameterCount = graph.function.numberOfFunctionTypeParameters;
    final wasmIndex = typeParameterCount == 0
        ? instr.variable.index
        : instr.variable.index - 1 + typeParameterCount;
    return paramLocals[wasmIndex];
  }

  @override
  w.Local? functionParameterLocal(Parameter instr) {
    final paramLocal = wasmParameter(instr);
    final expectedType = translateType(instr.type);
    return translator.needsConversion(paramLocal.type, expectedType)
        ? null
        : paramLocal;
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
    extends WasmInstructionLowerer<ProdCfgToWasm>
    implements TypeCodeGenerator {
  ProdWasmInstructionLowerer(super.gen);

  Translator get translator => gen.translator;

  bool canHandle(Instruction instr) {
    return switch (instr) {
      EntryBlock() => true,
      TargetBlock() => true,
      JoinBlock() => true,
      Parameter() => true,
      Phi() => true,
      Constant() =>
        !gen.isUndefined(instr) ||
            instr.inputUses.every((u) => u.getInstruction(gen.graph) is Phi),
      // TODO(dart2wasm): Support class type parameters.
      TypeParameters(:final kind) =>
        kind == TypeParametersKind.functionTypeParameters,
      TypeArguments() => true,
      Return() => true,
      Unreachable() => true,
      Branch() => true,
      Goto() => true,
      TypeTest() => true,
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
        ComparisonOpcode.equal ||
        ComparisonOpcode.notEqual ||
        ComparisonOpcode.identical ||
        ComparisonOpcode.notIdentical =>
          instr.left.type is NullType ||
              instr.right.type is NullType ||
              (!instr.left.type.canBeNum && !instr.right.type.canBeNum),
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
      TypeCast(:final isChecked) => !isChecked,
      LoadInstanceField() => _canHandleInstanceField(instr.field),
      StoreInstanceField() => _canHandleInstanceField(instr.field),
      DirectCall() => _canHandleDirectCall(instr),
      _ => false,
    };
  }

  bool _canHandleInstanceField(CField field) {
    if (field.isSynthetic) return false;
    return translator.fieldIndex.containsKey(field.astField);
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
    assert(instr.hasUses);
    // The CFG passes all function type arguments in a single parameter, but
    // the wasm function has a separate `_Type` parameter for each of them.
    // Uses of the type parameters load them directly from those wasm
    // parameters in [instantiateTypeParameter].
    if (instr.variable.isFunctionTypeParametersVariable) return;
    final paramLocal = gen.wasmParameter(instr);
    final local = gen.getLocal(instr);
    if (local != paramLocal) {
      b.local_get(paramLocal);
      gen.convertType(paramLocal.type, local.type);
      b.local_set(local);
    }
  }

  @override
  void visitTypeParameters(TypeParameters instr) {
    // Nothing to do here. Currently only function type parameters are
    // loaded from their wasm parameter local when needed for TypeArgument
    // instructions.
    //
    // Other instructions uses are not yet supported.
  }

  @override
  void visitTypeArguments(TypeArguments instr) {
    // Build each non-constant type argument once and store it in a local, so
    // all users of this instruction can share it.
    final locals = <w.Local?>[];
    final typeType = translator.types.nonNullableTypeType;
    for (final typeArgument in instr.types) {
      if (translator.types.isTypeConstant(typeArgument)) {
        locals.add(null);
      } else {
        final local = b.addLocal(typeType);
        translator.types.makeType(this, typeArgument);
        b.local_set(local);
        locals.add(local);
      }
    }
    gen.typeArgumentLocals[instr] = locals;
  }

  @override
  w.ValueType instantiateTypeParameter(ast.TypeParameter parameter) {
    final index = gen.member.function!.typeParameters.indexOf(parameter);
    if (index < 0) {
      throw UnsupportedError('Type parameter $parameter is not in scope.');
    }
    final local = gen.paramLocals[index];
    b.local_get(local);
    translator.convertType(b, local.type, translator.types.nonNullableTypeType);
    return translator.types.nonNullableTypeType;
  }

  @override
  void visitTypeTest(TypeTest instr) {
    if (!instr.hasUses) return;
    final operand = instr.operand;
    final operandLocal = gen.getLocal(operand);
    final operandType = operand.type.dartType;
    final boxedOperandType = operandType.isPotentiallyNullable
        ? translator.topType
        : translator.topTypeNonNullable;
    b.local_get(operandLocal);
    translator.convertType(b, operandLocal.type, boxedOperandType);
    translator.types.emitIsTest(this, instr.testedType.dartType, operandType);
    b.local_set(gen.getLocal(instr));
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
  void visitLoadInstanceField(LoadInstanceField instr) {
    assert(!instr.checkInitialized);
    final field = instr.field.astField;
    final info = translator.classInfo[field.enclosingClass!]!;
    final fieldIndex = translator.fieldIndex[field]!;
    final objectLocal = gen.getLocal(instr.object);

    b.local_get(objectLocal);
    gen.convertType(objectLocal.type, info.nonNullableType);
    b.struct_get(info.struct, fieldIndex);
    storeResult(instr, info.struct.fields[fieldIndex].type.unpacked);
  }

  @override
  void visitStoreInstanceField(StoreInstanceField instr) {
    assert(!instr.checkNotInitialized);
    final field = instr.field.astField;
    final info = translator.classInfo[field.enclosingClass!]!;
    final fieldIndex = translator.fieldIndex[field]!;
    final objectLocal = gen.getLocal(instr.object);
    final valueLocal = gen.getLocal(instr.value);

    b.local_get(objectLocal);
    gen.convertType(objectLocal.type, info.nonNullableType);
    b.local_get(valueLocal);
    gen.convertType(
      valueLocal.type,
      info.struct.fields[fieldIndex].type.unpacked,
    );
    b.struct_set(info.struct, fieldIndex);
  }

  @override
  void visitDirectCall(DirectCall instr) {
    final reference = instr.target.member.reference;
    final signature = translator.signatureForDirectCall(reference);
    final paramInfo = translator.paramInfoForDirectCall(reference);
    _pushArguments(instr, signature, paramInfo);

    final outputs = translator.callReference(reference, b);

    // Either the call never returns (`callReference` emitted `unreachable`) or
    // it produces no Wasm value (e.g. returns `WasmVoid`).
    if (outputs.isEmpty) return;

    assert(outputs.length == 1);
    storeResult(instr, outputs.single);
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
    // argument is passed as a separate function parameter, typed as a
    // non-nullable `_Type`.
    if (instr.hasTypeArguments) {
      final typeArgumentsDef = instr.typeArguments!;
      final List<ast.DartType> types;
      switch (typeArgumentsDef) {
        case Constant(value: ConstantValue(:TypeArgumentsConstant constant)):
          // All type arguments are constant.
          types = constant.types;
          for (int i = 0; i < types.length; ++i) {
            _pushConstantType(types[i]);
          }
        case TypeArguments():
          // Some type arguments depend on type parameters.
          types = typeArgumentsDef.types;
          final locals = gen.typeArgumentLocals[typeArgumentsDef]!;
          for (int i = 0; i < types.length; ++i) {
            final local = locals[i];
            // [visitTypeArguments] stored those in locals with `null` element
            // placeholders where constant types should be pushed instead.
            local == null ? _pushConstantType(types[i]) : b.local_get(local);
          }

        default:
          throw StateError('Unexpected type arguments: $typeArgumentsDef');
      }
      assert(types.length == paramInfo.typeParamCount);
      // The CFG instruction packs all type arguments together into the input
      // at offset 0. Positional parameters start after that.
      inputOffset = 1;
      signatureOffset = types.length;
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

  /// Pushes the constant `_Type` for [type], loaded from its constant global.
  void _pushConstantType(ast.DartType type) {
    translator.constants.instantiateConstant(
      b,
      ast.TypeLiteralConstant(type),
      translator.types.nonNullableTypeType,
    );
  }
}
