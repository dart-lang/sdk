// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/test_analysis_context.dart';
import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementAnnotationImplTest);
    defineReflectiveTests(FieldElementImplTest);
    defineReflectiveTests(FunctionTypeImplTest);
    defineReflectiveTests(InterfaceTypeImplTest);
    defineReflectiveTests(TypeParameterTypeImplTest);
    defineReflectiveTests(VoidTypeImplTest);
    defineReflectiveTests(ClassElementImplTest);
    defineReflectiveTests(CompilationUnitElementImplTest);
    defineReflectiveTests(ElementLocationImplTest);
    defineReflectiveTests(ElementImplTest);
    defineReflectiveTests(LibraryElementImplTest);
    defineReflectiveTests(TopLevelVariableElementImplTest);
    defineReflectiveTests(UniqueLocationTest);
  });
}

class AbstractTypeTest with ElementsTypesMixin {
  TestAnalysisContext _analysisContext;

  @override
  LibraryElementImpl testLibrary;

  @override
  TypeProvider typeProvider;

  TypeSystemImpl typeSystem;

  void setUp() {
    _analysisContext = TestAnalysisContext();
    typeProvider = _analysisContext.typeProviderLegacy;
    typeSystem = _analysisContext.typeSystemLegacy;

    testLibrary = library_(
      uriStr: 'package:test/test.dart',
      analysisSession: _analysisContext.analysisSession,
      typeSystem: typeSystem,
    );
  }
}

@reflectiveTest
class ClassElementImplTest extends AbstractTypeTest {
  void test_getField() {
    var classA = class_(name: 'A');
    String fieldName = "f";
    FieldElementImpl field =
        ElementFactory.fieldElement(fieldName, false, false, false, null);
    classA.fields = <FieldElement>[field];
    expect(classA.getField(fieldName), same(field));
    expect(field.isEnumConstant, false);
    // no such field
    expect(classA.getField("noSuchField"), same(null));
  }

  void test_getMethod_declared() {
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[method];
    expect(classA.getMethod(methodName), same(method));
  }

  void test_getMethod_undeclared() {
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[method];
    expect(classA.getMethod("${methodName}x"), isNull);
  }

