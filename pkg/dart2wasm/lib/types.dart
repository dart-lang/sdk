// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show max;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart' as type_env;
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'code_generator.dart';
import 'dispatch_table.dart' show Row, buildRowDisplacementTable;
import 'translator.dart';

/// Values for the `_kind` field in `_TopType`. Must match the definitions in
/// `_TopType`.
class TopTypeKind {
  static const int objectKind = 0;
  static const int dynamicKind = 1;
  static const int voidKind = 2;
}

class InterfaceTypeEnvironment {
  final Map<TypeParameter, int> _typeOffsets = {};

  void _add(InterfaceType type) {
    Class cls = type.classNode;
    int i = 0;
    for (TypeParameter typeParameter in cls.typeParameters) {
      _typeOffsets[typeParameter] = i++;
    }
  }

  int lookup(TypeParameter typeParameter) => _typeOffsets[typeParameter]!;
}

/// Helper class for building runtime types.
class Types {
  final Translator translator;

  /// Class info for `_Type`
  late final ClassInfo typeClassInfo =
      translator.classInfo[translator.typeClass]!;

  /// Wasm value type of `List<_Type>`
  late final w.ValueType typeListExpectedType =
      translator.classInfo[translator.listBaseClass]!.nonNullableType;

  /// Wasm array type of `WasmArray<_Type>`
  late final w.ArrayType typeArrayArrayType =
      translator.arrayTypeForDartType(typeType);

  /// Wasm value type of `WasmArray<_Type>`
  late final w.ValueType typeArrayExpectedType =
      w.RefType.def(typeArrayArrayType, nullable: false);

  /// Wasm value type of `WasmArray<_NamedParameter>`
  late final w.ValueType namedParametersExpectedType = classAndFieldToType(
      translator.functionTypeClass, FieldIndex.functionTypeNamedParameters);

  /// Wasm value type of `_RecordType.names` field.
  late final w.ValueType recordTypeNamesFieldExpectedType = classAndFieldToType(
      translator.recordTypeClass, FieldIndex.recordTypeNames);

  late final RuntimeTypeInformation rtt = RuntimeTypeInformation(translator);

  /// We will build the [interfaceTypeEnvironment] when building the
  /// [typeRules].
  final InterfaceTypeEnvironment interfaceTypeEnvironment =
      InterfaceTypeEnvironment();

  /// Type parameter offset for function types, specifying the lower end of
  /// their index range for type parameter types.
  Map<FunctionType, int> functionTypeParameterOffset = Map.identity();

  /// Index value for function type parameter types, indexing into the type
  /// parameter index range of their corresponding function type.
  Map<StructuralParameter, int> functionTypeParameterIndex = Map.identity();

  Types(this.translator);

  w.ValueType classAndFieldToType(Class cls, int fieldIndex) =>
      translator.classInfo[cls]!.struct.fields[fieldIndex].type.unpacked;

  /// Wasm value type for non-nullable `_Type` values
  w.ValueType get nonNullableTypeType => typeClassInfo.nonNullableType;

  InterfaceType get namedParameterType =>
      InterfaceType(translator.namedParameterClass, Nullability.nonNullable);

  InterfaceType get typeType =>
      InterfaceType(translator.typeClass, Nullability.nonNullable);

  CoreTypes get coreTypes => translator.coreTypes;

  bool isTypeConstant(DartType type) {
    return type is DynamicType ||
        type is VoidType ||
        type is NeverType ||
        type is NullType ||
        type is FutureOrType && isTypeConstant(type.typeArgument) ||
        (type is FunctionType &&
            type.typeParameters.every((p) => isTypeConstant(p.bound)) &&
            isTypeConstant(type.returnType) &&
            type.positionalParameters.every(isTypeConstant) &&
            type.namedParameters.every((n) => isTypeConstant(n.type))) ||
        type is InterfaceType && type.typeArguments.every(isTypeConstant) ||
        (type is RecordType &&
            type.positional.every(isTypeConstant) &&
            type.named.every((n) => isTypeConstant(n.type))) ||
        type is StructuralParameterType ||
        type is ExtensionType && isTypeConstant(type.extensionTypeErasure);
  }

  Class classForType(DartType type) {
    if (type is DynamicType) {
      return translator.topTypeClass;
    } else if (type is VoidType) {
      return translator.topTypeClass;
    } else if (type is NeverType) {
      return translator.bottomTypeClass;
    } else if (type is NullType) {
      return translator.bottomTypeClass;
    } else if (type is FutureOrType) {
      return translator.futureOrTypeClass;
    } else if (type is InterfaceType) {
      if (type.classNode == coreTypes.objectClass) {
        return translator.topTypeClass;
      }
      if (type.classNode == coreTypes.functionClass) {
        return translator.abstractFunctionTypeClass;
      }
      if (type.classNode == coreTypes.recordClass) {
        return translator.abstractRecordTypeClass;
      }
      return translator.interfaceTypeClass;
    } else if (type is FunctionType) {
      return translator.functionTypeClass;
    } else if (type is TypeParameterType) {
      return translator.interfaceTypeParameterTypeClass;
    } else if (type is StructuralParameterType) {
      return translator.functionTypeParameterTypeClass;
    } else if (type is ExtensionType) {
      return classForType(type.extensionTypeErasure);
    } else if (type is RecordType) {
      return translator.recordTypeClass;
    }
    throw "Unexpected DartType: $type";
  }

