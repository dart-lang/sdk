// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests related to the [TypeSystem] class.

library analyzer.test.generated.type_system_test;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(StrongAssignabilityTest);
  runReflectiveTests(StrongSubtypingTest);
  runReflectiveTests(StrongGenericFunctionInferenceTest);
  runReflectiveTests(LeastUpperBoundTest);
}

@reflectiveTest
class StrongAssignabilityTest {
  TypeProvider typeProvider;
  TypeSystem typeSystem;

  DartType get bottomType => typeProvider.bottomType;
  InterfaceType get doubleType => typeProvider.doubleType;
  DartType get dynamicType => typeProvider.dynamicType;
  InterfaceType get functionType => typeProvider.functionType;
  InterfaceType get intType => typeProvider.intType;
  InterfaceType get listType => typeProvider.listType;
  InterfaceType get numType => typeProvider.numType;
  InterfaceType get objectType => typeProvider.objectType;
  InterfaceType get stringType => typeProvider.stringType;
  DartType get voidType => VoidTypeImpl.instance;

  void setUp() {
    typeProvider = new TestTypeProvider();
    typeSystem = new StrongTypeSystemImpl();
  }

  void test_isAssignableTo_bottom_isBottom() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      doubleType,
      numType,
      stringType,
      interfaceType,
      bottomType
    ];

    _checkGroups(bottomType, interassignable: interassignable);
  }

  void test_isAssignableTo_call_method() {
    ClassElementImpl classBottom = ElementFactory.classElement2("B");
    MethodElement methodBottom =
        ElementFactory.methodElement("call", objectType, <DartType>[intType]);
    classBottom.methods = <MethodElement>[methodBottom];

    DartType top =
        TypeBuilder.function(required: <DartType>[intType], result: objectType);
    InterfaceType bottom = classBottom.type;

    _checkIsStrictAssignableTo(bottom, top);
  }

  void test_isAssignableTo_classes() {
    ClassElement classTop = ElementFactory.classElement2("A");
    ClassElement classLeft = ElementFactory.classElement("B", classTop.type);
    ClassElement classRight = ElementFactory.classElement("C", classTop.type);
    ClassElement classBottom = ElementFactory.classElement("D", classLeft.type)
      ..interfaces = <InterfaceType>[classRight.type];
    InterfaceType top = classTop.type;
    InterfaceType left = classLeft.type;
    InterfaceType right = classRight.type;
    InterfaceType bottom = classBottom.type;

    _checkLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_double() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      doubleType,
      numType,
      bottomType
    ];
    List<DartType> unrelated = <DartType>[intType, stringType, interfaceType,];

    _checkGroups(doubleType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_dynamic_isTop() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      doubleType,
      numType,
      stringType,
      interfaceType,
      bottomType
    ];
    _checkGroups(dynamicType, interassignable: interassignable);
  }

  void test_isAssignableTo_fuzzy_arrows() {
    FunctionType top = TypeBuilder
        .function(required: <DartType>[dynamicType], result: objectType);
    FunctionType left = TypeBuilder
        .function(required: <DartType>[objectType], result: objectType);
    FunctionType right = TypeBuilder
        .function(required: <DartType>[dynamicType], result: bottomType);
    FunctionType bottom = TypeBuilder
        .function(required: <DartType>[objectType], result: bottomType);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_generics() {
    ClassElementImpl LClass = ElementFactory.classElement2('L', ["T"]);
    InterfaceType LType = LClass.type;
    ClassElementImpl MClass = ElementFactory.classElement2('M', ["T"]);
    DartType typeParam = MClass.typeParameters[0].type;
    InterfaceType superType = LType.instantiate(<DartType>[typeParam]);
    MClass.interfaces = <InterfaceType>[superType];
    InterfaceType MType = MClass.type;

    InterfaceType top = LType.instantiate(<DartType>[dynamicType]);
    InterfaceType left = MType.instantiate(<DartType>[dynamicType]);
    InterfaceType right = LType.instantiate(<DartType>[intType]);
    InterfaceType bottom = MType.instantiate(<DartType>[intType]);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_int() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      intType,
      numType,
      bottomType
    ];
    List<DartType> unrelated = <DartType>[
      doubleType,
      stringType,
      interfaceType,
    ];

    _checkGroups(intType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_named_optional() {
    DartType r =
        TypeBuilder.function(required: <DartType>[intType], result: intType);
    DartType o = TypeBuilder.function(
        required: <DartType>[], optional: <DartType>[intType], result: intType);
    DartType n = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType},
        result: intType);
    DartType rr = TypeBuilder
        .function(required: <DartType>[intType, intType], result: intType);
    DartType ro = TypeBuilder.function(
        required: <DartType>[intType],
        optional: <DartType>[intType],
        result: intType);
    DartType rn = TypeBuilder.function(
        required: <DartType>[intType],
        named: <String, DartType>{'x': intType},
        result: intType);
    DartType oo = TypeBuilder.function(
        required: <DartType>[],
        optional: <DartType>[intType, intType],
        result: intType);
    DartType nn = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType, 'y': intType},
        result: intType);
    DartType nnn = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType, 'y': intType, 'z': intType},
        result: intType);

    _checkGroups(r,
        interassignable: [r, o, ro, rn, oo], unrelated: [n, rr, nn, nnn]);
    _checkGroups(o,
        interassignable: [o, oo], unrelated: [n, rr, ro, rn, nn, nnn]);
    _checkGroups(n,
        interassignable: [n, nn, nnn], unrelated: [r, o, rr, ro, rn, oo]);
    _checkGroups(rr,
        interassignable: [rr, ro, oo], unrelated: [r, o, n, rn, nn, nnn]);
    _checkGroups(ro, interassignable: [ro, oo], unrelated: [o, n, rn, nn, nnn]);
    _checkGroups(rn,
        interassignable: [rn], unrelated: [o, n, rr, ro, oo, nn, nnn]);
    _checkGroups(oo, interassignable: [oo], unrelated: [n, rn, nn, nnn]);
    _checkGroups(nn,
        interassignable: [nn, nnn], unrelated: [r, o, rr, ro, rn, oo]);
    _checkGroups(nnn,
        interassignable: [nnn], unrelated: [r, o, rr, ro, rn, oo]);
  }

  void test_isAssignableTo_num() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> interassignable = <DartType>[
      dynamicType,
      objectType,
      numType,
      intType,
      doubleType,
      bottomType
    ];
    List<DartType> unrelated = <DartType>[stringType, interfaceType,];

    _checkGroups(numType,
        interassignable: interassignable, unrelated: unrelated);
  }

  void test_isAssignableTo_simple_function() {
    FunctionType top =
        TypeBuilder.function(required: <DartType>[intType], result: objectType);
    FunctionType left =
        TypeBuilder.function(required: <DartType>[intType], result: intType);
    FunctionType right = TypeBuilder
        .function(required: <DartType>[objectType], result: objectType);
    FunctionType bottom =
        TypeBuilder.function(required: <DartType>[objectType], result: intType);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_void_functions() {
    FunctionType top =
        TypeBuilder.function(required: <DartType>[intType], result: voidType);
    FunctionType bottom =
        TypeBuilder.function(required: <DartType>[objectType], result: intType);

    _checkEquivalent(bottom, top);
  }

  void _checkCrossLattice(
      DartType top, DartType left, DartType right, DartType bottom) {
    _checkGroups(top, interassignable: <DartType>[top, left, right, bottom]);
    _checkGroups(left, interassignable: <DartType>[top, left, right, bottom]);
    _checkGroups(right, interassignable: <DartType>[top, left, right, bottom]);
    _checkGroups(bottom, interassignable: <DartType>[top, left, right, bottom]);
  }

  void _checkEquivalent(DartType type1, DartType type2) {
    _checkIsAssignableTo(type1, type2);
    _checkIsAssignableTo(type2, type1);
  }

  void _checkGroups(DartType t1,
      {List<DartType> interassignable, List<DartType> unrelated}) {
    if (interassignable != null) {
      for (DartType t2 in interassignable) {
        _checkEquivalent(t1, t2);
      }
    }
    if (unrelated != null) {
      for (DartType t2 in unrelated) {
        _checkUnrelated(t1, t2);
      }
    }
  }

  void _checkIsAssignableTo(DartType type1, DartType type2) {
    expect(typeSystem.isAssignableTo(type1, type2), true);
  }

  void _checkIsNotAssignableTo(DartType type1, DartType type2) {
    expect(typeSystem.isAssignableTo(type1, type2), false);
  }

  void _checkIsStrictAssignableTo(DartType type1, DartType type2) {
    _checkIsAssignableTo(type1, type2);
    _checkIsNotAssignableTo(type2, type1);
  }

  void _checkLattice(
      DartType top, DartType left, DartType right, DartType bottom) {
    _checkGroups(top, interassignable: <DartType>[top, left, right, bottom]);
    _checkGroups(left,
        interassignable: <DartType>[top, left, bottom],
        unrelated: <DartType>[right]);
    _checkGroups(right,
        interassignable: <DartType>[top, right, bottom],
        unrelated: <DartType>[left]);
    _checkGroups(bottom, interassignable: <DartType>[top, left, right, bottom]);
  }

  void _checkUnrelated(DartType type1, DartType type2) {
    _checkIsNotAssignableTo(type1, type2);
    _checkIsNotAssignableTo(type2, type1);
  }
}