  void test_hasNonFinalField_false_const() {
    var classA = class_(name: 'A');
    classA.fields = <FieldElement>[
      ElementFactory.fieldElement(
          "f", false, false, true, interfaceTypeStar(classA))
    ];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_final() {
    var classA = class_(name: 'A');
    classA.fields = <FieldElement>[
      ElementFactory.fieldElement(
          "f", false, true, false, interfaceTypeStar(classA))
    ];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_recursive() {
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.supertype = interfaceTypeStar(classB);
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_true_immediate() {
    var classA = class_(name: 'A');
    classA.fields = <FieldElement>[
      ElementFactory.fieldElement(
          "f", false, false, false, interfaceTypeStar(classA))
    ];
    expect(classA.hasNonFinalField, isTrue);
  }

  void test_hasNonFinalField_true_inherited() {
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.fields = <FieldElement>[
      ElementFactory.fieldElement(
          "f", false, false, false, interfaceTypeStar(classA))
    ];
    expect(classB.hasNonFinalField, isTrue);
  }

  void test_hasStaticMember_false_empty() {
    var classA = class_(name: 'A');
    // no members
    expect(classA.hasStaticMember, isFalse);
  }

  void test_hasStaticMember_false_instanceMethod() {
    var classA = class_(name: 'A');
    MethodElement method = ElementFactory.methodElement("foo", null);
    classA.methods = <MethodElement>[method];
    expect(classA.hasStaticMember, isFalse);
  }

  void test_hasStaticMember_instanceGetter() {
    var classA = class_(name: 'A');
    PropertyAccessorElement getter =
        ElementFactory.getterElement("foo", false, null);
    classA.accessors = <PropertyAccessorElement>[getter];
    expect(classA.hasStaticMember, isFalse);
  }

  void test_hasStaticMember_true_getter() {
    var classA = class_(name: 'A');
    PropertyAccessorElementImpl getter =
        ElementFactory.getterElement("foo", false, null);
    classA.accessors = <PropertyAccessorElement>[getter];
    // "foo" is static
    getter.isStatic = true;
    expect(classA.hasStaticMember, isTrue);
  }

  void test_hasStaticMember_true_method() {
    var classA = class_(name: 'A');
    MethodElementImpl method = ElementFactory.methodElement("foo", null);
    classA.methods = <MethodElement>[method];
    // "foo" is static
    method.isStatic = true;
    expect(classA.hasStaticMember, isTrue);
  }

  void test_hasStaticMember_true_setter() {
    var classA = class_(name: 'A');
    PropertyAccessorElementImpl setter =
        ElementFactory.setterElement("foo", false, null);
    classA.accessors = <PropertyAccessorElement>[setter];
    // "foo" is static
    setter.isStatic = true;
    expect(classA.hasStaticMember, isTrue);
  }

  void test_lookUpConcreteMethod_declared() {
    // class A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpConcreteMethod(methodName, library), same(method));
  }

  void test_lookUpConcreteMethod_declaredAbstract() {
    // class A {
    //   m();
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElementImpl method = ElementFactory.methodElement(methodName, null);
    method.isAbstract = true;
    classA.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpConcreteMethod(methodName, library), isNull);
  }

  void test_lookUpConcreteMethod_declaredAbstractAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m();
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    MethodElementImpl method = ElementFactory.methodElement(methodName, null);
    method.isAbstract = true;
    classB.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpConcreteMethod_declaredAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classB.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library), same(method));
  }

  void test_lookUpConcreteMethod_declaredAndInheritedAbstract() {
    // abstract class A {
    //   m();
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    classA.isAbstract = true;
    String methodName = "m";
    MethodElementImpl inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    inheritedMethod.isAbstract = true;
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classB.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library), same(method));
  }

  void test_lookUpConcreteMethod_inherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpConcreteMethod_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpConcreteMethod("m", library), isNull);
  }

  void test_lookUpGetter_declared() {
    // class A {
    //   get g {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String getterName = "g";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[getter];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpGetter(getterName, library), same(getter));
  }

  void test_lookUpGetter_inherited() {
    // class A {
    //   get g {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String getterName = "g";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[getter];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpGetter(getterName, library), same(getter));
  }

  void test_lookUpGetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpGetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.supertype = interfaceTypeStar(classB);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpInheritedConcreteGetter_declared() {
    // class A {
    //   get g {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String getterName = "g";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[getter];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedConcreteGetter(getterName, library), isNull);
  }

  void test_lookUpInheritedConcreteGetter_inherited() {
    // class A {
    //   get g {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String getterName = "g";
    PropertyAccessorElement inheritedGetter =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[inheritedGetter];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedConcreteGetter(getterName, library),
        same(inheritedGetter));
  }

  void test_lookUpInheritedConcreteGetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedConcreteGetter("g", library), isNull);
  }

  void test_lookUpInheritedConcreteGetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.supertype = interfaceTypeStar(classB);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classA.lookUpInheritedConcreteGetter("g", library), isNull);
  }

  void test_lookUpInheritedConcreteMethod_declared() {
    // class A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedConcreteMethod(methodName, library), isNull);
  }

  void test_lookUpInheritedConcreteMethod_declaredAbstractAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m();
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    MethodElementImpl method = ElementFactory.methodElement(methodName, null);
    method.isAbstract = true;
    classB.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedConcreteMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpInheritedConcreteMethod_declaredAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classB.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedConcreteMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpInheritedConcreteMethod_declaredAndInheritedAbstract() {
    // abstract class A {
    //   m();
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    classA.isAbstract = true;
    String methodName = "m";
    MethodElementImpl inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    inheritedMethod.isAbstract = true;
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classB.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedConcreteMethod(methodName, library), isNull);
  }

  void
      test_lookUpInheritedConcreteMethod_declaredAndInheritedWithAbstractBetween() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m();
    // }
    // class C extends B {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    MethodElementImpl abstractMethod =
        ElementFactory.methodElement(methodName, null);
    abstractMethod.isAbstract = true;
    classB.methods = <MethodElement>[abstractMethod];
    ClassElementImpl classC =
        ElementFactory.classElement("C", interfaceTypeStar(classB));
    MethodElementImpl method = ElementFactory.methodElement(methodName, null);
    classC.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB, classC];
    expect(classC.lookUpInheritedConcreteMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpInheritedConcreteMethod_inherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedConcreteMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpInheritedConcreteMethod_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedConcreteMethod("m", library), isNull);
  }

  void test_lookUpInheritedConcreteSetter_declared() {
    // class A {
    //   set g(x) {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String setterName = "s";
    PropertyAccessorElement setter =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setter];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedConcreteSetter(setterName, library), isNull);
  }

  void test_lookUpInheritedConcreteSetter_inherited() {
    // class A {
    //   set g(x) {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String setterName = "s";
    PropertyAccessorElement setter =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setter];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedConcreteSetter(setterName, library),
        same(setter));
  }

  void test_lookUpInheritedConcreteSetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedConcreteSetter("s", library), isNull);
  }

  void test_lookUpInheritedConcreteSetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.supertype = interfaceTypeStar(classB);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classA.lookUpInheritedConcreteSetter("s", library), isNull);
  }

  void test_lookUpInheritedMethod_declared() {
    // class A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedMethod(methodName, library), isNull);
  }

  void test_lookUpInheritedMethod_declaredAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classB.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpInheritedMethod_inherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpInheritedMethod_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedMethod("m", library), isNull);
  }

  void test_lookUpMethod_declared() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpMethod(methodName, library), same(method));
  }

  void test_lookUpMethod_inherited() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[method];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpMethod(methodName, library), same(method));
  }

  void test_lookUpMethod_undeclared() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpMethod_undeclared_recursive() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.supertype = interfaceTypeStar(classB);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpSetter_declared() {
    // class A {
    //   set g(x) {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String setterName = "s";
    PropertyAccessorElement setter =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setter];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpSetter(setterName, library), same(setter));
  }

  void test_lookUpSetter_inherited() {
    // class A {
    //   set g(x) {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String setterName = "s";
    PropertyAccessorElement setter =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setter];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpSetter(setterName, library), same(setter));
  }

  void test_lookUpSetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpSetter("s", library), isNull);
  }

  void test_lookUpSetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.supertype = interfaceTypeStar(classB);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classA.lookUpSetter("s", library), isNull);
  }

  LibraryElementImpl _newLibrary() => ElementFactory.library(null, 'lib');
}

@reflectiveTest
class CompilationUnitElementImplTest {
  void test_getType_declared() {
    CompilationUnitElementImpl unit =
        ElementFactory.compilationUnit("/lib.dart");
    String className = "C";
    ClassElement classElement = ElementFactory.classElement2(className);
    unit.types = <ClassElement>[classElement];
    expect(unit.getType(className), same(classElement));
  }

  void test_getType_undeclared() {
    CompilationUnitElementImpl unit =
        ElementFactory.compilationUnit("/lib.dart");
    String className = "C";
    ClassElement classElement = ElementFactory.classElement2(className);
    unit.types = <ClassElement>[classElement];
    expect(unit.getType("${className}x"), isNull);
  }
}

@reflectiveTest
class ElementAnnotationImplTest extends PubPackageResolutionTest {
  test_computeConstantValue() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  final String f;
  const A(this.f);
}
void f(@A('x') int p) {}
''');
    await resolveTestCode(r'''