  bool isSpecializedClass(Class cls) {
    return cls == coreTypes.objectClass ||
        cls == coreTypes.functionClass ||
        cls == coreTypes.recordClass;
  }

  int topTypeKind(DartType type) {
    return type is VoidType
        ? TopTypeKind.voidKind
        : type is DynamicType
            ? TopTypeKind.dynamicKind
            : TopTypeKind.objectKind;
  }

  /// Allocates a `WasmArray<_Type>` from [types] and pushes it to the
  /// stack.
  void _makeTypeArray(CodeGenerator codeGen, Iterable<DartType> types) {
    if (types.every(isTypeConstant)) {
      translator.constants.instantiateConstant(codeGen.b,
          translator.constants.makeTypeArray(types), typeArrayExpectedType);
    } else {
      for (DartType type in types) {
        makeType(codeGen, type);
      }
      codeGen.b.array_new_fixed(typeArrayArrayType, types.length);
    }
  }

  void _makeInterfaceType(CodeGenerator codeGen, InterfaceType type) {
    final b = codeGen.b;
    ClassInfo typeInfo = translator.classInfo[type.classNode]!;
    b.i32_const(encodedNullability(type));
    b.i32_const(typeInfo.classId);
    _makeTypeArray(codeGen, type.typeArguments);
  }

  void _makeRecordType(CodeGenerator codeGen, RecordType type) {
    codeGen.b.i32_const(encodedNullability(type));

    final names = translator.constants.makeArrayOf(
        translator.coreTypes.stringNonNullableRawType,
        type.named.map((t) => StringConstant(t.name)).toList());

    translator.constants.instantiateConstant(
        codeGen.b, names, recordTypeNamesFieldExpectedType);
    _makeTypeArray(
        codeGen, type.positional.followedBy(type.named.map((t) => t.type)));
  }

  /// Normalizes a Dart type. Many rules are already applied for us, but we
  /// still have to manually turn `Never?` into `Null` and normalize `FutureOr`.
  DartType normalize(DartType type) {
    if (type is NeverType && type.declaredNullability == Nullability.nullable) {
      return const NullType();
    }

    if (type is! FutureOrType) return type;

    final s = normalize(type.typeArgument);

    // `coreTypes.isTop` and `coreTypes.isObject` take into account the
    // normalization rules of `FutureOr`.
    if (coreTypes.isTop(type) || coreTypes.isObject(type)) {
      return type.declaredNullability == Nullability.nullable
          ? s.withDeclaredNullability(Nullability.nullable)
          : s;
    } else if (s is NeverType) {
      return InterfaceType(coreTypes.futureClass, Nullability.nonNullable,
          const [NeverType.nonNullable()]);
    } else if (s is NullType) {
      return InterfaceType(
          coreTypes.futureClass, Nullability.nullable, const [NullType()]);
    }

    // The type is normalized, and remains a `FutureOr` so now we normalize its
    // nullability.
    // Note: We diverge from the spec here and normalize the type to nullable if
    // its type argument is nullable, since this simplifies subtype checking.
    // We compensate for this difference when converting the type to a string,
    // making the discrepancy invisible to the user.
    final declaredNullability = s.nullability == Nullability.nullable
        ? Nullability.nullable
        : type.declaredNullability;
    return FutureOrType(s, declaredNullability);
  }

  void _makeFutureOrType(CodeGenerator codeGen, FutureOrType type) {
    final b = codeGen.b;
    b.i32_const(encodedNullability(type));
    makeType(codeGen, type.typeArgument);
    codeGen.call(translator.createNormalizedFutureOrType.reference);
  }

  void _makeFunctionType(CodeGenerator codeGen, FunctionType type) {
    int typeParameterOffset = computeFunctionTypeParameterOffset(type);
    final b = codeGen.b;
    b.i32_const(encodedNullability(type));
    b.i64_const(typeParameterOffset);

    // WasmArray<_Type> typeParameterBounds
    _makeTypeArray(codeGen, type.typeParameters.map((p) => p.bound));

    // WasmArray<_Type> typeParameterDefaults
    _makeTypeArray(codeGen, type.typeParameters.map((p) => p.defaultType));

    // _Type returnType
    makeType(codeGen, type.returnType);

    // WasmArray<_Type> positionalParameters
    _makeTypeArray(codeGen, type.positionalParameters);

    // int requiredParameterCount
    b.i64_const(type.requiredParameterCount);

    // WasmArray<_NamedParameter> namedParameters
    if (type.namedParameters.every((n) => isTypeConstant(n.type))) {
      translator.constants.instantiateConstant(
          b,
          translator.constants.makeNamedParametersArray(type),
          namedParametersExpectedType);
    } else {
      Class namedParameterClass = translator.namedParameterClass;
      Constructor namedParameterConstructor =
          namedParameterClass.constructors.single;
      List<Expression> expressions = [];
      for (NamedType n in type.namedParameters) {
        expressions.add(isTypeConstant(n.type)
            ? ConstantExpression(
                translator.constants.makeNamedParameterConstant(n),
                namedParameterType)
            : ConstructorInvocation(
                namedParameterConstructor,
                Arguments([
                  StringLiteral(n.name),
                  TypeLiteral(n.type),
                  BoolLiteral(n.isRequired)
                ])));
      }
      w.ValueType namedParametersListType =
          codeGen.makeArrayFromExpressions(expressions, namedParameterType);
      translator.convertType(
          b, namedParametersListType, namedParametersExpectedType);
    }
  }

