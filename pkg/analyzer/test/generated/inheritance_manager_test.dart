// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_context_factory.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InheritanceManagerTest);
  });
}

@reflectiveTest
class InheritanceManagerTest with ResourceProviderMixin {
  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  /**
   * The library containing the code being resolved.
   */
  LibraryElementImpl _definingLibrary;

  /**
   * The inheritance manager being tested.
   */
  @deprecated
  InheritanceManager _inheritanceManager;

  /**
   * The number of members that Object implements (as determined by [TestTypeProvider]).
   */
  int _numOfMembersInObject = 0;

  @deprecated
  void setUp() {
    _typeProvider = new TestTypeProvider();
    _inheritanceManager = _createInheritanceManager();
    InterfaceType objectType = _typeProvider.objectType;
    _numOfMembersInObject =
        objectType.methods.length + objectType.accessors.length;
  }

  @deprecated
  void test_getMapOfMembersInheritedFromClasses_accessor_extends() {
    // class A { int get g; }
    // class B extends A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromClasses(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromClasses(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject + 1);
    expect(mapB[getterName], same(getterG));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromClasses_accessor_implements() {
    // class A { int get g; }
    // class B implements A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromClasses(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromClasses(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject);
    expect(mapB[getterName], isNull);
  }

  @deprecated
  void test_getMapOfMembersInheritedFromClasses_accessor_with() {
    // class A { int get g; }
    // class B extends Object with A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromClasses(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromClasses(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject + 1);
    expect(mapB[getterName], same(getterG));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromClasses_implicitExtends() {
    // class A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromClasses(classA);
    expect(mapA.length, _numOfMembersInObject);
  }

  @deprecated
  void test_getMapOfMembersInheritedFromClasses_method_extends() {
    // class A { int g(); }
    // class B extends A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.supertype = classA.type;
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromClasses(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromClasses(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject + 1);
    expect(mapB[methodName], same(methodM));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromClasses_method_implements() {
    // class A { int g(); }
    // class B implements A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromClasses(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromClasses(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject);
    expect(mapB[methodName], isNull);
  }

  @deprecated
  void test_getMapOfMembersInheritedFromClasses_method_with() {
    // class A { int g(); }
    // class B extends Object with A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromClasses(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromClasses(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject + 1);
    expect(mapB[methodName], same(methodM));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromClasses_method_with_two_mixins() {
    // class A1 { int m(); }
    // class A2 { int m(); }
    // class B extends Object with A1, A2 {}
    ClassElementImpl classA1 = ElementFactory.classElement2("A1");
    String methodName = "m";
    MethodElement methodA1M =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA1.methods = <MethodElement>[methodA1M];
    ClassElementImpl classA2 = ElementFactory.classElement2("A2");
    MethodElement methodA2M =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA2.methods = <MethodElement>[methodA2M];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA1.type, classA2.type];
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromClasses(classB);
    expect(mapB[methodName], same(methodA2M));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromInterfaces_accessor_extends() {
    // class A { int get g; }
    // class B extends A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromInterfaces(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject + 1);
    expect(mapB[getterName], same(getterG));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromInterfaces_accessor_implements() {
    // class A { int get g; }
    // class B implements A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromInterfaces(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject + 1);
    expect(mapB[getterName], same(getterG));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromInterfaces_accessor_with() {
    // class A { int get g; }
    // class B extends Object with A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromInterfaces(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject + 1);
    expect(mapB[getterName], same(getterG));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromInterfaces_field_indirectWith() {
    // class A { int f; }
    // class B extends A {}
    // class C extends Object with B {}
    ClassElementImpl classA = ElementFactory.classElement2('A');
    String fieldName = "f";
    FieldElement fieldF = ElementFactory.fieldElement(
        fieldName, false, false, false, _typeProvider.intType);
    classA.fields = <FieldElement>[fieldF];
    classA.accessors = <PropertyAccessorElement>[fieldF.getter, fieldF.setter];

    ClassElementImpl classB = ElementFactory.classElement('B', classA.type);

    ClassElementImpl classC = ElementFactory.classElement2('C');
    classC.mixins = <InterfaceType>[classB.type];

    Map<String, ExecutableElement> mapC =
        _inheritanceManager.getMembersInheritedFromInterfaces(classC);
    expect(mapC, hasLength(_numOfMembersInObject + 2));
    expect(mapC[fieldName], same(fieldF.getter));
    expect(mapC['$fieldName='], same(fieldF.setter));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromInterfaces_implicitExtends() {
    // class A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject);
  }

  @deprecated
  void test_getMapOfMembersInheritedFromInterfaces_method_extends() {
    // class A { int g(); }
    // class B extends A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromInterfaces(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject + 1);
    expect(mapB[methodName], same(methodM));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromInterfaces_method_implements() {
    // class A { int g(); }
    // class B implements A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromInterfaces(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject + 1);
    expect(mapB[methodName], same(methodM));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromInterfaces_method_with() {
    // class A { int g(); }
    // class B extends Object with A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    Map<String, ExecutableElement> mapB =
        _inheritanceManager.getMembersInheritedFromInterfaces(classB);
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject);
    expect(mapB.length, _numOfMembersInObject + 1);
    expect(mapB[methodName], same(methodM));
  }

  @deprecated
  void test_getMapOfMembersInheritedFromInterfaces_union_differentNames() {
    // class I1 { int m1(); }
    // class I2 { int m2(); }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName1 = "m1";
    MethodElement methodM1 =
        ElementFactory.methodElement(methodName1, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    String methodName2 = "m2";
    MethodElement methodM2 =
        ElementFactory.methodElement(methodName2, _typeProvider.intType);
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject + 2);
    expect(mapA[methodName1], same(methodM1));
    expect(mapA[methodName2], same(methodM2));
  }

  @deprecated
  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_2_getters() {
    // class I1 { int get g; }
    // class I2 { num get g; }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String accessorName = "g";
    PropertyAccessorElement getter1 = ElementFactory.getterElement(
        accessorName, false, _typeProvider.intType);
    classI1.accessors = <PropertyAccessorElement>[getter1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    PropertyAccessorElement getter2 = ElementFactory.getterElement(
        accessorName, false, _typeProvider.numType);
    classI2.accessors = <PropertyAccessorElement>[getter2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject + 1);
    PropertyAccessorElement syntheticAccessor;
    syntheticAccessor = ElementFactory.getterElement(
        accessorName, false, _typeProvider.intType);
    expect(mapA[accessorName].type, syntheticAccessor.type);
  }

  @deprecated
  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_2_methods() {
    // class I1 { dynamic m(int); }
    // class I2 { dynamic m(num); }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElementImpl methodM1 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter1 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a0"));
    parameter1.type = _typeProvider.intType;
    parameter1.parameterKind = ParameterKind.REQUIRED;
    methodM1.parameters = <ParameterElement>[parameter1];
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElementImpl methodM2 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter2 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a0"));
    parameter2.type = _typeProvider.numType;
    parameter2.parameterKind = ParameterKind.REQUIRED;
    methodM2.parameters = <ParameterElement>[parameter2];
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject + 1);
    MethodElement syntheticMethod;
    syntheticMethod = ElementFactory.methodElement(
        methodName, _typeProvider.dynamicType, [_typeProvider.numType]);
    expect(mapA[methodName].type, syntheticMethod.type);
  }

  @deprecated
  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_2_setters() {
    // class I1 { set s(int); }
    // class I2 { set s(num); }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String accessorName = "s";
    PropertyAccessorElement setter1 = ElementFactory.setterElement(
        accessorName, false, _typeProvider.intType);
    classI1.accessors = <PropertyAccessorElement>[setter1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    PropertyAccessorElement setter2 = ElementFactory.setterElement(
        accessorName, false, _typeProvider.numType);
    classI2.accessors = <PropertyAccessorElement>[setter2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject + 1);
    PropertyAccessorElementImpl syntheticAccessor;
    syntheticAccessor = ElementFactory.setterElement(
        accessorName, false, _typeProvider.numType);
    syntheticAccessor.returnType = VoidTypeImpl.instance;
    expect(mapA["$accessorName="].type, syntheticAccessor.type);
  }

  @deprecated
  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_3_getters() {
    // class A {}
    // class B extends A {}
    // class C extends B {}
    // class I1 { A get g; }
    // class I2 { B get g; }
    // class I3 { C get g; }
    // class D implements I1, I2, I3 {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String accessorName = "g";
    PropertyAccessorElement getter1 =
        ElementFactory.getterElement(accessorName, false, classA.type);
    classI1.accessors = <PropertyAccessorElement>[getter1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    PropertyAccessorElement getter2 =
        ElementFactory.getterElement(accessorName, false, classB.type);
    classI2.accessors = <PropertyAccessorElement>[getter2];
    ClassElementImpl classI3 = ElementFactory.classElement2("I3");
    PropertyAccessorElement getter3 =
        ElementFactory.getterElement(accessorName, false, classC.type);
    classI3.accessors = <PropertyAccessorElement>[getter3];
    ClassElementImpl classD = ElementFactory.classElement2("D");
    classD.interfaces = <InterfaceType>[
      classI1.type,
      classI2.type,
      classI3.type
    ];
    Map<String, ExecutableElement> mapD =
        _inheritanceManager.getMembersInheritedFromInterfaces(classD);
    expect(mapD.length, _numOfMembersInObject + 1);
    PropertyAccessorElement syntheticAccessor;
    syntheticAccessor =
        ElementFactory.getterElement(accessorName, false, classC.type);
    expect(mapD[accessorName].type, syntheticAccessor.type);
  }

  @deprecated
  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_3_methods() {
    // class A {}
    // class B extends A {}
    // class C extends B {}
    // class I1 { dynamic m(A a); }
    // class I2 { dynamic m(B b); }
    // class I3 { dynamic m(C c); }
    // class D implements I1, I2, I3 {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElementImpl methodM1 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter1 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a0"));
    parameter1.type = classA.type;
    parameter1.parameterKind = ParameterKind.REQUIRED;
    methodM1.parameters = <ParameterElement>[parameter1];
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElementImpl methodM2 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter2 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a0"));
    parameter2.type = classB.type;
    parameter2.parameterKind = ParameterKind.REQUIRED;
    methodM2.parameters = <ParameterElement>[parameter2];
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classI3 = ElementFactory.classElement2("I3");
    MethodElementImpl methodM3 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter3 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a0"));
    parameter3.type = classC.type;
    parameter3.parameterKind = ParameterKind.REQUIRED;
    methodM3.parameters = <ParameterElement>[parameter3];
    classI3.methods = <MethodElement>[methodM3];
    ClassElementImpl classD = ElementFactory.classElement2("D");
    classD.interfaces = <InterfaceType>[
      classI1.type,
      classI2.type,
      classI3.type
    ];
    Map<String, ExecutableElement> mapD =
        _inheritanceManager.getMembersInheritedFromInterfaces(classD);
    expect(mapD.length, _numOfMembersInObject + 1);
    MethodElement syntheticMethod;
    syntheticMethod = ElementFactory.methodElement(
        methodName, _typeProvider.dynamicType, [classA.type]);
    expect(mapD[methodName].type, syntheticMethod.type);
  }

  @deprecated
  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_3_setters() {
    // class A {}
    // class B extends A {}
    // class C extends B {}
    // class I1 { set s(A); }
    // class I2 { set s(B); }
    // class I3 { set s(C); }
    // class D implements I1, I2, I3 {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String accessorName = "s";
    PropertyAccessorElement setter1 =
        ElementFactory.setterElement(accessorName, false, classA.type);
    classI1.accessors = <PropertyAccessorElement>[setter1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    PropertyAccessorElement setter2 =
        ElementFactory.setterElement(accessorName, false, classB.type);
    classI2.accessors = <PropertyAccessorElement>[setter2];
    ClassElementImpl classI3 = ElementFactory.classElement2("I3");
    PropertyAccessorElement setter3 =
        ElementFactory.setterElement(accessorName, false, classC.type);
    classI3.accessors = <PropertyAccessorElement>[setter3];
    ClassElementImpl classD = ElementFactory.classElement2("D");
    classD.interfaces = <InterfaceType>[
      classI1.type,
      classI2.type,
      classI3.type
    ];
    Map<String, ExecutableElement> mapD =
        _inheritanceManager.getMembersInheritedFromInterfaces(classD);
    expect(mapD.length, _numOfMembersInObject + 1);
    PropertyAccessorElementImpl syntheticAccessor;
    syntheticAccessor =
        ElementFactory.setterElement(accessorName, false, classA.type);
    syntheticAccessor.returnType = VoidTypeImpl.instance;
    expect(mapD["$accessorName="].type, syntheticAccessor.type);
  }

  @deprecated
  void
      test_getMapOfMembersInheritedFromInterfaces_union_oneSubtype_2_methods() {
    // class I1 { int m(); }
    // class I2 { int m([int]); }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElement methodM1 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElementImpl methodM2 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    ParameterElementImpl parameter1 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a1"));
    parameter1.type = _typeProvider.intType;
    parameter1.parameterKind = ParameterKind.POSITIONAL;
    methodM2.parameters = <ParameterElement>[parameter1];
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject + 1);
    expect(mapA[methodName], same(methodM2));
  }

  @deprecated
  void
      test_getMapOfMembersInheritedFromInterfaces_union_oneSubtype_3_methods() {
    // class I1 { int m(); }
    // class I2 { int m([int]); }
    // class I3 { int m([int, int]); }
    // class A implements I1, I2, I3 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElementImpl methodM1 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElementImpl methodM2 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    ParameterElementImpl parameter1 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a1"));
    parameter1.type = _typeProvider.intType;
    parameter1.parameterKind = ParameterKind.POSITIONAL;
    methodM1.parameters = <ParameterElement>[parameter1];
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classI3 = ElementFactory.classElement2("I3");
    MethodElementImpl methodM3 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    ParameterElementImpl parameter2 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a2"));
    parameter2.type = _typeProvider.intType;
    parameter2.parameterKind = ParameterKind.POSITIONAL;
    ParameterElementImpl parameter3 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a3"));
    parameter3.type = _typeProvider.intType;
    parameter3.parameterKind = ParameterKind.POSITIONAL;
    methodM3.parameters = <ParameterElement>[parameter2, parameter3];
    classI3.methods = <MethodElement>[methodM3];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[
      classI1.type,
      classI2.type,
      classI3.type
    ];
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject + 1);
    expect(mapA[methodName], same(methodM3));
  }

  @deprecated
  void
      test_getMapOfMembersInheritedFromInterfaces_union_oneSubtype_4_methods() {
    // class I1 { int m(); }
    // class I2 { int m(); }
    // class I3 { int m([int]); }
    // class I4 { int m([int, int]); }
    // class A implements I1, I2, I3, I4 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElement methodM1 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElement methodM2 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classI3 = ElementFactory.classElement2("I3");
    MethodElementImpl methodM3 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    ParameterElementImpl parameter1 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a1"));
    parameter1.type = _typeProvider.intType;
    parameter1.parameterKind = ParameterKind.POSITIONAL;
    methodM3.parameters = <ParameterElement>[parameter1];
    classI3.methods = <MethodElement>[methodM3];
    ClassElementImpl classI4 = ElementFactory.classElement2("I4");
    MethodElementImpl methodM4 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    ParameterElementImpl parameter2 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a2"));
    parameter2.type = _typeProvider.intType;
    parameter2.parameterKind = ParameterKind.POSITIONAL;
    ParameterElementImpl parameter3 =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("a3"));
    parameter3.type = _typeProvider.intType;
    parameter3.parameterKind = ParameterKind.POSITIONAL;
    methodM4.parameters = <ParameterElement>[parameter2, parameter3];
    classI4.methods = <MethodElement>[methodM4];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[
      classI1.type,
      classI2.type,
      classI3.type,
      classI4.type
    ];
    Map<String, ExecutableElement> mapA =
        _inheritanceManager.getMembersInheritedFromInterfaces(classA);
    expect(mapA.length, _numOfMembersInObject + 1);
    expect(mapA[methodName], same(methodM4));
  }

  @deprecated
  void test_getMembersInheritedFromClasses_field_indirectWith() {
    // class A { int f; }
    // class B extends A {}
    // class C extends Object with B {}
    ClassElementImpl classA = ElementFactory.classElement2('A');
    String fieldName = "f";
    FieldElement fieldF = ElementFactory.fieldElement(
        fieldName, false, false, false, _typeProvider.intType);
    classA.fields = <FieldElement>[fieldF];
    classA.accessors = <PropertyAccessorElement>[fieldF.getter, fieldF.setter];

    ClassElementImpl classB = ElementFactory.classElement('B', classA.type);

    ClassElementImpl classC = ElementFactory.classElement2('C');
    classC.mixins = <InterfaceType>[classB.type];

    Map<String, ExecutableElement> mapC =
        _inheritanceManager.getMembersInheritedFromClasses(classC);
    expect(mapC, hasLength(_numOfMembersInObject));
  }

  @deprecated
  void test_lookupInheritance_interface_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classB, getterName),
        same(getterG));
  }

  @deprecated
  void test_lookupInheritance_interface_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classB, methodName),
        same(methodM));
  }

  @deprecated
  void test_lookupInheritance_interface_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setterS];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classB, "$setterName="),
        same(setterS));
  }