import 'a.dart';
main() {
  f(3);
}
''');
    var argument = findNode.integerLiteral('3');
    ParameterElement parameter = argument.staticParameterElement;

    ElementAnnotation annotation = parameter.metadata[0];

    DartObject value = annotation.computeConstantValue();
    expect(value, isNotNull);
    expect(value.getField('f').toStringValue(), 'x');
  }
}

@reflectiveTest
class ElementImplTest extends AbstractTypeTest {
  void test_equals() {
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    ClassElementImpl classElement = ElementFactory.classElement2("C");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    FieldElement field = ElementFactory.fieldElement(
      "next",
      false,
      false,
      false,
      classElement.instantiate(
        typeArguments: [],
        nullabilitySuffix: NullabilitySuffix.star,
      ),
    );
    classElement.fields = <FieldElement>[field];
    expect(field == field, isTrue);
    // ignore: unrelated_type_equality_checks
    expect(field == field.getter, isFalse);
    // ignore: unrelated_type_equality_checks
    expect(field == field.setter, isFalse);
    expect(field.getter == field.setter, isFalse);
  }

  void test_isAccessibleIn_private_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(_analysisContext, "lib1");
    ClassElement classElement = ElementFactory.classElement2("_C");
    (library1.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(_analysisContext, "lib2");
    expect(classElement.isAccessibleIn(library2), isFalse);
  }

  void test_isAccessibleIn_private_sameLibrary() {
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    ClassElement classElement = ElementFactory.classElement2("_C");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    expect(classElement.isAccessibleIn(library), isTrue);
  }

  void test_isAccessibleIn_public_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(_analysisContext, "lib1");
    ClassElement classElement = ElementFactory.classElement2("C");
    (library1.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(_analysisContext, "lib2");
    expect(classElement.isAccessibleIn(library2), isTrue);
  }

  void test_isAccessibleIn_public_sameLibrary() {
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    ClassElement classElement = ElementFactory.classElement2("C");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    expect(classElement.isAccessibleIn(library), isTrue);
  }

  void test_isPrivate_false() {
    Element element = ElementFactory.classElement2("C");
    expect(element.isPrivate, isFalse);
  }

  void test_isPrivate_null() {
    Element element = ElementFactory.classElement2(null);
    expect(element.isPrivate, isTrue);
  }

  void test_isPrivate_true() {
    Element element = ElementFactory.classElement2("_C");
    expect(element.isPrivate, isTrue);
  }

  void test_isPublic_false() {
    Element element = ElementFactory.classElement2("_C");
    expect(element.isPublic, isFalse);
  }

  void test_isPublic_null() {
    Element element = ElementFactory.classElement2(null);
    expect(element.isPublic, isFalse);
  }

  void test_isPublic_true() {
    Element element = ElementFactory.classElement2("C");
    expect(element.isPublic, isTrue);
  }

  void test_SORT_BY_OFFSET() {
    ClassElementImpl classElementA = class_(name: 'A');
    classElementA.nameOffset = 1;
    ClassElementImpl classElementB = ElementFactory.classElement2("B");
    classElementB.nameOffset = 2;
    expect(Element.SORT_BY_OFFSET(classElementA, classElementA), 0);
    expect(Element.SORT_BY_OFFSET(classElementA, classElementB) < 0, isTrue);
    expect(Element.SORT_BY_OFFSET(classElementB, classElementA) > 0, isTrue);
  }
}

@reflectiveTest
class ElementLocationImplTest {
  void test_create_encoding() {
    String encoding = "a;b;c";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  /// For example unnamed constructor.
  void test_create_encoding_emptyLast() {
    String encoding = "a;b;c;";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  void test_equals_equal() {
    String encoding = "a;b;c";
    ElementLocationImpl first = ElementLocationImpl.con2(encoding);
    ElementLocationImpl second = ElementLocationImpl.con2(encoding);
    expect(first == second, isTrue);
  }

  void test_equals_notEqual_differentLengths() {
    ElementLocationImpl first = ElementLocationImpl.con2("a;b;c");
    ElementLocationImpl second = ElementLocationImpl.con2("a;b;c;d");
    expect(first == second, isFalse);
  }

  void test_equals_notEqual_notLocation() {
    ElementLocationImpl first = ElementLocationImpl.con2("a;b;c");
    // ignore: unrelated_type_equality_checks
    expect(first == "a;b;d", isFalse);
  }

  void test_equals_notEqual_sameLengths() {
    ElementLocationImpl first = ElementLocationImpl.con2("a;b;c");
    ElementLocationImpl second = ElementLocationImpl.con2("a;b;d");
    expect(first == second, isFalse);
  }

  void test_getComponents() {
    String encoding = "a;b;c";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    List<String> components = location.components;
    expect(components, hasLength(3));
    expect(components[0], "a");
    expect(components[1], "b");
    expect(components[2], "c");
  }

  void test_getEncoding() {
    String encoding = "a;b;c;;d";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  void test_hashCode_equal() {
    String encoding = "a;b;c";
    ElementLocationImpl first = ElementLocationImpl.con2(encoding);
    ElementLocationImpl second = ElementLocationImpl.con2(encoding);
    expect(first.hashCode == second.hashCode, isTrue);
  }
}

@reflectiveTest
class FieldElementImplTest extends PubPackageResolutionTest {
  test_isEnumConstant() async {
    await resolveTestCode(r'''