  /// Makes a `_Type` object on the stack.
  /// TODO(joshualitt): Refactor this logic to remove the dependency on
  /// CodeGenerator.
  w.ValueType makeType(CodeGenerator codeGen, DartType type) {
    // Always ensure type is normalized before making a type.
    type = normalize(type);
    final b = codeGen.b;
    if (isTypeConstant(type)) {
      translator.constants.instantiateConstant(
          b, TypeLiteralConstant(type), nonNullableTypeType);
      return nonNullableTypeType;
    }
    // All of the singleton types represented by canonical objects should be
    // created const.
    assert(type is TypeParameterType ||
        type is ExtensionType ||
        type is InterfaceType ||
        type is FutureOrType ||
        type is FunctionType ||
        type is RecordType);
    if (type is TypeParameterType) {
      codeGen.instantiateTypeParameter(type.parameter);
      if (type.declaredNullability == Nullability.nullable) {
        codeGen.call(translator.typeAsNullable.reference);
      }
      return nonNullableTypeType;
    }

    if (type is ExtensionType) {
      return makeType(codeGen, type.extensionTypeErasure);
    }

    ClassInfo info = translator.classInfo[classForType(type)]!;
    if (type is FutureOrType) {
      _makeFutureOrType(codeGen, type);
      return info.nonNullableType;
    }

    translator.functions.recordClassAllocation(info.classId);
    b.i32_const(info.classId);
    b.i32_const(initialIdentityHash);
    if (type is InterfaceType) {
      _makeInterfaceType(codeGen, type);
    } else if (type is FunctionType) {
      _makeFunctionType(codeGen, type);
    } else if (type is RecordType) {
      _makeRecordType(codeGen, type);
    } else {
      throw '`$type` should have already been handled.';
    }
    b.struct_new(info.struct);
    return info.nonNullableType;
  }

  /// Compute the lower end of the type parameter index range for this function
  /// type. This is computed such that it avoids overlap between the index range
  /// of this function type and the index ranges of all generic function types
  /// nested within it that contain references to the type parameters of this
  /// function type.
  ///
  /// This will also compute the index values for all of the function's type
  /// parameters, which can subsequently be queried using
  /// [getFunctionTypeParameterIndex].
  int computeFunctionTypeParameterOffset(FunctionType type) {
    if (type.typeParameters.isEmpty) return 0;
    int? offset = functionTypeParameterOffset[type];
    if (offset != null) return offset;
    _FunctionTypeParameterOffsetCollector(this).visitFunctionType(type);
    return functionTypeParameterOffset[type]!;
  }

  /// Get the index value for a function type parameter, indexing into the
  /// type parameter index range of its corresponding function type.
  int getFunctionTypeParameterIndex(StructuralParameter type) {
    assert(functionTypeParameterIndex.containsKey(type),
        "Type parameter offset has not been computed for function type");
    return functionTypeParameterIndex[type]!;
  }

  /// Emit code for testing a value against a Dart type. Expects the value on
  /// the stack as a (ref null #Top) and leaves the result on the stack as an
  /// i32.
  void emitIsTest(
      CodeGenerator codeGen, DartType testedAgainstType, DartType operandType,
      [Location? location]) {
    final b = codeGen.b;
    b.comment("type check against $testedAgainstType");
    w.Local? operandTemp;
    if (translator.options.verifyTypeChecks) {
      operandTemp = b.addLocal(translator.topInfo.nullableType);
      b.local_tee(operandTemp);
    }
    final (typeToCheck, :checkArguments) =
        _canUseTypeCheckHelper(testedAgainstType, operandType);
    if (typeToCheck != null) {
      if (checkArguments) {
        for (final typeArgument in typeToCheck.typeArguments) {
          makeType(codeGen, typeArgument);
        }
      }
      b.call(_generateIsChecker(
          typeToCheck, checkArguments, operandType.isPotentiallyNullable));
    } else {
      if (testedAgainstType is InterfaceType &&
          classForType(testedAgainstType) == translator.interfaceTypeClass) {
        final typeClassInfo =
            translator.classInfo[testedAgainstType.classNode]!;
        final typeArguments = testedAgainstType.typeArguments;
        b.i32_const(encodedNullability(testedAgainstType));
        b.i32_const(typeClassInfo.classId);
        if (typeArguments.isEmpty) {
          codeGen.call(translator.isInterfaceSubtype0.reference);
        } else if (typeArguments.length == 1) {
          makeType(codeGen, typeArguments[0]);
          codeGen.call(translator.isInterfaceSubtype1.reference);
        } else if (typeArguments.length == 2) {
          makeType(codeGen, typeArguments[0]);
          makeType(codeGen, typeArguments[1]);
          codeGen.call(translator.isInterfaceSubtype2.reference);
        } else {
          _makeTypeArray(codeGen, typeArguments);
          codeGen.call(translator.isInterfaceSubtype.reference);
        }
      } else {
        makeType(codeGen, testedAgainstType);
        codeGen.call(translator.isSubtype.reference);
      }
    }
    if (translator.options.verifyTypeChecks) {
      b.local_get(operandTemp!);
      makeType(codeGen, testedAgainstType);
      if (location != null) {
        w.FunctionType verifyFunctionType = translator.signatureForDirectCall(
            translator.verifyOptimizedTypeCheck.reference);
        translator.constants.instantiateConstant(
            b, StringConstant('$location'), verifyFunctionType.inputs.last);
      } else {
        b.ref_null(w.HeapType.none);
      }
      codeGen.call(translator.verifyOptimizedTypeCheck.reference);
    }
  }