@reflectiveTest
class StrongGenericFunctionInferenceTest {
  TypeProvider typeProvider;
  StrongTypeSystemImpl typeSystem;

  DartType get bottomType => typeProvider.bottomType;
  InterfaceType get doubleType => typeProvider.doubleType;
  DartType get dynamicType => typeProvider.dynamicType;
  InterfaceType get functionType => typeProvider.functionType;
  InterfaceType get intType => typeProvider.intType;
  InterfaceType get iterableType => typeProvider.iterableType;
  InterfaceType get listType => typeProvider.listType;
  InterfaceType get numType => typeProvider.numType;
  InterfaceType get objectType => typeProvider.objectType;
  InterfaceType get stringType => typeProvider.stringType;
  DartType get voidType => VoidTypeImpl.instance;

  void setUp() {
    typeProvider = new TestTypeProvider();
    typeSystem = new StrongTypeSystemImpl();
  }

  void test_boundedByAnotherTypeParameter() {
    // <TFrom, TTo extends Iterable<TFrom>>(TFrom) -> TTo
    var tFrom = TypeBuilder.variable('TFrom');
    var tTo =
        TypeBuilder.variable('TTo', bound: iterableType.instantiate([tFrom]));
    var cast = TypeBuilder
        .function(types: [tFrom, tTo], required: [tFrom], result: tTo);
    expect(_inferCall(cast, [stringType]), [
      stringType,
      iterableType.instantiate([stringType])
    ]);
  }