enum B {B1, B2, B3}
''');
    var B = findElement.enum_('B');

    FieldElement b2Element = B.getField('B2');
    expect(b2Element.isEnumConstant, isTrue);

    FieldElement indexElement = B.getField('index');
    expect(indexElement.isEnumConstant, isFalse);
  }
}

@reflectiveTest
class FunctionTypeImplTest extends AbstractTypeTest {
  void assertType(DartType type, String expected) {
    var typeStr = type.getDisplayString(withNullability: false);
    expect(typeStr, expected);
  }

  void test_getNamedParameterTypes_namedParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        requiredParameter(name: 'a', type: intNone),
        namedParameter(name: 'b', type: doubleNone),
        namedParameter(name: 'c', type: stringNone),
      ],
      returnType: voidNone,
    );
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(2));
    expect(types['b'], doubleNone);
    expect(types['c'], stringNone);
  }

  void test_getNamedParameterTypes_noNamedParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        requiredParameter(type: intNone),
        requiredParameter(type: doubleNone),
        positionalParameter(type: stringNone),
      ],
      returnType: voidNone,
    );
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNamedParameterTypes_noParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [],
      returnType: voidNone,
    );
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_noNormalParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        positionalParameter(type: intNone),
        positionalParameter(type: doubleNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_noParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [],
      returnType: voidNone,
    );
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_normalParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        requiredParameter(type: intNone),
        requiredParameter(type: doubleNone),
        positionalParameter(type: stringNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(2));
    expect(types[0], intNone);
    expect(types[1], doubleNone);
  }

  void test_getOptionalParameterTypes_noOptionalParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        requiredParameter(name: 'a', type: intNone),
        namedParameter(name: 'b', type: doubleNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getOptionalParameterTypes_noParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [],
      returnType: voidNone,
    );
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getOptionalParameterTypes_optionalParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        requiredParameter(type: intNone),
        positionalParameter(type: doubleNone),
        positionalParameter(type: stringNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(2));
    expect(types[0], doubleNone);
    expect(types[1], stringNone);
  }

  void test_resolveToBound() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [],
      returnType: voidNone,
    );

    // Returns this.
    expect(type.resolveToBound(null), same(type));
  }
}

@reflectiveTest
class InterfaceTypeImplTest extends AbstractTypeTest {
  void test_allSupertypes() {
    void check(InterfaceType type, List<String> expected) {
      var actual = type.allSupertypes.map((e) {
        return e.getDisplayString(
          withNullability: true,
        );
      }).toList()
        ..sort();
      expect(actual, expected);
    }

    check(objectNone, []);
    check(numNone, ['Comparable<num>', 'Object']);
    check(intNone, ['Comparable<num>', 'Object', 'num']);
    check(listNone(intQuestion), ['Iterable<int?>', 'Object']);
  }

  test_asInstanceOf_explicitGeneric() {
    // class A<E> {}
    // class B implements A<C> {}
    // class C {}
    var A = class_(name: 'A', typeParameters: [
      typeParameter('E'),
    ]);
    var B = class_(name: 'B');
    var C = class_(name: 'C');

    var AofC = A.instantiate(
      typeArguments: [
        interfaceTypeStar(C),
      ],
      nullabilitySuffix: NullabilitySuffix.star,
    );

    B.interfaces = <InterfaceType>[AofC];

    InterfaceTypeImpl targetType = interfaceTypeStar(B);
    InterfaceType result = targetType.asInstanceOf(A);
    expect(result, AofC);
  }

  test_asInstanceOf_passThroughGeneric() {
    // class A<E> {}
    // class B<E> implements A<E> {}
    // class C {}
    var AE = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [AE]);

    var BE = typeParameter('E');
    var B = class_(
      name: 'B',
      typeParameters: [BE],
      interfaces: [
        A.instantiate(
          typeArguments: [typeParameterTypeStar(BE)],
          nullabilitySuffix: NullabilitySuffix.star,
        ),
      ],
    );

    var C = class_(name: 'C');

    InterfaceTypeImpl targetType = B.instantiate(
      typeArguments: [interfaceTypeStar(C)],
      nullabilitySuffix: NullabilitySuffix.star,
    );
    InterfaceType result = targetType.asInstanceOf(A);
    expect(
      result,
      A.instantiate(
        typeArguments: [interfaceTypeStar(C)],
        nullabilitySuffix: NullabilitySuffix.star,
      ),
    );
  }

  void test_creation() {
    expect(interfaceTypeStar(class_(name: 'A')), isNotNull);
  }

  void test_getAccessors() {
    ClassElementImpl typeElement = class_(name: 'A');
    PropertyAccessorElement getterG =
        ElementFactory.getterElement("g", false, null);
    PropertyAccessorElement getterH =
        ElementFactory.getterElement("h", false, null);
    typeElement.accessors = <PropertyAccessorElement>[getterG, getterH];
    InterfaceTypeImpl type = interfaceTypeStar(typeElement);
    expect(type.accessors.length, 2);
  }

  void test_getAccessors_empty() {
    ClassElementImpl typeElement = class_(name: 'A');
    InterfaceTypeImpl type = interfaceTypeStar(typeElement);
    expect(type.accessors.length, 0);
  }

  void test_getConstructors() {
    ClassElementImpl typeElement = class_(name: 'A');
    ConstructorElementImpl constructorOne =
        ElementFactory.constructorElement(typeElement, 'one', false);
    ConstructorElementImpl constructorTwo =
        ElementFactory.constructorElement(typeElement, 'two', false);
    typeElement.constructors = <ConstructorElement>[
      constructorOne,
      constructorTwo
    ];
    InterfaceTypeImpl type = interfaceTypeStar(typeElement);
    expect(type.constructors, hasLength(2));
  }

  void test_getConstructors_empty() {
    ClassElementImpl typeElement = class_(name: 'A');
    typeElement.constructors = const <ConstructorElement>[];
    InterfaceTypeImpl type = interfaceTypeStar(typeElement);
    expect(type.constructors, isEmpty);
  }

  void test_getElement() {
    ClassElementImpl typeElement = class_(name: 'A');
    InterfaceTypeImpl type = interfaceTypeStar(typeElement);
    expect(type.element, typeElement);
  }

  void test_getGetter_implemented() {
    //
    // class A { g {} }
    //
    var classA = class_(name: 'A');
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[getterG];
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getGetter(getterName), same(getterG));
  }

  void test_getGetter_parameterized() {
    //
    // class A<E> { E get g {} }
    //
    var AE = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [AE]);

    DartType typeAE = typeParameterTypeStar(AE);
    String getterName = "g";
    PropertyAccessorElementImpl getterG =
        ElementFactory.getterElement(getterName, false, typeAE);
    A.accessors = <PropertyAccessorElement>[getterG];
    //
    // A<I>
    //
    InterfaceType I = interfaceTypeStar(class_(name: 'I'));
    InterfaceTypeImpl AofI = A.instantiate(
      typeArguments: [I],
      nullabilitySuffix: NullabilitySuffix.star,
    );

    PropertyAccessorElement getter = AofI.getGetter(getterName);
    expect(getter, isNotNull);
    FunctionType getterType = getter.type;
    expect(getterType.returnType, same(I));
  }

  void test_getGetter_unimplemented() {
    //
    // class A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getGetter("g"), isNull);
  }

  void test_getInterfaces_nonParameterized() {
    //
    // class C implements A, B
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    var classB = ElementFactory.classElement2("B");
    InterfaceType typeB = interfaceTypeStar(classB);
    var classC = ElementFactory.classElement2("C");
    classC.interfaces = <InterfaceType>[typeA, typeB];
    List<InterfaceType> interfaces = interfaceTypeStar(classC).interfaces;
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
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);
    var F = typeParameter('F');
    var B = class_(
      name: 'B',
      typeParameters: [F],
      interfaces: [
        A.instantiate(
          typeArguments: [typeParameterTypeStar(F)],
          nullabilitySuffix: NullabilitySuffix.star,
        )
      ],
    );
    //
    // B<I>
    //
    InterfaceType typeI = interfaceTypeStar(class_(name: 'I'));
    InterfaceTypeImpl typeBI = interfaceTypeStar(B, typeArguments: [typeI]);

    List<InterfaceType> interfaces = typeBI.interfaces;
    expect(interfaces, hasLength(1));
    InterfaceType result = interfaces[0];
    expect(result.element, same(A));
    expect(result.typeArguments[0], same(typeI));
  }

  void test_getMethod_implemented() {
    //
    // class A { m() {} }
    //
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[methodM];
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getMethod(methodName), same(methodM));
  }

  void test_getMethod_parameterized_usesTypeParameter() {
    //
    // class A<E> { E m(E p) {} }
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);
    DartType typeE = typeParameterTypeStar(E);
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeE, [typeE]);
    A.methods = <MethodElement>[methodM];
    //
    // A<I>
    //
    InterfaceType typeI = interfaceTypeStar(class_(name: 'I'));
    InterfaceTypeImpl typeAI =
        interfaceTypeStar(A, typeArguments: <DartType>[typeI]);
    MethodElement method = typeAI.getMethod(methodName);
    expect(method, isNotNull);
    FunctionType methodType = method.type;
    expect(methodType.typeArguments, isEmpty);
    expect(methodType.returnType, same(typeI));
    List<DartType> parameterTypes = methodType.normalParameterTypes;
    expect(parameterTypes, hasLength(1));
    expect(parameterTypes[0], same(typeI));
  }

  void test_getMethod_unimplemented() {
    //
    // class A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getMethod("m"), isNull);
  }

  void test_getMethods() {
    ClassElementImpl typeElement = class_(name: 'A');
    MethodElementImpl methodOne = ElementFactory.methodElement("one", null);
    MethodElementImpl methodTwo = ElementFactory.methodElement("two", null);
    typeElement.methods = <MethodElement>[methodOne, methodTwo];
    InterfaceTypeImpl type = interfaceTypeStar(typeElement);
    expect(type.methods.length, 2);
  }

  void test_getMethods_empty() {
    ClassElementImpl typeElement = class_(name: 'A');
    InterfaceTypeImpl type = interfaceTypeStar(typeElement);
    expect(type.methods.length, 0);
  }

  void test_getMixins_nonParameterized() {
    //
    // class C extends Object with A, B
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    var classB = ElementFactory.classElement2("B");
    InterfaceType typeB = interfaceTypeStar(classB);
    var classC = ElementFactory.classElement2("C");
    classC.mixins = <InterfaceType>[typeA, typeB];
    List<InterfaceType> interfaces = interfaceTypeStar(classC).mixins;
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
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);

    var F = typeParameter('F');
    var B = class_(
      name: 'B',
      typeParameters: [F],
      mixins: [
        interfaceTypeStar(A, typeArguments: [
          typeParameterTypeStar(F),
        ]),
      ],
    );
    //
    // B<I>
    //
    InterfaceType typeI = interfaceTypeStar(class_(name: 'I'));
    InterfaceTypeImpl typeBI =
        interfaceTypeStar(B, typeArguments: <DartType>[typeI]);
    List<InterfaceType> interfaces = typeBI.mixins;
    expect(interfaces, hasLength(1));
    InterfaceType result = interfaces[0];
    expect(result.element, same(A));
    expect(result.typeArguments[0], same(typeI));
  }

  void test_getSetter_implemented() {
    //
    // class A { s() {} }
    //
    var classA = class_(name: 'A');
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setterS];
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getSetter(setterName), same(setterS));
  }

  void test_getSetter_parameterized() {
    //
    // class A<E> { set s(E p) {} }
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);
    DartType typeE = typeParameterTypeStar(E);
    String setterName = "s";
    PropertyAccessorElementImpl setterS =
        ElementFactory.setterElement(setterName, false, typeE);
    A.accessors = <PropertyAccessorElement>[setterS];
    //
    // A<I>
    //
    InterfaceType typeI = interfaceTypeStar(class_(name: 'I'));
    InterfaceTypeImpl typeAI =
        interfaceTypeStar(A, typeArguments: <DartType>[typeI]);
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
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getSetter("s"), isNull);
  }

  void test_getSuperclass_nonParameterized() {
    //
    // class B extends A
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    var classB = ElementFactory.classElement("B", typeA);
    InterfaceType typeB = interfaceTypeStar(classB);
    expect(typeB.superclass, same(typeA));
  }

  void test_getSuperclass_parameterized() {
    //
    // class A<E>
    // class B<F> extends A<F>
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);

    var F = typeParameter('F');
    var typeF = typeParameterTypeStar(F);

    var B = class_(
      name: 'B',
      typeParameters: [F],
      superType: interfaceTypeStar(A, typeArguments: [typeF]),
    );

    var classB = B;
    //
    // B<I>
    //
    InterfaceType typeI = interfaceTypeStar(class_(name: 'I'));
    InterfaceTypeImpl typeBI =
        interfaceTypeStar(classB, typeArguments: <DartType>[typeI]);
    InterfaceType superclass = typeBI.superclass;
    expect(superclass.element, same(A));
    expect(superclass.typeArguments[0], same(typeI));
  }

  void test_getTypeArguments_empty() {
    InterfaceType type = interfaceTypeStar(ElementFactory.classElement2('A'));
    expect(type.typeArguments, hasLength(0));
  }

  void test_hashCode() {
    ClassElement classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(0 == typeA.hashCode, isFalse);
  }

  @deprecated
  void test_lookUpGetter_implemented() {
    //
    // class A { g {} }
    //
    var classA = class_(name: 'A');
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[getterG];
    InterfaceType typeA = interfaceTypeStar(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpGetter(getterName, library), same(getterG));
  }

  @deprecated
  void test_lookUpGetter_inherited() {
    //
    // class A { g {} }
    // class B extends A {}
    //
    var classA = class_(name: 'A');
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    InterfaceType typeB = interfaceTypeStar(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeB.lookUpGetter(getterName, library), same(getterG));
  }

  @deprecated
  void test_lookUpGetter_mixin_shadowing() {
    //
    // class B {}
    // class M1 { get g {} }
    // class M2 { get g {} }
    // class C extends B with M1, M2 {}
    //
    TestTypeProvider typeProvider = TestTypeProvider();
    String getterName = 'g';
    var classB = class_(name: 'B');
    ClassElementImpl classM1 = ElementFactory.classElement2('M1');
    PropertyAccessorElementImpl getterM1g = ElementFactory.getterElement(
        getterName, false, typeProvider.dynamicType);
    classM1.accessors = <PropertyAccessorElement>[getterM1g];
    ClassElementImpl classM2 = ElementFactory.classElement2('M2');
    PropertyAccessorElementImpl getterM2g = ElementFactory.getterElement(
        getterName, false, typeProvider.dynamicType);
    classM2.accessors = <PropertyAccessorElement>[getterM2g];
    ClassElementImpl classC =
        ElementFactory.classElement('C', interfaceTypeStar(classB));
    classC.mixins = <InterfaceType>[
      interfaceTypeStar(classM1),
      interfaceTypeStar(classM2)
    ];
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElementImpl unit = library.definingCompilationUnit;
    unit.types = <ClassElement>[classB, classM1, classM2, classC];
    expect(
        interfaceTypeStar(classC).lookUpGetter(getterName, library), getterM2g);
  }

  @deprecated
  void test_lookUpGetter_recursive() {
    //
    // class A extends B {}
    // class B extends A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    var classB = ElementFactory.classElement("B", typeA);
    classA.supertype = interfaceTypeStar(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeA.lookUpGetter("g", library), isNull);
  }

  @deprecated
  void test_lookUpGetter_unimplemented() {
    //
    // class A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpGetter("g", library), isNull);
  }

  @deprecated
  void test_lookUpMethod_implemented() {
    //
    // class A { m() {} }
    //
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[methodM];
    InterfaceType typeA = interfaceTypeStar(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpMethod(methodName, library), same(methodM));
  }

  @deprecated
  void test_lookUpMethod_inherited() {
    //
    // class A { m() {} }
    // class B extends A {}
    //
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    InterfaceType typeB = interfaceTypeStar(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeB.lookUpMethod(methodName, library), same(methodM));
  }

  @deprecated
  void test_lookUpMethod_mixin_shadowing() {
    //
    // class B {}
    // class M1 { m() {} }
    // class M2 { m() {} }
    // class C extends B with M1, M2 {}
    //
    String methodName = 'm';
    var classB = class_(name: 'B');
    ClassElementImpl classM1 = ElementFactory.classElement2('M1');
    MethodElementImpl methodM1m =
        ElementFactory.methodElement(methodName, null);
    classM1.methods = <MethodElement>[methodM1m];
    ClassElementImpl classM2 = ElementFactory.classElement2('M2');
    MethodElementImpl methodM2m =
        ElementFactory.methodElement(methodName, null);
    classM2.methods = <MethodElement>[methodM2m];
    ClassElementImpl classC =
        ElementFactory.classElement('C', interfaceTypeStar(classB));
    classC.mixins = <InterfaceType>[
      interfaceTypeStar(classM1),
      interfaceTypeStar(classM2)
    ];
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElementImpl unit = library.definingCompilationUnit;
    unit.types = <ClassElement>[classB, classM1, classM2, classC];
    expect(
        interfaceTypeStar(classC).lookUpMethod(methodName, library), methodM2m);
  }

  @deprecated
  void test_lookUpMethod_parameterized() {
    //
    // class A<E> { E m(E p) {} }
    // class B<F> extends A<F> {}
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);
    DartType typeE = typeParameterTypeStar(E);
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeE, [typeE]);
    A.methods = <MethodElement>[methodM];

    var F = typeParameter('F');
    var B = class_(
      name: 'B',
      typeParameters: [F],
      superType: interfaceTypeStar(A, typeArguments: [
        typeParameterTypeStar(F),
      ]),
    );
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[A];
    //
    // B<I>
    //
    InterfaceType typeI = interfaceTypeStar(class_(name: 'I'));
    InterfaceTypeImpl typeBI =
        interfaceTypeStar(B, typeArguments: <DartType>[typeI]);
    MethodElement method = typeBI.lookUpMethod(methodName, library);
    expect(method, isNotNull);
    FunctionType methodType = method.type;
    expect(methodType.returnType, same(typeI));
    List<DartType> parameterTypes = methodType.normalParameterTypes;
    expect(parameterTypes, hasLength(1));
    expect(parameterTypes[0], same(typeI));
  }

  @deprecated
  void test_lookUpMethod_recursive() {
    //
    // class A extends B {}
    // class B extends A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    var classB = ElementFactory.classElement("B", typeA);
    classA.supertype = interfaceTypeStar(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeA.lookUpMethod("m", library), isNull);
  }

  @deprecated
  void test_lookUpMethod_unimplemented() {
    //
    // class A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpMethod("m", library), isNull);
  }

  @deprecated
  void test_lookUpSetter_implemented() {
    //
    // class A { s(x) {} }
    //
    var classA = class_(name: 'A');
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setterS];
    InterfaceType typeA = interfaceTypeStar(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpSetter(setterName, library), same(setterS));
  }

  @deprecated
  void test_lookUpSetter_inherited() {
    //
    // class A { s(x) {} }
    // class B extends A {}
    //
    var classA = class_(name: 'A');
    String setterName = "g";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setterS];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    InterfaceType typeB = interfaceTypeStar(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeB.lookUpSetter(setterName, library), same(setterS));
  }

  @deprecated
  void test_lookUpSetter_mixin_shadowing() {
    //
    // class B {}
    // class M1 { set s() {} }
    // class M2 { set s() {} }
    // class C extends B with M1, M2 {}
    //
    TestTypeProvider typeProvider = TestTypeProvider();
    String setterName = 's';
    var classB = class_(name: 'B');
    ClassElementImpl classM1 = ElementFactory.classElement2('M1');
    PropertyAccessorElementImpl setterM1g = ElementFactory.setterElement(
        setterName, false, typeProvider.dynamicType);
    classM1.accessors = <PropertyAccessorElement>[setterM1g];
    ClassElementImpl classM2 = ElementFactory.classElement2('M2');
    PropertyAccessorElementImpl setterM2g = ElementFactory.getterElement(
        setterName, false, typeProvider.dynamicType);
    classM2.accessors = <PropertyAccessorElement>[setterM2g];
    ClassElementImpl classC =
        ElementFactory.classElement('C', interfaceTypeStar(classB));
    classC.mixins = <InterfaceType>[
      interfaceTypeStar(classM1),
      interfaceTypeStar(classM2)
    ];
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElementImpl unit = library.definingCompilationUnit;
    unit.types = <ClassElement>[classB, classM1, classM2, classC];
    expect(
        interfaceTypeStar(classC).lookUpGetter(setterName, library), setterM2g);
  }

  @deprecated
  void test_lookUpSetter_recursive() {
    //
    // class A extends B {}
    // class B extends A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    var classB = ElementFactory.classElement("B", typeA);
    classA.supertype = interfaceTypeStar(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeA.lookUpSetter("s", library), isNull);
  }

  @deprecated
  void test_lookUpSetter_unimplemented() {
    //
    // class A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpSetter("s", library), isNull);
  }

  void test_resolveToBound() {
    InterfaceTypeImpl type =
        interfaceTypeStar(ElementFactory.classElement2('A'));

    // Returns this.
    expect(type.resolveToBound(null), same(type));
  }
}

@reflectiveTest
class LibraryElementImplTest {
  void test_getImportedLibraries() {
    AnalysisContext context = TestAnalysisContext();
    LibraryElementImpl library1 = ElementFactory.library(context, "l1");
    LibraryElementImpl library2 = ElementFactory.library(context, "l2");
    LibraryElementImpl library3 = ElementFactory.library(context, "l3");
    LibraryElementImpl library4 = ElementFactory.library(context, "l4");
    PrefixElement prefixA = PrefixElementImpl('a', -1);
    PrefixElement prefixB = PrefixElementImpl('b', -1);
    List<ImportElementImpl> imports = [
      ElementFactory.importFor(library2, null),
      ElementFactory.importFor(library2, prefixB),
      ElementFactory.importFor(library3, null),
      ElementFactory.importFor(library3, prefixA),
      ElementFactory.importFor(library3, prefixB),
      ElementFactory.importFor(library4, prefixA)
    ];
    library1.imports = imports;
    List<LibraryElement> libraries = library1.importedLibraries;
    expect(libraries,
        unorderedEquals(<LibraryElement>[library2, library3, library4]));
  }

  void test_getPrefixes() {
    AnalysisContext context = TestAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "l1");
    PrefixElement prefixA = PrefixElementImpl('a', -1);
    PrefixElement prefixB = PrefixElementImpl('b', -1);
    List<ImportElementImpl> imports = [
      ElementFactory.importFor(ElementFactory.library(context, "l2"), null),
      ElementFactory.importFor(ElementFactory.library(context, "l3"), null),
      ElementFactory.importFor(ElementFactory.library(context, "l4"), prefixA),
      ElementFactory.importFor(ElementFactory.library(context, "l5"), prefixA),
      ElementFactory.importFor(ElementFactory.library(context, "l6"), prefixB)
    ];
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
    AnalysisContext context = TestAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "test");
    CompilationUnitElement unitLib = library.definingCompilationUnit;
    CompilationUnitElementImpl unitA =
        ElementFactory.compilationUnit("unit_a.dart", unitLib.source);
    CompilationUnitElementImpl unitB =
        ElementFactory.compilationUnit("unit_b.dart", unitLib.source);
    library.parts = <CompilationUnitElement>[unitA, unitB];
    expect(library.units,
        unorderedEquals(<CompilationUnitElement>[unitLib, unitA, unitB]));
  }

  void test_setImports() {
    AnalysisContext context = TestAnalysisContext();
    LibraryElementImpl library = LibraryElementImpl(
        context, null, 'l1', -1, 0, FeatureSet.latestLanguageVersion());
    List<ImportElementImpl> expectedImports = [
      ElementFactory.importFor(ElementFactory.library(context, "l2"), null),
      ElementFactory.importFor(ElementFactory.library(context, "l3"), null)
    ];
    library.imports = expectedImports;
    List<ImportElement> actualImports = library.imports;
    expect(actualImports, hasLength(expectedImports.length));
    for (int i = 0; i < actualImports.length; i++) {
      expect(actualImports[i], same(expectedImports[i]));
    }
  }
}

@reflectiveTest
class TopLevelVariableElementImplTest extends PubPackageResolutionTest {
  test_computeConstantValue() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const int C = 42;
''');
    await resolveTestCode(r'''
import 'a.dart';
main() {
  print(C);
}
''');
    SimpleIdentifier argument = findNode.simple('C);');
    PropertyAccessorElementImpl getter = argument.staticElement;
    TopLevelVariableElement constant = getter.variable;

    DartObject value = constant.computeConstantValue();
    expect(value, isNotNull);
    expect(value.toIntValue(), 42);
  }
}