  w.ValueType emitAsCheck(CodeGenerator codeGen, DartType testedAgainstType,
      DartType operandType, w.RefType boxedOperandType,
      [Location? location]) {
    final b = codeGen.b;

    final (typeToCheck, :checkArguments) =
        _canUseTypeCheckHelper(testedAgainstType, operandType);
    if (typeToCheck != null) {
      if (checkArguments) {
        for (final typeArgument in typeToCheck.typeArguments) {
          makeType(codeGen, typeArgument);
        }
      }
      b.call(_generateAsChecker(
          typeToCheck, checkArguments, operandType.isPotentiallyNullable));
      return translator.translateType(testedAgainstType);
    }

    w.Local operand = b.addLocal(boxedOperandType);
    b.local_tee(operand);

    late List<w.ValueType> outputsToDrop;
    if (testedAgainstType is InterfaceType &&
        classForType(testedAgainstType) == translator.interfaceTypeClass) {
      final typeClassInfo = translator.classInfo[testedAgainstType.classNode]!;
      final typeArguments = testedAgainstType.typeArguments;
      b.i32_const(encodedNullability(testedAgainstType));
      b.i32_const(typeClassInfo.classId);
      if (typeArguments.isEmpty) {
        outputsToDrop = codeGen.call(translator.asInterfaceSubtype0.reference);
      } else if (typeArguments.length == 1) {
        makeType(codeGen, typeArguments[0]);
        outputsToDrop = codeGen.call(translator.asInterfaceSubtype1.reference);
      } else if (typeArguments.length == 2) {
        makeType(codeGen, typeArguments[0]);
        makeType(codeGen, typeArguments[1]);
        outputsToDrop = codeGen.call(translator.asInterfaceSubtype2.reference);
      } else {
        _makeTypeArray(codeGen, typeArguments);
        outputsToDrop = codeGen.call(translator.asInterfaceSubtype.reference);
      }
    } else {
      makeType(codeGen, testedAgainstType);
      outputsToDrop = codeGen.call(translator.asSubtype.reference);
    }
    for (final _ in outputsToDrop) {
      b.drop();
    }
    b.local_get(operand);
    return operand.type;
  }

  // If a type check helper can be used, returns the type the caller has to
  // check and whether arguments of the type have to be checked or not.
  (InterfaceType?, {bool checkArguments}) _canUseTypeCheckHelper(
      DartType testedAgainstType, DartType operandType) {
    // The is/as check helpers are for cid-range checks of interface types.
    if (testedAgainstType is! InterfaceType) {
      return (null, checkArguments: false);
    }

    if (_hasOnlyDefaultTypeArguments(testedAgainstType)) {
      return (testedAgainstType, checkArguments: false);
    }

    if (operandType is InterfaceType &&
        _staticTypesEnsureTypeArgumentsMatch(testedAgainstType, operandType)) {
      return (
        _getTypeWithDefaultsToBounds(testedAgainstType),
        checkArguments: false
      );
    }

    if (!rtt.requiresTypeArgumentSubstitution(testedAgainstType.classNode)) {
      return (testedAgainstType, checkArguments: true);
    }

    return (null, checkArguments: false);
  }

  bool _staticTypesEnsureTypeArgumentsMatch(
      InterfaceType testedAgainstType, InterfaceType operandType) {
    assert(testedAgainstType.typeArguments.isNotEmpty);

    // If the operand type doesn't have any type arguments it will not be able
    // to tell us anything about the type arguments of testedAgainstType.
    if (operandType.typeArguments.isEmpty) return false;

    final sufficiency = translator.typeEnvironment
        .computeTypeShapeCheckSufficiency(
            expressionStaticType: operandType,
            checkTargetType:
                testedAgainstType.withDeclaredNullability(Nullability.nullable),
            subtypeCheckMode: type_env.SubtypeCheckMode.withNullabilities);

    // If `true` the caller only needs to check nullabillity and the actual
    // concrete class, no need to check [testedAgainstType] arguments.
    return sufficiency == type_env.TypeShapeCheckSufficiency.interfaceShape;
  }

  bool _hasOnlyDefaultTypeArguments(InterfaceType testedAgainstType) {
    if (testedAgainstType.typeArguments.isEmpty) return true;

    final parameters = testedAgainstType.classNode.typeParameters;
    final arguments = testedAgainstType.typeArguments;
    assert(parameters.length == arguments.length);
    for (int i = 0; i < arguments.length; ++i) {
      if (arguments[i] != parameters[i].defaultType) return false;
    }
    return true;
  }

  InterfaceType _getTypeWithDefaultsToBounds(InterfaceType type) {
    // We only need to check whether the nullability and the class itself fits
    // (the [testedAgainstType] arguments are guaranteed to fit statically)
    final parameters = type.classNode.typeParameters;
    final args = [
      for (int i = 0; i < parameters.length; ++i) parameters[i].defaultType,
    ];
    return InterfaceType(type.classNode, type.nullability, args);
  }