  void test_boundedRecursively() {
    // class Clonable<T extends Clonable<T>>
    ClassElementImpl clonable =
        ElementFactory.classElement('Clonable', objectType, ['T']);
    (clonable.typeParameters[0] as TypeParameterElementImpl).bound =
        clonable.type;
    // class Foo extends Clonable<Foo>
    ClassElementImpl foo = ElementFactory.classElement('Foo', null);
    foo.supertype = clonable.type.instantiate([foo.type]);

    // <S extends Clonable<S>>
    var s = TypeBuilder.variable('S');
    (s.element as TypeParameterElementImpl).bound =
        clonable.type.instantiate([s]);
    // (S, S) -> S
    var clone = TypeBuilder.function(types: [s], required: [s, s], result: s);
    expect(_inferCall(clone, [foo.type, foo.type]), [foo.type]);

    // Something invalid...
    expect(_inferCall(clone, [stringType, numType]), [
      clonable.type.instantiate([dynamicType])
    ]);
  }

  void test_genericCastFunction() {
    // <TFrom, TTo>(TFrom) -> TTo
    var tFrom = TypeBuilder.variable('TFrom');
    var tTo = TypeBuilder.variable('TTo');
    var cast = TypeBuilder
        .function(types: [tFrom, tTo], required: [tFrom], result: tTo);
    expect(_inferCall(cast, [intType]), [intType, dynamicType]);
  }

  void test_genericCastFunctionWithUpperBound() {
    // <TFrom, TTo extends TFrom>(TFrom) -> TTo
    var tFrom = TypeBuilder.variable('TFrom');
    var tTo = TypeBuilder.variable('TTo', bound: tFrom);
    var cast = TypeBuilder
        .function(types: [tFrom, tTo], required: [tFrom], result: tTo);
    expect(_inferCall(cast, [intType]), [intType, intType]);
  }

  void test_parametersToFunctionParam() {
    // <T>(f(T t)) -> T
    var t = TypeBuilder.variable('T');
    var cast = TypeBuilder.function(types: [
      t
    ], required: [
      TypeBuilder.function(required: [t], result: dynamicType)
    ], result: t);
    expect(
        _inferCall(cast, [
          TypeBuilder.function(required: [numType], result: dynamicType)
        ]),
        [numType]);
  }

  void test_parametersUseLeastUpperBound() {
    // <T>(T x, T y) -> T
    var t = TypeBuilder.variable('T');
    var cast = TypeBuilder.function(types: [t], required: [t, t], result: t);
    expect(_inferCall(cast, [intType, doubleType]), [numType]);
  }

  void test_parameterTypeUsesUpperBound() {
    // <T extends num>(T) -> dynamic
    var t = TypeBuilder.variable('T', bound: numType);
    var f =
        TypeBuilder.function(types: [t], required: [t], result: dynamicType);
    expect(_inferCall(f, [intType]), [intType]);
  }

  void test_returnFunctionWithGenericParameter() {
    // <T>(T -> T) -> (T -> void)
    var t = TypeBuilder.variable('T');
    var f = TypeBuilder.function(types: [
      t
    ], required: [
      TypeBuilder.function(required: [t], result: t)
    ], result: TypeBuilder.function(required: [t], result: voidType));
    expect(
        _inferCall(f, [
          TypeBuilder.function(required: [numType], result: intType)
        ]),
        [numType]);
  }

  void test_returnFunctionWithGenericParameterAndReturn() {
    // <T>(T -> T) -> (T -> T)
    var t = TypeBuilder.variable('T');
    var f = TypeBuilder.function(types: [
      t
    ], required: [
      TypeBuilder.function(required: [t], result: t)
    ], result: TypeBuilder.function(required: [t], result: t));
    expect(
        _inferCall(f, [
          TypeBuilder.function(required: [numType], result: intType)
        ]),
        [numType]);
  }

  void test_returnFunctionWithGenericReturn() {
    // <T>(T -> T) -> (() -> T)
    var t = TypeBuilder.variable('T');
    var f = TypeBuilder.function(types: [
      t
    ], required: [
      TypeBuilder.function(required: [t], result: t)
    ], result: TypeBuilder.function(required: [], result: t));
    expect(
        _inferCall(f, [
          TypeBuilder.function(required: [numType], result: intType)
        ]),
        [intType]);
  }

  void test_returnTypeFromContext() {
    // <T>() -> T
    var t = TypeBuilder.variable('T');
    var f = TypeBuilder.function(types: [t], required: [], result: t);
    expect(_inferCall(f, [], stringType), [stringType]);
  }

  void test_returnTypeWithBoundFromContext() {
    // <T extends num>() -> T
    var t = TypeBuilder.variable('T', bound: numType);
    var f = TypeBuilder.function(types: [t], required: [], result: t);
    expect(_inferCall(f, [], doubleType), [doubleType]);
  }

  void test_returnTypeWithBoundFromInvalidContext() {
    // <T extends num>() -> T
    var t = TypeBuilder.variable('T', bound: numType);
    var f = TypeBuilder.function(types: [t], required: [], result: t);
    expect(_inferCall(f, [], stringType), [numType]);
  }

