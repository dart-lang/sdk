// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.element_test;

import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext, AnalysisContextImpl;
import 'package:unittest/unittest.dart';
import 'test_support.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'resolver_test.dart' show TestTypeProvider, AnalysisContextHelper;

import '../reflective_tests.dart';


class AngularPropertyKindTest extends EngineTestCase {
  void test_ATTR() {
    AngularPropertyKind kind = AngularPropertyKind.ATTR;
    expect(kind.callsGetter(), isFalse);
    expect(kind.callsSetter(), isTrue);
  }

  void test_CALLBACK() {
    AngularPropertyKind kind = AngularPropertyKind.CALLBACK;
    expect(kind.callsGetter(), isFalse);
    expect(kind.callsSetter(), isTrue);
  }

  void test_ONE_WAY() {
    AngularPropertyKind kind = AngularPropertyKind.ONE_WAY;
    expect(kind.callsGetter(), isFalse);
    expect(kind.callsSetter(), isTrue);
  }

  void test_ONE_WAY_ONE_TIME() {
    AngularPropertyKind kind = AngularPropertyKind.ONE_WAY_ONE_TIME;
    expect(kind.callsGetter(), isFalse);
    expect(kind.callsSetter(), isTrue);
  }

  void test_TWO_WAY() {
    AngularPropertyKind kind = AngularPropertyKind.TWO_WAY;
    expect(kind.callsGetter(), isTrue);
    expect(kind.callsSetter(), isTrue);
  }
}

class ClassElementImplTest extends EngineTestCase {
  void test_getAllSupertypes_interface() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = elementC.type;
    elementC.interfaces = <InterfaceType> [typeB];
    List<InterfaceType> supers = elementC.allSupertypes;
    List<InterfaceType> types = new List<InterfaceType>();
    types.addAll(supers);
    expect(types.contains(typeA), isTrue);
    expect(types.contains(typeB), isTrue);
    expect(types.contains(typeObject), isTrue);
    expect(types.contains(typeC), isFalse);
  }

  void test_getAllSupertypes_mixins() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classC.mixins = <InterfaceType> [typeB];
    List<InterfaceType> supers = classC.allSupertypes;
    List<InterfaceType> types = new List<InterfaceType>();
    types.addAll(supers);
    expect(types.contains(typeA), isFalse);
    expect(types.contains(typeB), isTrue);
    expect(types.contains(typeObject), isTrue);
    expect(types.contains(typeC), isFalse);
  }

  void test_getAllSupertypes_recursive() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    List<InterfaceType> supers = classB.allSupertypes;
    expect(supers, hasLength(1));
  }

  void test_getField() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String fieldName = "f";
    FieldElementImpl field = ElementFactory.fieldElement(fieldName, false, false, false, null);
    classA.fields = <FieldElement> [field];
    expect(classA.getField(fieldName), same(field));
    // no such field
    expect(classA.getField("noSuchField"), same(null));
  }

  void test_getMethod_declared() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    expect(classA.getMethod(methodName), same(method));
  }

  void test_getMethod_undeclared() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    expect(classA.getMethod("${methodName}x"), isNull);
  }

  void test_getNode() {
    AnalysisContextHelper contextHelper = new AnalysisContextHelper();
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
class A {}
class B {}''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    // A
    {
      ClassElement elementA = unitElement.getType("A");
      ClassDeclaration nodeA = elementA.node;
      expect(nodeA, isNotNull);
      expect(nodeA.name.name, "A");
      expect(nodeA.element, same(elementA));
    }
    // B
    {
      ClassElement elementB = unitElement.getType("B");
      ClassDeclaration nodeB = elementB.node;
      expect(nodeB, isNotNull);
      expect(nodeB.name.name, "B");
      expect(nodeB.element, same(elementB));
    }
  }

  void test_hasNonFinalField_false_const() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.fields = <FieldElement> [ElementFactory.fieldElement("f", false, false, true, classA.type)];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_final() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.fields = <FieldElement> [ElementFactory.fieldElement("f", false, true, false, classA.type)];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_recursive() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_true_immediate() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.fields = <FieldElement> [ElementFactory.fieldElement("f", false, false, false, classA.type)];
    expect(classA.hasNonFinalField, isTrue);
  }

  void test_hasNonFinalField_true_inherited() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.fields = <FieldElement> [ElementFactory.fieldElement("f", false, false, false, classA.type)];
    expect(classB.hasNonFinalField, isTrue);
  }

  void test_hasStaticMember_false_empty() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    // no members
    expect(classA.hasStaticMember, isFalse);
  }

  void test_hasStaticMember_false_instanceMethod() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    MethodElement method = ElementFactory.methodElement("foo", null, []);
    classA.methods = <MethodElement> [method];
    expect(classA.hasStaticMember, isFalse);
  }

  void test_hasStaticMember_instanceGetter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    PropertyAccessorElement getter = ElementFactory.getterElement("foo", false, null);
    classA.accessors = <PropertyAccessorElement> [getter];
    expect(classA.hasStaticMember, isFalse);
  }

  void test_hasStaticMember_true_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    PropertyAccessorElementImpl getter = ElementFactory.getterElement("foo", false, null);
    classA.accessors = <PropertyAccessorElement> [getter];
    // "foo" is static
    getter.static = true;
    expect(classA.hasStaticMember, isTrue);
  }

  void test_hasStaticMember_true_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    MethodElementImpl method = ElementFactory.methodElement("foo", null, []);
    classA.methods = <MethodElement> [method];
    // "foo" is static
    method.static = true;
    expect(classA.hasStaticMember, isTrue);
  }

  void test_hasStaticMember_true_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    PropertyAccessorElementImpl setter = ElementFactory.setterElement("foo", false, null);
    classA.accessors = <PropertyAccessorElement> [setter];
    // "foo" is static
    setter.static = true;
    expect(classA.hasStaticMember, isTrue);
  }

  void test_lookUpConcreteMethod_declared() {
    // class A {
    //   m() {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpConcreteMethod(methodName, library), same(method));
  }

  void test_lookUpConcreteMethod_declaredAbstract() {
    // class A {
    //   m();
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElementImpl method = ElementFactory.methodElement(methodName, null, []);
    method.abstract = true;
    classA.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpConcreteMethod(methodName, library), isNull);
  }

  void test_lookUpConcreteMethod_declaredAbstractAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m();
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement inheritedMethod = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    MethodElementImpl method = ElementFactory.methodElement(methodName, null, []);
    method.abstract = true;
    classB.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library), same(inheritedMethod));
  }

  void test_lookUpConcreteMethod_declaredAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement inheritedMethod = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classB.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library), same(method));
  }

  void test_lookUpConcreteMethod_declaredAndInheritedAbstract() {
    // abstract class A {
    //   m();
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.abstract = true;
    String methodName = "m";
    MethodElementImpl inheritedMethod = ElementFactory.methodElement(methodName, null, []);
    inheritedMethod.abstract = true;
    classA.methods = <MethodElement> [inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classB.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library), same(method));
  }

  void test_lookUpConcreteMethod_inherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement inheritedMethod = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library), same(inheritedMethod));
  }

  void test_lookUpConcreteMethod_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpConcreteMethod("m", library), isNull);
  }

  void test_lookUpGetter_declared() {
    // class A {
    //   get g {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getter = ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement> [getter];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpGetter(getterName, library), same(getter));
  }

  void test_lookUpGetter_inherited() {
    // class A {
    //   get g {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getter = ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement> [getter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpGetter(getterName, library), same(getter));
  }

  void test_lookUpGetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpGetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpInheritedConcreteGetter_declared() {
    // class A {
    //   get g {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getter = ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement> [getter];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpInheritedConcreteGetter(getterName, library), isNull);
  }

  void test_lookUpInheritedConcreteGetter_inherited() {
    // class A {
    //   get g {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement inheritedGetter = ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement> [inheritedGetter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpInheritedConcreteGetter(getterName, library), same(inheritedGetter));
  }

  void test_lookUpInheritedConcreteGetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpInheritedConcreteGetter("g", library), isNull);
  }

  void test_lookUpInheritedConcreteGetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classA.lookUpInheritedConcreteGetter("g", library), isNull);
  }

  void test_lookUpInheritedConcreteMethod_declared() {
    // class A {
    //   m() {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpInheritedConcreteMethod(methodName, library), isNull);
  }

  void test_lookUpInheritedConcreteMethod_declaredAbstractAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m();
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement inheritedMethod = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    MethodElementImpl method = ElementFactory.methodElement(methodName, null, []);
    method.abstract = true;
    classB.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpInheritedConcreteMethod(methodName, library), same(inheritedMethod));
  }

  void test_lookUpInheritedConcreteMethod_declaredAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement inheritedMethod = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classB.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpInheritedConcreteMethod(methodName, library), same(inheritedMethod));
  }

  void test_lookUpInheritedConcreteMethod_declaredAndInheritedAbstract() {
    // abstract class A {
    //   m();
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.abstract = true;
    String methodName = "m";
    MethodElementImpl inheritedMethod = ElementFactory.methodElement(methodName, null, []);
    inheritedMethod.abstract = true;
    classA.methods = <MethodElement> [inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classB.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpInheritedConcreteMethod(methodName, library), isNull);
  }

  void test_lookUpInheritedConcreteMethod_declaredAndInheritedWithAbstractBetween() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m();
    // }
    // class C extends B {
    //   m() {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement inheritedMethod = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    MethodElementImpl abstractMethod = ElementFactory.methodElement(methodName, null, []);
    abstractMethod.abstract = true;
    classB.methods = <MethodElement> [abstractMethod];
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type, []);
    MethodElementImpl method = ElementFactory.methodElement(methodName, null, []);
    classC.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB, classC];
    expect(classC.lookUpInheritedConcreteMethod(methodName, library), same(inheritedMethod));
  }

  void test_lookUpInheritedConcreteMethod_inherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement inheritedMethod = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpInheritedConcreteMethod(methodName, library), same(inheritedMethod));
  }

  void test_lookUpInheritedConcreteMethod_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpInheritedConcreteMethod("m", library), isNull);
  }

  void test_lookUpInheritedConcreteSetter_declared() {
    // class A {
    //   set g(x) {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setter = ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement> [setter];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpInheritedConcreteSetter(setterName, library), isNull);
  }

  void test_lookUpInheritedConcreteSetter_inherited() {
    // class A {
    //   set g(x) {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setter = ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement> [setter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpInheritedConcreteSetter(setterName, library), same(setter));
  }

  void test_lookUpInheritedConcreteSetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpInheritedConcreteSetter("s", library), isNull);
  }

  void test_lookUpInheritedConcreteSetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classA.lookUpInheritedConcreteSetter("s", library), isNull);
  }

  void test_lookUpInheritedMethod_declared() {
    // class A {
    //   m() {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpInheritedMethod(methodName, library), isNull);
  }

  void test_lookUpInheritedMethod_declaredAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement inheritedMethod = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classB.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpInheritedMethod(methodName, library), same(inheritedMethod));
  }

  void test_lookUpInheritedMethod_inherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement inheritedMethod = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpInheritedMethod(methodName, library), same(inheritedMethod));
  }

  void test_lookUpInheritedMethod_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpInheritedMethod("m", library), isNull);
  }

  void test_lookUpMethod_declared() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpMethod(methodName, library), same(method));
  }

  void test_lookUpMethod_inherited() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpMethod(methodName, library), same(method));
  }

  void test_lookUpMethod_undeclared() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpMethod_undeclared_recursive() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpSetter_declared() {
    // class A {
    //   set g(x) {}
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setter = ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement> [setter];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpSetter(setterName, library), same(setter));
  }

  void test_lookUpSetter_inherited() {
    // class A {
    //   set g(x) {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setter = ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement> [setter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classB.lookUpSetter(setterName, library), same(setter));
  }

  void test_lookUpSetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(classA.lookUpSetter("s", library), isNull);
  }

  void test_lookUpSetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(classA.lookUpSetter("s", library), isNull);
  }
}