  final Map<DartType, w.BaseFunction> _nullableIsCheckers = {};
  final Map<DartType, w.BaseFunction> _isCheckers = {};
  final Map<DartType, w.BaseFunction> _nullableIsCheckersWithArgumentsCheck =
      {};
  final Map<DartType, w.BaseFunction> _isCheckersWithArgumentsCheck = {};

  // Currently the is-checker helper functions only check nullability and the
  // concrete class (the arguments do not have to be checked).
  w.BaseFunction _generateIsChecker(InterfaceType testedAgainstType,
      bool checkArguments, bool operandIsNullable) {
    assert(_hasOnlyDefaultTypeArguments(testedAgainstType) || checkArguments);

    final interfaceClass = testedAgainstType.classNode;

    final Map<DartType, w.BaseFunction> cache;
    final int argumentCount;
    if (checkArguments) {
      testedAgainstType = _getTypeWithDefaultsToBounds(testedAgainstType);
      argumentCount = interfaceClass.typeParameters.length;
      cache = operandIsNullable
          ? _nullableIsCheckersWithArgumentsCheck
          : _isCheckersWithArgumentsCheck;
    } else {
      argumentCount = 0;
      cache = operandIsNullable ? _nullableIsCheckers : _isCheckers;
    }

    return cache.putIfAbsent(testedAgainstType, () {
      final typeType = translator.translateType(translator.typeType);
      final argumentType = operandIsNullable
          ? translator.topInfo.nullableType
          : translator.topInfo.nonNullableType;
      final typeArgumentsName = checkArguments
          ? '<${[for (int i = 0; i < argumentCount; ++i) 'T$i'].join(', ')}>'
          : '';
      final name =
          '<obj> is ${testedAgainstType.classNode.name}$typeArgumentsName';
      final function = translator.m.functions.define(
          translator.m.types.defineFunction(
            [argumentType, for (int i = 0; i < argumentCount; ++i) typeType],
            [w.NumType.i32],
          ),
          name);

      final b = function.body;

      w.Local operand = b.locals[0];
      w.Local boolTemp = b.addLocal(w.NumType.i32);

      final w.Label resultLabel = b.block(const [], const [w.NumType.i32]);
      if (operandIsNullable) {
        w.Label nullLabel = b.block(const [], const []);
        b.local_get(operand);
        b.br_on_null(nullLabel);
        final nonNullableOperand =
            b.addLocal(translator.topInfo.nonNullableType);
        b.local_get(operand);
        b.ref_cast(nonNullableOperand.type as w.RefType);
        b.local_set(nonNullableOperand);
        operand = nonNullableOperand;
      }

      if (checkArguments) {
        b.local_get(operand);
        b.call(_generateIsChecker(testedAgainstType, false, false));
        b.local_set(boolTemp);

        // If cid ranges fail, we fail
        {
          final w.Label okBlock = b.block(const [], const []);
          b.local_get(boolTemp);
          b.i32_const(1);
          b.i32_eq();
          b.br_if(okBlock);
          b.i32_const(0);
          b.br(resultLabel);
          b.end();
        }

        // Otherwise we have to check each argument.

        // Call Object._getArguments()
        w.Local typeArguments = b.addLocal(typeArrayExpectedType);
        b.local_get(operand);
        b.call(translator.functions
            .getFunction(translator.objectGetTypeArguments.reference));
        b.local_set(typeArguments);
        for (int i = 0; i < argumentCount; ++i) {
          b.local_get(typeArguments);
          b.i32_const(i);
          b.array_get(typeArrayArrayType);
          b.local_get(b.locals[1 + i]);
          b.call(translator.functions
              .getFunction(translator.isTypeSubtype.reference));
          {
            b.local_set(boolTemp);
            final w.Label okBlock = b.block(const [], const []);
            b.local_get(boolTemp);
            b.i32_const(1);
            b.i32_eq();
            b.br_if(okBlock);
            b.i32_const(0);
            b.br(resultLabel);
            b.end();
          }
        }
        b.i32_const(1);
        b.br(resultLabel);
      } else {
        if (interfaceClass == coreTypes.objectClass) {
          b.drop();
          b.i32_const(1);
        } else if (interfaceClass == coreTypes.functionClass) {
          b.local_get(operand);
          b.ref_test(translator.closureInfo.nonNullableType);
        } else {
          final ranges = translator.classIdNumbering
              .getConcreteClassIdRanges(interfaceClass);
          b.local_get(operand);
          b.struct_get(translator.topInfo.struct, FieldIndex.classId);
          b.emitClassIdRangeCheck(ranges);
        }
        b.br(resultLabel);
      }

      if (operandIsNullable) {
        b.end(); // nullLabel
        b.i32_const(encodedNullability(testedAgainstType));
      }
      b.end(); // resultLabel

      b.return_();
      b.end();

      return function;
    });
  }

  final Map<DartType, w.BaseFunction> _nullableAsCheckers = {};
  final Map<DartType, w.BaseFunction> _asCheckers = {};
  final Map<DartType, w.BaseFunction> _asCheckersWithArgumentsCheck = {};
  final Map<DartType, w.BaseFunction> _nullableAsCheckersWithArgumentsCheck =
      {};