  void test_unifyParametersToFunctionParam() {
    // <T>(f(T t), g(T t)) -> T
    var t = TypeBuilder.variable('T');
    var cast = TypeBuilder.function(types: [
      t
    ], required: [
      TypeBuilder.function(required: [t], result: dynamicType),
      TypeBuilder.function(required: [t], result: dynamicType)
    ], result: t);
    expect(
        _inferCall(cast, [
          TypeBuilder.function(required: [intType], result: dynamicType),
          TypeBuilder.function(required: [doubleType], result: dynamicType)
        ]),
        [dynamicType]);
  }

  void test_unusedReturnTypeIsDynamic() {
    // <T>() -> T
    var t = TypeBuilder.variable('T');
    var f = TypeBuilder.function(types: [t], required: [], result: t);
    expect(_inferCall(f, []), [dynamicType]);
  }

  void test_unusedReturnTypeWithUpperBound() {
    // <T extends num>() -> T
    var t = TypeBuilder.variable('T', bound: numType);
    var f = TypeBuilder.function(types: [t], required: [], result: t);
    expect(_inferCall(f, []), [numType]);
  }

  List<DartType> _inferCall(FunctionTypeImpl ft, List<DartType> arguments,
      [DartType returnType]) {
    FunctionType inferred = typeSystem.inferGenericFunctionCall(typeProvider,
        ft, ft.parameters.map((p) => p.type).toList(), arguments, returnType);
    return inferred.typeArguments;
  }
}

@reflectiveTest
class StrongSubtypingTest {
  TypeProvider typeProvider;
  TypeSystem typeSystem;

  DartType get bottomType => typeProvider.bottomType;
  InterfaceType get doubleType => typeProvider.doubleType;
  DartType get dynamicType => typeProvider.dynamicType;
  InterfaceType get functionType => typeProvider.functionType;
  InterfaceType get intType => typeProvider.intType;
  InterfaceType get listType => typeProvider.listType;
  InterfaceType get numType => typeProvider.numType;
  InterfaceType get objectType => typeProvider.objectType;
  InterfaceType get stringType => typeProvider.stringType;
  DartType get voidType => VoidTypeImpl.instance;

  void setUp() {
    typeProvider = new TestTypeProvider();
    typeSystem = new StrongTypeSystemImpl();
  }

