// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show max;
import 'dart:typed_data' show Uint8List;

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/code_generator.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Values for the type category table. Entries for masqueraded classes contain
/// the class ID of the masquerade.
class TypeCategory {
  static const abstractClass = 0;
  static const function = 1;
  static const record = 2;
  static const notMasqueraded = 3;
  static const minMasqueradeClassId = 4;
  static const maxMasqueradeClassId = 63; // Leaves 2 unused bits for future use
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
  late final w.ValueType typeListExpectedType = classAndFieldToType(
      translator.interfaceTypeClass, FieldIndex.interfaceTypeTypeArguments);

  /// Wasm value type of `List<_NamedParameter>`
  late final w.ValueType namedParametersExpectedType = classAndFieldToType(
      translator.functionTypeClass, FieldIndex.functionTypeNamedParameters);

  /// Wasm value type of `_RecordType.names` field.
  late final w.ValueType recordTypeNamesFieldExpectedType = classAndFieldToType(
      translator.recordTypeClass, FieldIndex.recordTypeNames);

  /// A mapping from concrete subclass `classID` to [Map]s of superclass
  /// `classID` and the necessary substitutions which must be performed to test
  /// for a valid subtyping relationship.
  late final Map<int, Map<int, List<DartType>>> typeRules = _buildTypeRules();

  /// We will build the [interfaceTypeEnvironment] when building the
  /// [typeRules].
  final InterfaceTypeEnvironment interfaceTypeEnvironment =
      InterfaceTypeEnvironment();

  /// Because we can't currently support [Map]s in our `TypeUniverse`, we have
  /// to decompose [typeRules] into two [Map]s based on [List]s.
  ///
  /// [typeRulesSupers] is a [List] where the index in the list is a subclasses'
  /// `classID` and the value at that index is a [List] of superclass
  /// `classID`s.
  late final List<List<int>> typeRulesSupers = _buildTypeRulesSupers();

  /// [typeRulesSubstitutions] is a [List] where the index in the list is a
  /// subclasses' `classID` and the value at that index is a [List] indexed by
  /// the index of the superclasses' `classID` in [typeRulesSuper] and the value
  /// at that index is a [List] of [DartType]s which must be substituted for the
  /// subtyping relationship to be valid.
  late final List<List<List<DartType>>> typeRulesSubstitutions =
      _buildTypeRulesSubstitutions();

  /// A list which maps class ID to the classes [String] name.
  late final List<String> typeNames = _buildTypeNames();

  /// Type parameter offset for function types, specifying the lower end of
  /// their index range for type parameter types.
  Map<FunctionType, int> functionTypeParameterOffset = Map.identity();

  /// Index value for function type parameter types, indexing into the type
  /// parameter index range of their corresponding function type.
  Map<TypeParameter, int> functionTypeParameterIndex = Map.identity();

  /// An `i8` array of type category values, indexed by class ID.
  late final w.Global typeCategoryTable = _buildTypeCategoryTable();

  Types(this.translator);

  w.ValueType classAndFieldToType(Class cls, int fieldIndex) =>
      translator.classInfo[cls]!.struct.fields[fieldIndex].type.unpacked;

  Iterable<Class> _getConcreteSubtypes(Class cls) =>
      translator.subtypes.getSubtypesOf(cls).where((c) => !c.isAbstract);

  /// Wasm value type for non-nullable `_Type` values
  w.ValueType get nonNullableTypeType => typeClassInfo.nonNullableType;

  InterfaceType get namedParameterType =>
      InterfaceType(translator.namedParameterClass, Nullability.nonNullable);

  InterfaceType get typeType =>
      InterfaceType(translator.typeClass, Nullability.nonNullable);

  CoreTypes get coreTypes => translator.coreTypes;