  // Currently the as-checker helper functions only check nullability and the
  // concrete class (the arguments do not have to be checked).
  w.BaseFunction _generateAsChecker(InterfaceType testedAgainstType,
      bool checkArguments, bool operandIsNullable) {
    assert(_hasOnlyDefaultTypeArguments(testedAgainstType) || checkArguments);

    final Map<DartType, w.BaseFunction> cache;
    final int argumentCount;
    if (checkArguments) {
      testedAgainstType = _getTypeWithDefaultsToBounds(testedAgainstType);
      argumentCount = testedAgainstType.classNode.typeParameters.length;
      cache = operandIsNullable
          ? _nullableAsCheckersWithArgumentsCheck
          : _asCheckersWithArgumentsCheck;
    } else {
      argumentCount = 0;
      cache = operandIsNullable ? _nullableAsCheckers : _asCheckers;
    }

    return cache.putIfAbsent(testedAgainstType, () {
      final returnType = translator.translateType(testedAgainstType);
      final argumentType = operandIsNullable
          ? translator.topInfo.nullableType
          : translator.topInfo.nonNullableType;
      final typeType = translator.translateType(translator.typeType);
      final typeArgumentsName = checkArguments
          ? '<${[for (int i = 0; i < argumentCount; ++i) 'T$i'].join(', ')}>'
          : '';
      final name =
          '<obj> as ${testedAgainstType.classNode.name}$typeArgumentsName';
      final function = translator.m.functions.define(
          translator.m.types.defineFunction(
            [argumentType, for (int i = 0; i < argumentCount; ++i) typeType],
            [returnType],
          ),
          name);

      final b = function.body;
      w.Label asCheckBlock = b.block();
      b.local_get(b.locals[0]);
      for (int i = 0; i < argumentCount; ++i) {
        b.local_get(b.locals[1 + i]);
      }
      b.call(_generateIsChecker(
          testedAgainstType, checkArguments, operandIsNullable));
      b.br_if(asCheckBlock);

      if (checkArguments) {
        final testedAgainstClassId =
            translator.classInfo[testedAgainstType.classNode]!.classId;
        b.local_get(b.locals[0]);
        b.i32_const(encodedNullability(testedAgainstType));
        b.i32_const(testedAgainstClassId);
        if (argumentCount == 1) {
          b.local_get(b.locals[1]);
          b.call(translator.functions.getFunction(
              translator.throwInterfaceTypeAsCheckError1.reference));
        } else if (argumentCount == 2) {
          b.local_get(b.locals[1]);
          b.local_get(b.locals[2]);
          b.call(translator.functions.getFunction(
              translator.throwInterfaceTypeAsCheckError2.reference));
        } else {
          for (int i = 0; i < argumentCount; ++i) {
            b.local_get(b.locals[1 + i]);
          }
          b.array_new_fixed(typeArrayArrayType, argumentCount);
          b.call(translator.functions.getFunction(
              translator.throwInterfaceTypeAsCheckError.reference));
        }
      } else {
        b.local_get(b.locals[0]);
        translator.constants.instantiateConstant(
            b, TypeLiteralConstant(testedAgainstType), nonNullableTypeType);
        b.call(translator.functions
            .getFunction(translator.throwAsCheckError.reference));
      }
      b.unreachable();

      b.end();

      b.local_get(b.locals[0]);
      translator.convertType(b, argumentType, returnType);
      b.return_();
      b.end();

      return function;
    });
  }

  int encodedNullability(DartType type) =>
      type.declaredNullability == Nullability.nullable ? 1 : 0;
}

/// Builds up data structures that the Runtime Type System implementation uses.
///
/// There are 2 data structures:
///
///   * The name of all classes represented as an wasm array of strings.
///
///   * A type row-displacement table encoding whether a class is a subclass of
///    another class and if so, how to translate the type arguments from a
///    subclass to a super clss.
///
/// See sdk/lib/_internal/wasm/lib/type.dart for more information.
class RuntimeTypeInformation {
  final Translator translator;

  /// This index in the substitution canonicalization table indicates that we do
  /// not have to substitute anything.
  static const int noSubstitutionIndex = 0;

  /// Table of type names indexed by class id.
  late final InstanceConstant typeNames;
  late final DartType typeNamesType;

  /// See sdk/lib/_internal/wasm/lib/type.dart:_typeRowDisplacement*
  /// for what this contains and how it's used for substitution.
  late final InstanceConstant typeRowDisplacementOffsets;
  late final DartType typeRowDisplacementOffsetsType;
  late final InstanceConstant typeRowDisplacementTable;
  late final DartType typeRowDisplacementTableType;
  late final InstanceConstant typeRowDisplacementSubstTable;
  late final DartType typeRowDisplacementSubstTableType;

  CoreTypes get coreTypes => translator.coreTypes;
  Types get types => translator.types;

  late final Map<int, Map<int, int>> _substitutionSubclassToSuperclass;
  late final Map<int, Map<int, int>> _substitutionSuperclassToSubclass;
  late final Map<InstanceConstant, int> _substitutionTable;
  late final List<InstanceConstant> _substitutionTableByIndex;

  final Map<int, bool> _requiresSubstitutionForSubclasses = {};

  RuntimeTypeInformation(this.translator) {
    _buildTypeRules();

    // Data structure to tell whether two types are related and if so how to
    // translate type arguments from one class to that of a super class.
    _initTypeRowDiplacementTable();

    // The class name table of type WasmArray<String>
    _initTypeNames();
  }