class CompilationUnitElementImplTest extends EngineTestCase {
  void test_getEnum_declared() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    CompilationUnitElementImpl unit = ElementFactory.compilationUnit("/lib.dart");
    String enumName = "E";
    ClassElement enumElement = ElementFactory.enumElement(typeProvider, enumName, []);
    unit.enums = <ClassElement> [enumElement];
    expect(unit.getEnum(enumName), same(enumElement));
  }

  void test_getEnum_undeclared() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    CompilationUnitElementImpl unit = ElementFactory.compilationUnit("/lib.dart");
    String enumName = "E";
    ClassElement enumElement = ElementFactory.enumElement(typeProvider, enumName, []);
    unit.enums = <ClassElement> [enumElement];
    expect(unit.getEnum("${enumName}x"), isNull);
  }

  void test_getType_declared() {
    CompilationUnitElementImpl unit = ElementFactory.compilationUnit("/lib.dart");
    String className = "C";
    ClassElement classElement = ElementFactory.classElement2(className, []);
    unit.types = <ClassElement> [classElement];
    expect(unit.getType(className), same(classElement));
  }

  void test_getType_undeclared() {
    CompilationUnitElementImpl unit = ElementFactory.compilationUnit("/lib.dart");
    String className = "C";
    ClassElement classElement = ElementFactory.classElement2(className, []);
    unit.types = <ClassElement> [classElement];
    expect(unit.getType("${className}x"), isNull);
  }
}

class ElementImplTest extends EngineTestCase {
  void test_equals() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classElement = ElementFactory.classElement2("C", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classElement];
    FieldElement field = ElementFactory.fieldElement("next", false, false, false, classElement.type);
    classElement.fields = <FieldElement> [field];
    expect(field == field, isTrue);
    expect(field == field.getter, isFalse);
    expect(field == field.setter, isFalse);
    expect(field.getter == field.setter, isFalse);
  }

  void test_isAccessibleIn_private_differentLibrary() {
    AnalysisContextImpl context = createAnalysisContext();
    LibraryElementImpl library1 = ElementFactory.library(context, "lib1");
    ClassElement classElement = ElementFactory.classElement2("_C", []);
    (library1.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classElement];
    LibraryElementImpl library2 = ElementFactory.library(context, "lib2");
    expect(classElement.isAccessibleIn(library2), isFalse);
  }

  void test_isAccessibleIn_private_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElement classElement = ElementFactory.classElement2("_C", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classElement];
    expect(classElement.isAccessibleIn(library), isTrue);
  }

  void test_isAccessibleIn_public_differentLibrary() {
    AnalysisContextImpl context = createAnalysisContext();
    LibraryElementImpl library1 = ElementFactory.library(context, "lib1");
    ClassElement classElement = ElementFactory.classElement2("C", []);
    (library1.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classElement];
    LibraryElementImpl library2 = ElementFactory.library(context, "lib2");
    expect(classElement.isAccessibleIn(library2), isTrue);
  }

  void test_isAccessibleIn_public_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElement classElement = ElementFactory.classElement2("C", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classElement];
    expect(classElement.isAccessibleIn(library), isTrue);
  }

  void test_isPrivate_false() {
    Element element = ElementFactory.classElement2("C", []);
    expect(element.isPrivate, isFalse);
  }

  void test_isPrivate_null() {
    Element element = ElementFactory.classElement2(null, []);
    expect(element.isPrivate, isTrue);
  }

  void test_isPrivate_true() {
    Element element = ElementFactory.classElement2("_C", []);
    expect(element.isPrivate, isTrue);
  }

  void test_isPublic_false() {
    Element element = ElementFactory.classElement2("_C", []);
    expect(element.isPublic, isFalse);
  }

  void test_isPublic_null() {
    Element element = ElementFactory.classElement2(null, []);
    expect(element.isPublic, isFalse);
  }

  void test_isPublic_true() {
    Element element = ElementFactory.classElement2("C", []);
    expect(element.isPublic, isTrue);
  }

  void test_SORT_BY_OFFSET() {
    ClassElementImpl classElementA = ElementFactory.classElement2("A", []);
    classElementA.nameOffset = 1;
    ClassElementImpl classElementB = ElementFactory.classElement2("B", []);
    classElementB.nameOffset = 2;
    expect(Element.SORT_BY_OFFSET(classElementA, classElementA), 0);
    expect(Element.SORT_BY_OFFSET(classElementA, classElementB) < 0, isTrue);
    expect(Element.SORT_BY_OFFSET(classElementB, classElementA) > 0, isTrue);
  }
}

class ElementKindTest extends EngineTestCase {
  void test_of_nonNull() {
    expect(ElementKind.of(ElementFactory.classElement2("A", [])), same(ElementKind.CLASS));
  }

  void test_of_null() {
    expect(ElementKind.of(null), same(ElementKind.ERROR));
  }
}

