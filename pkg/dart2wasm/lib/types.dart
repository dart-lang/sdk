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
  final Map<TypeParameter, int> _typeOffsets = {};

  void _add(InterfaceType type) {
    Class cls = type.classNode;
    if (_typeOffsets.containsKey(cls)) {
      return;
    }
    int i = 0;
    for (TypeParameter typeParameter in cls.typeParameters) {
      _typeOffsets[typeParameter] = i++;
    }
  }

  int lookup(TypeParameter typeParameter) => _typeOffsets[typeParameter]!;
}

/// Environment that maps function type parameters to their runtime
/// representation when inside a generic function type.
class FunctionTypeEnvironment {
  /// Mapping from function type parameters to their runtime representation.
  late final Map<TypeParameter, FunctionTypeParameterType> _typeOffsets = {};

  /// Current nesting depth of function types (number of function types
  /// enclosing the current function type), or -1 if currently not inside a
  /// function type.
  int _depth = -1;

  FunctionTypeEnvironment();

  /// Enter the scope of a function type and add its type parameters to the
  /// environment.
  void enterFunctionType(FunctionType type) {
    _depth++;
    for (int i = 0; i < type.typeParameters.length; i++) {
      _typeOffsets[type.typeParameters[i]] =
          FunctionTypeParameterType(_depth, i);
    }
  }

  /// Leave the scope of a function type.
  void leaveFunctionType() {
    if (--_depth == -1) {
      // This clear is not strictly necessary, since type parameters for
      // different function types are distinct, but it avoids bloating the
      // map throughout the compilation.
      _typeOffsets.clear();
    }
  }

  /// Look up a function type parameter in the environment.
  FunctionTypeParameterType lookup(TypeParameter typeParameter) =>
      _typeOffsets[typeParameter]!;
}

/// Description of the runtime representation of a function type parameter.
class FunctionTypeParameterType {
  /// The nesting depth of the function type declaring this type parameter,
  /// i.e. the number of function types it is embedded inside.
  final int depth;

  /// The index of this type parameter in the function type's list of type
  /// parameters.
  final int index;

  FunctionTypeParameterType(this.depth, this.index);
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

  /// Environment that maps function type parameters to their runtime
  /// representation when inside a generic function type.
  FunctionTypeEnvironment _env = FunctionTypeEnvironment();

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
        type is TypeParameterType && isFunctionTypeParameter(type);
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
    }
    throw "Unexpected DartType: $type";
  }

  /// Allocates a `List<_Type>` from [types] and pushes it to the stack.
  void _makeTypeList(CodeGenerator codeGen, List<DartType> types) {
    w.ValueType listType = codeGen.makeListFromExpressions(
        types.map((t) => TypeLiteral(t)).toList(), typeType);
    translator.convertType(codeGen.function, listType, typeListExpectedType);
  }

  void _makeInterfaceType(CodeGenerator codeGen, InterfaceType type) {
    w.Instructions b = codeGen.b;
    ClassInfo typeInfo = translator.classInfo[type.classNode]!;
    b.i32_const(encodedNullability(type));
    b.i64_const(typeInfo.classId);
    _makeTypeList(codeGen, type.typeArguments);
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
    w.Instructions b = codeGen.b;
    b.i32_const(encodedNullability(type));
    _env.enterFunctionType(type);
    _makeTypeList(codeGen, type.typeParameters.map((p) => p.bound).toList());
    makeType(codeGen, type.returnType);
    if (type.positionalParameters.every(_isTypeConstant)) {
      translator.constants.instantiateTypeConstant(codeGen.function, b,
          translator.constants.makeTypeList(type.positionalParameters), _env);
    } else {
      _makeTypeList(codeGen, type.positionalParameters);
    }
    b.i64_const(type.requiredParameterCount);
    if (type.namedParameters.every((n) => _isTypeConstant(n.type))) {
      translator.constants.instantiateTypeConstant(codeGen.function, b,
          translator.constants.makeNamedParametersList(type), _env);
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
    _env.leaveFunctionType();
  }

  /// Makes a `_Type` object on the stack.
  /// TODO(joshualitt): Refactor this logic to remove the dependency on
  /// CodeGenerator.
  w.ValueType makeType(CodeGenerator codeGen, DartType type) {
    // Always ensure type is normalized before making a type.
    type = normalize(type);
    w.Instructions b = codeGen.b;
    if (_isTypeConstant(type)) {
      translator.constants.instantiateTypeConstant(
          codeGen.function, b, TypeLiteralConstant(type), _env);
      return nonNullableTypeType;
    }
    // All of the singleton types represented by canonical objects should be
    // created const.
    assert(type is TypeParameterType ||
        type is InterfaceType ||
        type is FutureOrType ||
        type is FunctionType);
    if (type is TypeParameterType) {
      assert(!isFunctionTypeParameter(type));
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
      _makeInterfaceType(codeGen, type);
    } else if (type is FunctionType) {
      _makeFunctionType(codeGen, type);
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