  bool requiresTypeArgumentSubstitution(Class superclass) {
    final superclassId = translator.classIdNumbering.classIds[superclass]!;
    return _requiresSubstitutionForSubclasses.putIfAbsent(superclassId, () {
      final subclassSubstitutions =
          _substitutionSuperclassToSubclass[superclassId];

      if (subclassSubstitutions == null) return false;
      for (final entry in subclassSubstitutions.entries) {
        final substitutionIndex = entry.value;
        if (substitutionIndex != noSubstitutionIndex) return true;
      }
      return false;
    });
  }

  void _buildTypeRules() {
    _substitutionSubclassToSuperclass = <int, Map<int, int>>{};
    _substitutionSuperclassToSubclass = <int, Map<int, int>>{};
    _substitutionTable = <InstanceConstant, int>{};
    _substitutionTableByIndex = <InstanceConstant>[];

    assert(noSubstitutionIndex == 0);
    assert(_substitutionTable.length == noSubstitutionIndex);
    assert(_substitutionTableByIndex.length == noSubstitutionIndex);
    final noSubstitution = translator.constants.makeTypeArray([]);
    _substitutionTable[noSubstitution] = noSubstitutionIndex;
    _substitutionTableByIndex.add(noSubstitution);

    for (ClassInfo classInfo in translator.classes) {
      ClassInfo superclassInfo = classInfo;

      // We don't need type rules for any class without a superclass, or for
      // classes whose supertype is [Object]. The latter case will be handled
      // directly in the subtype checking algorithm.
      if (superclassInfo.cls == null ||
          superclassInfo.cls == coreTypes.objectClass) {
        continue;
      }
      Class superclass = superclassInfo.cls!;
      assert(!superclass.isAnonymousMixin);

      // TODO(joshualitt): This includes abstract types that can't be
      // instantiated, but might be needed for subtype checks. The majority of
      // abstract classes are probably unnecessary though. We should filter
      // these cases to reduce the size of the type rules.
      Iterable<Class> subclasses = translator.subtypes
          .getSubtypesOf(superclass)
          .where((cls) => cls != superclass);
      Iterable<InterfaceType> subtypes = subclasses.map(
          (Class cls) => cls.getThisType(coreTypes, Nullability.nonNullable));
      for (InterfaceType subtype in subtypes) {
        if (subtype.classNode.isAnonymousMixin) continue;

        types.interfaceTypeEnvironment._add(subtype);

        final List<DartType>? typeArguments = translator.hierarchy
            .getInterfaceTypeArgumentsAsInstanceOfClass(subtype, superclass)
            ?.map(types.normalize)
            .toList();

        int substitutionIndex;
        if (_isIdentitySubstitution(typeArguments)) {
          substitutionIndex = noSubstitutionIndex;
        } else {
          final substitution =
              translator.constants.makeTypeArray(typeArguments!);
          int? index = _substitutionTable[substitution];
          if (index == null) {
            assert(
                _substitutionTableByIndex.length == _substitutionTable.length);
            index = _substitutionTableByIndex.length;
            _substitutionTableByIndex.add(substitution);
            _substitutionTable[substitution] = index;
          }
          substitutionIndex = index;
        }

        final subclassId = translator.classInfo[subtype.classNode]!.classId;
        (_substitutionSubclassToSuperclass[subclassId] ??=
            {})[superclassInfo.classId] = substitutionIndex;
        (_substitutionSuperclassToSubclass[superclassInfo.classId] ??=
            {})[subclassId] = substitutionIndex;
      }
    }
  }

  /// Whether the substitution [typeArguments] would cause a NOP substitution.
  ///
  /// We have a NOP substitution if one of the following conditions apply:
  ///
  ///   - the classes are unrelated
  ///   - the super class is not generic
  ///   - the type arguments from subclass are the same as for the super class
  ///
  bool _isIdentitySubstitution(List<DartType>? typeArguments) {
    // This happen if the classes are not related to each other.
    if (typeArguments == null) return true;

    for (int i = 0; i < typeArguments.length; ++i) {
      final typeArgument = typeArguments[i];
      if (typeArgument is! TypeParameterType) {
        return false;
      }
      if (typeArgument.declaredNullability == Nullability.nullable) {
        return false;
      }
      final int environmentIndex =
          types.interfaceTypeEnvironment.lookup(typeArgument.parameter);
      if (i != environmentIndex) {
        return false;
      }
    }
    return true;
  }