class ElementLocationImplTest extends EngineTestCase {
  void test_create_encoding() {
    String encoding = "a;b;c";
    ElementLocationImpl location = new ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  /**
   * For example unnamed constructor.
   */
  void test_create_encoding_emptyLast() {
    String encoding = "a;b;c;";
    ElementLocationImpl location = new ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  void test_equals_equal() {
    String encoding = "a;b;c";
    ElementLocationImpl first = new ElementLocationImpl.con2(encoding);
    ElementLocationImpl second = new ElementLocationImpl.con2(encoding);
    expect(first == second, isTrue);
  }

  void test_equals_notEqual_differentLengths() {
    ElementLocationImpl first = new ElementLocationImpl.con2("a;b;c");
    ElementLocationImpl second = new ElementLocationImpl.con2("a;b;c;d");
    expect(first == second, isFalse);
  }

  void test_equals_notEqual_notLocation() {
    ElementLocationImpl first = new ElementLocationImpl.con2("a;b;c");
    expect(first == "a;b;d", isFalse);
  }

  void test_equals_notEqual_sameLengths() {
    ElementLocationImpl first = new ElementLocationImpl.con2("a;b;c");
    ElementLocationImpl second = new ElementLocationImpl.con2("a;b;d");
    expect(first == second, isFalse);
  }

  void test_getComponents() {
    String encoding = "a;b;c";
    ElementLocationImpl location = new ElementLocationImpl.con2(encoding);
    List<String> components = location.components;
    expect(components, hasLength(3));
    expect(components[0], "a");
    expect(components[1], "b");
    expect(components[2], "c");
  }

  void test_getEncoding() {
    String encoding = "a;b;c;;d";
    ElementLocationImpl location = new ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  void test_hashCode_equal() {
    String encoding = "a;b;c";
    ElementLocationImpl first = new ElementLocationImpl.con2(encoding);
    ElementLocationImpl second = new ElementLocationImpl.con2(encoding);
    expect(first.hashCode == second.hashCode, isTrue);
  }
}

class FunctionTypeImplTest extends EngineTestCase {
  void test_creation() {
    expect(new FunctionTypeImpl.con1(new FunctionElementImpl.forNode(AstFactory.identifier3("f"))), isNotNull);
  }

  void test_getElement() {
    FunctionElementImpl typeElement = new FunctionElementImpl.forNode(AstFactory.identifier3("f"));
    FunctionTypeImpl type = new FunctionTypeImpl.con1(typeElement);
    expect(type.element, typeElement);
  }

  void test_getNamedParameterTypes() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.forNode(AstFactory.identifier3("f")));
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.forNode(AstFactory.identifier3("f")));
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getReturnType() {
    DartType expectedReturnType = VoidTypeImpl.instance;
    FunctionElementImpl functionElement = new FunctionElementImpl.forNode(AstFactory.identifier3("f"));
    functionElement.returnType = expectedReturnType;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(functionElement);
    DartType returnType = type.returnType;
    expect(returnType, expectedReturnType);
  }

  void test_getTypeArguments() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.forNode(AstFactory.identifier3("f")));
    List<DartType> types = type.typeArguments;
    expect(types, hasLength(0));
  }

  void test_hashCode_element() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.forNode(AstFactory.identifier3("f")));
    type.hashCode;
  }

  void test_hashCode_noElement() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(null);
    type.hashCode;
  }

  void test_isAssignableTo_normalAndPositionalArgs() {
    // ([a]) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [a]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
    // assignable iff subtype
    expect(t.isAssignableTo(s), isTrue);
    expect(s.isAssignableTo(t), isFalse);
  }

  void test_isSubtypeOf_baseCase_classFunction() {
    // () -> void <: Function
    ClassElementImpl functionElement = ElementFactory.classElement2("Function", []);
    InterfaceTypeImpl functionType = new InterfaceTypeImpl_FunctionTypeImplTest_test_isSubtypeOf_baseCase_classFunction(functionElement);
    FunctionType f = ElementFactory.functionElement("f").type;
    expect(f.isSubtypeOf(functionType), isTrue);
  }

  void test_isSubtypeOf_baseCase_notFunctionType() {
    // class C
    // ! () -> void <: C
    FunctionType f = ElementFactory.functionElement("f").type;
    InterfaceType t = ElementFactory.classElement2("C", []).type;
    expect(f.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_baseCase_null() {
    // ! () -> void <: null
    FunctionType f = ElementFactory.functionElement("f").type;
    expect(f.isSubtypeOf(null), isFalse);
  }

  void test_isSubtypeOf_baseCase_self() {
    // () -> void <: () -> void
    FunctionType f = ElementFactory.functionElement("f").type;
    expect(f.isSubtypeOf(f), isTrue);
  }

  void test_isSubtypeOf_namedParameters_isAssignable() {
    // B extends A
    // ({name: A}) -> void <: ({name: B}) -> void
    // ({name: B}) -> void <: ({name: A}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name"], <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name"], <ClassElement> [b]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_namedParameters_isNotAssignable() {
    // ! ({name: A}) -> void <: ({name: B}) -> void
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name"], <ClassElement> [ElementFactory.classElement2("A", [])]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name"], <ClassElement> [ElementFactory.classElement2("B", [])]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_namedParameters_namesDifferent() {
    // B extends A
    // void t({A name}) {}
    // void s({A diff}) {}
    // ! t <: s
    // ! s <: t
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name"], <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["diff"], <ClassElement> [b]).type;
    expect(t.isSubtypeOf(s), isFalse);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_namedParameters_orderOfParams() {
    // B extends A
    // ({A: A, B: B}) -> void <: ({B: B, A: A}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["A", "B"], <ClassElement> [a, b]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["B", "A"], <ClassElement> [b, a]).type;
    expect(t.isSubtypeOf(s), isTrue);
  }

  void test_isSubtypeOf_namedParameters_orderOfParams2() {
    // B extends A
    // ! ({B: B}) -> void <: ({B: B, A: A}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["B"], <ClassElement> [b]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["B", "A"], <ClassElement> [b, a]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_namedParameters_orderOfParams3() {
    // B extends A
    // ({A: A, B: B}) -> void <: ({A: A}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["A", "B"], <ClassElement> [a, b]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["B"], <ClassElement> [b]).type;
    expect(t.isSubtypeOf(s), isTrue);
  }

  void test_isSubtypeOf_namedParameters_sHasMoreParams() {
    // B extends A
    // ! ({name: A}) -> void <: ({name: B, name2: B}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name"], <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name", "name2"], <ClassElement> [b, b]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_namedParameters_tHasMoreParams() {
    // B extends A
    // ({name: A, name2: A}) -> void <: ({name: B}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name", "name2"], <ClassElement> [a, a]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name"], <ClassElement> [b]).type;
    expect(t.isSubtypeOf(s), isTrue);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_1() {
    // ([a]) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [a]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_2() {
    // (a, [a]) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", <ClassElement> [a], <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [a]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_3() {
    // ([a]) -> void <: () -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement("s").type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_4() {
    // (a, b, [c, d, e]) -> void <: (a, b, c, [d]) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement2("B", []);
    ClassElement c = ElementFactory.classElement2("C", []);
    ClassElement d = ElementFactory.classElement2("D", []);
    ClassElement e = ElementFactory.classElement2("E", []);
    FunctionType t = ElementFactory.functionElement6("t", <ClassElement> [a, b], <ClassElement> [c, d, e]).type;
    FunctionType s = ElementFactory.functionElement6("s", <ClassElement> [a, b, c], <ClassElement> [d]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalParameters_isAssignable() {
    // B extends A
    // (a) -> void <: (b) -> void
    // (b) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [b]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_normalParameters_isNotAssignable() {
    // ! (a) -> void <: (b) -> void
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [ElementFactory.classElement2("A", [])]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [ElementFactory.classElement2("B", [])]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_normalParameters_sHasMoreParams() {
    // B extends A
    // ! (a) -> void <: (b, b) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [b, b]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_normalParameters_tHasMoreParams() {
    // B extends A
    // ! (a, a) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a, a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [b]).type;
    // note, this is a different assertion from the other "tHasMoreParams" tests, this is
    // intentional as it is a difference of the "normal parameters"
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_Object() {
    // () -> void <: Object
    FunctionType f = ElementFactory.functionElement("f").type;
    InterfaceType t = ElementFactory.object.type;
    expect(f.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_positionalParameters_isAssignable() {
    // B extends A
    // ([a]) -> void <: ([b]) -> void
    // ([b]) -> void <: ([a]) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [b]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_positionalParameters_isNotAssignable() {
    // ! ([a]) -> void <: ([b]) -> void
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [ElementFactory.classElement2("A", [])]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [ElementFactory.classElement2("B", [])]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_positionalParameters_sHasMoreParams() {
    // B extends A
    // ! ([a]) -> void <: ([b, b]) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [b, b]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_positionalParameters_tHasMoreParams() {
    // B extends A
    // ([a, a]) -> void <: ([b]) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a, a]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [b]).type;
    expect(t.isSubtypeOf(s), isTrue);
  }

  void test_isSubtypeOf_returnType_sIsVoid() {
    // () -> void <: void
    FunctionType t = ElementFactory.functionElement("t").type;
    FunctionType s = ElementFactory.functionElement("s").type;
    // function s has the implicit return type of void, we assert it here
    expect(VoidTypeImpl.instance == s.returnType, isTrue);
    expect(t.isSubtypeOf(s), isTrue);
  }

  void test_isSubtypeOf_returnType_tAssignableToS() {
    // B extends A
    // () -> A <: () -> B
    // () -> B <: () -> A
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement2("t", a).type;
    FunctionType s = ElementFactory.functionElement2("s", b).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_returnType_tNotAssignableToS() {
    // ! () -> A <: () -> B
    FunctionType t = ElementFactory.functionElement2("t", ElementFactory.classElement2("A", [])).type;
    FunctionType s = ElementFactory.functionElement2("s", ElementFactory.classElement2("B", [])).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_typeParameters_matchesBounds() {
    TestTypeProvider provider = new TestTypeProvider();
    InterfaceType boolType = provider.boolType;
    InterfaceType stringType = provider.stringType;
    TypeParameterElementImpl parameterB = new TypeParameterElementImpl.forNode(AstFactory.identifier3("B"));
    parameterB.bound = boolType;
    TypeParameterTypeImpl typeB = new TypeParameterTypeImpl(parameterB);
    TypeParameterElementImpl parameterS = new TypeParameterElementImpl.forNode(AstFactory.identifier3("S"));
    parameterS.bound = stringType;
    TypeParameterTypeImpl typeS = new TypeParameterTypeImpl(parameterS);
    FunctionElementImpl functionAliasElement = new FunctionElementImpl.forNode(AstFactory.identifier3("func"));
    functionAliasElement.parameters = <ParameterElement> [
        ElementFactory.requiredParameter2("a", typeB),
        ElementFactory.positionalParameter2("b", typeS)];
    functionAliasElement.returnType = stringType;
    FunctionTypeImpl functionAliasType = new FunctionTypeImpl.con1(functionAliasElement);
    functionAliasElement.type = functionAliasType;
    FunctionElementImpl functionElement = new FunctionElementImpl.forNode(AstFactory.identifier3("f"));
    functionElement.parameters = <ParameterElement> [
        ElementFactory.requiredParameter2("c", boolType),
        ElementFactory.positionalParameter2("d", stringType)];
    functionElement.returnType = provider.dynamicType;
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    functionElement.type = functionType;
    expect(functionType.isAssignableTo(functionAliasType), isTrue);
  }

  void test_isSubtypeOf_wrongFunctionType_normal_named() {
    // ! (a) -> void <: ({name: A}) -> void
    // ! ({name: A}) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement7("s", null, <String> ["name"], <ClassElement> [a]).type;
    expect(t.isSubtypeOf(s), isFalse);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_wrongFunctionType_optional_named() {
    // ! ([a]) -> void <: ({name: A}) -> void
    // ! ({name: A}) -> void <: ([a]) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement7("s", null, <String> ["name"], <ClassElement> [a]).type;
    expect(t.isSubtypeOf(s), isFalse);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_setTypeArguments() {
    ClassElementImpl enclosingClass = ElementFactory.classElement2("C", ["E"]);
    MethodElementImpl methodElement = new MethodElementImpl.forNode(AstFactory.identifier3("m"));
    enclosingClass.methods = <MethodElement> [methodElement];
    FunctionTypeImpl type = new FunctionTypeImpl.con1(methodElement);
    DartType expectedType = enclosingClass.typeParameters[0].type;
    type.typeArguments = <DartType> [expectedType];
    List<DartType> arguments = type.typeArguments;
    expect(arguments, hasLength(1));
    expect(arguments[0], expectedType);
  }

  void test_substitute2_equal() {
    ClassElementImpl definingClass = ElementFactory.classElement2("C", ["E"]);
    TypeParameterType parameterType = definingClass.typeParameters[0].type;
    MethodElementImpl functionElement = new MethodElementImpl.forNode(AstFactory.identifier3("m"));
    String namedParameterName = "c";
    functionElement.parameters = <ParameterElement> [
        ElementFactory.requiredParameter2("a", parameterType),
        ElementFactory.positionalParameter2("b", parameterType),
        ElementFactory.namedParameter2(namedParameterName, parameterType)];
    functionElement.returnType = parameterType;
    definingClass.methods = <MethodElement> [functionElement];
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    functionType.typeArguments = <DartType> [parameterType];
    InterfaceTypeImpl argumentType = new InterfaceTypeImpl.con1(new ClassElementImpl.forNode(AstFactory.identifier3("D")));
    FunctionType result = functionType.substitute2(<DartType> [argumentType], <DartType> [parameterType]);
    expect(result.returnType, argumentType);
    List<DartType> normalParameters = result.normalParameterTypes;
    expect(normalParameters, hasLength(1));
    expect(normalParameters[0], argumentType);
    List<DartType> optionalParameters = result.optionalParameterTypes;
    expect(optionalParameters, hasLength(1));
    expect(optionalParameters[0], argumentType);
    Map<String, DartType> namedParameters = result.namedParameterTypes;
    expect(namedParameters, hasLength(1));
    expect(namedParameters[namedParameterName], argumentType);
  }

  void test_substitute2_notEqual() {
    DartType returnType = new InterfaceTypeImpl.con1(new ClassElementImpl.forNode(AstFactory.identifier3("R")));
    DartType normalParameterType = new InterfaceTypeImpl.con1(new ClassElementImpl.forNode(AstFactory.identifier3("A")));
    DartType optionalParameterType = new InterfaceTypeImpl.con1(new ClassElementImpl.forNode(AstFactory.identifier3("B")));
    DartType namedParameterType = new InterfaceTypeImpl.con1(new ClassElementImpl.forNode(AstFactory.identifier3("C")));
    FunctionElementImpl functionElement = new FunctionElementImpl.forNode(AstFactory.identifier3("f"));
    String namedParameterName = "c";
    functionElement.parameters = <ParameterElement> [
        ElementFactory.requiredParameter2("a", normalParameterType),
        ElementFactory.positionalParameter2("b", optionalParameterType),
        ElementFactory.namedParameter2(namedParameterName, namedParameterType)];
    functionElement.returnType = returnType;
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    InterfaceTypeImpl argumentType = new InterfaceTypeImpl.con1(new ClassElementImpl.forNode(AstFactory.identifier3("D")));
    TypeParameterTypeImpl parameterType = new TypeParameterTypeImpl(new TypeParameterElementImpl.forNode(AstFactory.identifier3("E")));
    FunctionType result = functionType.substitute2(<DartType> [argumentType], <DartType> [parameterType]);
    expect(result.returnType, returnType);
    List<DartType> normalParameters = result.normalParameterTypes;
    expect(normalParameters, hasLength(1));
    expect(normalParameters[0], normalParameterType);
    List<DartType> optionalParameters = result.optionalParameterTypes;
    expect(optionalParameters, hasLength(1));
    expect(optionalParameters[0], optionalParameterType);
    Map<String, DartType> namedParameters = result.namedParameterTypes;
    expect(namedParameters, hasLength(1));
    expect(namedParameters[namedParameterName], namedParameterType);
  }
}

class HtmlElementImplTest extends EngineTestCase {
  void test_equals_differentSource() {
    AnalysisContextImpl context = createAnalysisContext();
    HtmlElementImpl elementA = ElementFactory.htmlUnit(context, "indexA.html");
    HtmlElementImpl elementB = ElementFactory.htmlUnit(context, "indexB.html");
    expect(elementA == elementB, isFalse);
  }

  void test_equals_null() {
    AnalysisContextImpl context = createAnalysisContext();
    HtmlElementImpl element = ElementFactory.htmlUnit(context, "index.html");
    expect(element == null, isFalse);
  }

  void test_equals_sameSource() {
    AnalysisContextImpl context = createAnalysisContext();
    HtmlElementImpl elementA = ElementFactory.htmlUnit(context, "index.html");
    HtmlElementImpl elementB = ElementFactory.htmlUnit(context, "index.html");
    expect(elementA == elementB, isTrue);
  }

  void test_equals_self() {
    AnalysisContextImpl context = createAnalysisContext();
    HtmlElementImpl element = ElementFactory.htmlUnit(context, "index.html");
    expect(element == element, isTrue);
  }
}

class InterfaceTypeImplTest extends EngineTestCase {
  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  @override
  void setUp() {
    _typeProvider = new TestTypeProvider();
  }

  void test_computeLongestInheritancePathToObject_multipleInterfacePaths() {
    //
    //   Object
    //     |
    //     A
    //    / \
    //   B   C
    //   |   |
    //   |   D
    //    \ /
    //     E
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    ClassElementImpl classD = ElementFactory.classElement2("D", []);
    ClassElementImpl classE = ElementFactory.classElement2("E", []);
    classB.interfaces = <InterfaceType> [classA.type];
    classC.interfaces = <InterfaceType> [classA.type];
    classD.interfaces = <InterfaceType> [classC.type];
    classE.interfaces = <InterfaceType> [classB.type, classD.type];
    // assertion: even though the longest path to Object for typeB is 2, and typeE implements typeB,
    // the longest path for typeE is 4 since it also implements typeD
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type), 2);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classE.type), 4);
  }

  void test_computeLongestInheritancePathToObject_multipleSuperclassPaths() {
    //
    //   Object
    //     |
    //     A
    //    / \
    //   B   C
    //   |   |
    //   |   D
    //    \ /
    //     E
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElement classC = ElementFactory.classElement("C", classA.type, []);
    ClassElement classD = ElementFactory.classElement("D", classC.type, []);
    ClassElementImpl classE = ElementFactory.classElement("E", classB.type, []);
    classE.interfaces = <InterfaceType> [classD.type];
    // assertion: even though the longest path to Object for typeB is 2, and typeE extends typeB,
    // the longest path for typeE is 4 since it also implements typeD
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type), 2);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classE.type), 4);
  }

  void test_computeLongestInheritancePathToObject_object() {
    //
    //   Object
    //     |
    //     A
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType object = classA.supertype;
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(object), 0);
  }

  void test_computeLongestInheritancePathToObject_recursion() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classA.type), 2);
  }

  void test_computeLongestInheritancePathToObject_singleInterfacePath() {
    //
    //   Object
    //     |
    //     A
    //     |
    //     B
    //     |
    //     C
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    classB.interfaces = <InterfaceType> [classA.type];
    classC.interfaces = <InterfaceType> [classB.type];
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classA.type), 1);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type), 2);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classC.type), 3);
  }

  void test_computeLongestInheritancePathToObject_singleSuperclassPath() {
    //
    //   Object
    //     |
    //     A
    //     |
    //     B
    //     |
    //     C
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElement classC = ElementFactory.classElement("C", classB.type, []);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classA.type), 1);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type), 2);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classC.type), 3);
  }

  void test_computeSuperinterfaceSet_genericInterfacePath() {
    //
    //  A
    //  | implements
    //  B<T>
    //  | implements
    //  C<T>
    //
    //  D
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", ["T"]);
    ClassElementImpl classC = ElementFactory.classElement2("C", ["T"]);
    ClassElement classD = ElementFactory.classElement2("D", []);
    InterfaceType typeA = classA.type;
    classB.interfaces = <InterfaceType> [typeA];
    InterfaceTypeImpl typeBT = new InterfaceTypeImpl.con1(classB);
    DartType typeT = classC.type.typeArguments[0];
    typeBT.typeArguments = <DartType> [typeT];
    classC.interfaces = <InterfaceType> [typeBT];
    // A
    Set<InterfaceType> superinterfacesOfA = InterfaceTypeImpl.computeSuperinterfaceSet(typeA);
    expect(superinterfacesOfA, hasLength(1));
    InterfaceType typeObject = ElementFactory.object.type;
    expect(superinterfacesOfA.contains(typeObject), isTrue);
    // B<D>
    InterfaceTypeImpl typeBD = new InterfaceTypeImpl.con1(classB);
    typeBD.typeArguments = <DartType> [classD.type];
    Set<InterfaceType> superinterfacesOfBD = InterfaceTypeImpl.computeSuperinterfaceSet(typeBD);
    expect(superinterfacesOfBD, hasLength(2));
    expect(superinterfacesOfBD.contains(typeObject), isTrue);
    expect(superinterfacesOfBD.contains(typeA), isTrue);
    // C<D>
    InterfaceTypeImpl typeCD = new InterfaceTypeImpl.con1(classC);
    typeCD.typeArguments = <DartType> [classD.type];
    Set<InterfaceType> superinterfacesOfCD = InterfaceTypeImpl.computeSuperinterfaceSet(typeCD);
    expect(superinterfacesOfCD, hasLength(3));
    expect(superinterfacesOfCD.contains(typeObject), isTrue);
    expect(superinterfacesOfCD.contains(typeA), isTrue);
    expect(superinterfacesOfCD.contains(typeBD), isTrue);
  }

  void test_computeSuperinterfaceSet_genericSuperclassPath() {
    //
    //  A
    //  |
    //  B<T>
    //  |
    //  C<T>
    //
    //  D
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    ClassElement classB = ElementFactory.classElement("B", typeA, ["T"]);
    ClassElementImpl classC = ElementFactory.classElement2("C", ["T"]);
    InterfaceTypeImpl typeBT = new InterfaceTypeImpl.con1(classB);
    DartType typeT = classC.type.typeArguments[0];
    typeBT.typeArguments = <DartType> [typeT];
    classC.supertype = typeBT;
    ClassElement classD = ElementFactory.classElement2("D", []);
    // A
    Set<InterfaceType> superinterfacesOfA = InterfaceTypeImpl.computeSuperinterfaceSet(typeA);
    expect(superinterfacesOfA, hasLength(1));
    InterfaceType typeObject = ElementFactory.object.type;
    expect(superinterfacesOfA.contains(typeObject), isTrue);
    // B<D>
    InterfaceTypeImpl typeBD = new InterfaceTypeImpl.con1(classB);
    typeBD.typeArguments = <DartType> [classD.type];
    Set<InterfaceType> superinterfacesOfBD = InterfaceTypeImpl.computeSuperinterfaceSet(typeBD);
    expect(superinterfacesOfBD, hasLength(2));
    expect(superinterfacesOfBD.contains(typeObject), isTrue);
    expect(superinterfacesOfBD.contains(typeA), isTrue);
    // C<D>
    InterfaceTypeImpl typeCD = new InterfaceTypeImpl.con1(classC);
    typeCD.typeArguments = <DartType> [classD.type];
    Set<InterfaceType> superinterfacesOfCD = InterfaceTypeImpl.computeSuperinterfaceSet(typeCD);
    expect(superinterfacesOfCD, hasLength(3));
    expect(superinterfacesOfCD.contains(typeObject), isTrue);
    expect(superinterfacesOfCD.contains(typeA), isTrue);
    expect(superinterfacesOfCD.contains(typeBD), isTrue);
  }

  void test_computeSuperinterfaceSet_multipleInterfacePaths() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    ClassElementImpl classD = ElementFactory.classElement2("D", []);
    ClassElementImpl classE = ElementFactory.classElement2("E", []);
    classB.interfaces = <InterfaceType> [classA.type];
    classC.interfaces = <InterfaceType> [classA.type];
    classD.interfaces = <InterfaceType> [classC.type];
    classE.interfaces = <InterfaceType> [classB.type, classD.type];
    // D
    Set<InterfaceType> superinterfacesOfD = InterfaceTypeImpl.computeSuperinterfaceSet(classD.type);
    expect(superinterfacesOfD, hasLength(3));
    expect(superinterfacesOfD.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfD.contains(classA.type), isTrue);
    expect(superinterfacesOfD.contains(classC.type), isTrue);
    // E
    Set<InterfaceType> superinterfacesOfE = InterfaceTypeImpl.computeSuperinterfaceSet(classE.type);
    expect(superinterfacesOfE, hasLength(5));
    expect(superinterfacesOfE.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfE.contains(classA.type), isTrue);
    expect(superinterfacesOfE.contains(classB.type), isTrue);
    expect(superinterfacesOfE.contains(classC.type), isTrue);
    expect(superinterfacesOfE.contains(classD.type), isTrue);
  }

  void test_computeSuperinterfaceSet_multipleSuperclassPaths() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElement classC = ElementFactory.classElement("C", classA.type, []);
    ClassElement classD = ElementFactory.classElement("D", classC.type, []);
    ClassElementImpl classE = ElementFactory.classElement("E", classB.type, []);
    classE.interfaces = <InterfaceType> [classD.type];
    // D
    Set<InterfaceType> superinterfacesOfD = InterfaceTypeImpl.computeSuperinterfaceSet(classD.type);
    expect(superinterfacesOfD, hasLength(3));
    expect(superinterfacesOfD.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfD.contains(classA.type), isTrue);
    expect(superinterfacesOfD.contains(classC.type), isTrue);
    // E
    Set<InterfaceType> superinterfacesOfE = InterfaceTypeImpl.computeSuperinterfaceSet(classE.type);
    expect(superinterfacesOfE, hasLength(5));
    expect(superinterfacesOfE.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfE.contains(classA.type), isTrue);
    expect(superinterfacesOfE.contains(classB.type), isTrue);
    expect(superinterfacesOfE.contains(classC.type), isTrue);
    expect(superinterfacesOfE.contains(classD.type), isTrue);
  }

  void test_computeSuperinterfaceSet_recursion() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    Set<InterfaceType> superinterfacesOfB = InterfaceTypeImpl.computeSuperinterfaceSet(classB.type);
    expect(superinterfacesOfB, hasLength(2));
  }

  void test_computeSuperinterfaceSet_singleInterfacePath() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    classB.interfaces = <InterfaceType> [classA.type];
    classC.interfaces = <InterfaceType> [classB.type];
    // A
    Set<InterfaceType> superinterfacesOfA = InterfaceTypeImpl.computeSuperinterfaceSet(classA.type);
    expect(superinterfacesOfA, hasLength(1));
    expect(superinterfacesOfA.contains(ElementFactory.object.type), isTrue);
    // B
    Set<InterfaceType> superinterfacesOfB = InterfaceTypeImpl.computeSuperinterfaceSet(classB.type);
    expect(superinterfacesOfB, hasLength(2));
    expect(superinterfacesOfB.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfB.contains(classA.type), isTrue);
    // C
    Set<InterfaceType> superinterfacesOfC = InterfaceTypeImpl.computeSuperinterfaceSet(classC.type);
    expect(superinterfacesOfC, hasLength(3));
    expect(superinterfacesOfC.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfC.contains(classA.type), isTrue);
    expect(superinterfacesOfC.contains(classB.type), isTrue);
  }

  void test_computeSuperinterfaceSet_singleSuperclassPath() {
    //
    //  A
    //  |
    //  B
    //  |
    //  C
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElement classC = ElementFactory.classElement("C", classB.type, []);
    // A
    Set<InterfaceType> superinterfacesOfA = InterfaceTypeImpl.computeSuperinterfaceSet(classA.type);
    expect(superinterfacesOfA, hasLength(1));
    expect(superinterfacesOfA.contains(ElementFactory.object.type), isTrue);
    // B
    Set<InterfaceType> superinterfacesOfB = InterfaceTypeImpl.computeSuperinterfaceSet(classB.type);
    expect(superinterfacesOfB, hasLength(2));
    expect(superinterfacesOfB.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfB.contains(classA.type), isTrue);
    // C
    Set<InterfaceType> superinterfacesOfC = InterfaceTypeImpl.computeSuperinterfaceSet(classC.type);
    expect(superinterfacesOfC, hasLength(3));
    expect(superinterfacesOfC.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfC.contains(classA.type), isTrue);
    expect(superinterfacesOfC.contains(classB.type), isTrue);
  }

  void test_creation() {
    expect(new InterfaceTypeImpl.con1(ElementFactory.classElement2("A", [])), isNotNull);
  }

  void test_getAccessors() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A", []);
    PropertyAccessorElement getterG = ElementFactory.getterElement("g", false, null);
    PropertyAccessorElement getterH = ElementFactory.getterElement("h", false, null);
    typeElement.accessors = <PropertyAccessorElement> [getterG, getterH];
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(typeElement);
    expect(type.accessors.length, 2);
  }

  void test_getAccessors_empty() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A", []);
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(typeElement);
    expect(type.accessors.length, 0);
  }

  void test_getElement() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A", []);
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(typeElement);
    expect(type.element, typeElement);
  }

  void test_getGetter_implemented() {
    //
    // class A { g {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getterG = ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement> [getterG];
    InterfaceType typeA = classA.type;
    expect(typeA.getGetter(getterName), same(getterG));
  }

  void test_getGetter_parameterized() {
    //
    // class A<E> { E get g {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", ["E"]);
    DartType typeE = classA.type.typeArguments[0];
    String getterName = "g";
    PropertyAccessorElement getterG = ElementFactory.getterElement(getterName, false, typeE);
    classA.accessors = <PropertyAccessorElement> [getterG];
    (getterG.type as FunctionTypeImpl).typeArguments = classA.type.typeArguments;
    //
    // A<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I", []).type;
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl.con1(classA);
    typeAI.typeArguments = <DartType> [typeI];
    PropertyAccessorElement getter = typeAI.getGetter(getterName);
    expect(getter, isNotNull);
    FunctionType getterType = getter.type;
    expect(getterType.returnType, same(typeI));
  }

  void test_getGetter_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    expect(typeA.getGetter("g"), isNull);
  }

  void test_getInterfaces_nonParameterized() {
    //
    // class C implements A, B
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    InterfaceType typeB = classB.type;
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    classC.interfaces = <InterfaceType> [typeA, typeB];
    List<InterfaceType> interfaces = classC.type.interfaces;
    expect(interfaces, hasLength(2));
    if (identical(interfaces[0], typeA)) {
      expect(interfaces[1], same(typeB));
    } else {
      expect(interfaces[0], same(typeB));
      expect(interfaces[1], same(typeA));
    }
  }

  void test_getInterfaces_parameterized() {
    //
    // class A<E>
    // class B<F> implements A<F>
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", ["E"]);
    ClassElementImpl classB = ElementFactory.classElement2("B", ["F"]);
    InterfaceType typeB = classB.type;
    InterfaceTypeImpl typeAF = new InterfaceTypeImpl.con1(classA);
    typeAF.typeArguments = <DartType> [typeB.typeArguments[0]];
    classB.interfaces = <InterfaceType> [typeAF];
    //
    // B<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I", []).type;
    InterfaceTypeImpl typeBI = new InterfaceTypeImpl.con1(classB);
    typeBI.typeArguments = <DartType> [typeI];
    List<InterfaceType> interfaces = typeBI.interfaces;
    expect(interfaces, hasLength(1));
    InterfaceType result = interfaces[0];
    expect(result.element, same(classA));
    expect(result.typeArguments[0], same(typeI));
  }

  void test_getLeastUpperBound_directInterfaceCase() {
    //
    // class A
    // class B implements A
    // class C implements B
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType> [typeA];
    classC.interfaces = <InterfaceType> [typeB];
    expect(typeB.getLeastUpperBound(typeC), typeB);
    expect(typeC.getLeastUpperBound(typeB), typeB);
  }

  void test_getLeastUpperBound_directSubclassCase() {
    //
    // class A
    // class B extends A
    // class C extends B
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type, []);
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    expect(typeB.getLeastUpperBound(typeC), typeB);
    expect(typeC.getLeastUpperBound(typeB), typeB);
  }

  void test_getLeastUpperBound_functionType() {
    DartType interfaceType = ElementFactory.classElement2("A", []).type;
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(new FunctionElementImpl.forNode(AstFactory.identifier3("f")));
    expect(interfaceType.getLeastUpperBound(functionType), isNull);
  }

  void test_getLeastUpperBound_mixinCase() {
    //
    // class A
    // class B extends A
    // class C extends A
    // class D extends B with M, N, O, P
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElement classC = ElementFactory.classElement("C", classA.type, []);
    ClassElementImpl classD = ElementFactory.classElement("D", classB.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    classD.mixins = <InterfaceType> [
        ElementFactory.classElement2("M", []).type,
        ElementFactory.classElement2("N", []).type,
        ElementFactory.classElement2("O", []).type,
        ElementFactory.classElement2("P", []).type];
    expect(typeD.getLeastUpperBound(typeC), typeA);
    expect(typeC.getLeastUpperBound(typeD), typeA);
  }

  void test_getLeastUpperBound_null() {
    DartType interfaceType = ElementFactory.classElement2("A", []).type;
    expect(interfaceType.getLeastUpperBound(null), isNull);
  }

  void test_getLeastUpperBound_object() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    DartType typeObject = typeA.element.supertype;
    // assert that object does not have a super type
    expect((typeObject.element as ClassElement).supertype, isNull);
    // assert that both A and B have the same super type of Object
    expect(typeB.element.supertype, typeObject);
    // finally, assert that the only least upper bound of A and B is Object
    expect(typeA.getLeastUpperBound(typeB), typeObject);
  }

  void test_getLeastUpperBound_self() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    expect(typeA.getLeastUpperBound(typeA), typeA);
  }

  void test_getLeastUpperBound_sharedSuperclass1() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    expect(typeB.getLeastUpperBound(typeC), typeA);
    expect(typeC.getLeastUpperBound(typeB), typeA);
  }

  void test_getLeastUpperBound_sharedSuperclass2() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type, []);
    ClassElementImpl classD = ElementFactory.classElement("D", classC.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeD = classD.type;
    expect(typeB.getLeastUpperBound(typeD), typeA);
    expect(typeD.getLeastUpperBound(typeB), typeA);
  }

  void test_getLeastUpperBound_sharedSuperclass3() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type, []);
    ClassElementImpl classD = ElementFactory.classElement("D", classB.type, []);
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    expect(typeC.getLeastUpperBound(typeD), typeB);
    expect(typeD.getLeastUpperBound(typeC), typeB);
  }

  void test_getLeastUpperBound_sharedSuperclass4() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classA2 = ElementFactory.classElement2("A2", []);
    ClassElement classA3 = ElementFactory.classElement2("A3", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeA2 = classA2.type;
    InterfaceType typeA3 = classA3.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType> [typeA2];
    classC.interfaces = <InterfaceType> [typeA3];
    expect(typeB.getLeastUpperBound(typeC), typeA);
    expect(typeC.getLeastUpperBound(typeB), typeA);
  }

  void test_getLeastUpperBound_sharedSuperinterface1() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType> [typeA];
    classC.interfaces = <InterfaceType> [typeA];
    expect(typeB.getLeastUpperBound(typeC), typeA);
    expect(typeC.getLeastUpperBound(typeB), typeA);
  }

  void test_getLeastUpperBound_sharedSuperinterface2() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    ClassElementImpl classD = ElementFactory.classElement2("D", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    classB.interfaces = <InterfaceType> [typeA];
    classC.interfaces = <InterfaceType> [typeA];
    classD.interfaces = <InterfaceType> [typeC];
    expect(typeB.getLeastUpperBound(typeD), typeA);
    expect(typeD.getLeastUpperBound(typeB), typeA);
  }

  void test_getLeastUpperBound_sharedSuperinterface3() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    ClassElementImpl classD = ElementFactory.classElement2("D", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    classB.interfaces = <InterfaceType> [typeA];
    classC.interfaces = <InterfaceType> [typeB];
    classD.interfaces = <InterfaceType> [typeB];
    expect(typeC.getLeastUpperBound(typeD), typeB);
    expect(typeD.getLeastUpperBound(typeC), typeB);
  }

  void test_getLeastUpperBound_sharedSuperinterface4() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classA2 = ElementFactory.classElement2("A2", []);
    ClassElement classA3 = ElementFactory.classElement2("A3", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeA2 = classA2.type;
    InterfaceType typeA3 = classA3.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classB.interfaces = <InterfaceType> [typeA, typeA2];
    classC.interfaces = <InterfaceType> [typeA, typeA3];
    expect(typeB.getLeastUpperBound(typeC), typeA);
    expect(typeC.getLeastUpperBound(typeB), typeA);
  }

  void test_getLeastUpperBound_twoComparables() {
    InterfaceType string = _typeProvider.stringType;
    InterfaceType num = _typeProvider.numType;
    expect(string.getLeastUpperBound(num), _typeProvider.objectType);
  }

  void test_getLeastUpperBound_typeParameters_different() {
    //
    // class List<int>
    // class List<double>
    //
    InterfaceType listType = _typeProvider.listType;
    InterfaceType intType = _typeProvider.intType;
    InterfaceType doubleType = _typeProvider.doubleType;
    InterfaceType listOfIntType = listType.substitute4(<DartType> [intType]);
    InterfaceType listOfDoubleType = listType.substitute4(<DartType> [doubleType]);
    expect(listOfIntType.getLeastUpperBound(listOfDoubleType), _typeProvider.objectType);
  }

  void test_getLeastUpperBound_typeParameters_same() {
    //
    // List<int>
    // List<int>
    //
    InterfaceType listType = _typeProvider.listType;
    InterfaceType intType = _typeProvider.intType;
    InterfaceType listOfIntType = listType.substitute4(<DartType> [intType]);
    expect(listOfIntType.getLeastUpperBound(listOfIntType), listOfIntType);
  }

  void test_getMethod_implemented() {
    //
    // class A { m() {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [methodM];
    InterfaceType typeA = classA.type;
    expect(typeA.getMethod(methodName), same(methodM));
  }

  void test_getMethod_parameterized() {
    //
    // class A<E> { E m(E p) {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", ["E"]);
    DartType typeE = classA.type.typeArguments[0];
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, typeE, [typeE]);
    classA.methods = <MethodElement> [methodM];
    (methodM.type as FunctionTypeImpl).typeArguments = classA.type.typeArguments;
    //
    // A<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I", []).type;
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl.con1(classA);
    typeAI.typeArguments = <DartType> [typeI];
    MethodElement method = typeAI.getMethod(methodName);
    expect(method, isNotNull);
    FunctionType methodType = method.type;
    expect(methodType.returnType, same(typeI));
    List<DartType> parameterTypes = methodType.normalParameterTypes;
    expect(parameterTypes, hasLength(1));
    expect(parameterTypes[0], same(typeI));
  }

  void test_getMethod_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    expect(typeA.getMethod("m"), isNull);
  }

  void test_getMethods() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A", []);
    MethodElementImpl methodOne = ElementFactory.methodElement("one", null, []);
    MethodElementImpl methodTwo = ElementFactory.methodElement("two", null, []);
    typeElement.methods = <MethodElement> [methodOne, methodTwo];
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(typeElement);
    expect(type.methods.length, 2);
  }

  void test_getMethods_empty() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A", []);
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(typeElement);
    expect(type.methods.length, 0);
  }

  void test_getMixins_nonParameterized() {
    //
    // class C extends Object with A, B
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    InterfaceType typeB = classB.type;
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    classC.mixins = <InterfaceType> [typeA, typeB];
    List<InterfaceType> interfaces = classC.type.mixins;
    expect(interfaces, hasLength(2));
    if (identical(interfaces[0], typeA)) {
      expect(interfaces[1], same(typeB));
    } else {
      expect(interfaces[0], same(typeB));
      expect(interfaces[1], same(typeA));
    }
  }

  void test_getMixins_parameterized() {
    //
    // class A<E>
    // class B<F> extends Object with A<F>
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", ["E"]);
    ClassElementImpl classB = ElementFactory.classElement2("B", ["F"]);
    InterfaceType typeB = classB.type;
    InterfaceTypeImpl typeAF = new InterfaceTypeImpl.con1(classA);
    typeAF.typeArguments = <DartType> [typeB.typeArguments[0]];
    classB.mixins = <InterfaceType> [typeAF];
    //
    // B<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I", []).type;
    InterfaceTypeImpl typeBI = new InterfaceTypeImpl.con1(classB);
    typeBI.typeArguments = <DartType> [typeI];
    List<InterfaceType> interfaces = typeBI.mixins;
    expect(interfaces, hasLength(1));
    InterfaceType result = interfaces[0];
    expect(result.element, same(classA));
    expect(result.typeArguments[0], same(typeI));
  }

  void test_getSetter_implemented() {
    //
    // class A { s() {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setterS = ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement> [setterS];
    InterfaceType typeA = classA.type;
    expect(typeA.getSetter(setterName), same(setterS));
  }

  void test_getSetter_parameterized() {
    //
    // class A<E> { set s(E p) {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", ["E"]);
    DartType typeE = classA.type.typeArguments[0];
    String setterName = "s";
    PropertyAccessorElement setterS = ElementFactory.setterElement(setterName, false, typeE);
    classA.accessors = <PropertyAccessorElement> [setterS];
    (setterS.type as FunctionTypeImpl).typeArguments = classA.type.typeArguments;
    //
    // A<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I", []).type;
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl.con1(classA);
    typeAI.typeArguments = <DartType> [typeI];
    PropertyAccessorElement setter = typeAI.getSetter(setterName);
    expect(setter, isNotNull);
    FunctionType setterType = setter.type;
    List<DartType> parameterTypes = setterType.normalParameterTypes;
    expect(parameterTypes, hasLength(1));
    expect(parameterTypes[0], same(typeI));
  }

  void test_getSetter_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    expect(typeA.getSetter("s"), isNull);
  }

  void test_getSuperclass_nonParameterized() {
    //
    // class B extends A
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement("B", typeA, []);
    InterfaceType typeB = classB.type;
    expect(typeB.superclass, same(typeA));
  }

  void test_getSuperclass_parameterized() {
    //
    // class A<E>
    // class B<F> extends A<F>
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", ["E"]);
    ClassElementImpl classB = ElementFactory.classElement2("B", ["F"]);
    InterfaceType typeB = classB.type;
    InterfaceTypeImpl typeAF = new InterfaceTypeImpl.con1(classA);
    typeAF.typeArguments = <DartType> [typeB.typeArguments[0]];
    classB.supertype = typeAF;
    //
    // B<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I", []).type;
    InterfaceTypeImpl typeBI = new InterfaceTypeImpl.con1(classB);
    typeBI.typeArguments = <DartType> [typeI];
    InterfaceType superclass = typeBI.superclass;
    expect(superclass.element, same(classA));
    expect(superclass.typeArguments[0], same(typeI));
  }

  void test_getTypeArguments_empty() {
    InterfaceType type = ElementFactory.classElement2("A", []).type;
    expect(type.typeArguments, hasLength(0));
  }

  void test_hashCode() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    expect(0 == typeA.hashCode, isFalse);
  }

  void test_isAssignableTo_typeVariables() {
    //
    // class A<E> {}
    // class B<F, G> {
    //   A<F> af;
    //   f (A<G> ag) {
    //     af = ag;
    //   }
    // }
    //
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classB = ElementFactory.classElement2("B", ["F", "G"]);
    InterfaceTypeImpl typeAF = new InterfaceTypeImpl.con1(classA);
    typeAF.typeArguments = <DartType> [classB.typeParameters[0].type];
    InterfaceTypeImpl typeAG = new InterfaceTypeImpl.con1(classA);
    typeAG.typeArguments = <DartType> [classB.typeParameters[1].type];
    expect(typeAG.isAssignableTo(typeAF), isFalse);
  }

  void test_isAssignableTo_void() {
    expect(VoidTypeImpl.instance.isAssignableTo(_typeProvider.intType), isFalse);
  }

  void test_isDirectSupertypeOf_extends() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    expect(typeA.isDirectSupertypeOf(typeB), isTrue);
  }

  void test_isDirectSupertypeOf_false() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement2("B", []);
    ClassElement classC = ElementFactory.classElement("C", classB.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    expect(typeA.isDirectSupertypeOf(typeC), isFalse);
  }

  void test_isDirectSupertypeOf_implements() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    classB.interfaces = <InterfaceType> [typeA];
    expect(typeA.isDirectSupertypeOf(typeB), isTrue);
  }

  void test_isDirectSupertypeOf_with() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    classB.mixins = <InterfaceType> [typeA];
    expect(typeA.isDirectSupertypeOf(typeB), isTrue);
  }

  void test_isMoreSpecificThan_bottom() {
    DartType type = ElementFactory.classElement2("A", []).type;
    expect(BottomTypeImpl.instance.isMoreSpecificThan(type), isTrue);
  }

  void test_isMoreSpecificThan_covariance() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classI = ElementFactory.classElement2("I", []);
    ClassElement classJ = ElementFactory.classElement("J", classI.type, []);
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl.con1(classA);
    InterfaceTypeImpl typeAJ = new InterfaceTypeImpl.con1(classA);
    typeAI.typeArguments = <DartType> [classI.type];
    typeAJ.typeArguments = <DartType> [classJ.type];
    expect(typeAJ.isMoreSpecificThan(typeAI), isTrue);
    expect(typeAI.isMoreSpecificThan(typeAJ), isFalse);
  }

  void test_isMoreSpecificThan_directSupertype() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    expect(typeB.isMoreSpecificThan(typeA), isTrue);
    // the opposite test tests a different branch in isMoreSpecificThan()
    expect(typeA.isMoreSpecificThan(typeB), isFalse);
  }

  void test_isMoreSpecificThan_dynamic() {
    InterfaceType type = ElementFactory.classElement2("A", []).type;
    expect(type.isMoreSpecificThan(DynamicTypeImpl.instance), isTrue);
  }

  void test_isMoreSpecificThan_generic() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classB = ElementFactory.classElement2("B", []);
    DartType dynamicType = DynamicTypeImpl.instance;
    InterfaceType typeAOfDynamic = classA.type.substitute4(<DartType> [dynamicType]);
    InterfaceType typeAOfB = classA.type.substitute4(<DartType> [classB.type]);
    expect(typeAOfDynamic.isMoreSpecificThan(typeAOfB), isFalse);
    expect(typeAOfB.isMoreSpecificThan(typeAOfDynamic), isTrue);
  }

  void test_isMoreSpecificThan_self() {
    InterfaceType type = ElementFactory.classElement2("A", []).type;
    expect(type.isMoreSpecificThan(type), isTrue);
  }

  void test_isMoreSpecificThan_transitive_interface() {
    //
    //  class A {}
    //  class B extends A {}
    //  class C implements B {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    classC.interfaces = <InterfaceType> [classB.type];
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    expect(typeC.isMoreSpecificThan(typeA), isTrue);
  }

  void test_isMoreSpecificThan_transitive_mixin() {
    //
    //  class A {}
    //  class B extends A {}
    //  class C with B {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    classC.mixins = <InterfaceType> [classB.type];
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    expect(typeC.isMoreSpecificThan(typeA), isTrue);
  }

  void test_isMoreSpecificThan_transitive_recursive() {
    //
    //  class A extends B {}
    //  class B extends A {}
    //  class C {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    classA.supertype = classB.type;
    expect(typeA.isMoreSpecificThan(typeC), isFalse);
  }

  void test_isMoreSpecificThan_transitive_superclass() {
    //
    //  class A {}
    //  class B extends A {}
    //  class C extends B {}
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElement classC = ElementFactory.classElement("C", classB.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    expect(typeC.isMoreSpecificThan(typeA), isTrue);
  }

  void test_isMoreSpecificThan_typeParameterType() {
    //
    // class A<E> {}
    //
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    InterfaceType typeA = classA.type;
    TypeParameterType parameterType = classA.typeParameters[0].type;
    DartType objectType = _typeProvider.objectType;
    expect(parameterType.isMoreSpecificThan(objectType), isTrue);
    expect(parameterType.isMoreSpecificThan(typeA), isFalse);
  }

  void test_isMoreSpecificThan_typeParameterType_withBound() {
    //
    // class A {}
    // class B<E extends A> {}
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    TypeParameterElementImpl parameterEA = new TypeParameterElementImpl.forNode(AstFactory.identifier3("E"));
    TypeParameterType parameterAEType = new TypeParameterTypeImpl(parameterEA);
    parameterEA.bound = typeA;
    parameterEA.type = parameterAEType;
    classB.typeParameters = <TypeParameterElementImpl> [parameterEA];
    expect(parameterAEType.isMoreSpecificThan(typeA), isTrue);
  }

  void test_isSubtypeOf_directSubtype() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    expect(typeB.isSubtypeOf(typeA), isTrue);
    expect(typeA.isSubtypeOf(typeB), isFalse);
  }

  void test_isSubtypeOf_dynamic() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    DartType dynamicType = DynamicTypeImpl.instance;
    expect(dynamicType.isSubtypeOf(typeA), isTrue);
    expect(typeA.isSubtypeOf(dynamicType), isTrue);
  }

  void test_isSubtypeOf_function() {
    //
    // void f(String s) {}
    // class A {
    //   void call(String s) {}
    // }
    //
    InterfaceType stringType = _typeProvider.stringType;
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.methods = <MethodElement> [ElementFactory.methodElement("call", VoidTypeImpl.instance, [stringType])];
    FunctionType functionType = ElementFactory.functionElement5("f", <ClassElement> [stringType.element]).type;
    expect(classA.type.isSubtypeOf(functionType), isTrue);
  }

  void test_isSubtypeOf_generic() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classB = ElementFactory.classElement2("B", []);
    DartType dynamicType = DynamicTypeImpl.instance;
    InterfaceType typeAOfDynamic = classA.type.substitute4(<DartType> [dynamicType]);
    InterfaceType typeAOfB = classA.type.substitute4(<DartType> [classB.type]);
    expect(typeAOfDynamic.isSubtypeOf(typeAOfB), isTrue);
    expect(typeAOfB.isSubtypeOf(typeAOfDynamic), isTrue);
  }

  void test_isSubtypeOf_interface() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classC.interfaces = <InterfaceType> [typeB];
    expect(typeC.isSubtypeOf(typeB), isTrue);
    expect(typeC.isSubtypeOf(typeObject), isTrue);
    expect(typeC.isSubtypeOf(typeA), isTrue);
    expect(typeA.isSubtypeOf(typeC), isFalse);
  }

  void test_isSubtypeOf_mixins() {
    //
    // class A {}
    // class B extends A {}
    // class C with B {}
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classC.mixins = <InterfaceType> [typeB];
    expect(typeC.isSubtypeOf(typeB), isTrue);
    expect(typeC.isSubtypeOf(typeObject), isTrue);
    expect(typeC.isSubtypeOf(typeA), isTrue);
    expect(typeA.isSubtypeOf(typeC), isFalse);
  }

  void test_isSubtypeOf_object() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeObject = classA.supertype;
    expect(typeA.isSubtypeOf(typeObject), isTrue);
    expect(typeObject.isSubtypeOf(typeA), isFalse);
  }

  void test_isSubtypeOf_self() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    expect(typeA.isSubtypeOf(typeA), isTrue);
  }

  void test_isSubtypeOf_transitive_recursive() {
    //
    //  class A extends B {}
    //  class B extends A {}
    //  class C {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    classA.supertype = classB.type;
    expect(typeA.isSubtypeOf(typeC), isFalse);
  }

  void test_isSubtypeOf_transitive_superclass() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElement classC = ElementFactory.classElement("C", classB.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    expect(typeC.isSubtypeOf(typeA), isTrue);
    expect(typeA.isSubtypeOf(typeC), isFalse);
  }

  void test_isSubtypeOf_typeArguments() {
    DartType dynamicType = DynamicTypeImpl.instance;
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classI = ElementFactory.classElement2("I", []);
    ClassElement classJ = ElementFactory.classElement("J", classI.type, []);
    ClassElement classK = ElementFactory.classElement2("K", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeA_dynamic = typeA.substitute4(<DartType> [dynamicType]);
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl.con1(classA);
    InterfaceTypeImpl typeAJ = new InterfaceTypeImpl.con1(classA);
    InterfaceTypeImpl typeAK = new InterfaceTypeImpl.con1(classA);
    typeAI.typeArguments = <DartType> [classI.type];
    typeAJ.typeArguments = <DartType> [classJ.type];
    typeAK.typeArguments = <DartType> [classK.type];
    // A<J> <: A<I> since J <: I
    expect(typeAJ.isSubtypeOf(typeAI), isTrue);
    expect(typeAI.isSubtypeOf(typeAJ), isFalse);
    // A<I> <: A<I> since I <: I
    expect(typeAI.isSubtypeOf(typeAI), isTrue);
    // A <: A<I> and A <: A<J>
    expect(typeA_dynamic.isSubtypeOf(typeAI), isTrue);
    expect(typeA_dynamic.isSubtypeOf(typeAJ), isTrue);
    // A<I> <: A and A<J> <: A
    expect(typeAI.isSubtypeOf(typeA_dynamic), isTrue);
    expect(typeAJ.isSubtypeOf(typeA_dynamic), isTrue);
    // A<I> !<: A<K> and A<K> !<: A<I>
    expect(typeAI.isSubtypeOf(typeAK), isFalse);
    expect(typeAK.isSubtypeOf(typeAI), isFalse);
  }

  void test_isSubtypeOf_typeParameter() {
    //
    // class A<E> {}
    //
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    InterfaceType typeA = classA.type;
    TypeParameterType parameterType = classA.typeParameters[0].type;
    expect(typeA.isSubtypeOf(parameterType), isFalse);
  }

  void test_isSupertypeOf_directSupertype() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    expect(typeB.isSupertypeOf(typeA), isFalse);
    expect(typeA.isSupertypeOf(typeB), isTrue);
  }

  void test_isSupertypeOf_dynamic() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    DartType dynamicType = DynamicTypeImpl.instance;
    expect(dynamicType.isSupertypeOf(typeA), isTrue);
    expect(typeA.isSupertypeOf(dynamicType), isTrue);
  }

  void test_isSupertypeOf_indirectSupertype() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElement classC = ElementFactory.classElement("C", classB.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    expect(typeC.isSupertypeOf(typeA), isFalse);
    expect(typeA.isSupertypeOf(typeC), isTrue);
  }

  void test_isSupertypeOf_interface() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classC.interfaces = <InterfaceType> [typeB];
    expect(typeB.isSupertypeOf(typeC), isTrue);
    expect(typeObject.isSupertypeOf(typeC), isTrue);
    expect(typeA.isSupertypeOf(typeC), isTrue);
    expect(typeC.isSupertypeOf(typeA), isFalse);
  }

  void test_isSupertypeOf_mixins() {
    //
    // class A {}
    // class B extends A {}
    // class C with B {}
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classC.mixins = <InterfaceType> [typeB];
    expect(typeB.isSupertypeOf(typeC), isTrue);
    expect(typeObject.isSupertypeOf(typeC), isTrue);
    expect(typeA.isSupertypeOf(typeC), isTrue);
    expect(typeC.isSupertypeOf(typeA), isFalse);
  }

  void test_isSupertypeOf_object() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeObject = classA.supertype;
    expect(typeA.isSupertypeOf(typeObject), isFalse);
    expect(typeObject.isSupertypeOf(typeA), isTrue);
  }

  void test_isSupertypeOf_self() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    expect(typeA.isSupertypeOf(typeA), isTrue);
  }

  void test_lookUpGetter_implemented() {
    //
    // class A { g {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getterG = ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement> [getterG];
    InterfaceType typeA = classA.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(typeA.lookUpGetter(getterName, library), same(getterG));
  }

  void test_lookUpGetter_inherited() {
    //
    // class A { g {} }
    // class B extends A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getterG = ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement> [getterG];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeB = classB.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(typeB.lookUpGetter(getterName, library), same(getterG));
  }

  void test_lookUpGetter_recursive() {
    //
    // class A extends B {}
    // class B extends A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement("B", typeA, []);
    classA.supertype = classB.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(typeA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpGetter_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(typeA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpMethod_implemented() {
    //
    // class A { m() {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [methodM];
    InterfaceType typeA = classA.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(typeA.lookUpMethod(methodName, library), same(methodM));
  }

  void test_lookUpMethod_inherited() {
    //
    // class A { m() {} }
    // class B extends A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [methodM];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeB = classB.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(typeB.lookUpMethod(methodName, library), same(methodM));
  }

  void test_lookUpMethod_parameterized() {
    //
    // class A<E> { E m(E p) {} }
    // class B<F> extends A<F> {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", ["E"]);
    DartType typeE = classA.type.typeArguments[0];
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, typeE, [typeE]);
    classA.methods = <MethodElement> [methodM];
    (methodM.type as FunctionTypeImpl).typeArguments = classA.type.typeArguments;
    ClassElementImpl classB = ElementFactory.classElement2("B", ["F"]);
    InterfaceType typeB = classB.type;
    InterfaceTypeImpl typeAF = new InterfaceTypeImpl.con1(classA);
    typeAF.typeArguments = <DartType> [typeB.typeArguments[0]];
    classB.supertype = typeAF;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    //
    // B<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I", []).type;
    InterfaceTypeImpl typeBI = new InterfaceTypeImpl.con1(classB);
    typeBI.typeArguments = <DartType> [typeI];
    MethodElement method = typeBI.lookUpMethod(methodName, library);
    expect(method, isNotNull);
    FunctionType methodType = method.type;
    expect(methodType.returnType, same(typeI));
    List<DartType> parameterTypes = methodType.normalParameterTypes;
    expect(parameterTypes, hasLength(1));
    expect(parameterTypes[0], same(typeI));
  }

  void test_lookUpMethod_recursive() {
    //
    // class A extends B {}
    // class B extends A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement("B", typeA, []);
    classA.supertype = classB.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(typeA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpMethod_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(typeA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpSetter_implemented() {
    //
    // class A { s(x) {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setterS = ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement> [setterS];
    InterfaceType typeA = classA.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(typeA.lookUpSetter(setterName, library), same(setterS));
  }

  void test_lookUpSetter_inherited() {
    //
    // class A { s(x) {} }
    // class B extends A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "g";
    PropertyAccessorElement setterS = ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement> [setterS];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeB = classB.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(typeB.lookUpSetter(setterName, library), same(setterS));
  }

  void test_lookUpSetter_recursive() {
    //
    // class A extends B {}
    // class B extends A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement("B", typeA, []);
    classA.supertype = classB.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    expect(typeA.lookUpSetter("s", library), isNull);
  }

  void test_lookUpSetter_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    expect(typeA.lookUpSetter("s", library), isNull);
  }

  void test_setTypeArguments() {
    InterfaceTypeImpl type = ElementFactory.classElement2("A", []).type as InterfaceTypeImpl;
    List<DartType> typeArguments = <DartType> [
        ElementFactory.classElement2("B", []).type,
        ElementFactory.classElement2("C", []).type];
    type.typeArguments = typeArguments;
    expect(type.typeArguments, typeArguments);
  }

  void test_substitute_equal() {
    ClassElement classAE = ElementFactory.classElement2("A", ["E"]);
    InterfaceType typeAE = classAE.type;
    InterfaceType argumentType = ElementFactory.classElement2("B", []).type;
    List<DartType> args = [argumentType];
    List<DartType> params = [classAE.typeParameters[0].type];
    InterfaceType typeAESubbed = typeAE.substitute2(args, params);
    expect(typeAESubbed.element, classAE);
    List<DartType> resultArguments = typeAESubbed.typeArguments;
    expect(resultArguments, hasLength(1));
    expect(resultArguments[0], argumentType);
  }

  void test_substitute_exception() {
    try {
      ClassElementImpl classA = ElementFactory.classElement2("A", []);
      InterfaceTypeImpl type = new InterfaceTypeImpl.con1(classA);
      InterfaceType argumentType = ElementFactory.classElement2("B", []).type;
      type.substitute2(<DartType> [argumentType], <DartType> []);
      fail("Expected to encounter exception, argument and parameter type array lengths not equal.");
    } catch (e) {
      // Expected result
    }
  }

  void test_substitute_notEqual() {
    // The [test_substitute_equals] above has a slightly higher level implementation.
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    TypeParameterElementImpl parameterElement = new TypeParameterElementImpl.forNode(AstFactory.identifier3("E"));
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(classA);
    TypeParameterTypeImpl parameter = new TypeParameterTypeImpl(parameterElement);
    type.typeArguments = <DartType> [parameter];
    InterfaceType argumentType = ElementFactory.classElement2("B", []).type;
    TypeParameterTypeImpl parameterType = new TypeParameterTypeImpl(new TypeParameterElementImpl.forNode(AstFactory.identifier3("F")));
    InterfaceType result = type.substitute2(<DartType> [argumentType], <DartType> [parameterType]);
    expect(result.element, classA);
    List<DartType> resultArguments = result.typeArguments;
    expect(resultArguments, hasLength(1));
    expect(resultArguments[0], parameter);
  }
}

class InterfaceTypeImpl_FunctionTypeImplTest_test_isSubtypeOf_baseCase_classFunction extends InterfaceTypeImpl {
  InterfaceTypeImpl_FunctionTypeImplTest_test_isSubtypeOf_baseCase_classFunction(ClassElement arg0) : super.con1(arg0);

  @override
  bool get isDartCoreFunction => true;
}

class LibraryElementImplTest extends EngineTestCase {
  void test_creation() {
    expect(new LibraryElementImpl.forNode(createAnalysisContext(), AstFactory.libraryIdentifier2(["l"])), isNotNull);
  }

  void test_getImportedLibraries() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library1 = ElementFactory.library(context, "l1");
    LibraryElementImpl library2 = ElementFactory.library(context, "l2");
    LibraryElementImpl library3 = ElementFactory.library(context, "l3");
    LibraryElementImpl library4 = ElementFactory.library(context, "l4");
    PrefixElement prefixA = new PrefixElementImpl.forNode(AstFactory.identifier3("a"));
    PrefixElement prefixB = new PrefixElementImpl.forNode(AstFactory.identifier3("b"));
    List<ImportElementImpl> imports = [
        ElementFactory.importFor(library2, null, []),
        ElementFactory.importFor(library2, prefixB, []),
        ElementFactory.importFor(library3, null, []),
        ElementFactory.importFor(library3, prefixA, []),
        ElementFactory.importFor(library3, prefixB, []),
        ElementFactory.importFor(library4, prefixA, [])];
    library1.imports = imports;
    List<LibraryElement> libraries = library1.importedLibraries;
    expect(libraries, unorderedEquals(<LibraryElement> [library2, library3, library4]));
  }

  void test_getPrefixes() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "l1");
    PrefixElement prefixA = new PrefixElementImpl.forNode(AstFactory.identifier3("a"));
    PrefixElement prefixB = new PrefixElementImpl.forNode(AstFactory.identifier3("b"));
    List<ImportElementImpl> imports = [
        ElementFactory.importFor(ElementFactory.library(context, "l2"), null, []),
        ElementFactory.importFor(ElementFactory.library(context, "l3"), null, []),
        ElementFactory.importFor(ElementFactory.library(context, "l4"), prefixA, []),
        ElementFactory.importFor(ElementFactory.library(context, "l5"), prefixA, []),
        ElementFactory.importFor(ElementFactory.library(context, "l6"), prefixB, [])];
    library.imports = imports;
    List<PrefixElement> prefixes = library.prefixes;
    expect(prefixes, hasLength(2));
    if (identical(prefixA, prefixes[0])) {
      expect(prefixes[1], same(prefixB));
    } else {
      expect(prefixes[0], same(prefixB));
      expect(prefixes[1], same(prefixA));
    }
  }

  void test_getUnits() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "test");
    CompilationUnitElement unitLib = library.definingCompilationUnit;
    CompilationUnitElementImpl unitA = ElementFactory.compilationUnit("unit_a.dart");
    CompilationUnitElementImpl unitB = ElementFactory.compilationUnit("unit_b.dart");
    library.parts = <CompilationUnitElement> [unitA, unitB];
    expect(library.units, unorderedEquals(<CompilationUnitElement> [unitLib, unitA, unitB]));
  }

  void test_getVisibleLibraries_cycle() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "app");
    LibraryElementImpl libraryA = ElementFactory.library(context, "A");
    libraryA.imports = <ImportElementImpl> [ElementFactory.importFor(library, null, [])];
    library.imports = <ImportElementImpl> [ElementFactory.importFor(libraryA, null, [])];
    List<LibraryElement> libraries = library.visibleLibraries;
    expect(libraries, unorderedEquals(<LibraryElement> [library, libraryA]));
  }

  void test_getVisibleLibraries_directExports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "app");
    LibraryElementImpl libraryA = ElementFactory.library(context, "A");
    library.exports = <ExportElementImpl> [ElementFactory.exportFor(libraryA, [])];
    List<LibraryElement> libraries = library.visibleLibraries;
    expect(libraries, unorderedEquals(<LibraryElement> [library]));
  }

  void test_getVisibleLibraries_directImports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "app");
    LibraryElementImpl libraryA = ElementFactory.library(context, "A");
    library.imports = <ImportElementImpl> [ElementFactory.importFor(libraryA, null, [])];
    List<LibraryElement> libraries = library.visibleLibraries;
    expect(libraries, unorderedEquals(<LibraryElement> [library, libraryA]));
  }

  void test_getVisibleLibraries_indirectExports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "app");
    LibraryElementImpl libraryA = ElementFactory.library(context, "A");
    LibraryElementImpl libraryAA = ElementFactory.library(context, "AA");
    libraryA.exports = <ExportElementImpl> [ElementFactory.exportFor(libraryAA, [])];
    library.imports = <ImportElementImpl> [ElementFactory.importFor(libraryA, null, [])];
    List<LibraryElement> libraries = library.visibleLibraries;
    expect(libraries, unorderedEquals(<LibraryElement> [library, libraryA, libraryAA]));
  }

  void test_getVisibleLibraries_indirectImports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "app");
    LibraryElementImpl libraryA = ElementFactory.library(context, "A");
    LibraryElementImpl libraryAA = ElementFactory.library(context, "AA");
    LibraryElementImpl libraryB = ElementFactory.library(context, "B");
    libraryA.imports = <ImportElementImpl> [ElementFactory.importFor(libraryAA, null, [])];
    library.imports = <ImportElementImpl> [
        ElementFactory.importFor(libraryA, null, []),
        ElementFactory.importFor(libraryB, null, [])];
    List<LibraryElement> libraries = library.visibleLibraries;
    expect(libraries, unorderedEquals(<LibraryElement> [library, libraryA, libraryAA, libraryB]));
  }

  void test_getVisibleLibraries_noImports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "app");
    expect(library.visibleLibraries, unorderedEquals(<LibraryElement> [library]));
  }

  void test_isUpToDate() {
    AnalysisContext context = createAnalysisContext();
    context.sourceFactory = new SourceFactory([]);
    LibraryElement library = ElementFactory.library(context, "foo");
    context.setContents(library.definingCompilationUnit.source, "sdfsdff");
    // Assert that we are not up to date if the target has an old time stamp.
    expect(library.isUpToDate(0), isFalse);
    // Assert that we are up to date with a target modification time in the future.
    expect(library.isUpToDate(JavaSystem.currentTimeMillis() + 1000), isTrue);
  }

  void test_setImports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = new LibraryElementImpl.forNode(context, AstFactory.libraryIdentifier2(["l1"]));
    List<ImportElementImpl> expectedImports = [
        ElementFactory.importFor(ElementFactory.library(context, "l2"), null, []),
        ElementFactory.importFor(ElementFactory.library(context, "l3"), null, [])];
    library.imports = expectedImports;
    List<ImportElement> actualImports = library.imports;
    expect(actualImports, hasLength(expectedImports.length));
    for (int i = 0; i < actualImports.length; i++) {
      expect(actualImports[i], same(expectedImports[i]));
    }
  }
}

