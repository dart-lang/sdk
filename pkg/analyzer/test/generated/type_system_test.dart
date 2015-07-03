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

main() {
  groupSep = ' | ';
  runReflectiveTests(TypeSystemTest);
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
    typeSystem = new TypeSystemImpl(typeProvider);
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
        typeSystem.getLeastUpperBound(dynamicType, dynamicType), dynamicType);
    expect(typeSystem.getLeastUpperBound(voidType, voidType), voidType);
    expect(typeSystem.getLeastUpperBound(bottomType, bottomType), bottomType);
    expect(typeSystem.getLeastUpperBound(typeParam, typeParam), typeParam);
    expect(typeSystem.getLeastUpperBound(interfaceType, interfaceType),
        interfaceType);
    expect(
        typeSystem.getLeastUpperBound(simpleFunctionType, simpleFunctionType),
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
    expect(typeSystem.getLeastUpperBound(listOfIntType, listOfIntType),
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
    expect(typeSystem.getLeastUpperBound(type1, type2), expectedResult);
  }
}