  void _initTypeRowDiplacementTable() {
    final rowForSuperclass = List<Row?>.filled(translator.classes.length, null);
    final rows = <Row<(int, int)>>[];
    final ranges = _buildRanges(_substitutionSuperclassToSubclass);
    ranges.forEach((int superId, List<(Range, int)> subs) {
      if (subs.isEmpty) return;

      final rowEntries = <({int index, (int, int) value})>[];
      for (final (Range range, int substitutionIndex) in subs) {
        for (int classId = range.start; classId <= range.end; ++classId) {
          rowEntries.add((index: classId, value: (superId, substitutionIndex)));
        }
      }
      final row = Row<(int, int)>(rowEntries);
      rows.add(row);
      rowForSuperclass[superId] = row;
    });

    final typeType =
        InterfaceType(translator.typeClass, Nullability.nonNullable);
    final arrayOfType = InterfaceType(
        translator.wasmArrayClass, Nullability.nonNullable, [typeType]);
    final arrayOfArrayOfType = InterfaceType(
        translator.wasmArrayClass, Nullability.nonNullable, [arrayOfType]);
    final wasmI32 =
        InterfaceType(translator.wasmI32Class, Nullability.nonNullable);
    final arrayOfI32 = InterfaceType(
        translator.wasmArrayClass, Nullability.nonNullable, [wasmI32]);

    final maxId = translator.classIdNumbering.maxClassId;
    int normalize(int value) => (100 * value) ~/ maxId;
    int weight(Row row) {
      return normalize(row.values.length) + normalize(row.holes);
    }

    rows.sort((Row a, Row b) => -weight(a).compareTo(weight(b)));
    final table = buildRowDisplacementTable(rows, firstAvailable: 1);
    typeRowDisplacementTable = translator.constants.makeArrayOf(wasmI32, [
      for (final entry in table)
        IntConstant(entry == null
            ? 0
            : (entry.$2 == noSubstitutionIndex ? -entry.$1 : entry.$1)),
    ]);
    typeRowDisplacementTableType = arrayOfI32;
    typeRowDisplacementSubstTable =
        translator.constants.makeArrayOf(arrayOfType, [
      for (final entry in table)
        _substitutionTableByIndex[
            entry == null ? noSubstitutionIndex : entry.$2],
    ]);
    typeRowDisplacementSubstTableType = arrayOfArrayOfType;

    typeRowDisplacementOffsets = translator.constants.makeArrayOf(wasmI32, [
      for (int classId = 0; classId < translator.classes.length; ++classId)
        IntConstant(rowForSuperclass[classId]?.offset ?? -1),
    ]);
    typeRowDisplacementOffsetsType = arrayOfI32;
  }

  void _initTypeNames() {
    final stringType =
        translator.coreTypes.stringRawType(Nullability.nonNullable);

    final emptyString = StringConstant('');
    List<StringConstant> nameConstants = [];
    for (ClassInfo classInfo in translator.classes) {
      Class? cls = classInfo.cls;
      if (cls == null || cls.isAnonymousMixin) {
        nameConstants.add(emptyString);
      } else {
        nameConstants.add(StringConstant(cls.name));
      }
    }
    typeNames = translator.constants.makeArrayOf(stringType, nameConstants);
    typeNamesType = InterfaceType(
        translator.wasmArrayClass, Nullability.nonNullable, [stringType]);
  }

  Map<int, List<(Range, int)>> _buildRanges(Map<int, Map<int, int>> map) {
    final rangeValues = <int, List<(Range, int)>>{};
    map.forEach((int id, Map<int, int> subs) {
      final entries = subs.entries
          .map((entry) => (Range(entry.key, entry.key), entry.value))
          .toList();
      entries.sort((a, b) => a.$1.start.compareTo(b.$1.start));

      int writeIndex = 0;
      for (int readIndex = 1; readIndex < entries.length; ++readIndex) {
        final current = entries[writeIndex];
        final next = entries[readIndex];
        if (current.$2 == next.$2 && (current.$1.end + 1) == next.$1.start) {
          entries[writeIndex] =
              (Range(current.$1.start, next.$1.end), current.$2);
          continue;
        }
        entries[++writeIndex] = next;
      }
      entries.length = writeIndex + 1;
      rangeValues[id] = entries;
    });
    return rangeValues;
  }
}

/// For a function type F = `... Function<X0, ..., Xn-1>(...)` compute offset(F)
/// such that for any function type G = `... Function<Y0, ..., Ym-1>(...)`
/// nested inside F, if G contains a reference to any type parameters of F, then
/// offset(F) >= offset(G) + m.
///
/// Conceptually, the type parameters of F are indexed from offset(F) inclusive
/// to offset(F) + n exclusive.
///
/// Also assign to each type parameter Xi the index offset(F) + i such that it
/// indexes the correct type parameter in the conceptual type parameter index
/// range of F.
///
/// This ensures that for every reference to a type parameter, its corresponding
/// function type is the innermost function type enclosing it for which the
/// index falls within the type parameter index range of the function type.
class _FunctionTypeParameterOffsetCollector extends RecursiveVisitor {
  final Types types;

  final List<FunctionType> _functionStack = [];
  final List<Set<FunctionType>> _functionsContainingParameters = [];
  final Map<StructuralParameter, int> _functionForParameter = {};

  _FunctionTypeParameterOffsetCollector(this.types);

  @override
  void visitFunctionType(FunctionType node) {
    int slot = _functionStack.length;
    _functionStack.add(node);
    _functionsContainingParameters.add({});

    for (int i = 0; i < node.typeParameters.length; i++) {
      StructuralParameter parameter = node.typeParameters[i];
      _functionForParameter[parameter] = slot;
    }

    super.visitFunctionType(node);

    int offset = 0;
    for (FunctionType inner in _functionsContainingParameters.last) {
      offset = max(
          offset,
          types.functionTypeParameterOffset[inner]! +
              inner.typeParameters.length);
    }
    types.functionTypeParameterOffset[node] = offset;

    for (int i = 0; i < node.typeParameters.length; i++) {
      StructuralParameter parameter = node.typeParameters[i];
      types.functionTypeParameterIndex[parameter] = offset + i;
    }

    _functionsContainingParameters.removeLast();
    _functionStack.removeLast();
  }

  @override
  void visitStructuralParameterType(StructuralParameterType node) {
    int slot = _functionForParameter[node.parameter]!;
    for (int inner = slot + 1; inner < _functionStack.length; inner++) {
      _functionsContainingParameters[slot].add(_functionStack[inner]);
    }
  }
}