class MultiplyDefinedElementImplTest extends EngineTestCase {
  void test_fromElements_conflicting() {
    Element firstElement = ElementFactory.localVariableElement2("xx");
    Element secondElement = ElementFactory.localVariableElement2("yy");
    Element result = MultiplyDefinedElementImpl.fromElements(null, firstElement, secondElement);
    EngineTestCase.assertInstanceOf((obj) => obj is MultiplyDefinedElement, MultiplyDefinedElement, result);
    List<Element> elements = (result as MultiplyDefinedElement).conflictingElements;
    expect(elements, hasLength(2));
    for (int i = 0; i < elements.length; i++) {
      EngineTestCase.assertInstanceOf((obj) => obj is LocalVariableElement, LocalVariableElement, elements[i]);
    }
  }

  void test_fromElements_multiple() {
    Element firstElement = ElementFactory.localVariableElement2("xx");
    Element secondElement = ElementFactory.localVariableElement2("yy");
    Element thirdElement = ElementFactory.localVariableElement2("zz");
    Element result = MultiplyDefinedElementImpl.fromElements(null, MultiplyDefinedElementImpl.fromElements(null, firstElement, secondElement), thirdElement);
    EngineTestCase.assertInstanceOf((obj) => obj is MultiplyDefinedElement, MultiplyDefinedElement, result);
    List<Element> elements = (result as MultiplyDefinedElement).conflictingElements;
    expect(elements, hasLength(3));
    for (int i = 0; i < elements.length; i++) {
      EngineTestCase.assertInstanceOf((obj) => obj is LocalVariableElement, LocalVariableElement, elements[i]);
    }
  }

