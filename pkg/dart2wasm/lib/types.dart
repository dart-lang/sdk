// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/code_generator.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

class InterfaceTypeEnvironment {
  final Map<TypeParameter, int> typeOffsets = {};

  void _add(InterfaceType type) {
    Class cls = type.classNode;
    if (typeOffsets.containsKey(cls)) {
      return;
    }
    int i = 0;
    for (TypeParameter typeParameter in cls.typeParameters) {
      typeOffsets[typeParameter] = i++;
    }
  }

  int lookup(TypeParameter typeParameter) => typeOffsets[typeParameter]!;
}

/// Helper class for building runtime types.
class Types {
  final Translator translator;
  late final typeClassInfo = translator.classInfo[translator.typeClass]!;
  late final w.ValueType typeListExpectedType = classAndFieldToType(
      translator.interfaceTypeClass, FieldIndex.interfaceTypeTypeArguments);
  late final w.ValueType namedParametersExpectedType = classAndFieldToType(
      translator.functionTypeClass, FieldIndex.functionTypeNamedParameters);

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

  Types(this.translator);

  w.ValueType classAndFieldToType(Class cls, int fieldIndex) =>
      translator.classInfo[cls]!.struct.fields[fieldIndex].type.unpacked;

  Iterable<Class> _getConcreteSubtypes(Class cls) =>
      translator.subtypes.getSubtypesOf(cls).where((c) => !c.isAbstract);

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
    for (int i = 0; i < translator.classInfoCollector.nextClassId; i++) {
      List<int>? superclassIds = typeRules[i]?.keys.toList();
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
    for (int i = 0; i < translator.classInfoCollector.nextClassId; i++) {
      List<int> supers = typeRulesSupers[i];
      typeRulesSubstitutions.add(supers.isEmpty ? const [] : []);
      for (int j = 0; j < supers.length; j++) {
        int superId = supers[j];
        typeRulesSubstitutions.last.add(typeRules[i]![superId]!);
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
        substitutionsConstantL1.add(ListConstant(
            listTypeType,
            substitutionsL2.map((t) {
              // TODO(joshualitt): implement generic functions
              if (t is FunctionType && isGenericFunction(t)) {
                return TypeLiteralConstant(DynamicType());
              } else {
                return TypeLiteralConstant(t);
              }
            }).toList()));
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
    DartType stringType = InterfaceType(
        translator.stringBaseClass,
        Nullability.nonNullable,
        [translator.coreTypes.stringNonNullableRawType]);
    List<StringConstant> listStringConstant = [];
    for (String name in typeNames) {
      listStringConstant.add(StringConstant(name));
    }
    DartType listStringType = InterfaceType(
        translator.immutableListClass, Nullability.nonNullable, [stringType]);
    translator.constants.instantiateConstant(null, b,
        ListConstant(listStringType, listStringConstant), expectedType);
    return expectedType;
  }

  bool isGenericFunction(FunctionType type) => type.typeParameters.isNotEmpty;

  bool isGenericFunctionTypeParameter(TypeParameterType type) =>
      type.parameter.parent == null;

  bool _isTypeConstant(DartType type) {
    return type is DynamicType ||
        type is VoidType ||
        type is NeverType ||
        type is NullType ||
        type is FutureOrType && _isTypeConstant(type.typeArgument) ||
        (type is FunctionType &&
            type.typeParameters.isEmpty && // TODO(joshualitt) generic functions
            _isTypeConstant(type.returnType) &&
            type.positionalParameters.every(_isTypeConstant) &&
            type.namedParameters.every((n) => _isTypeConstant(n.type))) ||
        type is InterfaceType && type.typeArguments.every(_isTypeConstant);
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
      if (isGenericFunction(type)) {
        return translator.genericFunctionTypeClass;
      } else {
        return translator.functionTypeClass;
      }
    } else if (type is TypeParameterType) {
      if (isGenericFunctionTypeParameter(type)) {
        return translator.genericFunctionTypeParameterTypeClass;
      } else {
        return translator.interfaceTypeParameterTypeClass;
      }
    }
    throw "Unexpected DartType: $type";
  }

  void _makeTypeList(CodeGenerator codeGen, List<DartType> types) {
    w.ValueType listType = codeGen.makeListFromExpressions(
        types.map((t) => TypeLiteral(t)).toList(), typeType);
    translator.convertType(codeGen.function, listType, typeListExpectedType);
  }

  void _makeInterfaceType(
      CodeGenerator codeGen, ClassInfo info, InterfaceType type) {
    w.Instructions b = codeGen.b;
    ClassInfo typeInfo = translator.classInfo[type.classNode]!;
    b.i32_const(encodedNullability(type));
    b.i64_const(typeInfo.classId);
    _makeTypeList(codeGen, type.typeArguments);
  }

  DartType normalizeFutureOrType(FutureOrType type) {
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

  /// Normalizes a Dart type. Many rules are already applied for us, but some we
  /// have to apply manually, particularly to [FutureOr].
  DartType normalize(DartType type) {
    if (type is InterfaceType) {
      return InterfaceType(type.classNode, type.nullability,
          type.typeArguments.map(normalize).toList());
    } else if (type is FunctionType) {
      return FunctionType(type.positionalParameters.map(normalize).toList(),
          normalize(type.returnType), type.nullability,
          namedParameters: type.namedParameters
              .map((namedType) => NamedType(
                  namedType.name, normalize(namedType.type),
                  isRequired: namedType.isRequired))
              .toList(),
          typeParameters: type.typeParameters
              .map((typeParameter) => TypeParameter(
                  typeParameter.name,
                  normalize(typeParameter.bound),
                  normalize(typeParameter.defaultType)))
              .toList(),
          requiredParameterCount: type.requiredParameterCount);
    } else if (type is FutureOrType) {
      return normalizeFutureOrType(type);
    } else {
      return type;
    }
  }

  void _makeFutureOrType(CodeGenerator codeGen, FutureOrType type) {
    w.Instructions b = codeGen.b;
    b.i32_const(encodedNullability(type));
    makeType(codeGen, type.typeArgument);
    codeGen.call(translator.createNormalizedFutureOrType.reference);
  }

  void _makeFunctionType(
      CodeGenerator codeGen, ClassInfo info, FunctionType type) {
    w.Instructions b = codeGen.b;
    b.i32_const(encodedNullability(type));
    makeType(codeGen, type.returnType);
    if (type.positionalParameters.every(_isTypeConstant)) {
      translator.constants.instantiateConstant(
          codeGen.function,
          b,
          translator.constants.makeTypeList(type.positionalParameters),
          typeListExpectedType);
    } else {
      _makeTypeList(codeGen, type.positionalParameters);
    }
    b.i64_const(type.requiredParameterCount);
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
        type is InterfaceType ||
        type is FutureOrType ||
        type is FunctionType);
    if (type is TypeParameterType) {
      codeGen.instantiateTypeParameter(type.parameter);
      if (type.declaredNullability == Nullability.nullable) {
        codeGen.call(translator.typeAsNullable.reference);
      }
      return nonNullableTypeType;
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
      _makeInterfaceType(codeGen, info, type);
    } else if (type is FunctionType) {
      if (isGenericFunction(type)) {
        // TODO(joshualitt): Implement generic function types and share most of
        // the logic with _makeFunctionType.
        print("Not implemented: RTI ${type}");
        b.i32_const(encodedNullability(type));
      } else {
        _makeFunctionType(codeGen, info, type);
      }
    } else {
      throw '`$type` should have already been handled.';
    }
    b.struct_new(info.struct);
    return info.nonNullableType;
  }

  /// Test value against a Dart type. Expects the value on the stack as a
  /// (ref null #Top) and leaves the result on the stack as an i32.
  /// TODO(joshualitt): Remove dependency on [CodeGenerator]
  void emitTypeTest(CodeGenerator codeGen, DartType type, DartType operandType,
      TreeNode node) {
    w.Instructions b = codeGen.b;
    if (type is FunctionType && isGenericFunction(type)) {
      // TODO(joshualitt): Finish generic function types.
      print("Not implemented: Type test with generic function type $type"
          " at ${node.location}");
      b.drop();
      b.i32_const(1);
      return;
    }
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
      // If the tested-against type as an instance of the static operand type
      // has the same type arguments as the static operand type, it is not
      // necessary to test the type arguments.
      Class cls = translator.classForType(operandType);
      InterfaceType? base = translator.hierarchy
          .getTypeAsInstanceOf(type, cls, codeGen.member.enclosingLibrary)
          ?.withDeclaredNullability(operandType.declaredNullability);
      if (base != operandType) {
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
      ClassInfo functionInfo = translator.classInfo[translator.functionClass]!;
      b.ref_test(functionInfo.struct);
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