  @deprecated
  void test_lookupInheritance_interface_staticMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    (methodM as MethodElementImpl).isStatic = true;
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classB, methodName), isNull);
  }

  @deprecated
  void test_lookupInheritance_interfaces_infiniteLoop() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classA, "name"), isNull);
  }

  @deprecated
  void test_lookupInheritance_interfaces_infiniteLoop2() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classA.interfaces = <InterfaceType>[classB.type];
    classB.interfaces = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classA, "name"), isNull);
  }

  @deprecated
  void test_lookupInheritance_interfaces_union2() {
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName1 = "m1";
    MethodElement methodM1 =
        ElementFactory.methodElement(methodName1, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    String methodName2 = "m2";
    MethodElement methodM2 =
        ElementFactory.methodElement(methodName2, _typeProvider.intType);
    classI2.methods = <MethodElement>[methodM2];
    classI2.interfaces = <InterfaceType>[classI1.type];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI2.type];
    expect(_inheritanceManager.lookupInheritance(classA, methodName1),
        same(methodM1));
    expect(_inheritanceManager.lookupInheritance(classA, methodName2),
        same(methodM2));
  }

  @deprecated
  void test_lookupInheritance_mixin_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classB, getterName),
        same(getterG));
  }

  @deprecated
  void test_lookupInheritance_mixin_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classB, methodName),
        same(methodM));
  }

  @deprecated
  void test_lookupInheritance_mixin_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setterS];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classB, "$setterName="),
        same(setterS));
  }

  @deprecated
  void test_lookupInheritance_mixin_staticMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    (methodM as MethodElementImpl).isStatic = true;
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classB, methodName), isNull);
  }

  @deprecated
  void test_lookupInheritance_noMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    expect(_inheritanceManager.lookupInheritance(classA, "a"), isNull);
  }

  @deprecated
  void test_lookupInheritance_superclass_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    expect(_inheritanceManager.lookupInheritance(classB, getterName),
        same(getterG));
  }

  @deprecated
  void test_lookupInheritance_superclass_infiniteLoop() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.supertype = classA.type;
    expect(_inheritanceManager.lookupInheritance(classA, "name"), isNull);
  }

  @deprecated
  void test_lookupInheritance_superclass_infiniteLoop2() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classA.supertype = classB.type;
    classB.supertype = classA.type;
    expect(_inheritanceManager.lookupInheritance(classA, "name"), isNull);
  }

  @deprecated
  void test_lookupInheritance_superclass_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    expect(_inheritanceManager.lookupInheritance(classB, methodName),
        same(methodM));
  }

  @deprecated
  void test_lookupInheritance_superclass_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setterS];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    expect(_inheritanceManager.lookupInheritance(classB, "$setterName="),
        same(setterS));
  }

  @deprecated
  void test_lookupInheritance_superclass_staticMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    (methodM as MethodElementImpl).isStatic = true;
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    expect(_inheritanceManager.lookupInheritance(classB, methodName), isNull);
  }

  @deprecated
  void test_lookupMember_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    expect(_inheritanceManager.lookupMember(classA, getterName), same(getterG));
  }

  @deprecated
  void test_lookupMember_getter_static() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, true, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    expect(_inheritanceManager.lookupMember(classA, getterName), isNull);
  }

  @deprecated
  void test_lookupMember_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    expect(_inheritanceManager.lookupMember(classA, methodName), same(methodM));
  }

  @deprecated
  void test_lookupMember_method_static() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    (methodM as MethodElementImpl).isStatic = true;
    classA.methods = <MethodElement>[methodM];
    expect(_inheritanceManager.lookupMember(classA, methodName), isNull);
  }

  @deprecated
  void test_lookupMember_noMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    expect(_inheritanceManager.lookupMember(classA, "a"), isNull);
  }

  @deprecated
  void test_lookupMember_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setterS];
    expect(_inheritanceManager.lookupMember(classA, "$setterName="),
        same(setterS));
  }

  @deprecated
  void test_lookupMember_setter_static() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, true, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setterS];
    expect(_inheritanceManager.lookupMember(classA, setterName), isNull);
  }

  @deprecated
  void test_lookupOverrides_noParentClasses() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    expect(
        _inheritanceManager.lookupOverrides(classA, methodName), hasLength(0));
  }

  @deprecated
  void test_lookupOverrides_overrideBaseClass() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl methodMinA =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodMinA];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    MethodElementImpl methodMinB =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classB.methods = <MethodElement>[methodMinB];
    List<ExecutableElement> overrides =
        _inheritanceManager.lookupOverrides(classB, methodName);
    expect(overrides, unorderedEquals([methodMinA]));
  }

  @deprecated
  void test_lookupOverrides_overrideInterface() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl methodMinA =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodMinA];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    MethodElementImpl methodMinB =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classB.methods = <MethodElement>[methodMinB];
    List<ExecutableElement> overrides =
        _inheritanceManager.lookupOverrides(classB, methodName);
    expect(overrides, unorderedEquals([methodMinA]));
  }

  @deprecated
  void test_lookupOverrides_overrideTwoInterfaces() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl methodMinA =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodMinA];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    MethodElementImpl methodMinB =
        ElementFactory.methodElement(methodName, _typeProvider.doubleType);
    classB.methods = <MethodElement>[methodMinB];
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classC.interfaces = <InterfaceType>[classA.type, classB.type];
    MethodElementImpl methodMinC =
        ElementFactory.methodElement(methodName, _typeProvider.numType);
    classC.methods = <MethodElement>[methodMinC];
    List<ExecutableElement> overrides =
        _inheritanceManager.lookupOverrides(classC, methodName);
    expect(overrides, unorderedEquals([methodMinA, methodMinB]));
  }

  /**
   * Create the inheritance manager used by the tests.
   *
   * @return the inheritance manager that was created
   */
  @deprecated
  InheritanceManager _createInheritanceManager() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore(
        resourceProvider: resourceProvider);
    Source source = new FileSource(getFile("/test.dart"));
    CompilationUnitElementImpl definingCompilationUnit =
        new CompilationUnitElementImpl();
    definingCompilationUnit.librarySource =
        definingCompilationUnit.source = source;
    _definingLibrary = ElementFactory.library(context, "test");
    _definingLibrary.definingCompilationUnit = definingCompilationUnit;
    return new InheritanceManager(_definingLibrary);
  }
}