@reflectiveTest
class TypeParameterTypeImplTest extends AbstractTypeTest {
  void test_asInstanceOf_hasBound_element() {
    var T = typeParameter('T', bound: listNone(intNone));
    _assert_asInstanceOf(
      typeParameterTypeNone(T),
      typeProvider.iterableElement,
      'Iterable<int>',
    );
  }

  void test_asInstanceOf_hasBound_element_noMatch() {
    var T = typeParameter('T', bound: numNone);
    _assert_asInstanceOf(
      typeParameterTypeNone(T),
      typeProvider.iterableElement,
      null,
    );
  }

  void test_asInstanceOf_hasBound_promoted() {
    var T = typeParameter('T');
    _assert_asInstanceOf(
      typeParameterTypeNone(
        T,
        promotedBound: listNone(intNone),
      ),
      typeProvider.iterableElement,
      'Iterable<int>',
    );
  }

  void test_asInstanceOf_hasBound_promoted_noMatch() {
    var T = typeParameter('T');
    _assert_asInstanceOf(
      typeParameterTypeNone(
        T,
        promotedBound: numNone,
      ),
      typeProvider.iterableElement,
      null,
    );
  }

  void test_asInstanceOf_noBound() {
    var T = typeParameter('T');
    _assert_asInstanceOf(
      typeParameterTypeNone(T),
      typeProvider.iterableElement,
      null,
    );
  }

