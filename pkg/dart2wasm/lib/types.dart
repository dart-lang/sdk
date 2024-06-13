// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' show max;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart' as type_env;
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'code_generator.dart';
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
      translator.constants.instantiateConstant(codeGen.function, codeGen.b,
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
    b.i64_const(typeInfo.classId);
    _makeTypeArray(codeGen, type.typeArguments);
  }

  void _makeRecordType(CodeGenerator codeGen, RecordType type) {
    codeGen.b.i32_const(encodedNullability(type));

    final names = translator.constants.makeArrayOf(
        translator.coreTypes.stringNonNullableRawType,
        type.named.map((t) => StringConstant(t.name)).toList());

    translator.constants.instantiateConstant(
        codeGen.function, codeGen.b, names, recordTypeNamesFieldExpectedType);
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
          codeGen.function,
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
      translator.convertType(codeGen.function, namedParametersListType,
          namedParametersExpectedType);
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
          codeGen.function, b, TypeLiteralConstant(type), nonNullableTypeType);
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
      operandTemp =
          b.addLocal(translator.topInfo.nullableType, isParameter: false);
      b.local_tee(operandTemp);
    }
    final typeToCheck = _canUseTypeCheckHelper(testedAgainstType, operandType);
    if (typeToCheck != null) {
      b.call(
          _generateIsChecker(typeToCheck, operandType.isPotentiallyNullable));
    } else {
      if (testedAgainstType is InterfaceType &&
          classForType(testedAgainstType) == translator.interfaceTypeClass) {
        final typeClassInfo =
            translator.classInfo[testedAgainstType.classNode]!;
        final typeArguments = testedAgainstType.typeArguments;
        b.i32_const(encodedNullability(testedAgainstType));
        b.i64_const(typeClassInfo.classId);
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
        w.FunctionType verifyFunctionType = translator.functions
            .getFunctionType(translator.verifyOptimizedTypeCheck.reference);
        translator.constants.instantiateConstant(codeGen.function, b,
            StringConstant('$location'), verifyFunctionType.inputs.last);
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

    final typeToCheck = _canUseTypeCheckHelper(testedAgainstType, operandType);
    if (typeToCheck != null) {
      b.call(
          _generateAsChecker(typeToCheck, operandType.isPotentiallyNullable));
      return translator.translateType(testedAgainstType);
    }

    w.Local operand = b.addLocal(boxedOperandType, isParameter: false);
    b.local_tee(operand);

    late List<w.ValueType> outputsToDrop;
    if (testedAgainstType is InterfaceType &&
        classForType(testedAgainstType) == translator.interfaceTypeClass) {
      final typeClassInfo = translator.classInfo[testedAgainstType.classNode]!;
      final typeArguments = testedAgainstType.typeArguments;
      b.i32_const(encodedNullability(testedAgainstType));
      b.i64_const(typeClassInfo.classId);
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

  // Returns the type to check against if a helper can be used, otherwise `null`
  InterfaceType? _canUseTypeCheckHelper(
      DartType testedAgainstType, DartType operandType) {
    // The is/as check helpers are for cid-range checks of interface types.
    if (testedAgainstType is! InterfaceType) return null;

    if (_hasOnlyDefaultTypeArguments(testedAgainstType)) {
      return testedAgainstType;
    }

    if (operandType is InterfaceType &&
        _staticTypesEnsureTypeArgumentsMatch(testedAgainstType, operandType)) {
      // We only need to check whether the nullability and the class itself fits
      // (the [testedAgainstType] arguments are guaranteed to fit statically)
      final parameters = testedAgainstType.classNode.typeParameters;
      final args = [
        for (int i = 0; i < parameters.length; ++i) parameters[i].defaultType,
      ];
      return InterfaceType(
          testedAgainstType.classNode, testedAgainstType.nullability, args);
    }
    return null;
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

  final Map<DartType, w.BaseFunction> _nullableIsCheckers = {};
  final Map<DartType, w.BaseFunction> _isCheckers = {};

  // Currently the is-checker helper functions only check nullability and the
  // concrete class (the arguments do not have to be checked).
  w.BaseFunction _generateIsChecker(
      InterfaceType testedAgainstType, bool operandIsNullable) {
    assert(_hasOnlyDefaultTypeArguments(testedAgainstType));

    final interfaceClass = testedAgainstType.classNode;

    final cachedIsCheckers =
        operandIsNullable ? _nullableIsCheckers : _isCheckers;

    return cachedIsCheckers.putIfAbsent(testedAgainstType, () {
      final argumentType = operandIsNullable
          ? translator.topInfo.nullableType
          : translator.topInfo.nonNullableType;
      final function = translator.m.functions.define(
          translator.m.types.defineFunction(
            [argumentType],
            [w.NumType.i32],
          ),
          '<obj> is ${testedAgainstType.classNode}');

      final b = function.body;
      b.local_get(b.locals[0]);

      w.Label? resultLabel;
      if (operandIsNullable) {
        // Store operand in a temporary variable, since Binaryen does not support
        // block inputs.
        w.Local operand = function.addLocal(translator.topInfo.nullableType);
        b.local_set(operand);
        resultLabel = b.block(const [], const [w.NumType.i32]);
        w.Label nullLabel = b.block(const [], const []);
        b.local_get(operand);
        b.br_on_null(nullLabel);
      }

      if (interfaceClass == coreTypes.objectClass) {
        b.drop();
        b.i32_const(1);
      } else if (interfaceClass == coreTypes.functionClass) {
        b.ref_test(translator.closureInfo.nonNullableType);
      } else {
        final ranges = translator.classIdNumbering
            .getConcreteClassIdRanges(interfaceClass);
        b.struct_get(translator.topInfo.struct, FieldIndex.classId);
        b.emitClassIdRangeCheck(ranges);
      }

      if (operandIsNullable) {
        b.br(resultLabel!);
        b.end(); // nullLabel
        b.i32_const(encodedNullability(testedAgainstType));
        b.end(); // resultLabel
      }

      b.return_();
      b.end();

      return function;
    });
  }

  final Map<DartType, w.BaseFunction> _nullableAsCheckers = {};
  final Map<DartType, w.BaseFunction> _asCheckers = {};

  // Currently the as-checker helper functions only check nullability and the
  // concrete class (the arguments do not have to be checked).
  w.BaseFunction _generateAsChecker(
      InterfaceType testedAgainstType, bool operandIsNullable) {
    assert(_hasOnlyDefaultTypeArguments(testedAgainstType));

    final cachedAsCheckers =
        operandIsNullable ? _nullableAsCheckers : _asCheckers;
    final returnType = translator.translateType(testedAgainstType);
    return cachedAsCheckers.putIfAbsent(testedAgainstType, () {
      final argumentType = operandIsNullable
          ? translator.topInfo.nullableType
          : translator.topInfo.nonNullableType;
      final function = translator.m.functions.define(
          translator.m.types.defineFunction(
            [argumentType],
            [returnType],
          ),
          '<obj> as ${testedAgainstType.classNode}');

      final b = function.body;
      w.Label asCheckBlock = b.block();
      b.local_get(b.locals[0]);
      b.call(_generateIsChecker(testedAgainstType, operandIsNullable));
      b.br_if(asCheckBlock);

      b.local_get(b.locals[0]);
      translator.constants.instantiateConstant(function, b,
          TypeLiteralConstant(testedAgainstType), nonNullableTypeType);
      b.call(translator.functions
          .getFunction(translator.throwAsCheckError.reference));
      b.unreachable();

      b.end();

      b.local_get(b.locals[0]);
      translator.convertType(function, argumentType, returnType);
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
/// There are 3 data structures:
///
///   * The name of all classes represented as an wasm array of strings.
///
///   * A canonical substitution table where each entry represents
///     (potentially uninstantiated) type arguments to a superclass.
///
///     => This is used for translating type arguments between related classes
///     in a hierarchy.
///
///   * A table mapping each class id to its transitive super classes (i.e.
///     transitive implements/extends) and an index into the canonical
///     substitution table on how to translate type arguments between the two
///     related clases.
///
/// See sdk/lib/_internal/wasm/lib/type.dart for more information.
class RuntimeTypeInformation {
  final Translator translator;

  /// Canonical substitution table of type `const WasmArray<WasmArray<_Type>>`.
  ///
  /// Stores a canonical table of substitution arrays. Each substitution array
  /// describes (possibly uninstantiated) type arguments that can be
  /// instantiated with actual object type arguments.
  /// => This allows translating an objects type arguments to the type arguments
  /// of a related super class.
  ///
  /// See sdk/lib/_internal/wasm/lib/type.dart:_canonicalSubstitutionTable for
  /// what this contains and how it's used for substitution.
  late final InstanceConstant substitutionTableConstant;

  /// The Dart type of the [substitutionTableConstant] constant.
  late final DartType substitutionTableConstantType;

  /// This index in the substitution canonicalization table indicates that we do
  /// not have to substitute anything.
  static const int noSubstitutionIndex = 0;

  /// Type rules supers table of type `const WasmArray<WasmArray<_WasmI32>>`.
  ///
  /// Has an array for every class id in the system. For a particular class id
  /// it has (super-classId, canonical-substitutionIndex) tuples used by the RTT
  /// system to determine whether two classes are related and how to translate
  /// type arguments from one class to type arguments of a related other class.
  ///
  /// See sdk/lib/_internal/wasm/lib/type.dart:_typeRulesSupers for
  /// what this contains and how it's used for substitution.
  late final InstanceConstant typeRulesSupers;
  late final DartType typeRulesSupersType;

  /// Table of type names indexed by class id.
  late final InstanceConstant typeNames;
  late final DartType typeNamesType;

  CoreTypes get coreTypes => translator.coreTypes;
  Types get types => translator.types;

  RuntimeTypeInformation(this.translator) {
    final (
      Map<int, Map<int, int>> typeRules,
      LinkedHashMap<InstanceConstant, int> substitutionTable
    ) = _buildTypeRules();

    // The canonical substitution table of type WasmArray<WasmArray<_Type>>
    _initSubstitutionTableConstant(substitutionTable);

    // The super type substitution rules for each class of type
    // WasmArray<WasmArray<WasmI32>>.
    _initTypeRulesSupers(typeRules);

    // The class name table of type WasmArray<String>
    _initTypeNames();
  }

  (Map<int, Map<int, int>>, LinkedHashMap<InstanceConstant, int>)
      _buildTypeRules() {
    final subtypeMap = <int, Map<int, int>>{};
    // ignore: prefer_collection_literals
    final substitutionTable = LinkedHashMap<InstanceConstant, int>();

    assert(noSubstitutionIndex == 0);
    assert(substitutionTable.length == noSubstitutionIndex);
    substitutionTable[translator.constants.makeTypeArray([])] =
        noSubstitutionIndex;

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
          substitutionIndex = substitutionTable.putIfAbsent(
              substitution, () => substitutionTable.length);
        }

        final subclassId = translator.classInfo[subtype.classNode]!.classId;
        (subtypeMap[subclassId] ??= {})[superclassInfo.classId] =
            substitutionIndex;
      }
    }
    return (subtypeMap, substitutionTable);
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

  void _initSubstitutionTableConstant(
      LinkedHashMap<InstanceConstant, int> substitutionTable) {
    final typeType =
        InterfaceType(translator.typeClass, Nullability.nonNullable);
    final arrayOfType = InterfaceType(
        translator.wasmArrayClass, Nullability.nonNullable, [typeType]);

    // We rely on the keys being in insertion order.
    substitutionTableConstant = translator.constants
        .makeArrayOf(arrayOfType, substitutionTable.keys.toList());
    substitutionTableConstantType = InterfaceType(
        translator.wasmArrayClass, Nullability.nonNullable, [arrayOfType]);
  }

  void _initTypeRulesSupers(Map<int, Map<int, int>> typeRules) {
    final wasmI32 =
        InterfaceType(translator.wasmI32Class, Nullability.nonNullable);
    final arrayOfI32 = InterfaceType(
        translator.wasmArrayClass, Nullability.nonNullable, [wasmI32]);

    // Maps each class id to a list of super class ids followed by a list of
    // substitution table indices.
    final typeRulesArray = <InstanceConstant>[];
    for (int classId = 0; classId < translator.classes.length; classId++) {
      final rules = typeRules[classId];
      if (rules == null) {
        typeRulesArray.add(
            translator.constants.makeArrayOf(wasmI32, const <IntConstant>[]));
        continue;
      }

      final List<int> superclassIds = rules.keys.toList();
      superclassIds.sort();
      final superClassSubstitutionTuples =
          List<IntConstant>.filled(2 * superclassIds.length, IntConstant(0));
      for (int i = 0; i < superclassIds.length; ++i) {
        final superClassId = superclassIds[i];
        final substitutionTableIndex = rules[superClassId]!;

        superClassSubstitutionTuples[i] = IntConstant(superClassId);
        superClassSubstitutionTuples[superclassIds.length + i] =
            IntConstant(substitutionTableIndex);
      }
      typeRulesArray.add(translator.constants
          .makeArrayOf(wasmI32, superClassSubstitutionTuples));
    }
    typeRulesSupers =
        translator.constants.makeArrayOf(arrayOfI32, typeRulesArray);
    typeRulesSupersType = InterfaceType(
        translator.wasmArrayClass, Nullability.nonNullable, [arrayOfI32]);
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