  void test_bottom_isBottom() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> equivalents = <DartType>[bottomType];
    List<DartType> supertypes = <DartType>[
      dynamicType,
      objectType,
      intType,
      doubleType,
      numType,
      stringType,
      functionType,
      interfaceType
    ];
    _checkGroups(bottomType, equivalents: equivalents, supertypes: supertypes);
  }

  void test_call_method() {
    ClassElementImpl classBottom = ElementFactory.classElement2("Bottom");
    MethodElement methodBottom =
        ElementFactory.methodElement("call", objectType, <DartType>[intType]);
    classBottom.methods = <MethodElement>[methodBottom];

    DartType top =
        TypeBuilder.function(required: <DartType>[intType], result: objectType);
    InterfaceType bottom = classBottom.type;

    _checkIsStrictSubtypeOf(bottom, top);
  }

  void test_classes() {
    ClassElement classTop = ElementFactory.classElement2("A");
    ClassElement classLeft = ElementFactory.classElement("B", classTop.type);
    ClassElement classRight = ElementFactory.classElement("C", classTop.type);
    ClassElement classBottom = ElementFactory.classElement("D", classLeft.type)
      ..interfaces = <InterfaceType>[classRight.type];
    InterfaceType top = classTop.type;
    InterfaceType left = classLeft.type;
    InterfaceType right = classRight.type;
    InterfaceType bottom = classBottom.type;

    _checkLattice(top, left, right, bottom);
  }

  void test_double() {
    List<DartType> equivalents = <DartType>[doubleType];
    List<DartType> supertypes = <DartType>[numType];
    List<DartType> unrelated = <DartType>[intType];
    _checkGroups(doubleType,
        equivalents: equivalents, supertypes: supertypes, unrelated: unrelated);
  }

  void test_dynamic_isTop() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    List<DartType> equivalents = <DartType>[dynamicType, objectType];
    List<DartType> subtypes = <DartType>[
      intType,
      doubleType,
      numType,
      stringType,
      functionType,
      interfaceType,
      bottomType
    ];
    _checkGroups(dynamicType, equivalents: equivalents, subtypes: subtypes);
  }

  void test_fuzzy_arrows() {
    FunctionType top = TypeBuilder
        .function(required: <DartType>[dynamicType], result: objectType);
    FunctionType left = TypeBuilder
        .function(required: <DartType>[objectType], result: objectType);
    FunctionType right = TypeBuilder
        .function(required: <DartType>[dynamicType], result: bottomType);
    FunctionType bottom = TypeBuilder
        .function(required: <DartType>[objectType], result: bottomType);

    _checkLattice(top, left, right, bottom);
  }

  void test_genericFunction_generic_monomorphic() {
    DartType s = TypeBuilder.variable("S");
    DartType t = TypeBuilder.variable("T", bound: s);
    DartType u = TypeBuilder.variable("U", bound: intType);
    DartType v = TypeBuilder.variable("V", bound: u);

    _checkIsStrictSubtypeOf(
        TypeBuilder.function(types: [s, t], required: [s], result: t),
        TypeBuilder.function(required: [dynamicType], result: dynamicType));

    _checkIsNotSubtypeOf(
        TypeBuilder.function(types: [u, v], required: [u], result: v),
        TypeBuilder.function(required: [objectType], result: objectType));

    _checkIsStrictSubtypeOf(
        TypeBuilder.function(types: [u, v], required: [u], result: v),
        TypeBuilder.function(required: [intType], result: intType));
  }

  void test_genericFunction_simple() {
    DartType s = TypeBuilder.variable("S");
    DartType t = TypeBuilder.variable("T");

    _checkEquivalent(
        TypeBuilder.function(types: [t]), TypeBuilder.function(types: [s]));

    _checkEquivalent(TypeBuilder.function(types: [t], required: [t], result: t),
        TypeBuilder.function(types: [s], required: [s], result: s));
  }

  void test_genericFunction_simple_bounded() {
    DartType s = TypeBuilder.variable("S");
    DartType t = TypeBuilder.variable("T", bound: s);
    DartType u = TypeBuilder.variable("U");
    DartType v = TypeBuilder.variable("V", bound: u);

    _checkEquivalent(TypeBuilder.function(types: [s, t]),
        TypeBuilder.function(types: [u, v]));

    _checkEquivalent(
        TypeBuilder.function(types: [s, t], required: [s], result: t),
        TypeBuilder.function(types: [u, v], required: [u], result: v));

    {
      DartType top =
          TypeBuilder.function(types: [s, t], required: [t], result: s);
      DartType left =
          TypeBuilder.function(types: [u, v], required: [u], result: u);
      DartType right =
          TypeBuilder.function(types: [u, v], required: [v], result: v);
      DartType bottom =
          TypeBuilder.function(types: [s, t], required: [s], result: t);
      _checkLattice(top, left, right, bottom);
    }
  }

  void test_genericFunction_simple_fBounded() {
    ClassElementImpl AClass = ElementFactory.classElement2('A', ["Q"]);
    InterfaceType AType = AClass.type;
    ClassElementImpl BClass = ElementFactory.classElement2('B', ["R"]);
    BClass.supertype = AType.instantiate([BClass.typeParameters[0].type]);
    InterfaceType BType = BClass.type;

    DartType s = TypeBuilder.variable("S");
    (s.element as TypeParameterElementImpl).bound = AType.instantiate([s]);
    DartType t = TypeBuilder.variable("T", bound: s);
    DartType u = TypeBuilder.variable("U");
    (u.element as TypeParameterElementImpl).bound = BType.instantiate([u]);
    DartType v = TypeBuilder.variable("V", bound: u);

    _checkIsStrictSubtypeOf(
        TypeBuilder.function(types: [s]), TypeBuilder.function(types: [u]));

    _checkIsStrictSubtypeOf(
        TypeBuilder.function(types: [s, t], required: [s], result: t),
        TypeBuilder.function(types: [u, v], required: [u], result: v));
  }

  void test_generics() {
    ClassElementImpl LClass = ElementFactory.classElement2('L', ["T"]);
    InterfaceType LType = LClass.type;
    ClassElementImpl MClass = ElementFactory.classElement2('M', ["T"]);
    DartType typeParam = MClass.typeParameters[0].type;
    InterfaceType superType = LType.instantiate(<DartType>[typeParam]);
    MClass.interfaces = <InterfaceType>[superType];
    InterfaceType MType = MClass.type;

    InterfaceType top = LType.instantiate(<DartType>[dynamicType]);
    InterfaceType left = MType.instantiate(<DartType>[dynamicType]);
    InterfaceType right = LType.instantiate(<DartType>[intType]);
    InterfaceType bottom = MType.instantiate(<DartType>[intType]);

    _checkLattice(top, left, right, bottom);
  }

  void test_int() {
    List<DartType> equivalents = <DartType>[intType];
    List<DartType> supertypes = <DartType>[numType];
    List<DartType> unrelated = <DartType>[doubleType];
    _checkGroups(intType,
        equivalents: equivalents, supertypes: supertypes, unrelated: unrelated);
  }

  void test_named_optional() {
    DartType r =
        TypeBuilder.function(required: <DartType>[intType], result: intType);
    DartType o = TypeBuilder.function(
        required: <DartType>[], optional: <DartType>[intType], result: intType);
    DartType n = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType},
        result: intType);
    DartType rr = TypeBuilder
        .function(required: <DartType>[intType, intType], result: intType);
    DartType ro = TypeBuilder.function(
        required: <DartType>[intType],
        optional: <DartType>[intType],
        result: intType);
    DartType rn = TypeBuilder.function(
        required: <DartType>[intType],
        named: <String, DartType>{'x': intType},
        result: intType);
    DartType oo = TypeBuilder.function(
        required: <DartType>[],
        optional: <DartType>[intType, intType],
        result: intType);
    DartType nn = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType, 'y': intType},
        result: intType);
    DartType nnn = TypeBuilder.function(
        required: <DartType>[],
        named: <String, DartType>{'x': intType, 'y': intType, 'z': intType},
        result: intType);

    _checkGroups(r,
        equivalents: [r],
        subtypes: [o, ro, rn, oo],
        unrelated: [n, rr, nn, nnn]);
    _checkGroups(o,
        equivalents: [o], subtypes: [oo], unrelated: [n, rr, ro, rn, nn, nnn]);
    _checkGroups(n,
        equivalents: [n],
        subtypes: [nn, nnn],
        unrelated: [r, o, rr, ro, rn, oo]);
    _checkGroups(rr,
        equivalents: [rr],
        subtypes: [ro, oo],
        unrelated: [r, o, n, rn, nn, nnn]);
    _checkGroups(ro,
        equivalents: [ro], subtypes: [oo], unrelated: [o, n, rn, nn, nnn]);
    _checkGroups(rn,
        equivalents: [rn],
        subtypes: [],
        unrelated: [o, n, rr, ro, oo, nn, nnn]);
    _checkGroups(oo,
        equivalents: [oo], subtypes: [], unrelated: [n, rn, nn, nnn]);
    _checkGroups(nn,
        equivalents: [nn], subtypes: [nnn], unrelated: [r, o, rr, ro, rn, oo]);
    _checkGroups(nnn,
        equivalents: [nnn], subtypes: [], unrelated: [r, o, rr, ro, rn, oo]);
  }

  void test_num() {
    List<DartType> equivalents = <DartType>[numType];
    List<DartType> supertypes = <DartType>[];
    List<DartType> unrelated = <DartType>[stringType];
    List<DartType> subtypes = <DartType>[intType, doubleType];
    _checkGroups(numType,
        equivalents: equivalents,
        supertypes: supertypes,
        unrelated: unrelated,
        subtypes: subtypes);
  }

  void test_simple_function() {
    FunctionType top =
        TypeBuilder.function(required: <DartType>[intType], result: objectType);
    FunctionType left =
        TypeBuilder.function(required: <DartType>[intType], result: intType);
    FunctionType right = TypeBuilder
        .function(required: <DartType>[objectType], result: objectType);
    FunctionType bottom =
        TypeBuilder.function(required: <DartType>[objectType], result: intType);

    _checkLattice(top, left, right, bottom);
  }

  /// Regression test for https://github.com/dart-lang/sdk/issues/25069
  void test_simple_function_void() {
    FunctionType functionType =
        TypeBuilder.function(required: <DartType>[intType], result: objectType);
    _checkIsNotSubtypeOf(voidType, functionType);
  }

  void test_void_functions() {
    FunctionType top =
        TypeBuilder.function(required: <DartType>[intType], result: voidType);
    FunctionType bottom =
        TypeBuilder.function(required: <DartType>[objectType], result: intType);

    _checkIsStrictSubtypeOf(bottom, top);
  }

  void _checkEquivalent(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsSubtypeOf(type2, type1);
  }

  void _checkGroups(DartType t1,
      {List<DartType> equivalents,
      List<DartType> unrelated,
      List<DartType> subtypes,
      List<DartType> supertypes}) {
    if (equivalents != null) {
      for (DartType t2 in equivalents) {
        _checkEquivalent(t1, t2);
      }
    }
    if (unrelated != null) {
      for (DartType t2 in unrelated) {
        _checkUnrelated(t1, t2);
      }
    }
    if (subtypes != null) {
      for (DartType t2 in subtypes) {
        _checkIsStrictSubtypeOf(t2, t1);
      }
    }
    if (supertypes != null) {
      for (DartType t2 in supertypes) {
        _checkIsStrictSubtypeOf(t1, t2);
      }
    }
  }

  void _checkIsNotSubtypeOf(DartType type1, DartType type2) {
    expect(typeSystem.isSubtypeOf(type1, type2), false);
  }

  void _checkIsStrictSubtypeOf(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  void _checkIsSubtypeOf(DartType type1, DartType type2) {
    expect(typeSystem.isSubtypeOf(type1, type2), true);
  }

  void _checkLattice(
      DartType top, DartType left, DartType right, DartType bottom) {
    _checkGroups(top,
        equivalents: <DartType>[top],
        subtypes: <DartType>[left, right, bottom]);
    _checkGroups(left,
        equivalents: <DartType>[left],
        subtypes: <DartType>[bottom],
        unrelated: <DartType>[right],
        supertypes: <DartType>[top]);
    _checkGroups(right,
        equivalents: <DartType>[right],
        subtypes: <DartType>[bottom],
        unrelated: <DartType>[left],
        supertypes: <DartType>[top]);
    _checkGroups(bottom,
        equivalents: <DartType>[bottom],
        supertypes: <DartType>[top, left, right]);
  }

  void _checkUnrelated(DartType type1, DartType type2) {
    _checkIsNotSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }
}