  /// Builds a [Map<int, Map<int, List<DartType>>>] to store subtype
  /// information.  The first key is the class id of a subtype. This returns a
  /// map where each key is the class id of a transitively implemented super
  /// type and each value is a list of the necessary type substitutions required
  /// for the subtyping relationship to be valid.
  Map<int, Map<int, List<DartType>>> _buildTypeRules() {
    List<ClassInfo> classes = translator.classes;
    Map<int, Map<int, List<DartType>>> subtypeMap = {};
    for (ClassInfo classInfo in classes) {
      ClassInfo superclassInfo = classInfo;

      // We don't need type rules for any class without a superclass, or for
      // classes whose supertype is [Object]. The latter case will be handled
      // directly in the subtype checking algorithm.
      if (superclassInfo.cls == null ||
          superclassInfo.cls == coreTypes.objectClass) continue;
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
        interfaceTypeEnvironment._add(subtype);
        List<DartType>? typeArguments = translator.hierarchy
            .getTypeArgumentsAsInstanceOf(subtype, superclass)
            ?.map(normalize)
            .toList();
        ClassInfo subclassInfo = translator.classInfo[subtype.classNode]!;
        Map<int, List<DartType>> substitutionMap =
            subtypeMap[subclassInfo.classId] ??= {};
        substitutionMap[superclassInfo.classId] = typeArguments ?? const [];
      }
    }
    return subtypeMap;
  }

  List<List<int>> _buildTypeRulesSupers() {
    List<List<int>> typeRulesSupers = [];
    for (int classId = 0; classId < translator.classes.length; classId++) {
      List<int>? superclassIds = typeRules[classId]?.keys.toList();
      if (superclassIds == null) {
        typeRulesSupers.add(const []);
      } else {
        superclassIds.sort();
        typeRulesSupers.add(superclassIds);
      }
    }
    return typeRulesSupers;
  }

  List<List<List<DartType>>> _buildTypeRulesSubstitutions() {
    List<List<List<DartType>>> typeRulesSubstitutions = [];
    for (int classId = 0; classId < translator.classes.length; classId++) {
      List<int> supers = typeRulesSupers[classId];
      typeRulesSubstitutions.add(supers.isEmpty ? const [] : []);
      for (int j = 0; j < supers.length; j++) {
        int superId = supers[j];
        typeRulesSubstitutions.last.add(typeRules[classId]![superId]!);
      }
    }
    return typeRulesSubstitutions;
  }

  List<String> _buildTypeNames() {
    // This logic assumes `translator.classes` returns the classes indexed by
    // class ID. If we ever change that logic, we will need to change this code.
    List<String> typeNames = [];
    for (ClassInfo classInfo in translator.classes) {
      String className = classInfo.cls?.name ?? '';
      typeNames.add(className);
    }
    return typeNames;
  }

  /// Builds a map of subclasses to the transitive set of superclasses they
  /// implement.
  /// TODO(joshualitt): This implementation is just temporary. Eventually we
  /// should move to a data structure more closely resembling [typeRules].
  w.ValueType makeTypeRulesSupers(w.Instructions b) {
    w.ValueType expectedType =
        translator.classInfo[translator.immutableListClass]!.nonNullableType;
    DartType listIntType = InterfaceType(translator.immutableListClass,
        Nullability.nonNullable, [translator.coreTypes.intNonNullableRawType]);
    List<ListConstant> listIntConstant = [];
    for (List<int> supers in typeRulesSupers) {
      listIntConstant.add(ListConstant(
          listIntType, supers.map((i) => IntConstant(i)).toList()));
    }
    DartType listListIntType = InterfaceType(
        translator.immutableListClass, Nullability.nonNullable, [listIntType]);
    translator.constants.instantiateConstant(
        null, b, ListConstant(listListIntType, listIntConstant), expectedType);
    return expectedType;
  }

  /// Similar to the above, but provides the substitutions required for each
  /// supertype.
  /// TODO(joshualitt): Like [makeTypeRulesSupers], this is just temporary.
  w.ValueType makeTypeRulesSubstitutions(w.Instructions b) {
    w.ValueType expectedType =
        translator.classInfo[translator.immutableListClass]!.nonNullableType;
    DartType listTypeType = InterfaceType(
        translator.immutableListClass,
        Nullability.nonNullable,
        [translator.typeClass.getThisType(coreTypes, Nullability.nonNullable)]);
    DartType listListTypeType = InterfaceType(
        translator.immutableListClass, Nullability.nonNullable, [listTypeType]);
    DartType listListListTypeType = InterfaceType(translator.immutableListClass,
        Nullability.nonNullable, [listListTypeType]);
    List<ListConstant> substitutionsConstantL0 = [];
    for (List<List<DartType>> substitutionsL1 in typeRulesSubstitutions) {
      List<ListConstant> substitutionsConstantL1 = [];
      for (List<DartType> substitutionsL2 in substitutionsL1) {
        substitutionsConstantL1.add(ListConstant(listTypeType,
            substitutionsL2.map((t) => TypeLiteralConstant(t)).toList()));
      }
      substitutionsConstantL0
          .add(ListConstant(listListTypeType, substitutionsConstantL1));
    }
    translator.constants.instantiateConstant(
        null,
        b,
        ListConstant(listListListTypeType, substitutionsConstantL0),
        expectedType);
    return expectedType;
  }

  /// Returns a list of string type names for pretty printing types.
  w.ValueType makeTypeNames(w.Instructions b) {
    w.ValueType expectedType =
        translator.classInfo[translator.immutableListClass]!.nonNullableType;
    List<StringConstant> listStringConstant = [];
    for (String name in typeNames) {
      listStringConstant.add(StringConstant(name));
    }
    DartType listStringType = InterfaceType(
        translator.immutableListClass,
        Nullability.nonNullable,
        [translator.coreTypes.stringNonNullableRawType]);
    translator.constants.instantiateConstant(null, b,
        ListConstant(listStringType, listStringConstant), expectedType);
    return expectedType;
  }

  /// Build a global array of byte values used to categorize runtime types.
  w.Global _buildTypeCategoryTable() {
    Set<Class> recordClasses = Set.from(translator.recordClasses.values);
    Uint8List table = Uint8List(translator.classes.length);
    for (int i = 0; i < translator.classes.length; i++) {
      ClassInfo info = translator.classes[i];
      ClassInfo? masquerade = info.masquerade;
      Class? cls = info.cls;
      int category;
      if (cls == null || cls.isAbstract) {
        category = TypeCategory.abstractClass;
      } else if (cls == translator.closureClass) {
        category = TypeCategory.function;
      } else if (recordClasses.contains(cls)) {
        category = TypeCategory.record;
      } else if (masquerade == null || masquerade.classId == i) {
        category = TypeCategory.notMasqueraded;
      } else {
        // Masqueraded class
        assert(cls.enclosingLibrary.importUri.scheme == "dart");
        assert(masquerade.classId >= TypeCategory.minMasqueradeClassId);
        assert(masquerade.classId <= TypeCategory.maxMasqueradeClassId);
        category = masquerade.classId;
      }
      table[i] = category;
    }

    w.DataSegment segment = translator.m.addDataSegment(table);
    w.ArrayType arrayType =
        translator.wasmArrayType(w.PackedType.i8, "const i8", mutable: false);
    w.DefinedGlobal global = translator.m
        .addGlobal(w.GlobalType(w.RefType.def(arrayType, nullable: false)));
    // Initialize the global to a dummy array, since `array.new_data` is not
    // a constant instruction and thus can't be used in the initializer.
    global.initializer.array_new_fixed(arrayType, 0);
    global.initializer.end();
    // Create the actual table in the init function.
    w.Instructions b = translator.initFunction.body;
    b.i32_const(0);
    b.i32_const(table.length);
    b.array_new_data(arrayType, segment);
    b.global_set(global);

    return global;
  }

  bool isFunctionTypeParameter(TypeParameterType type) =>
      type.parameter.parent == null;

  bool _isTypeConstant(DartType type) {
    return type is DynamicType ||
        type is VoidType ||
        type is NeverType ||
        type is NullType ||
        type is FutureOrType && _isTypeConstant(type.typeArgument) ||
        (type is FunctionType &&
            type.typeParameters.every((p) => _isTypeConstant(p.bound)) &&
            _isTypeConstant(type.returnType) &&
            type.positionalParameters.every(_isTypeConstant) &&
            type.namedParameters.every((n) => _isTypeConstant(n.type))) ||
        type is InterfaceType && type.typeArguments.every(_isTypeConstant) ||
        (type is RecordType &&
            type.positional.every(_isTypeConstant) &&
            type.named.every((n) => _isTypeConstant(n.type))) ||
        type is TypeParameterType && isFunctionTypeParameter(type) ||
        type is InlineType &&
            _isTypeConstant(type.instantiatedRepresentationType);
  }

  Class classForType(DartType type) {
    if (type is DynamicType) {
      return translator.dynamicTypeClass;
    } else if (type is VoidType) {
      return translator.voidTypeClass;
    } else if (type is NeverType) {
      // For runtime types with sound null safety, `Never?` is the same as
      // `Null`.
      if (type.nullability == Nullability.nullable) {
        return translator.nullTypeClass;
      } else {
        return translator.neverTypeClass;
      }
    } else if (type is NullType) {
      return translator.nullTypeClass;
    } else if (type is FutureOrType) {
      return translator.futureOrTypeClass;
    } else if (type is InterfaceType) {
      return translator.interfaceTypeClass;
    } else if (type is FunctionType) {
      return translator.functionTypeClass;
    } else if (type is TypeParameterType) {
      if (isFunctionTypeParameter(type)) {
        return translator.functionTypeParameterTypeClass;
      } else {
        return translator.interfaceTypeParameterTypeClass;
      }
    } else if (type is InlineType) {
      return classForType(type.instantiatedRepresentationType);
    } else if (type is RecordType) {
      return translator.recordTypeClass;
    }
    throw "Unexpected DartType: $type";
  }

  /// Allocates a `List<_Type>` from [types] and pushes it to the stack.
  void _makeTypeList(CodeGenerator codeGen, Iterable<DartType> types) {
    if (types.every(_isTypeConstant)) {
      translator.constants.instantiateConstant(codeGen.function, codeGen.b,
          translator.constants.makeTypeList(types), typeListExpectedType);
    } else {
      w.ValueType listType = codeGen.makeListFromExpressions(
          types.map((t) => TypeLiteral(t)).toList(), typeType);
      translator.convertType(codeGen.function, listType, typeListExpectedType);
    }
  }

  void _makeInterfaceType(CodeGenerator codeGen, InterfaceType type) {
    w.Instructions b = codeGen.b;
    ClassInfo typeInfo = translator.classInfo[type.classNode]!;
    b.i32_const(encodedNullability(type));
    b.i64_const(typeInfo.classId);
    _makeTypeList(codeGen, type.typeArguments);
  }

  void _makeRecordType(CodeGenerator codeGen, RecordType type) {
    codeGen.b.i32_const(encodedNullability(type));
    translator.constants.instantiateConstant(
        codeGen.function,
        codeGen.b,
        ListConstant(
          InterfaceType(
              translator.coreTypes.stringClass, Nullability.nonNullable),
          type.named.map((t) => StringConstant(t.name)).toList(),
        ),
        recordTypeNamesFieldExpectedType);
    _makeTypeList(
        codeGen, type.positional.followedBy(type.named.map((t) => t.type)));
  }

  /// Normalizes a Dart type. Many rules are already applied for us, but we
  /// still have to manually normalize [FutureOr].
  DartType normalize(DartType type) {
    if (type is! FutureOrType) return type;

    final s = normalize(type.typeArgument);

    // `coreTypes.isTope` and `coreTypes.isObject` take into account the
    // normalization rules of `futureOr`.
    if (coreTypes.isTop(type) || coreTypes.isObject(type)) {
      return s;
    } else if (s is NeverType) {
      return InterfaceType(coreTypes.futureClass, Nullability.nonNullable,
          const [const NeverType.nonNullable()]);
    } else if (s is NullType) {
      return InterfaceType(coreTypes.futureClass, Nullability.nullable,
          const [const NullType()]);
    }

    // The type is normalized, and remains a `FutureOr` so now we normalize its
    // nullability.
    final declaredNullability = s.nullability == Nullability.nullable
        ? Nullability.nonNullable
        : type.declaredNullability;
    return FutureOrType(s, declaredNullability);
  }

  void _makeFutureOrType(CodeGenerator codeGen, FutureOrType type) {
    w.Instructions b = codeGen.b;
    b.i32_const(encodedNullability(type));
    makeType(codeGen, type.typeArgument);
    codeGen.call(translator.createNormalizedFutureOrType.reference);
  }

  void _makeFunctionType(CodeGenerator codeGen, FunctionType type) {
    int typeParameterOffset = computeFunctionTypeParameterOffset(type);
    w.Instructions b = codeGen.b;
    b.i32_const(encodedNullability(type));
    b.i64_const(typeParameterOffset);

    // List<_Type> typeParameterBounds
    _makeTypeList(codeGen, type.typeParameters.map((p) => p.bound));

    // List<_Type> typeParameterDefaults
    _makeTypeList(codeGen, type.typeParameters.map((p) => p.defaultType));

    // _Type returnType
    makeType(codeGen, type.returnType);

    // List<_Type> positionalParameters
    _makeTypeList(codeGen, type.positionalParameters);

    // int requiredParameterCount
    b.i64_const(type.requiredParameterCount);

    // List<_NamedParameter> namedParameters
    if (type.namedParameters.every((n) => _isTypeConstant(n.type))) {
      translator.constants.instantiateConstant(
          codeGen.function,
          b,
          translator.constants.makeNamedParametersList(type),
          namedParametersExpectedType);
    } else {
      Class namedParameterClass = translator.namedParameterClass;
      Constructor namedParameterConstructor =
          namedParameterClass.constructors.single;
      List<Expression> expressions = [];
      for (NamedType n in type.namedParameters) {
        expressions.add(_isTypeConstant(n.type)
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
          codeGen.makeListFromExpressions(expressions, namedParameterType);
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
    w.Instructions b = codeGen.b;
    if (_isTypeConstant(type)) {
      translator.constants.instantiateConstant(
          codeGen.function, b, TypeLiteralConstant(type), nonNullableTypeType);
      return nonNullableTypeType;
    }
    // All of the singleton types represented by canonical objects should be
    // created const.
    assert(type is TypeParameterType ||
        type is InlineType ||
        type is InterfaceType ||
        type is FutureOrType ||
        type is FunctionType ||
        type is RecordType);
    if (type is TypeParameterType) {
      assert(!isFunctionTypeParameter(type));
      codeGen.instantiateTypeParameter(type.parameter);
      if (type.declaredNullability == Nullability.nullable) {
        codeGen.call(translator.typeAsNullable.reference);
      }
      return nonNullableTypeType;
    }

    if (type is InlineType) {
      return makeType(codeGen, type.instantiatedRepresentationType);
    }

    ClassInfo info = translator.classInfo[classForType(type)]!;
    if (type is FutureOrType) {
      _makeFutureOrType(codeGen, type);
      return info.nonNullableType;
    }

    translator.functions.allocateClass(info.classId);
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
  int getFunctionTypeParameterIndex(TypeParameter type) {
    assert(functionTypeParameterIndex.containsKey(type),
        "Type parameter offset has not been computed for function type");
    return functionTypeParameterIndex[type]!;
  }

  /// Test value against a Dart type. Expects the value on the stack as a
  /// (ref null #Top) and leaves the result on the stack as an i32.
  /// TODO(joshualitt): Remove dependency on [CodeGenerator]
  void emitTypeTest(
      CodeGenerator codeGen, DartType type, DartType operandType) {
    w.Instructions b = codeGen.b;
    if (type is! InterfaceType) {
      makeType(codeGen, type);
      codeGen.call(translator.isSubtype.reference);
      return;
    }
    bool isPotentiallyNullable = operandType.isPotentiallyNullable;
    w.Label? resultLabel;
    if (isPotentiallyNullable) {
      // Store operand in a temporary variable, since Binaryen does not support
      // block inputs.
      w.Local operand = codeGen.addLocal(translator.topInfo.nullableType);
      b.local_set(operand);
      resultLabel = b.block(const [], const [w.NumType.i32]);
      w.Label nullLabel = b.block(const [], const []);
      b.local_get(operand);
      b.br_on_null(nullLabel);
    }
    void _endPotentiallyNullableBlock() {
      if (isPotentiallyNullable) {
        b.br(resultLabel!);
        b.end(); // nullLabel
        b.i32_const(encodedNullability(type));
        b.end(); // resultLabel
      }
    }

    if (type.typeArguments.any((t) => t is! DynamicType)) {
      // Type has at least one type argument that is not `dynamic`.
      //
      // In cases like `x is List<T>` where `x : Iterable<T>` (tested-against
      // type is a subtype of the operand's static type and the types have same
      // number of type arguments), it is not necessary to test the type
      // arguments.
      Class cls = translator.classForType(operandType);
      InterfaceType? base = translator.hierarchy
          .getTypeAsInstanceOf(type, cls,
              isNonNullableByDefault:
                  codeGen.member.enclosingLibrary.isNonNullableByDefault)
          ?.withDeclaredNullability(operandType.declaredNullability);

      final sameNumTypeParams = operandType is InterfaceType &&
          operandType.typeArguments.length == type.typeArguments.length;

      if (!(sameNumTypeParams && base == operandType)) {
        makeType(codeGen, type);
        codeGen.call(translator.isSubtype.reference);
        _endPotentiallyNullableBlock();
        return;
      }
    }
    List<Class> concrete = _getConcreteSubtypes(type.classNode).toList();
    if (type.classNode == coreTypes.objectClass) {
      b.drop();
      b.i32_const(1);
    } else if (type.classNode == coreTypes.functionClass) {
      b.ref_test(translator.closureInfo.nonNullableType);
    } else if (concrete.isEmpty) {
      b.drop();
      b.i32_const(0);
    } else if (concrete.length == 1) {
      ClassInfo info = translator.classInfo[concrete.single]!;
      b.struct_get(translator.topInfo.struct, FieldIndex.classId);
      b.i32_const(info.classId);
      b.i32_eq();
    } else {
      w.Local idLocal = codeGen.addLocal(w.NumType.i32);
      b.struct_get(translator.topInfo.struct, FieldIndex.classId);
      b.local_set(idLocal);
      w.Label done = b.block(const [], const [w.NumType.i32]);
      b.i32_const(1);
      for (Class cls in concrete) {
        ClassInfo info = translator.classInfo[cls]!;
        b.i32_const(info.classId);
        b.local_get(idLocal);
        b.i32_eq();
        b.br_if(done);
      }
      b.drop();
      b.i32_const(0);
      b.end(); // done
    }
    _endPotentiallyNullableBlock();
  }

  int encodedNullability(DartType type) =>
      type.declaredNullability == Nullability.nullable ? 1 : 0;
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
  final Map<TypeParameter, int> _functionForParameter = {};

  _FunctionTypeParameterOffsetCollector(this.types);

  @override
  void visitFunctionType(FunctionType node) {
    int slot = _functionStack.length;
    _functionStack.add(node);
    _functionsContainingParameters.add({});

    for (int i = 0; i < node.typeParameters.length; i++) {
      TypeParameter parameter = node.typeParameters[i];
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
      TypeParameter parameter = node.typeParameters[i];
      types.functionTypeParameterIndex[parameter] = offset + i;
    }

    _functionsContainingParameters.removeLast();
    _functionStack.removeLast();
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    if (types.isFunctionTypeParameter(node)) {
      int slot = _functionForParameter[node.parameter]!;
      for (int inner = slot + 1; inner < _functionStack.length; inner++) {
        _functionsContainingParameters[slot].add(_functionStack[inner]);
      }
    }
  }
}