  void test_creation() {
    expect(typeParameterTypeStar(TypeParameterElementImpl('E', -1)), isNotNull);
  }

  void test_getElement() {
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    TypeParameterTypeImpl type = typeParameterTypeStar(element);
    expect(type.element, element);
  }

  void test_resolveToBound_bound() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeStar(classS);
    TypeParameterTypeImpl type = typeParameterTypeStar(element);
    expect(type.resolveToBound(null), interfaceTypeStar(classS));
  }

  void test_resolveToBound_bound_nullableInner() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeQuestion(classS);
    TypeParameterTypeImpl type = typeParameterTypeStar(element);
    expect(type.resolveToBound(null), same(element.bound));
  }

  void test_resolveToBound_bound_nullableInnerOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeQuestion(classS);
    TypeParameterTypeImpl type = typeParameterTypeStar(element)
        .withNullability(NullabilitySuffix.question);
    expect(type.resolveToBound(null), same(element.bound));
  }

  void test_resolveToBound_bound_nullableInnerStarOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeQuestion(classS);
    TypeParameterTypeImpl type = typeParameterTypeStar(element)
        .withNullability(NullabilitySuffix.question);
    expect(type.resolveToBound(null), equals(interfaceTypeQuestion(classS)));
  }

  void test_resolveToBound_bound_nullableOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeStar(classS);
    TypeParameterTypeImpl type = typeParameterTypeStar(element)
        .withNullability(NullabilitySuffix.question);
    expect(type.resolveToBound(null), equals(interfaceTypeQuestion(classS)));
  }

  void test_resolveToBound_bound_starInner() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeStar(classS);
    TypeParameterTypeImpl type = typeParameterTypeStar(element);
    expect(type.resolveToBound(null), same(element.bound));
  }

  void test_resolveToBound_bound_starInnerNullableOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeQuestion(classS);
    TypeParameterTypeImpl type =
        typeParameterTypeStar(element).withNullability(NullabilitySuffix.star);
    expect(type.resolveToBound(null), same(element.bound));
  }

  void test_resolveToBound_bound_starOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeStar(classS);
    TypeParameterTypeImpl type =
        typeParameterTypeStar(element).withNullability(NullabilitySuffix.star);
    expect(type.resolveToBound(null), interfaceTypeStar(classS));
  }

  void test_resolveToBound_nestedBound() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl elementE = TypeParameterElementImpl('E', -1);
    elementE.bound = interfaceTypeStar(classS);
    TypeParameterTypeImpl typeE = typeParameterTypeStar(elementE);
    TypeParameterElementImpl elementF = TypeParameterElementImpl('F', -1);
    elementF.bound = typeE;
    TypeParameterTypeImpl typeF = typeParameterTypeStar(elementE);
    expect(typeF.resolveToBound(null), interfaceTypeStar(classS));
  }

  void test_resolveToBound_unbound() {
    TypeParameterTypeImpl type =
        typeParameterTypeStar(TypeParameterElementImpl('E', -1));
    // Returns whatever type is passed to resolveToBound().
    expect(type.resolveToBound(VoidTypeImpl.instance),
        same(VoidTypeImpl.instance));
  }

  void _assert_asInstanceOf(
    DartType type,
    ClassElement element,
    String expected,
  ) {
    var result = (type as TypeImpl).asInstanceOf(element);
    expect(
      result?.getDisplayString(withNullability: true),
      expected,
    );
  }
}