class TypeBuilder {
  static FunctionTypeImpl function(
      {List<DartType> types,
      List<DartType> required,
      List<DartType> optional,
      Map<String, DartType> named,
      DartType result}) {
    result = result ?? VoidTypeImpl.instance;
    required = required ?? [];
    FunctionElementImpl f = ElementFactory.functionElement8(required, result,
        optional: optional, named: named);
    if (types != null) {
      f.typeParameters =
          new List<TypeParameterElement>.from(types.map((t) => t.element));
    }
    return f.type = new FunctionTypeImpl(f);
  }

  static TypeParameterType variable(String name, {DartType bound}) =>
      ElementFactory.typeParameterWithType(name, bound).type;
}

@reflectiveTest
class LeastUpperBoundTest {
  TypeProvider typeProvider;
  TypeSystem typeSystem;
  FunctionType simpleFunctionType;

  DartType get bottomType => typeProvider.bottomType;
  InterfaceType get doubleType => typeProvider.doubleType;
  DartType get dynamicType => typeProvider.dynamicType;
  InterfaceType get functionType => typeProvider.functionType;
  InterfaceType get intType => typeProvider.intType;
  InterfaceType get listType => typeProvider.listType;
  InterfaceType get numType => typeProvider.numType;
  InterfaceType get objectType => typeProvider.objectType;
  InterfaceType get stringType => typeProvider.stringType;
  DartType get voidType => VoidTypeImpl.instance;