  void test_fromElements_nonConflicting() {
    Element element = ElementFactory.localVariableElement2("xx");
    expect(MultiplyDefinedElementImpl.fromElements(null, element, element), same(element));
  }
}

class TypeParameterTypeImplTest extends EngineTestCase {
  void test_creation() {
    expect(new TypeParameterTypeImpl(new TypeParameterElementImpl.forNode(AstFactory.identifier3("E"))), isNotNull);
  }

  void test_getElement() {
    TypeParameterElementImpl element = new TypeParameterElementImpl.forNode(AstFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    expect(type.element, element);
  }

  void test_isMoreSpecificThan_typeArguments_dynamic() {
    TypeParameterElementImpl element = new TypeParameterElementImpl.forNode(AstFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    // E << dynamic
    expect(type.isMoreSpecificThan(DynamicTypeImpl.instance), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_object() {
    TypeParameterElementImpl element = new TypeParameterElementImpl.forNode(AstFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    // E << Object
    expect(type.isMoreSpecificThan(ElementFactory.object.type), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_resursive() {
    ClassElementImpl classS = ElementFactory.classElement2("A", []);
    TypeParameterElementImpl typeParameterU = new TypeParameterElementImpl.forNode(AstFactory.identifier3("U"));
    TypeParameterTypeImpl typeParameterTypeU = new TypeParameterTypeImpl(typeParameterU);
    TypeParameterElementImpl typeParameterT = new TypeParameterElementImpl.forNode(AstFactory.identifier3("T"));
    TypeParameterTypeImpl typeParameterTypeT = new TypeParameterTypeImpl(typeParameterT);
    typeParameterT.bound = typeParameterTypeU;
    typeParameterU.bound = typeParameterTypeU;
    // <T extends U> and <U extends T>
    // T << S
    expect(typeParameterTypeT.isMoreSpecificThan(classS.type), isFalse);
  }

  void test_isMoreSpecificThan_typeArguments_self() {
    TypeParameterElementImpl element = new TypeParameterElementImpl.forNode(AstFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    // E << E
    expect(type.isMoreSpecificThan(type), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_transitivity_interfaceTypes() {
    //  class A {}
    //  class B extends A {}
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    TypeParameterElementImpl typeParameterT = new TypeParameterElementImpl.forNode(AstFactory.identifier3("T"));
    typeParameterT.bound = typeB;
    TypeParameterTypeImpl typeParameterTypeT = new TypeParameterTypeImpl(typeParameterT);
    // <T extends B>
    // T << A
    expect(typeParameterTypeT.isMoreSpecificThan(typeA), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_transitivity_typeParameters() {
    ClassElementImpl classS = ElementFactory.classElement2("A", []);
    TypeParameterElementImpl typeParameterU = new TypeParameterElementImpl.forNode(AstFactory.identifier3("U"));
    typeParameterU.bound = classS.type;
    TypeParameterTypeImpl typeParameterTypeU = new TypeParameterTypeImpl(typeParameterU);
    TypeParameterElementImpl typeParameterT = new TypeParameterElementImpl.forNode(AstFactory.identifier3("T"));
    typeParameterT.bound = typeParameterTypeU;
    TypeParameterTypeImpl typeParameterTypeT = new TypeParameterTypeImpl(typeParameterT);
    // <T extends U> and <U extends S>
    // T << S
    expect(typeParameterTypeT.isMoreSpecificThan(classS.type), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_upperBound() {
    ClassElementImpl classS = ElementFactory.classElement2("A", []);
    TypeParameterElementImpl typeParameterT = new TypeParameterElementImpl.forNode(AstFactory.identifier3("T"));
    typeParameterT.bound = classS.type;
    TypeParameterTypeImpl typeParameterTypeT = new TypeParameterTypeImpl(typeParameterT);
    // <T extends S>
    // T << S
    expect(typeParameterTypeT.isMoreSpecificThan(classS.type), isTrue);
  }

  void test_substitute_equal() {
    TypeParameterElementImpl element = new TypeParameterElementImpl.forNode(AstFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    InterfaceTypeImpl argument = new InterfaceTypeImpl.con1(new ClassElementImpl.forNode(AstFactory.identifier3("A")));
    TypeParameterTypeImpl parameter = new TypeParameterTypeImpl(element);
    expect(type.substitute2(<DartType> [argument], <DartType> [parameter]), same(argument));
  }

  void test_substitute_notEqual() {
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(new TypeParameterElementImpl.forNode(AstFactory.identifier3("E")));
    InterfaceTypeImpl argument = new InterfaceTypeImpl.con1(new ClassElementImpl.forNode(AstFactory.identifier3("A")));
    TypeParameterTypeImpl parameter = new TypeParameterTypeImpl(new TypeParameterElementImpl.forNode(AstFactory.identifier3("F")));
    expect(type.substitute2(<DartType> [argument], <DartType> [parameter]), same(type));
  }
}

class UnionTypeImplTest extends EngineTestCase {
  ClassElement _classA;

  InterfaceType _typeA;

  ClassElement _classB;

  InterfaceType _typeB;

  DartType _uA;

  DartType _uB;

  DartType _uAB;

  DartType _uBA;

  List<DartType> _us;

  void test_emptyUnionsNotAllowed() {
    try {
      UnionTypeImpl.union([]);
    } on IllegalArgumentException catch (e) {
      return;
    }
    fail("Expected illegal argument exception.");
  }

  void test_equality_beingASubtypeOfAnElementIsNotSufficient() {
    // Non-equal if some elements are different
    expect(_uAB == _uA, isFalse);
  }

  void test_equality_insertionOrderDoesntMatter() {
    // Insertion order doesn't matter, only sets of elements
    expect(_uAB == _uBA, isTrue);
    expect(_uBA == _uAB, isTrue);
  }

  void test_equality_reflexivity() {
    for (DartType u in _us) {
      expect(u == u, isTrue);
    }
  }

  void test_equality_singletonsCollapse() {
    expect(_typeA == _uA, isTrue);
    expect(_uA == _typeA, isTrue);
  }

  void test_isMoreSpecificThan_allElementsOnLHSAreSubtypesOfSomeElementOnRHS() {
    // Unions are subtypes when all elements are subtypes
    expect(_uAB.isMoreSpecificThan(_uA), isTrue);
    expect(_uAB.isMoreSpecificThan(_typeA), isTrue);
  }

  void test_isMoreSpecificThan_element() {
    // Elements of union are sub types
    expect(_typeA.isMoreSpecificThan(_uAB), isTrue);
    expect(_typeB.isMoreSpecificThan(_uAB), isTrue);
  }

  void test_isMoreSpecificThan_notSubtypeOfAnyElement() {
    // Types that are not subtypes of elements are not subtypes
    expect(_typeA.isMoreSpecificThan(_uB), isFalse);
  }

  void test_isMoreSpecificThan_reflexivity() {
    for (DartType u in _us) {
      expect(u.isMoreSpecificThan(u), isTrue);
    }
  }

  void test_isMoreSpecificThan_someElementOnLHSIsNotASubtypeOfAnyElementOnRHS() {
    // Unions are subtypes when some element is a subtype
    expect(_uAB.isMoreSpecificThan(_uB), isTrue);
    expect(_uAB.isMoreSpecificThan(_typeB), isTrue);
  }

  void test_isMoreSpecificThan_subtypeOfSomeElement() {
    // Subtypes of elements are sub types
    expect(_typeB.isMoreSpecificThan(_uA), isTrue);
  }

  void test_isSubtypeOf_allElementsOnLHSAreSubtypesOfSomeElementOnRHS() {
    // Unions are subtypes when all elements are subtypes
    expect(_uAB.isSubtypeOf(_uA), isTrue);
    expect(_uAB.isSubtypeOf(_typeA), isTrue);
  }

  void test_isSubtypeOf_element() {
    // Elements of union are sub types
    expect(_typeA.isSubtypeOf(_uAB), isTrue);
    expect(_typeB.isSubtypeOf(_uAB), isTrue);
  }

  void test_isSubtypeOf_notSubtypeOfAnyElement() {
    // Types that are not subtypes of elements are not subtypes
    expect(_typeA.isSubtypeOf(_uB), isFalse);
  }

  void test_isSubtypeOf_reflexivity() {
    for (DartType u in _us) {
      expect(u.isSubtypeOf(u), isTrue);
    }
  }

  void test_isSubtypeOf_someElementOnLHSIsNotASubtypeOfAnyElementOnRHS() {
    // Unions are subtypes when some element is a subtype
    expect(_uAB.isSubtypeOf(_uB), isTrue);
    expect(_uAB.isSubtypeOf(_typeB), isTrue);
  }

  void test_isSubtypeOf_subtypeOfSomeElement() {
    // Subtypes of elements are sub types
    expect(_typeB.isSubtypeOf(_uA), isTrue);
  }

  void test_nestedUnionsCollapse() {
    UnionType u = UnionTypeImpl.union([_uAB, _typeA]) as UnionType;
    for (DartType t in u.elements) {
      if (t is UnionType) {
        fail("Expected only non-union types but found $t!");
      }
    }
  }

  void test_noLossage() {
    UnionType u = UnionTypeImpl.union([_typeA, _typeB, _typeB, _typeA, _typeB, _typeB]) as UnionType;
    Set<DartType> elements = u.elements;
    expect(elements.contains(_typeA), isTrue);
    expect(elements.contains(_typeB), isTrue);
    expect(elements.length == 2, isTrue);
  }

  void test_substitute() {
    // Based on [InterfaceTypeImplTest.test_substitute_equal].
    ClassElement classAE = ElementFactory.classElement2("A", ["E"]);
    InterfaceType typeAE = classAE.type;
    List<DartType> args = [_typeB];
    List<DartType> params = [classAE.typeParameters[0].type];
    DartType typeAESubbed = typeAE.substitute2(args, params);
    expect(typeAE == typeAESubbed, isFalse);
    expect(UnionTypeImpl.union([_typeA, typeAESubbed]), UnionTypeImpl.union([_typeA, typeAE]).substitute2(args, params));
  }

  void test_toString_pair() {
    String s = _uAB.toString();
    expect(s == "{A,B}" || s == "{B,A}", isTrue);
    expect(_uAB.displayName, s);
  }

  void test_toString_singleton() {
    // Singleton unions collapse to the the single type.
    expect(_uA.toString(), "A");
  }

  void test_unionTypeIsLessSpecificThan_function() {
    // Based on [FunctionTypeImplTest.test_isAssignableTo_normalAndPositionalArgs].
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    DartType uAT = UnionTypeImpl.union([_uA, t]);
    expect(t.isMoreSpecificThan(uAT), isTrue);
    expect(t.isMoreSpecificThan(_uAB), isFalse);
  }

  void test_unionTypeIsSuperTypeOf_function() {
    // Based on [FunctionTypeImplTest.test_isAssignableTo_normalAndPositionalArgs].
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    DartType uAT = UnionTypeImpl.union([_uA, t]);
    expect(t.isSubtypeOf(uAT), isTrue);
    expect(t.isSubtypeOf(_uAB), isFalse);
  }

  @override
  void setUp() {
    super.setUp();
    _classA = ElementFactory.classElement2("A", []);
    _typeA = _classA.type;
    _classB = ElementFactory.classElement("B", _typeA, []);
    _typeB = _classB.type;
    _uA = UnionTypeImpl.union([_typeA]);
    _uB = UnionTypeImpl.union([_typeB]);
    _uAB = UnionTypeImpl.union([_typeA, _typeB]);
    _uBA = UnionTypeImpl.union([_typeB, _typeA]);
    _us = <DartType> [_uA, _uB, _uAB, _uBA];
  }
}

class VoidTypeImplTest extends EngineTestCase {
  /**
   * Reference {code VoidTypeImpl.getInstance()}.
   */
  DartType _voidType = VoidTypeImpl.instance;

  void test_isMoreSpecificThan_void_A() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    expect(_voidType.isMoreSpecificThan(classA.type), isFalse);
  }

  void test_isMoreSpecificThan_void_dynamic() {
    expect(_voidType.isMoreSpecificThan(DynamicTypeImpl.instance), isTrue);
  }

  void test_isMoreSpecificThan_void_void() {
    expect(_voidType.isMoreSpecificThan(_voidType), isTrue);
  }

  void test_isSubtypeOf_void_A() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    expect(_voidType.isSubtypeOf(classA.type), isFalse);
  }

  void test_isSubtypeOf_void_dynamic() {
    expect(_voidType.isSubtypeOf(DynamicTypeImpl.instance), isTrue);
  }

  void test_isSubtypeOf_void_void() {
    expect(_voidType.isSubtypeOf(_voidType), isTrue);
  }

  void test_isVoid() {
    expect(_voidType.isVoid, isTrue);
  }
}

main() {
  groupSep = ' | ';
  runReflectiveTests(AngularPropertyKindTest);
  runReflectiveTests(ElementKindTest);
  runReflectiveTests(FunctionTypeImplTest);
  runReflectiveTests(InterfaceTypeImplTest);
  runReflectiveTests(TypeParameterTypeImplTest);
  runReflectiveTests(UnionTypeImplTest);
  runReflectiveTests(VoidTypeImplTest);
  runReflectiveTests(ClassElementImplTest);
  runReflectiveTests(CompilationUnitElementImplTest);
  runReflectiveTests(ElementLocationImplTest);
  runReflectiveTests(ElementImplTest);
  runReflectiveTests(HtmlElementImplTest);
  runReflectiveTests(LibraryElementImplTest);
  runReflectiveTests(MultiplyDefinedElementImplTest);
}