@reflectiveTest
class UniqueLocationTest extends PubPackageResolutionTest {
  test_ambiguous_closure_in_executable() async {
    await resolveTestCode('''
void f() => [() => 0, () => 1];
''');
    expect(findNode.functionExpression('() => 0').declaredElement.location,
        isNot(findNode.functionExpression('() => 1').declaredElement.location));
  }

  test_ambiguous_closure_in_local_variable() async {
    await resolveTestCode('''
void f() {
  var x = [() => 0, () => 1];
}
''');
    expect(findNode.functionExpression('() => 0').declaredElement.location,
        isNot(findNode.functionExpression('() => 1').declaredElement.location));
  }

  test_ambiguous_closure_in_top_level_variable() async {
    await resolveTestCode('''
var x = [() => 0, () => 1];
''');
    expect(findNode.functionExpression('() => 0').declaredElement.location,
        isNot(findNode.functionExpression('() => 1').declaredElement.location));
  }

  test_ambiguous_local_variable_in_executable() async {
    await resolveTestCode('''
f() {
  {
    int x = 0;
  }
  {
    int x = 1;
  }
}
''');
    expect(findNode.variableDeclaration('x = 0').declaredElement.location,
        isNot(findNode.variableDeclaration('x = 1').declaredElement.location));
  }
}

@reflectiveTest
class VoidTypeImplTest extends AbstractTypeTest {
  /// Reference {code VoidTypeImpl.getInstance()}.
  final DartType _voidType = VoidTypeImpl.instance;

  void test_isVoid() {
    expect(_voidType.isVoid, isTrue);
  }

  void test_resolveToBound() {
    // Returns this.
    expect(_voidType.resolveToBound(null), same(_voidType));
  }
}