  void setUp() {
    typeProvider = new TestTypeProvider();
    typeSystem = new TypeSystemImpl();
    FunctionTypeAliasElementImpl typeAlias =
        ElementFactory.functionTypeAliasElement('A');
    typeAlias.parameters = [];
    typeAlias.returnType = voidType;
    simpleFunctionType = typeAlias.type;
  }

  void test_bottom_function() {
    _checkLeastUpperBound(bottomType, simpleFunctionType, simpleFunctionType);
  }

  void test_bottom_interface() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(bottomType, interfaceType, interfaceType);
  }

  void test_bottom_typeParam() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkLeastUpperBound(bottomType, typeParam, typeParam);
  }

  void test_directInterfaceCase() {
    //
    // class A
    // class B implements A
    // class C implements B
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType>[typeA];
    classC.interfaces = <InterfaceType>[typeB];
    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  void test_directSubclassCase() {
    //
    // class A
    // class B extends A
    // class C extends B
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  void test_dynamic_bottom() {
    _checkLeastUpperBound(dynamicType, bottomType, dynamicType);
  }

  void test_dynamic_function() {
    _checkLeastUpperBound(dynamicType, simpleFunctionType, dynamicType);
  }

  void test_dynamic_interface() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(dynamicType, interfaceType, dynamicType);
  }

  void test_dynamic_typeParam() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkLeastUpperBound(dynamicType, typeParam, dynamicType);
  }

  void test_dynamic_void() {
    _checkLeastUpperBound(dynamicType, voidType, dynamicType);
  }

  void test_interface_function() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(interfaceType, simpleFunctionType, objectType);
  }

  void test_mixinCase() {
    //
    // class A
    // class B extends A
    // class C extends A
    // class D extends B with M, N, O, P
    //
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElement classC = ElementFactory.classElement("C", classA.type);
    ClassElementImpl classD = ElementFactory.classElement("D", classB.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    classD.mixins = <InterfaceType>[
      ElementFactory.classElement2("M").type,
      ElementFactory.classElement2("N").type,
      ElementFactory.classElement2("O").type,
      ElementFactory.classElement2("P").type
    ];
    _checkLeastUpperBound(typeD, typeC, typeA);
  }

  void test_object() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    DartType typeObject = typeA.element.supertype;
    // assert that object does not have a super type
    expect((typeObject.element as ClassElement).supertype, isNull);
    // assert that both A and B have the same super type of Object
    expect(typeB.element.supertype, typeObject);
    // finally, assert that the only least upper bound of A and B is Object
    _checkLeastUpperBound(typeA, typeB, typeObject);
  }

  void test_self() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    DartType interfaceType = ElementFactory.classElement2('A', []).type;

    List<DartType> types = [
      dynamicType,
      voidType,
      bottomType,
      typeParam,
      interfaceType,
      simpleFunctionType
    ];

    for (DartType type in types) {
      _checkLeastUpperBound(type, type, type);
    }
  }

  void test_sharedSuperclass1() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperclass2() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type);
    ClassElementImpl classD = ElementFactory.classElement("D", classC.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeD = classD.type;
    _checkLeastUpperBound(typeB, typeD, typeA);
  }

  void test_sharedSuperclass3() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    ClassElementImpl classD = ElementFactory.classElement("D", classB.type);
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    _checkLeastUpperBound(typeC, typeD, typeB);
  }

  void test_sharedSuperclass4() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classA2 = ElementFactory.classElement2("A2");
    ClassElement classA3 = ElementFactory.classElement2("A3");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeA2 = classA2.type;
    InterfaceType typeA3 = classA3.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType>[typeA2];
    classC.interfaces = <InterfaceType>[typeA3];
    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperinterface1() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType>[typeA];
    classC.interfaces = <InterfaceType>[typeA];
    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_sharedSuperinterface2() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    ClassElementImpl classD = ElementFactory.classElement2("D");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    classB.interfaces = <InterfaceType>[typeA];
    classC.interfaces = <InterfaceType>[typeA];
    classD.interfaces = <InterfaceType>[typeC];
    _checkLeastUpperBound(typeB, typeD, typeA);
  }

  void test_sharedSuperinterface3() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    ClassElementImpl classD = ElementFactory.classElement2("D");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    classB.interfaces = <InterfaceType>[typeA];
    classC.interfaces = <InterfaceType>[typeB];
    classD.interfaces = <InterfaceType>[typeB];
    _checkLeastUpperBound(typeC, typeD, typeB);
  }

  void test_sharedSuperinterface4() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classA2 = ElementFactory.classElement2("A2");
    ClassElement classA3 = ElementFactory.classElement2("A3");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeA = classA.type;
    InterfaceType typeA2 = classA2.type;
    InterfaceType typeA3 = classA3.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType>[typeA, typeA2];
    classC.interfaces = <InterfaceType>[typeA, typeA3];
    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_twoComparables() {
    _checkLeastUpperBound(stringType, numType, objectType);
  }

  void test_typeParam_function_bounded() {
    DartType typeA = ElementFactory.classElement('A', functionType).type;
    TypeParameterElementImpl typeParamElement =
        ElementFactory.typeParameterElement('T');
    typeParamElement.bound = typeA;
    DartType typeParam = typeParamElement.type;
    _checkLeastUpperBound(typeParam, simpleFunctionType, functionType);
  }

  void test_typeParam_function_noBound() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkLeastUpperBound(typeParam, simpleFunctionType, objectType);
  }

  void test_typeParam_interface_bounded() {
    DartType typeA = ElementFactory.classElement2('A', []).type;
    DartType typeB = ElementFactory.classElement('B', typeA).type;
    DartType typeC = ElementFactory.classElement('C', typeA).type;
    TypeParameterElementImpl typeParamElement =
        ElementFactory.typeParameterElement('T');
    typeParamElement.bound = typeB;
    DartType typeParam = typeParamElement.type;
    _checkLeastUpperBound(typeParam, typeC, typeA);
  }

  void test_typeParam_interface_noBound() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(typeParam, interfaceType, objectType);
  }

  void test_typeParameters_different() {
    //
    // class List<int>
    // class List<double>
    //
    InterfaceType listOfIntType = listType.instantiate(<DartType>[intType]);
    InterfaceType listOfDoubleType =
        listType.instantiate(<DartType>[doubleType]);
    _checkLeastUpperBound(listOfIntType, listOfDoubleType, objectType);
  }

  void test_typeParameters_same() {
    //
    // List<int>
    // List<int>
    //
    InterfaceType listOfIntType = listType.instantiate(<DartType>[intType]);
    expect(
        typeSystem.getLeastUpperBound(
            typeProvider, listOfIntType, listOfIntType),
        listOfIntType);
  }

  void test_void_bottom() {
    _checkLeastUpperBound(voidType, bottomType, voidType);
  }

  void test_void_function() {
    _checkLeastUpperBound(voidType, simpleFunctionType, voidType);
  }

  void test_void_interface() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(voidType, interfaceType, voidType);
  }

  void test_void_typeParam() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkLeastUpperBound(voidType, typeParam, voidType);
  }

  void test_functionsSameType() {
    FunctionType type1 = _functionType([stringType, intType, numType],
        optional: [doubleType], named: {'n': numType}, returns: intType);
    FunctionType type2 = _functionType([stringType, intType, numType],
        optional: [doubleType], named: {'n': numType}, returns: intType);
    FunctionType expected = _functionType([stringType, intType, numType],
        optional: [doubleType], named: {'n': numType}, returns: intType);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsDifferentRequiredArity() {
    FunctionType type1 = _functionType([intType, intType]);
    FunctionType type2 = _functionType([intType, intType, intType]);
    _checkLeastUpperBound(type1, type2, functionType);
  }

  void test_functionsLubRequiredParams() {
    FunctionType type1 = _functionType([stringType, intType, intType]);
    FunctionType type2 = _functionType([intType, doubleType, numType]);
    FunctionType expected = _functionType([objectType, numType, numType]);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsLubPositionalParams() {
    FunctionType type1 = _functionType([], optional: [stringType, intType]);
    FunctionType type2 = _functionType([], optional: [intType, doubleType]);
    FunctionType expected = _functionType([], optional: [objectType, numType]);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsIgnoreExtraPositionalParams() {
    FunctionType type1 =
        _functionType([], optional: [intType, intType, stringType]);
    FunctionType type2 = _functionType([], optional: [doubleType]);
    FunctionType expected = _functionType([], optional: [numType]);
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsLubNamedParams() {
    FunctionType type1 =
        _functionType([], named: {'a': stringType, 'b': intType});
    FunctionType type2 =
        _functionType([], named: {'a': intType, 'b': doubleType});
    FunctionType expected =
        _functionType([], named: {'a': objectType, 'b': numType});
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsIgnoreExtraNamedParams() {
    FunctionType type1 = _functionType([], named: {'a': intType, 'b': intType});
    FunctionType type2 =
        _functionType([], named: {'a': doubleType, 'c': doubleType});
    FunctionType expected = _functionType([], named: {'a': numType});
    _checkLeastUpperBound(type1, type2, expected);
  }

  void test_functionsLubReturnType() {
    FunctionType type1 = _functionType([], returns: intType);
    FunctionType type2 = _functionType([], returns: doubleType);

    FunctionType expected = _functionType([], returns: numType);
    _checkLeastUpperBound(type1, type2, expected);
  }

  /**
   * Creates a function type with the given parameter and return types.
   *
   * The return type defaults to `void` if omitted.
   */
  FunctionType _functionType(List<DartType> required,
      {List<DartType> optional,
      Map<String, DartType> named,
      DartType returns}) {
    if (returns == null) {
      returns = voidType;
    }

    return ElementFactory
        .functionElement8(required, returns, optional: optional, named: named)
        .type;
  }

  void _checkLeastUpperBound(
      DartType type1, DartType type2, DartType expectedResult) {
    expect(typeSystem.getLeastUpperBound(typeProvider, type1, type2),
        expectedResult);
  }
}
