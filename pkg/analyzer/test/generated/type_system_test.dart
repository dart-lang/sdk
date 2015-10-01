// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests related to the [TypeSystem] class.

library engine.type_system_test;

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(TypeSystemTest);
  runReflectiveTests(StrongSubtypingTest);
  runReflectiveTests(StrongAssignabilityTest);
}

@reflectiveTest
class TypeSystemTest {
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

  void test_getLeastUpperBound_bottom_function() {
    _checkLeastUpperBound(bottomType, simpleFunctionType, simpleFunctionType);
  }

  void test_getLeastUpperBound_bottom_interface() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(bottomType, interfaceType, interfaceType);
  }

  void test_getLeastUpperBound_bottom_typeParam() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkLeastUpperBound(bottomType, typeParam, typeParam);
  }

  void test_getLeastUpperBound_directInterfaceCase() {
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

  void test_getLeastUpperBound_directSubclassCase() {
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

  void test_getLeastUpperBound_dynamic_bottom() {
    _checkLeastUpperBound(dynamicType, bottomType, dynamicType);
  }

  void test_getLeastUpperBound_dynamic_function() {
    _checkLeastUpperBound(dynamicType, simpleFunctionType, dynamicType);
  }

  void test_getLeastUpperBound_dynamic_interface() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(dynamicType, interfaceType, dynamicType);
  }

  void test_getLeastUpperBound_dynamic_typeParam() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkLeastUpperBound(dynamicType, typeParam, dynamicType);
  }

  void test_getLeastUpperBound_dynamic_void() {
    _checkLeastUpperBound(dynamicType, voidType, dynamicType);
  }

  void test_getLeastUpperBound_interface_function() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(interfaceType, simpleFunctionType, objectType);
  }

  void test_getLeastUpperBound_mixinCase() {
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

  void test_getLeastUpperBound_object() {
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

  void test_getLeastUpperBound_self() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    expect(
        typeSystem.getLeastUpperBound(typeProvider, dynamicType, dynamicType),
        dynamicType);
    expect(typeSystem.getLeastUpperBound(typeProvider, voidType, voidType),
        voidType);
    expect(typeSystem.getLeastUpperBound(typeProvider, bottomType, bottomType),
        bottomType);
    expect(typeSystem.getLeastUpperBound(typeProvider, typeParam, typeParam),
        typeParam);
    expect(
        typeSystem.getLeastUpperBound(
            typeProvider, interfaceType, interfaceType),
        interfaceType);
    expect(
        typeSystem.getLeastUpperBound(
            typeProvider, simpleFunctionType, simpleFunctionType),
        simpleFunctionType);
  }

  void test_getLeastUpperBound_sharedSuperclass1() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    _checkLeastUpperBound(typeB, typeC, typeA);
  }

  void test_getLeastUpperBound_sharedSuperclass2() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type);
    ClassElementImpl classD = ElementFactory.classElement("D", classC.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeD = classD.type;
    _checkLeastUpperBound(typeB, typeD, typeA);
  }

  void test_getLeastUpperBound_sharedSuperclass3() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    ClassElementImpl classD = ElementFactory.classElement("D", classB.type);
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    _checkLeastUpperBound(typeC, typeD, typeB);
  }

  void test_getLeastUpperBound_sharedSuperclass4() {
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

  void test_getLeastUpperBound_sharedSuperinterface1() {
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

  void test_getLeastUpperBound_sharedSuperinterface2() {
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

  void test_getLeastUpperBound_sharedSuperinterface3() {
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

  void test_getLeastUpperBound_sharedSuperinterface4() {
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

  void test_getLeastUpperBound_twoComparables() {
    _checkLeastUpperBound(stringType, numType, objectType);
  }

  void test_getLeastUpperBound_typeParam_function_bounded() {
    DartType typeA = ElementFactory.classElement('A', functionType).type;
    TypeParameterElementImpl typeParamElement =
        ElementFactory.typeParameterElement('T');
    typeParamElement.bound = typeA;
    DartType typeParam = typeParamElement.type;
    _checkLeastUpperBound(typeParam, simpleFunctionType, functionType);
  }

  void test_getLeastUpperBound_typeParam_function_noBound() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkLeastUpperBound(typeParam, simpleFunctionType, objectType);
  }

  void test_getLeastUpperBound_typeParam_interface_bounded() {
    DartType typeA = ElementFactory.classElement2('A', []).type;
    DartType typeB = ElementFactory.classElement('B', typeA).type;
    DartType typeC = ElementFactory.classElement('C', typeA).type;
    TypeParameterElementImpl typeParamElement =
        ElementFactory.typeParameterElement('T');
    typeParamElement.bound = typeB;
    DartType typeParam = typeParamElement.type;
    _checkLeastUpperBound(typeParam, typeC, typeA);
  }

  void test_getLeastUpperBound_typeParam_interface_noBound() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(typeParam, interfaceType, objectType);
  }

  void test_getLeastUpperBound_typeParameters_different() {
    //
    // class List<int>
    // class List<double>
    //
    InterfaceType listOfIntType = listType.substitute4(<DartType>[intType]);
    InterfaceType listOfDoubleType =
        listType.substitute4(<DartType>[doubleType]);
    _checkLeastUpperBound(listOfIntType, listOfDoubleType, objectType);
  }

  void test_getLeastUpperBound_typeParameters_same() {
    //
    // List<int>
    // List<int>
    //
    InterfaceType listOfIntType = listType.substitute4(<DartType>[intType]);
    expect(
        typeSystem.getLeastUpperBound(
            typeProvider, listOfIntType, listOfIntType),
        listOfIntType);
  }

  void test_getLeastUpperBound_void_bottom() {
    _checkLeastUpperBound(voidType, bottomType, voidType);
  }

  void test_getLeastUpperBound_void_function() {
    _checkLeastUpperBound(voidType, simpleFunctionType, voidType);
  }

  void test_getLeastUpperBound_void_interface() {
    DartType interfaceType = ElementFactory.classElement2('A', []).type;
    _checkLeastUpperBound(voidType, interfaceType, voidType);
  }

  void test_getLeastUpperBound_void_typeParam() {
    DartType typeParam = ElementFactory.typeParameterElement('T').type;
    _checkLeastUpperBound(voidType, typeParam, voidType);
  }

  void _checkLeastUpperBound(
      DartType type1, DartType type2, DartType expectedResult) {
    expect(typeSystem.getLeastUpperBound(typeProvider, type1, type2),
        expectedResult);
  }
}

class TypeBuilder {
  static FunctionType functionType(
      List<DartType> parameters, DartType returnType,
      {List<DartType> optional, Map<String, DartType> named}) {
    return ElementFactory
        .functionElement8(parameters, returnType,
            optional: optional, named: named)
        .type;
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

  void test_isSubtypeOf_dynamic_isTop() {
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

  void test_isSubtypeOf_bottom_isBottom() {
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

  void test_isSubtypeOf_int() {
    List<DartType> equivalents = <DartType>[intType];
    List<DartType> supertypes = <DartType>[numType];
    List<DartType> unrelated = <DartType>[doubleType];
    _checkGroups(intType,
        equivalents: equivalents, supertypes: supertypes, unrelated: unrelated);
  }

  void test_isSubtypeOf_double() {
    List<DartType> equivalents = <DartType>[doubleType];
    List<DartType> supertypes = <DartType>[numType];
    List<DartType> unrelated = <DartType>[intType];
    _checkGroups(doubleType,
        equivalents: equivalents, supertypes: supertypes, unrelated: unrelated);
  }

  void test_isSubtypeOf_num() {
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

  void test_isSubtypeOf_classes() {
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

  void test_isSubtypeOf_simple_function() {
    FunctionType top =
        TypeBuilder.functionType(<DartType>[intType], objectType);
    FunctionType left = TypeBuilder.functionType(<DartType>[intType], intType);
    FunctionType right =
        TypeBuilder.functionType(<DartType>[objectType], objectType);
    FunctionType bottom =
        TypeBuilder.functionType(<DartType>[objectType], intType);

    _checkLattice(top, left, right, bottom);
  }

  void test_isSubtypeOf_call_method() {
    ClassElementImpl classBottom = ElementFactory.classElement2("Bottom");
    MethodElement methodBottom =
        ElementFactory.methodElement("call", objectType, <DartType>[intType]);
    classBottom.methods = <MethodElement>[methodBottom];

    DartType top = TypeBuilder.functionType(<DartType>[intType], objectType);
    InterfaceType bottom = classBottom.type;

    _checkIsStrictSubtypeOf(bottom, top);
  }

  void test_isSubtypeOf_fuzzy_arrows() {
    FunctionType top =
        TypeBuilder.functionType(<DartType>[dynamicType], objectType);
    FunctionType left =
        TypeBuilder.functionType(<DartType>[objectType], objectType);
    FunctionType right =
        TypeBuilder.functionType(<DartType>[dynamicType], bottomType);
    FunctionType bottom =
        TypeBuilder.functionType(<DartType>[objectType], bottomType);

    _checkLattice(top, left, right, bottom);
  }

  void test_isSubtypeOf_void_functions() {
    FunctionType top = TypeBuilder.functionType(<DartType>[intType], voidType);
    FunctionType bottom =
        TypeBuilder.functionType(<DartType>[objectType], intType);

    _checkIsStrictSubtypeOf(bottom, top);
  }

  void test_isSubtypeOf_named_optional() {
    DartType r = TypeBuilder.functionType(<DartType>[intType], intType);
    DartType o = TypeBuilder.functionType(<DartType>[], intType,
        optional: <DartType>[intType]);
    DartType n = TypeBuilder.functionType(<DartType>[], intType,
        named: <String, DartType>{'x': intType});
    DartType rr =
        TypeBuilder.functionType(<DartType>[intType, intType], intType);
    DartType ro = TypeBuilder.functionType(<DartType>[intType], intType,
        optional: <DartType>[intType]);
    DartType rn = TypeBuilder.functionType(<DartType>[intType], intType,
        named: <String, DartType>{'x': intType});
    DartType oo = TypeBuilder.functionType(<DartType>[], intType,
        optional: <DartType>[intType, intType]);
    DartType nn = TypeBuilder.functionType(<DartType>[], intType,
        named: <String, DartType>{'x': intType, 'y': intType});
    DartType nnn = TypeBuilder.functionType(<DartType>[], intType,
        named: <String, DartType>{'x': intType, 'y': intType, 'z': intType});

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

  void test_isSubtypeOf_generics() {
    ClassElementImpl LClass = ElementFactory.classElement2('L', ["T"]);
    InterfaceType LType = LClass.type;
    ClassElementImpl MClass = ElementFactory.classElement2('M', ["T"]);
    DartType typeParam = MClass.typeParameters[0].type;
    InterfaceType superType = LType.substitute4(<DartType>[typeParam]);
    MClass.interfaces = <InterfaceType>[superType];
    InterfaceType MType = MClass.type;

    InterfaceType top = LType.substitute4(<DartType>[dynamicType]);
    InterfaceType left = MType.substitute4(<DartType>[dynamicType]);
    InterfaceType right = LType.substitute4(<DartType>[intType]);
    InterfaceType bottom = MType.substitute4(<DartType>[intType]);

    _checkLattice(top, left, right, bottom);
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

  void _checkUnrelated(DartType type1, DartType type2) {
    _checkIsNotSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  void _checkEquivalent(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsSubtypeOf(type2, type1);
  }

  void _checkIsStrictSubtypeOf(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  void _checkIsSubtypeOf(DartType type1, DartType type2) {
    expect(typeSystem.isSubtypeOf(type1, type2), true);
  }

  void _checkIsNotSubtypeOf(DartType type1, DartType type2) {
    expect(typeSystem.isSubtypeOf(type1, type2), false);
  }
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

  void test_isAssignableTo_simple_function() {
    FunctionType top =
        TypeBuilder.functionType(<DartType>[intType], objectType);
    FunctionType left = TypeBuilder.functionType(<DartType>[intType], intType);
    FunctionType right =
        TypeBuilder.functionType(<DartType>[objectType], objectType);
    FunctionType bottom =
        TypeBuilder.functionType(<DartType>[objectType], intType);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_call_method() {
    ClassElementImpl classBottom = ElementFactory.classElement2("B");
    MethodElement methodBottom =
        ElementFactory.methodElement("call", objectType, <DartType>[intType]);
    classBottom.methods = <MethodElement>[methodBottom];

    DartType top = TypeBuilder.functionType(<DartType>[intType], objectType);
    InterfaceType bottom = classBottom.type;

    _checkIsStrictAssignableTo(bottom, top);
  }

  void test_isAssignableTo_fuzzy_arrows() {
    FunctionType top =
        TypeBuilder.functionType(<DartType>[dynamicType], objectType);
    FunctionType left =
        TypeBuilder.functionType(<DartType>[objectType], objectType);
    FunctionType right =
        TypeBuilder.functionType(<DartType>[dynamicType], bottomType);
    FunctionType bottom =
        TypeBuilder.functionType(<DartType>[objectType], bottomType);

    _checkCrossLattice(top, left, right, bottom);
  }

  void test_isAssignableTo_void_functions() {
    FunctionType top = TypeBuilder.functionType(<DartType>[intType], voidType);
    FunctionType bottom =
        TypeBuilder.functionType(<DartType>[objectType], intType);

    _checkEquivalent(bottom, top);
  }

  void test_isAssignableTo_named_optional() {
    DartType r = TypeBuilder.functionType(<DartType>[intType], intType);
    DartType o = TypeBuilder.functionType(<DartType>[], intType,
        optional: <DartType>[intType]);
    DartType n = TypeBuilder.functionType(<DartType>[], intType,
        named: <String, DartType>{'x': intType});
    DartType rr =
        TypeBuilder.functionType(<DartType>[intType, intType], intType);
    DartType ro = TypeBuilder.functionType(<DartType>[intType], intType,
        optional: <DartType>[intType]);
    DartType rn = TypeBuilder.functionType(<DartType>[intType], intType,
        named: <String, DartType>{'x': intType});
    DartType oo = TypeBuilder.functionType(<DartType>[], intType,
        optional: <DartType>[intType, intType]);
    DartType nn = TypeBuilder.functionType(<DartType>[], intType,
        named: <String, DartType>{'x': intType, 'y': intType});
    DartType nnn = TypeBuilder.functionType(<DartType>[], intType,
        named: <String, DartType>{'x': intType, 'y': intType, 'z': intType});

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

  void test_isAssignableTo_generics() {
    ClassElementImpl LClass = ElementFactory.classElement2('L', ["T"]);
    InterfaceType LType = LClass.type;
    ClassElementImpl MClass = ElementFactory.classElement2('M', ["T"]);
    DartType typeParam = MClass.typeParameters[0].type;
    InterfaceType superType = LType.substitute4(<DartType>[typeParam]);
    MClass.interfaces = <InterfaceType>[superType];
    InterfaceType MType = MClass.type;

    InterfaceType top = LType.substitute4(<DartType>[dynamicType]);
    InterfaceType left = MType.substitute4(<DartType>[dynamicType]);
    InterfaceType right = LType.substitute4(<DartType>[intType]);
    InterfaceType bottom = MType.substitute4(<DartType>[intType]);

    _checkCrossLattice(top, left, right, bottom);
  }

  void _checkCrossLattice(
      DartType top, DartType left, DartType right, DartType bottom) {
    _checkGroups(top, interassignable: <DartType>[top, left, right, bottom]);
    _checkGroups(left, interassignable: <DartType>[top, left, right, bottom]);
    _checkGroups(right, interassignable: <DartType>[top, left, right, bottom]);
    _checkGroups(bottom, interassignable: <DartType>[top, left, right, bottom]);
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

  void _checkUnrelated(DartType type1, DartType type2) {
    _checkIsNotAssignableTo(type1, type2);
    _checkIsNotAssignableTo(type2, type1);
  }

  void _checkEquivalent(DartType type1, DartType type2) {
    _checkIsAssignableTo(type1, type2);
    _checkIsAssignableTo(type2, type1);
  }

  void _checkIsStrictAssignableTo(DartType type1, DartType type2) {
    _checkIsAssignableTo(type1, type2);
    _checkIsNotAssignableTo(type2, type1);
  }

  void _checkIsAssignableTo(DartType type1, DartType type2) {
    expect(typeSystem.isAssignableTo(type1, type2), true);
  }

  void _checkIsNotAssignableTo(DartType type1, DartType type2) {
    expect(typeSystem.isAssignableTo(type1, type2), false);
  }
}
