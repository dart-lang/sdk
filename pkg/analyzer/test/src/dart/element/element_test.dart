// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/test_analysis_context.dart';
import '../resolution/driver_resolution.dart';

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
    defineReflectiveTests(PropertyAccessorElementImplTest);
    defineReflectiveTests(TopLevelVariableElementImplTest);
  });
}

class AbstractTypeTest with ElementsTypesMixin {
  AnalysisContext _analysisContext;
  TypeProvider _typeProvider;

  TypeProvider get typeProvider => _typeProvider;

  void setUp() {
    _analysisContext = TestAnalysisContext();
    _typeProvider = _analysisContext.typeProvider;
  }
}

@reflectiveTest
class ClassElementImplTest extends AbstractTypeTest {
  void test_getAllSupertypes_interface() {
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    ClassElementImpl elementC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    InterfaceType typeC = interfaceType(elementC);
    elementC.interfaces = <InterfaceType>[typeB];
    List<InterfaceType> supers = elementC.allSupertypes;
    List<InterfaceType> types = new List<InterfaceType>();
    types.addAll(supers);
    expect(types.contains(typeA), isTrue);
    expect(types.contains(typeB), isTrue);
    expect(types.contains(typeObject), isTrue);
    expect(types.contains(typeC), isFalse);
  }

  void test_getAllSupertypes_mixins() {
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    var classC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    InterfaceType typeC = interfaceType(classC);
    classC.mixins = <InterfaceType>[typeB];
    List<InterfaceType> supers = classC.allSupertypes;
    List<InterfaceType> types = new List<InterfaceType>();
    types.addAll(supers);
    expect(types.contains(typeA), isTrue);
    expect(types.contains(typeB), isTrue);
    expect(types.contains(typeObject), isTrue);
    expect(types.contains(typeC), isFalse);
  }

  void test_getAllSupertypes_recursive() {
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceType(classA));
    classA.supertype = interfaceType(classB);
    List<InterfaceType> supers = classB.allSupertypes;
    expect(supers, hasLength(1));
  }

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
          "f", false, false, true, interfaceType(classA))
    ];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_final() {
    var classA = class_(name: 'A');
    classA.fields = <FieldElement>[
      ElementFactory.fieldElement(
          "f", false, true, false, interfaceType(classA))
    ];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_recursive() {
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceType(classA));
    classA.supertype = interfaceType(classB);
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_true_immediate() {
    var classA = class_(name: 'A');
    classA.fields = <FieldElement>[
      ElementFactory.fieldElement(
          "f", false, false, false, interfaceType(classA))
    ];
    expect(classA.hasNonFinalField, isTrue);
  }

  void test_hasNonFinalField_true_inherited() {
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceType(classA));
    classA.fields = <FieldElement>[
      ElementFactory.fieldElement(
          "f", false, false, false, interfaceType(classA))
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

  void test_isEnum() {
    String firstConst = "A";
    String secondConst = "B";
    EnumElementImpl enumE = ElementFactory.enumElement(
        new TestTypeProvider(), "E", [firstConst, secondConst]);

    // E is an enum
    expect(enumE.isEnum, true);

    // A and B are static members
    expect(enumE.getField(firstConst).isEnumConstant, true);
    expect(enumE.getField(secondConst).isEnumConstant, true);
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
    classA.supertype = interfaceType(classB);
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
    classA.supertype = interfaceType(classB);
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
    MethodElementImpl abstractMethod =
        ElementFactory.methodElement(methodName, null);
    abstractMethod.isAbstract = true;
    classB.methods = <MethodElement>[abstractMethod];
    ClassElementImpl classC =
        ElementFactory.classElement("C", interfaceType(classB));
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
    classA.supertype = interfaceType(classB);
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
    classA.supertype = interfaceType(classB);
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
        ElementFactory.classElement("B", interfaceType(classA));
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
        ElementFactory.classElement("B", interfaceType(classA));
    classA.supertype = interfaceType(classB);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classA.lookUpSetter("s", library), isNull);
  }

  LibraryElementImpl _newLibrary() => ElementFactory.library(null, 'lib');
}

@reflectiveTest
class CompilationUnitElementImplTest {
  void test_getEnum_declared() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    CompilationUnitElementImpl unit =
        ElementFactory.compilationUnit("/lib.dart");
    String enumName = "E";
    ClassElement enumElement =
        ElementFactory.enumElement(typeProvider, enumName);
    unit.enums = <ClassElement>[enumElement];
    expect(unit.getEnum(enumName), same(enumElement));
  }

  void test_getEnum_undeclared() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    CompilationUnitElementImpl unit =
        ElementFactory.compilationUnit("/lib.dart");
    String enumName = "E";
    ClassElement enumElement =
        ElementFactory.enumElement(typeProvider, enumName);
    unit.enums = <ClassElement>[enumElement];
    expect(unit.getEnum("${enumName}x"), isNull);
  }

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
class ElementAnnotationImplTest extends DriverResolutionTest {
  test_computeConstantValue() async {
    newFile('/test/lib/a.dart', content: r'''
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
    expect(annotation.constantValue, isNull);

    DartObject value = annotation.computeConstantValue();
    expect(value, isNotNull);
    expect(value.getField('f').toStringValue(), 'x');
    expect(annotation.constantValue, value);
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
    // ignore: unrelated_type_equality_checks
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

@reflectiveTest
class FieldElementImplTest extends DriverResolutionTest {
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
  void test_creation() {
    expect(
        new FunctionTypeImpl(
            new FunctionElementImpl.forNode(AstTestFactory.identifier3("f"))),
        isNotNull);
  }

  void test_equality_recursive() {
    var s = ElementFactory.genericTypeAliasElement('s');
    var t = ElementFactory.genericTypeAliasElement('t');
    var u = ElementFactory.genericTypeAliasElement('u');
    var v = ElementFactory.genericTypeAliasElement('v');
    s.function.returnType = functionTypeAliasType(t);
    t.function.returnType = functionTypeAliasType(s);
    u.function.returnType = functionTypeAliasType(v);
    v.function.returnType = functionTypeAliasType(u);
    // We don't care whether the types compare equal or not.  We just need the
    // computation to terminate.
    expect(
      functionTypeAliasType(s) == functionTypeAliasType(u),
      new TypeMatcher<bool>(),
    );
  }

  void test_getElement() {
    FunctionElementImpl typeElement =
        new FunctionElementImpl.forNode(AstTestFactory.identifier3("f"));
    FunctionTypeImpl type = new FunctionTypeImpl(typeElement);
    expect(type.element, typeElement);
  }

  void test_getNamedParameterTypes_namedParameters() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    FunctionElement element = ElementFactory.functionElementWithParameters(
        'f', VoidTypeImpl.instance, [
      ElementFactory.requiredParameter2('a', typeProvider.intType),
      ElementFactory.requiredParameter('b'),
      ElementFactory.namedParameter2('c', typeProvider.stringType),
      ElementFactory.namedParameter('d')
    ]);
    FunctionTypeImpl type = element.type;
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(2));
    expect(types['c'], typeProvider.stringType);
    expect(types['d'], DynamicTypeImpl.instance);
  }

  void test_getNamedParameterTypes_noNamedParameters() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    FunctionElement element = ElementFactory.functionElementWithParameters(
        'f', VoidTypeImpl.instance, [
      ElementFactory.requiredParameter2('a', typeProvider.intType),
      ElementFactory.requiredParameter('b'),
      ElementFactory.positionalParameter2('c', typeProvider.stringType)
    ]);
    FunctionTypeImpl type = element.type;
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNamedParameterTypes_noParameters() {
    FunctionTypeImpl type = ElementFactory.functionElement('f').type;
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_noNormalParameters() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    FunctionElement element = ElementFactory.functionElementWithParameters(
        'f', VoidTypeImpl.instance, [
      ElementFactory.positionalParameter2('c', typeProvider.stringType),
      ElementFactory.positionalParameter('d')
    ]);
    FunctionTypeImpl type = element.type;
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_noParameters() {
    FunctionTypeImpl type = ElementFactory.functionElement('f').type;
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_normalParameters() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    FunctionElement element = ElementFactory.functionElementWithParameters(
        'f', VoidTypeImpl.instance, [
      ElementFactory.requiredParameter2('a', typeProvider.intType),
      ElementFactory.requiredParameter('b'),
      ElementFactory.positionalParameter2('c', typeProvider.stringType)
    ]);
    FunctionTypeImpl type = element.type;
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(2));
    expect(types[0], typeProvider.intType);
    expect(types[1], DynamicTypeImpl.instance);
  }

  void test_getOptionalParameterTypes_noOptionalParameters() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    FunctionElement element = ElementFactory.functionElementWithParameters(
        'f', VoidTypeImpl.instance, [
      ElementFactory.requiredParameter2('a', typeProvider.intType),
      ElementFactory.requiredParameter('b'),
      ElementFactory.namedParameter2('c', typeProvider.stringType),
      ElementFactory.namedParameter('d')
    ]);
    FunctionTypeImpl type = element.type;
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getOptionalParameterTypes_noParameters() {
    FunctionTypeImpl type = ElementFactory.functionElement('f').type;
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getOptionalParameterTypes_optionalParameters() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    FunctionElement element = ElementFactory.functionElementWithParameters(
        'f', VoidTypeImpl.instance, [
      ElementFactory.requiredParameter2('a', typeProvider.intType),
      ElementFactory.requiredParameter('b'),
      ElementFactory.positionalParameter2('c', typeProvider.stringType),
      ElementFactory.positionalParameter('d')
    ]);
    FunctionTypeImpl type = element.type;
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(2));
    expect(types[0], typeProvider.stringType);
    expect(types[1], DynamicTypeImpl.instance);
  }

  void test_getReturnType() {
    DartType expectedReturnType = VoidTypeImpl.instance;
    FunctionElementImpl functionElement =
        new FunctionElementImpl.forNode(AstTestFactory.identifier3("f"));
    functionElement.returnType = expectedReturnType;
    FunctionTypeImpl type = new FunctionTypeImpl(functionElement);
    DartType returnType = type.returnType;
    expect(returnType, expectedReturnType);
  }

  void test_getTypeArguments() {
    FunctionTypeImpl type = new FunctionTypeImpl(
        new FunctionElementImpl.forNode(AstTestFactory.identifier3("f")));
    List<DartType> types = type.typeArguments;
    expect(types, hasLength(0));
  }

  void test_hashCode_element() {
    FunctionTypeImpl type = new FunctionTypeImpl(
        new FunctionElementImpl.forNode(AstTestFactory.identifier3("f")));
    type.hashCode;
  }

  void test_hashCode_noElement() {
    FunctionTypeImpl type = new FunctionTypeImpl(null);
    type.hashCode;
  }

  void test_hashCode_recursive() {
    var s = ElementFactory.genericTypeAliasElement('s');
    var t = ElementFactory.genericTypeAliasElement('t');
    s.function.returnType = functionTypeAliasType(t);
    t.function.returnType = functionTypeAliasType(s);
    // We don't care what the hash code is.  We just need its computation to
    // terminate.
    expect(functionTypeAliasType(t).hashCode, new TypeMatcher<int>());
  }

  void test_isAssignableTo_normalAndPositionalArgs() {
    // ([a]) -> void <: (a) -> void
    ClassElement a = class_(name: 'A');
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement5("s", <ClassElement>[a]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
    // assignable iff subtype
    // ignore: deprecated_member_use_from_same_package
    expect(t.isAssignableTo(s), isTrue);
    // ignore: deprecated_member_use_from_same_package
    expect(s.isAssignableTo(t), isFalse);
  }

  void test_isSubtypeOf_baseCase_classFunction() {
    // () -> void <: Function
    ClassElementImpl functionElement = ElementFactory.classElement2("Function");
    InterfaceTypeImpl functionType =
        new _FunctionTypeImplTest_isSubtypeOf_baseCase_classFunction(
            functionElement);
    FunctionType f = ElementFactory.functionElement("f").type;
    expect(f.isSubtypeOf(functionType), isTrue);
  }

  void test_isSubtypeOf_baseCase_notFunctionType() {
    // class C
    // ! () -> void <: C
    FunctionType f = ElementFactory.functionElement("f").type;
    InterfaceType t = interfaceType(class_(name: 'C'));
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
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["name"], <ClassElement>[a]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["name"], <ClassElement>[b]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_namedParameters_isNotAssignable() {
    // ! ({name: A}) -> void <: ({name: B}) -> void
    FunctionType t = ElementFactory.functionElement4("t", null, null,
        <String>["name"], <ClassElement>[class_(name: 'A')]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s",
        null,
        null,
        <String>["name"],
        <ClassElement>[ElementFactory.classElement2("B")]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_namedParameters_namesDifferent() {
    // B extends A
    // void t({A name}) {}
    // void s({A diff}) {}
    // ! t <: s
    // ! s <: t
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["name"], <ClassElement>[a]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["diff"], <ClassElement>[b]).type;
    expect(t.isSubtypeOf(s), isFalse);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_namedParameters_orderOfParams() {
    // B extends A
    // ({A: A, B: B}) -> void <: ({B: B, A: A}) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["A", "B"], <ClassElement>[a, b]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["B", "A"], <ClassElement>[b, a]).type;
    expect(t.isSubtypeOf(s), isTrue);
  }

  void test_isSubtypeOf_namedParameters_orderOfParams2() {
    // B extends A
    // ! ({B: B}) -> void <: ({B: B, A: A}) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["B"], <ClassElement>[b]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["B", "A"], <ClassElement>[b, a]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_namedParameters_orderOfParams3() {
    // B extends A
    // ({A: A, B: B}) -> void <: ({A: A}) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["A", "B"], <ClassElement>[a, b]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["B"], <ClassElement>[b]).type;
    expect(t.isSubtypeOf(s), isTrue);
  }

  void test_isSubtypeOf_namedParameters_sHasMoreParams() {
    // B extends A
    // ! ({name: A}) -> void <: ({name: B, name2: B}) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["name"], <ClassElement>[a]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["name", "name2"], <ClassElement>[b, b]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_namedParameters_tHasMoreParams() {
    // B extends A
    // ({name: A, name2: A}) -> void <: ({name: B}) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["name", "name2"], <ClassElement>[a, a]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["name"], <ClassElement>[b]).type;
    expect(t.isSubtypeOf(s), isTrue);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_1() {
    // ([a]) -> void <: (a) -> void
    ClassElement a = class_(name: 'A');
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement5("s", <ClassElement>[a]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_2() {
    // (a, [a]) -> void <: (a) -> void
    ClassElement a = class_(name: 'A');
    FunctionType t = ElementFactory.functionElement6(
        "t", <ClassElement>[a], <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement5("s", <ClassElement>[a]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_3() {
    // ([a]) -> void <: () -> void
    ClassElement a = class_(name: 'A');
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a]).type;
    FunctionType s = ElementFactory.functionElement("s").type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_4() {
    // (a, b, [c, d, e]) -> void <: (a, b, c, [d]) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement2("B");
    ClassElement c = ElementFactory.classElement2("C");
    ClassElement d = ElementFactory.classElement2("D");
    ClassElement e = ElementFactory.classElement2("E");
    FunctionType t = ElementFactory.functionElement6(
        "t", <ClassElement>[a, b], <ClassElement>[c, d, e]).type;
    FunctionType s = ElementFactory.functionElement6(
        "s", <ClassElement>[a, b, c], <ClassElement>[d]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalParameters_isAssignable() {
    // B extends A
    // (a) -> void <: (b) -> void
    // (b) -> void <: (a) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t =
        ElementFactory.functionElement5("t", <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement5("s", <ClassElement>[b]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_normalParameters_isNotAssignable() {
    // ! (a) -> void <: (b) -> void
    FunctionType t =
        ElementFactory.functionElement5("t", <ClassElement>[class_(name: 'A')])
            .type;
    FunctionType s = ElementFactory.functionElement5(
        "s", <ClassElement>[ElementFactory.classElement2("B")]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_normalParameters_sHasMoreParams() {
    // B extends A
    // ! (a) -> void <: (b, b) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t =
        ElementFactory.functionElement5("t", <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement5("s", <ClassElement>[b, b]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_normalParameters_tHasMoreParams() {
    // B extends A
    // ! (a, a) -> void <: (a) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t =
        ElementFactory.functionElement5("t", <ClassElement>[a, a]).type;
    FunctionType s =
        ElementFactory.functionElement5("s", <ClassElement>[b]).type;
    // note, this is a different assertion from the other "tHasMoreParams"
    // tests, this is intentional as it is a difference of the "normal
    // parameters"
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_Object() {
    // () -> void <: Object
    FunctionType f = ElementFactory.functionElement("f").type;
    InterfaceType t = typeProvider.objectType;
    expect(f.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_positionalParameters_isAssignable() {
    // B extends A
    // ([a]) -> void <: ([b]) -> void
    // ([b]) -> void <: ([a]) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement6("s", null, <ClassElement>[b]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_positionalParameters_isNotAssignable() {
    // ! ([a]) -> void <: ([b]) -> void
    FunctionType t = ElementFactory.functionElement6(
        "t", null, <ClassElement>[class_(name: 'A')]).type;
    FunctionType s = ElementFactory.functionElement6(
        "s", null, <ClassElement>[ElementFactory.classElement2("B")]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_positionalParameters_sHasMoreParams() {
    // B extends A
    // ! ([a]) -> void <: ([b, b]) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement6("s", null, <ClassElement>[b, b]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_positionalParameters_tHasMoreParams() {
    // B extends A
    // ([a, a]) -> void <: ([b]) -> void
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a, a]).type;
    FunctionType s =
        ElementFactory.functionElement6("s", null, <ClassElement>[b]).type;
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
    ClassElement a = class_(name: 'A');
    ClassElement b = ElementFactory.classElement('B', interfaceType(a));
    FunctionType t =
        ElementFactory.functionElement2("t", interfaceType(a)).type;
    FunctionType s =
        ElementFactory.functionElement2("s", interfaceType(b)).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_returnType_tNotAssignableToS() {
    // ! () -> A <: () -> B
    FunctionType t = ElementFactory.functionElement2(
            "t", interfaceType(ElementFactory.classElement2('A')))
        .type;
    FunctionType s =
        ElementFactory.functionElement2("s", interfaceType(class_(name: 'B')))
            .type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_typeParameters_matchesBounds() {
    TestTypeProvider provider = new TestTypeProvider();
    InterfaceType boolType = provider.boolType;
    InterfaceType stringType = provider.stringType;
    TypeParameterElementImpl parameterB =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("B"));
    parameterB.bound = boolType;
    TypeParameterTypeImpl typeB = new TypeParameterTypeImpl(parameterB);
    TypeParameterElementImpl parameterS =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("S"));
    parameterS.bound = stringType;
    TypeParameterTypeImpl typeS = new TypeParameterTypeImpl(parameterS);
    FunctionElementImpl functionAliasElement =
        new FunctionElementImpl.forNode(AstTestFactory.identifier3("func"));
    functionAliasElement.parameters = <ParameterElement>[
      ElementFactory.requiredParameter2("a", typeB),
      ElementFactory.positionalParameter2("b", typeS)
    ];
    functionAliasElement.returnType = stringType;
    FunctionTypeImpl functionAliasType =
        new FunctionTypeImpl(functionAliasElement);
    functionAliasElement.type = functionAliasType;
    FunctionElementImpl functionElement =
        new FunctionElementImpl.forNode(AstTestFactory.identifier3("f"));
    functionElement.parameters = <ParameterElement>[
      ElementFactory.requiredParameter2("c", boolType),
      ElementFactory.positionalParameter2("d", stringType)
    ];
    functionElement.returnType = provider.dynamicType;
    FunctionTypeImpl functionType = new FunctionTypeImpl(functionElement);
    functionElement.type = functionType;
    expect(functionType.isAssignableTo(functionAliasType), isTrue);
  }

  void test_isSubtypeOf_wrongFunctionType_normal_named() {
    // ! (a) -> void <: ({name: A}) -> void
    // ! ({name: A}) -> void <: (a) -> void
    ClassElement a = class_(name: 'A');
    FunctionType t =
        ElementFactory.functionElement5("t", <ClassElement>[a]).type;
    FunctionType s = ElementFactory.functionElement7(
        "s", null, <String>["name"], <ClassElement>[a]).type;
    expect(t.isSubtypeOf(s), isFalse);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_wrongFunctionType_optional_named() {
    // ! ([a]) -> void <: ({name: A}) -> void
    // ! ({name: A}) -> void <: ([a]) -> void
    ClassElement a = class_(name: 'A');
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a]).type;
    FunctionType s = ElementFactory.functionElement7(
        "s", null, <String>["name"], <ClassElement>[a]).type;
    expect(t.isSubtypeOf(s), isFalse);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_newPrune_non_typedef() {
    // No pruning needs to be done for function types that aren't associated
    // with typedefs because those types can't be directly referred to by the
    // user (and hence can't participate in circularities).
    FunctionElementImpl f = ElementFactory.functionElement('f');
    FunctionTypeImpl type = f.type;
    expect(type.newPrune, isNull);
  }

  void test_resolveToBound() {
    FunctionElementImpl f = ElementFactory.functionElement('f');
    FunctionTypeImpl type = f.type;

    // Returns this.
    expect(type.resolveToBound(null), same(type));
  }

  void test_substitute2_equal() {
    ClassElementImpl definingClass = ElementFactory.classElement2("C", ["E"]);
    TypeParameterType parameterType =
        typeParameterType(definingClass.typeParameters[0]);
    MethodElementImpl functionElement =
        new MethodElementImpl.forNode(AstTestFactory.identifier3("m"));
    String namedParameterName = "c";
    functionElement.parameters = <ParameterElement>[
      ElementFactory.requiredParameter2("a", parameterType),
      ElementFactory.positionalParameter2("b", parameterType),
      ElementFactory.namedParameter2(namedParameterName, parameterType)
    ];
    functionElement.returnType = parameterType;
    definingClass.methods = <MethodElement>[functionElement];
    FunctionTypeImpl functionType = new FunctionTypeImpl(functionElement);
    InterfaceTypeImpl argumentType = new InterfaceTypeImpl(
        new ClassElementImpl.forNode(AstTestFactory.identifier3("D")));
    FunctionType result = functionType
        .substitute2(<DartType>[argumentType], <DartType>[parameterType]);
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
    DartType returnType = new InterfaceTypeImpl(
        new ClassElementImpl.forNode(AstTestFactory.identifier3("R")));
    DartType normalParameterType = new InterfaceTypeImpl(
        new ClassElementImpl.forNode(AstTestFactory.identifier3("A")));
    DartType optionalParameterType = new InterfaceTypeImpl(
        new ClassElementImpl.forNode(AstTestFactory.identifier3("B")));
    DartType namedParameterType = new InterfaceTypeImpl(
        new ClassElementImpl.forNode(AstTestFactory.identifier3("C")));
    FunctionElementImpl functionElement =
        new FunctionElementImpl.forNode(AstTestFactory.identifier3("f"));
    String namedParameterName = "c";
    functionElement.parameters = <ParameterElement>[
      ElementFactory.requiredParameter2("a", normalParameterType),
      ElementFactory.positionalParameter2("b", optionalParameterType),
      ElementFactory.namedParameter2(namedParameterName, namedParameterType)
    ];
    functionElement.returnType = returnType;
    FunctionTypeImpl functionType = new FunctionTypeImpl(functionElement);
    InterfaceTypeImpl argumentType = new InterfaceTypeImpl(
        new ClassElementImpl.forNode(AstTestFactory.identifier3("D")));
    TypeParameterTypeImpl parameterType = new TypeParameterTypeImpl(
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E")));
    FunctionType result = functionType
        .substitute2(<DartType>[argumentType], <DartType>[parameterType]);
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

  void test_toString_recursive() {
    var t = ElementFactory.genericTypeAliasElement("t");
    var s = ElementFactory.genericTypeAliasElement("s");
    t.function.returnType = functionTypeAliasType(s);
    s.function.returnType = functionTypeAliasType(t);
    expect(
      functionTypeAliasType(t).toString(),
      'dynamic Function() Function()',
    );
  }

  void test_toString_recursive_via_interface_type() {
    var f = ElementFactory.genericTypeAliasElement('f');
    ClassElementImpl c = ElementFactory.classElement2('C', ['T']);
    f.function.returnType = c.instantiate(
      typeArguments: [functionTypeAliasType(f)],
      nullabilitySuffix: NullabilitySuffix.star,
    );
    expect(
      functionTypeAliasType(f).toString(),
      'C<dynamic Function()> Function()',
    );
  }

  void test_typeParameters_genericLocalFunction_genericMethod_genericClass() {
    //
    // class C<S> {
    //   Object m<T>() {
    //     U f<U>() => null;
    //   }
    // }
    //
    ClassElementImpl classElement =
        ElementFactory.classElement('C', null, ['S']);
    MethodElementImpl method = new MethodElementImpl('m', 0);
    method.enclosingElement = classElement;
    method.returnType = ElementFactory.objectType;
    method.typeParameters = ElementFactory.typeParameters(['T']);
    method.type = new FunctionTypeImpl(method);
    FunctionElementImpl function = ElementFactory.functionElement('f');
    function.enclosingElement = method;
    function.typeParameters = ElementFactory.typeParameters(['U']);
    function.returnType = typeParameterType(function.typeParameters[0]);
    function.type = new FunctionTypeImpl(function);

    List<TypeParameterElement> inheritedParameters = <TypeParameterElement>[];
    inheritedParameters.addAll(method.typeParameters);
    inheritedParameters.addAll(classElement.typeParameters);
    expect(function.type.typeArguments,
        unorderedEquals(_toTypes(inheritedParameters)));
    expect(function.type.typeFormals, unorderedEquals(function.typeParameters));
    expect(function.type.typeParameters, unorderedEquals(inheritedParameters));
  }

  void test_typeParameters_genericMethod_genericClass() {
    //
    // class C<S> {
    //   Object m<T>() => null;
    // }
    //
    ClassElementImpl classElement =
        ElementFactory.classElement('C', null, ['S']);
    MethodElementImpl method = new MethodElementImpl('m', 0);
    method.enclosingElement = classElement;
    method.returnType = ElementFactory.objectType;
    method.typeParameters = ElementFactory.typeParameters(['T']);
    method.type = new FunctionTypeImpl(method);

    expect(method.type.typeArguments,
        unorderedEquals(_toTypes(classElement.typeParameters)));
    expect(method.type.typeFormals, unorderedEquals(method.typeParameters));
    expect(method.type.typeParameters,
        unorderedEquals(classElement.typeParameters));
  }

  void test_typeParameters_genericMethod_simpleClass() {
    //
    // class C<S> {
    //   Object m<T>() => null;
    // }
    //
    ClassElementImpl classElement = class_(name: 'C');
    MethodElementImpl method = new MethodElementImpl('m', 0);
    method.enclosingElement = classElement;
    method.returnType = ElementFactory.objectType;
    method.typeParameters = ElementFactory.typeParameters(['T']);
    method.type = new FunctionTypeImpl(method);

    expect(method.type.typeArguments,
        unorderedEquals(_toTypes(classElement.typeParameters)));
    expect(method.type.typeFormals, unorderedEquals(method.typeParameters));
    expect(method.type.typeParameters,
        unorderedEquals(classElement.typeParameters));
  }

  void test_typeParameters_genericTopLevelFunction() {
    //
    // Object f<T>() => null;
    //
    FunctionElementImpl function = ElementFactory.functionElement('f');
    function.returnType = ElementFactory.objectType;
    function.typeParameters = ElementFactory.typeParameters(['T']);
    function.type = new FunctionTypeImpl(function);

    expect(function.type.typeArguments, isEmpty);
    expect(function.type.typeFormals, unorderedEquals(function.typeParameters));
    expect(function.type.typeParameters, isEmpty);
  }

  void test_typeParameters_simpleMethod_genericClass() {
    //
    // class C<S> {
    //   Object m<T>() => null;
    // }
    //
    ClassElementImpl classElement =
        ElementFactory.classElement('C', null, ['S']);
    MethodElementImpl method = new MethodElementImpl('m', 0);
    method.enclosingElement = classElement;
    method.typeParameters = ElementFactory.typeParameters(['T']);
    method.returnType = ElementFactory.objectType;
    method.type = new FunctionTypeImpl(method);

    expect(method.type.typeArguments,
        unorderedEquals(_toTypes(classElement.typeParameters)));
    expect(method.type.typeFormals, unorderedEquals(method.typeParameters));
    expect(method.type.typeParameters,
        unorderedEquals(classElement.typeParameters));
  }

  void test_typeParameters_simpleMethod_simpleClass() {
    //
    // class C<S> {
    //   Object m<T>() => null;
    // }
    //
    ClassElementImpl classElement = class_(name: 'C');
    MethodElementImpl method = new MethodElementImpl('m', 0);
    method.enclosingElement = classElement;
    method.typeParameters = ElementFactory.typeParameters(['T']);
    method.returnType = ElementFactory.objectType;
    method.type = new FunctionTypeImpl(method);

    expect(method.type.typeArguments,
        unorderedEquals(_toTypes(classElement.typeParameters)));
    expect(method.type.typeFormals, unorderedEquals(method.typeParameters));
    expect(method.type.typeParameters,
        unorderedEquals(classElement.typeParameters));
  }

  void test_withTypeArguments() {
    ClassElementImpl enclosingClass = ElementFactory.classElement2("C", ["E"]);
    MethodElementImpl methodElement =
        new MethodElementImpl.forNode(AstTestFactory.identifier3("m"));
    enclosingClass.methods = <MethodElement>[methodElement];
    FunctionTypeImpl type = new FunctionTypeImpl(methodElement);
    DartType expectedType = typeParameterType(enclosingClass.typeParameters[0]);
    List<DartType> arguments = type.typeArguments;
    expect(arguments, hasLength(1));
    expect(arguments[0], expectedType);
  }

  Iterable<DartType> _toTypes(List<TypeParameterElement> typeParameters) {
    return typeParameters
        .map((TypeParameterElement element) => typeParameterType(element));
  }
}

@reflectiveTest
class InterfaceTypeImplTest extends AbstractTypeTest {
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
        interfaceType(C),
      ],
      nullabilitySuffix: NullabilitySuffix.star,
    );

    B.interfaces = <InterfaceType>[AofC];

    InterfaceTypeImpl targetType = interfaceType(B);
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
          typeArguments: [typeParameterType(BE)],
          nullabilitySuffix: NullabilitySuffix.star,
        ),
      ],
    );

    var C = class_(name: 'C');

    InterfaceTypeImpl targetType = B.instantiate(
      typeArguments: [interfaceType(C)],
      nullabilitySuffix: NullabilitySuffix.star,
    );
    InterfaceType result = targetType.asInstanceOf(A);
    expect(
      result,
      A.instantiate(
        typeArguments: [interfaceType(C)],
        nullabilitySuffix: NullabilitySuffix.star,
      ),
    );
  }

  void test_creation() {
    expect(new InterfaceTypeImpl(class_(name: 'A')), isNotNull);
  }

  void test_getAccessors() {
    ClassElementImpl typeElement = class_(name: 'A');
    PropertyAccessorElement getterG =
        ElementFactory.getterElement("g", false, null);
    PropertyAccessorElement getterH =
        ElementFactory.getterElement("h", false, null);
    typeElement.accessors = <PropertyAccessorElement>[getterG, getterH];
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
    expect(type.accessors.length, 2);
  }

  void test_getAccessors_empty() {
    ClassElementImpl typeElement = class_(name: 'A');
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
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
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
    expect(type.constructors, hasLength(2));
  }

  void test_getConstructors_empty() {
    ClassElementImpl typeElement = class_(name: 'A');
    typeElement.constructors = const <ConstructorElement>[];
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
    expect(type.constructors, isEmpty);
  }

  void test_getElement() {
    ClassElementImpl typeElement = class_(name: 'A');
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
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
    InterfaceType typeA = interfaceType(classA);
    expect(typeA.getGetter(getterName), same(getterG));
  }

  void test_getGetter_parameterized() {
    //
    // class A<E> { E get g {} }
    //
    var AE = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [AE]);

    DartType typeAE = typeParameterType(AE);
    String getterName = "g";
    PropertyAccessorElementImpl getterG =
        ElementFactory.getterElement(getterName, false, typeAE);
    A.accessors = <PropertyAccessorElement>[getterG];
    getterG.type = new FunctionTypeImpl(getterG);
    //
    // A<I>
    //
    InterfaceType I = interfaceType(class_(name: 'I'));
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
    InterfaceType typeA = interfaceType(classA);
    expect(typeA.getGetter("g"), isNull);
  }

  void test_getInterfaces_nonParameterized() {
    //
    // class C implements A, B
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    var classB = ElementFactory.classElement2("B");
    InterfaceType typeB = interfaceType(classB);
    var classC = ElementFactory.classElement2("C");
    classC.interfaces = <InterfaceType>[typeA, typeB];
    List<InterfaceType> interfaces = interfaceType(classC).interfaces;
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
          typeArguments: [typeParameterType(F)],
          nullabilitySuffix: NullabilitySuffix.star,
        )
      ],
    );
    //
    // B<I>
    //
    InterfaceType typeI = interfaceType(class_(name: 'I'));
    InterfaceTypeImpl typeBI = interfaceType(B, typeArguments: [typeI]);

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
    InterfaceType typeA = interfaceType(classA);
    expect(typeA.getMethod(methodName), same(methodM));
  }

  void test_getMethod_parameterized_doesNotUseTypeParameter() {
    //
    // class A<E> { B m() {} }
    // class B {}
    //
    var classA = ElementFactory.classElement2("A", ["E"]);
    InterfaceType typeB = interfaceType(class_(name: 'B'));
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeB, []);
    classA.methods = <MethodElement>[methodM];
    methodM.type = new FunctionTypeImpl(methodM);
    //
    // A<I>
    //
    InterfaceType typeI = interfaceType(class_(name: 'I'));
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(classA);
    typeAI.typeArguments = <DartType>[typeI];
    MethodElement method = typeAI.getMethod(methodName);
    expect(method, isNotNull);
    FunctionType methodType = method.type;
    expect(methodType.typeParameters, isEmpty);
    expect(methodType.typeArguments, [same(typeI)]);
  }

  void test_getMethod_parameterized_flushCached_whenVersionChanges() {
    //
    // class A<E> { E m(E p) {} }
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);
    DartType typeE = typeParameterType(E);
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeE, [typeE]);
    A.methods = <MethodElement>[methodM];
    methodM.type = new FunctionTypeImpl(methodM);
    //
    // A<I>
    //
    InterfaceType typeI = interfaceType(class_(name: 'I'));
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(A);
    typeAI.typeArguments = <DartType>[typeI];
    // Methods list is cached.
    MethodElement method = typeAI.methods.single;
    expect(typeAI.methods.single, same(method));
    // Methods list is flushed on version change.
    A.version++;
    expect(typeAI.methods.single, isNot(same(method)));
  }

  void test_getMethod_parameterized_usesTypeParameter() {
    //
    // class A<E> { E m(E p) {} }
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);
    DartType typeE = typeParameterType(E);
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeE, [typeE]);
    A.methods = <MethodElement>[methodM];
    methodM.type = new FunctionTypeImpl(methodM);
    //
    // A<I>
    //
    InterfaceType typeI = interfaceType(class_(name: 'I'));
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(A);
    typeAI.typeArguments = <DartType>[typeI];
    MethodElement method = typeAI.getMethod(methodName);
    expect(method, isNotNull);
    FunctionType methodType = method.type;
    expect(methodType.typeParameters, isEmpty);
    expect(methodType.typeArguments, [same(typeI)]);
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
    InterfaceType typeA = interfaceType(classA);
    expect(typeA.getMethod("m"), isNull);
  }

  void test_getMethods() {
    ClassElementImpl typeElement = class_(name: 'A');
    MethodElementImpl methodOne = ElementFactory.methodElement("one", null);
    MethodElementImpl methodTwo = ElementFactory.methodElement("two", null);
    typeElement.methods = <MethodElement>[methodOne, methodTwo];
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
    expect(type.methods.length, 2);
  }

  void test_getMethods_empty() {
    ClassElementImpl typeElement = class_(name: 'A');
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
    expect(type.methods.length, 0);
  }

  void test_getMixins_nonParameterized() {
    //
    // class C extends Object with A, B
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    var classB = ElementFactory.classElement2("B");
    InterfaceType typeB = interfaceType(classB);
    var classC = ElementFactory.classElement2("C");
    classC.mixins = <InterfaceType>[typeA, typeB];
    List<InterfaceType> interfaces = interfaceType(classC).mixins;
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
        interfaceType(A, typeArguments: [
          typeParameterType(F),
        ]),
      ],
    );
    //
    // B<I>
    //
    InterfaceType typeI = interfaceType(class_(name: 'I'));
    InterfaceTypeImpl typeBI = new InterfaceTypeImpl(B);
    typeBI.typeArguments = <DartType>[typeI];
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
    InterfaceType typeA = interfaceType(classA);
    expect(typeA.getSetter(setterName), same(setterS));
  }

  void test_getSetter_parameterized() {
    //
    // class A<E> { set s(E p) {} }
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);
    DartType typeE = typeParameterType(E);
    String setterName = "s";
    PropertyAccessorElementImpl setterS =
        ElementFactory.setterElement(setterName, false, typeE);
    A.accessors = <PropertyAccessorElement>[setterS];
    setterS.type = new FunctionTypeImpl(setterS);
    //
    // A<I>
    //
    InterfaceType typeI = interfaceType(class_(name: 'I'));
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(A);
    typeAI.typeArguments = <DartType>[typeI];
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
    InterfaceType typeA = interfaceType(classA);
    expect(typeA.getSetter("s"), isNull);
  }

  void test_getSuperclass_nonParameterized() {
    //
    // class B extends A
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    var classB = ElementFactory.classElement("B", typeA);
    InterfaceType typeB = interfaceType(classB);
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
    var typeF = typeParameterType(F);

    var B = class_(
      name: 'B',
      typeParameters: [F],
      superType: interfaceType(A, typeArguments: [typeF]),
    );

    var classB = B;
    //
    // B<I>
    //
    InterfaceType typeI = interfaceType(class_(name: 'I'));
    InterfaceTypeImpl typeBI = new InterfaceTypeImpl(classB);
    typeBI.typeArguments = <DartType>[typeI];
    InterfaceType superclass = typeBI.superclass;
    expect(superclass.element, same(A));
    expect(superclass.typeArguments[0], same(typeI));
  }

  void test_getTypeArguments_empty() {
    InterfaceType type = interfaceType(ElementFactory.classElement2('A'));
    expect(type.typeArguments, hasLength(0));
  }

  void test_hashCode() {
    ClassElement classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
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
    InterfaceTypeImpl typeAF = new InterfaceTypeImpl(classA);
    typeAF.typeArguments = <DartType>[
      typeParameterType(classB.typeParameters[0])
    ];
    InterfaceTypeImpl typeAG = new InterfaceTypeImpl(classA);
    typeAG.typeArguments = <DartType>[
      typeParameterType(classB.typeParameters[1])
    ];
    expect(typeAG.isAssignableTo(typeAF), isFalse);
  }

  void test_isAssignableTo_void() {
    InterfaceTypeImpl intType = _typeProvider.intType;
    expect(VoidTypeImpl.instance.isAssignableTo(intType), isFalse);
  }

  void test_isDirectSupertypeOf_extends() {
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isDirectSupertypeOf(typeB), isTrue);
  }

  void test_isDirectSupertypeOf_false() {
    ClassElement classA = class_(name: 'A');
    ClassElement classB = ElementFactory.classElement2("B");
    ClassElement classC =
        ElementFactory.classElement("C", interfaceType(classB));
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeC = interfaceType(classC);
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isDirectSupertypeOf(typeC), isFalse);
  }

  void test_isDirectSupertypeOf_implements() {
    var classA = class_(name: 'A');
    var classB = ElementFactory.classElement2("B");
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    classB.interfaces = <InterfaceType>[typeA];
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isDirectSupertypeOf(typeB), isTrue);
  }

  void test_isDirectSupertypeOf_with() {
    var classA = class_(name: 'A');
    var classB = ElementFactory.classElement2("B");
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    classB.mixins = <InterfaceType>[typeA];
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isDirectSupertypeOf(typeB), isTrue);
  }

  void test_isMoreSpecificThan_bottom() {
    DartType type = interfaceType(ElementFactory.classElement2('A'));
    expect(BottomTypeImpl.instance.isMoreSpecificThan(type), isTrue);
  }

  void test_isMoreSpecificThan_covariance() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classI = ElementFactory.classElement2("I");
    ClassElement classJ =
        ElementFactory.classElement("J", interfaceType(classI));
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(classA);
    InterfaceTypeImpl typeAJ = new InterfaceTypeImpl(classA);
    typeAI.typeArguments = <DartType>[interfaceType(classI)];
    typeAJ.typeArguments = <DartType>[interfaceType(classJ)];
    expect(typeAJ.isMoreSpecificThan(typeAI), isTrue);
    expect(typeAI.isMoreSpecificThan(typeAJ), isFalse);
  }

  void test_isMoreSpecificThan_directSupertype() {
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    // ignore: deprecated_member_use_from_same_package
    expect(typeB.isMoreSpecificThan(typeA), isTrue);
    // the opposite test tests a different branch in isMoreSpecificThan()
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isMoreSpecificThan(typeB), isFalse);
  }

  void test_isMoreSpecificThan_dynamic() {
    InterfaceType type = interfaceType(ElementFactory.classElement2('A'));
    // ignore: deprecated_member_use_from_same_package
    expect(type.isMoreSpecificThan(DynamicTypeImpl.instance), isTrue);
  }

  void test_isMoreSpecificThan_generic() {
    ClassElement A = class_(
      name: 'A',
      typeParameters: [typeParameter('E')],
    );
    ClassElement B = class_(name: 'B');

    var AofDynamic = interfaceType(
      A,
      typeArguments: [dynamicType],
    );
    var AofB = interfaceType(
      A,
      typeArguments: [interfaceType(B)],
    );

    // ignore: deprecated_member_use_from_same_package
    expect(AofDynamic.isMoreSpecificThan(AofB), isFalse);
    // ignore: deprecated_member_use_from_same_package
    expect(AofB.isMoreSpecificThan(AofDynamic), isTrue);
  }

  void test_isMoreSpecificThan_self() {
    InterfaceType type = interfaceType(ElementFactory.classElement2('A'));
    // ignore: deprecated_member_use_from_same_package
    expect(type.isMoreSpecificThan(type), isTrue);
  }

  void test_isMoreSpecificThan_transitive_interface() {
    //
    //  class A {}
    //  class B extends A {}
    //  class C implements B {}
    //
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceType(classA));
    var classC = ElementFactory.classElement2("C");
    classC.interfaces = <InterfaceType>[interfaceType(classB)];
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeC = interfaceType(classC);
    // ignore: deprecated_member_use_from_same_package
    expect(typeC.isMoreSpecificThan(typeA), isTrue);
  }

  void test_isMoreSpecificThan_transitive_mixin() {
    //
    //  class A {}
    //  class B extends A {}
    //  class C with B {}
    //
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceType(classA));
    var classC = ElementFactory.classElement2("C");
    classC.mixins = <InterfaceType>[interfaceType(classB)];
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeC = interfaceType(classC);
    // ignore: deprecated_member_use_from_same_package
    expect(typeC.isMoreSpecificThan(typeA), isTrue);
  }

  void test_isMoreSpecificThan_transitive_recursive() {
    //
    //  class A extends B {}
    //  class B extends A {}
    //  class C {}
    //
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceType(classA));
    var classC = ElementFactory.classElement2("C");
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeC = interfaceType(classC);
    classA.supertype = interfaceType(classB);
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isMoreSpecificThan(typeC), isFalse);
  }

  void test_isMoreSpecificThan_transitive_superclass() {
    //
    //  class A {}
    //  class B extends A {}
    //  class C extends B {}
    //
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    ClassElement classC =
        ElementFactory.classElement("C", interfaceType(classB));
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeC = interfaceType(classC);
    // ignore: deprecated_member_use_from_same_package
    expect(typeC.isMoreSpecificThan(typeA), isTrue);
  }

  void test_isMoreSpecificThan_typeParameterType() {
    //
    // class A<E> {}
    //
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    InterfaceType typeA = interfaceType(classA);
    TypeParameterType parameterType =
        typeParameterType(classA.typeParameters[0]);
    DartType objectType = _typeProvider.objectType;
    // ignore: deprecated_member_use_from_same_package
    expect(parameterType.isMoreSpecificThan(objectType), isTrue);
    // ignore: deprecated_member_use_from_same_package
    expect(parameterType.isMoreSpecificThan(typeA), isFalse);
  }

  void test_isMoreSpecificThan_typeParameterType_withBound() {
    //
    // class A {}
    // class B<E extends A> {}
    //
    ClassElement classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    var classB = ElementFactory.classElement2("B");
    TypeParameterElementImpl parameterEA =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    TypeParameterType parameterAEType = new TypeParameterTypeImpl(parameterEA);
    parameterEA.bound = typeA;
    classB.typeParameters = <TypeParameterElementImpl>[parameterEA];
    // ignore: deprecated_member_use_from_same_package
    expect(parameterAEType.isMoreSpecificThan(typeA), isTrue);
  }

  void test_isSubtypeOf_directSubtype() {
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    expect(typeB.isSubtypeOf(typeA), isTrue);
    expect(typeA.isSubtypeOf(typeB), isFalse);
  }

  void test_isSubtypeOf_dynamic() {
    ClassElement classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
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
    var classA = class_(name: 'A');
    classA.methods = <MethodElement>[
      ElementFactory.methodElement("call", VoidTypeImpl.instance, [stringType])
    ];
    FunctionType functionType =
        ElementFactory.functionElement5("f", <ClassElement>[stringType.element])
            .type;
    expect(interfaceType(classA).isSubtypeOf(functionType), isTrue);
  }

  void test_isSubtypeOf_generic() {
    ClassElement A = ElementFactory.classElement2("A", ["E"]);
    ClassElement B = ElementFactory.classElement2("B");
    DartType dynamicType = DynamicTypeImpl.instance;
    InterfaceType typeAOfDynamic =
        interfaceType(A, typeArguments: [dynamicType]);
    InterfaceType typeAOfB =
        interfaceType(A, typeArguments: [interfaceType(B)]);
    expect(typeAOfDynamic.isSubtypeOf(typeAOfB), isTrue);
    expect(typeAOfB.isSubtypeOf(typeAOfDynamic), isTrue);
  }

  void test_isSubtypeOf_interface() {
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    var classC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    InterfaceType typeC = interfaceType(classC);
    classC.interfaces = <InterfaceType>[typeB];
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
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    var classC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    InterfaceType typeC = interfaceType(classC);
    classC.mixins = <InterfaceType>[typeB];
    expect(typeC.isSubtypeOf(typeB), isTrue);
    expect(typeC.isSubtypeOf(typeObject), isTrue);
    expect(typeC.isSubtypeOf(typeA), isTrue);
    expect(typeA.isSubtypeOf(typeC), isFalse);
  }

  void test_isSubtypeOf_object() {
    ClassElement classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeObject = classA.supertype;
    expect(typeA.isSubtypeOf(typeObject), isTrue);
    expect(typeObject.isSubtypeOf(typeA), isFalse);
  }

  void test_isSubtypeOf_self() {
    ClassElement classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    expect(typeA.isSubtypeOf(typeA), isTrue);
  }

  void test_isSubtypeOf_transitive_recursive() {
    //
    //  class A extends B {}
    //  class B extends A {}
    //  class C {}
    //
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceType(classA));
    var classC = ElementFactory.classElement2("C");
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeC = interfaceType(classC);
    classA.supertype = interfaceType(classB);
    expect(typeA.isSubtypeOf(typeC), isFalse);
  }

  void test_isSubtypeOf_transitive_superclass() {
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    ClassElement classC =
        ElementFactory.classElement("C", interfaceType(classB));
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeC = interfaceType(classC);
    expect(typeC.isSubtypeOf(typeA), isTrue);
    expect(typeA.isSubtypeOf(typeC), isFalse);
  }

  void test_isSubtypeOf_typeArguments() {
    DartType dynamicType = DynamicTypeImpl.instance;
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classI = ElementFactory.classElement2("I");
    ClassElement classJ =
        ElementFactory.classElement("J", interfaceType(classI));
    ClassElement classK = ElementFactory.classElement2("K");
    InterfaceType typeA_dynamic =
        interfaceType(classA, typeArguments: [dynamicType]);
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(classA);
    InterfaceTypeImpl typeAJ = new InterfaceTypeImpl(classA);
    InterfaceTypeImpl typeAK = new InterfaceTypeImpl(classA);
    typeAI.typeArguments = <DartType>[interfaceType(classI)];
    typeAJ.typeArguments = <DartType>[interfaceType(classJ)];
    typeAK.typeArguments = <DartType>[interfaceType(classK)];
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
    InterfaceType typeA = interfaceType(classA);
    TypeParameterType parameterType =
        typeParameterType(classA.typeParameters[0]);
    expect(typeA.isSubtypeOf(parameterType), isFalse);
  }

  void test_isSupertypeOf_directSupertype() {
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    // ignore: deprecated_member_use_from_same_package
    expect(typeB.isSupertypeOf(typeA), isFalse);
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isSupertypeOf(typeB), isTrue);
  }

  void test_isSupertypeOf_dynamic() {
    ClassElement classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    DartType dynamicType = DynamicTypeImpl.instance;
    // ignore: deprecated_member_use_from_same_package
    expect(dynamicType.isSupertypeOf(typeA), isTrue);
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isSupertypeOf(dynamicType), isTrue);
  }

  void test_isSupertypeOf_indirectSupertype() {
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    ClassElement classC =
        ElementFactory.classElement("C", interfaceType(classB));
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeC = interfaceType(classC);
    // ignore: deprecated_member_use_from_same_package
    expect(typeC.isSupertypeOf(typeA), isFalse);
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isSupertypeOf(typeC), isTrue);
  }

  void test_isSupertypeOf_interface() {
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    var classC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    InterfaceType typeC = interfaceType(classC);
    classC.interfaces = <InterfaceType>[typeB];
    // ignore: deprecated_member_use_from_same_package
    expect(typeB.isSupertypeOf(typeC), isTrue);
    // ignore: deprecated_member_use_from_same_package
    expect(typeObject.isSupertypeOf(typeC), isTrue);
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isSupertypeOf(typeC), isTrue);
    // ignore: deprecated_member_use_from_same_package
    expect(typeC.isSupertypeOf(typeA), isFalse);
  }

  void test_isSupertypeOf_mixins() {
    //
    // class A {}
    // class B extends A {}
    // class C with B {}
    //
    ClassElement classA = class_(name: 'A');
    ClassElement classB =
        ElementFactory.classElement("B", interfaceType(classA));
    var classC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeB = interfaceType(classB);
    InterfaceType typeC = interfaceType(classC);
    classC.mixins = <InterfaceType>[typeB];
    // ignore: deprecated_member_use_from_same_package
    expect(typeB.isSupertypeOf(typeC), isTrue);
    // ignore: deprecated_member_use_from_same_package
    expect(typeObject.isSupertypeOf(typeC), isTrue);
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isSupertypeOf(typeC), isTrue);
    // ignore: deprecated_member_use_from_same_package
    expect(typeC.isSupertypeOf(typeA), isFalse);
  }

  void test_isSupertypeOf_object() {
    ClassElement classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    InterfaceType typeObject = classA.supertype;
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isSupertypeOf(typeObject), isFalse);
    // ignore: deprecated_member_use_from_same_package
    expect(typeObject.isSupertypeOf(typeA), isTrue);
  }

  void test_isSupertypeOf_self() {
    ClassElement classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    // ignore: deprecated_member_use_from_same_package
    expect(typeA.isSupertypeOf(typeA), isTrue);
  }

  void test_lookUpGetter_implemented() {
    //
    // class A { g {} }
    //
    var classA = class_(name: 'A');
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[getterG];
    InterfaceType typeA = interfaceType(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpGetter(getterName, library), same(getterG));
  }

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
        ElementFactory.classElement("B", interfaceType(classA));
    InterfaceType typeB = interfaceType(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeB.lookUpGetter(getterName, library), same(getterG));
  }

  void test_lookUpGetter_mixin_shadowing() {
    //
    // class B {}
    // class M1 { get g {} }
    // class M2 { get g {} }
    // class C extends B with M1, M2 {}
    //
    TestTypeProvider typeProvider = new TestTypeProvider();
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
        ElementFactory.classElement('C', interfaceType(classB));
    classC.mixins = <InterfaceType>[
      interfaceType(classM1),
      interfaceType(classM2)
    ];
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElementImpl unit = library.definingCompilationUnit;
    unit.types = <ClassElement>[classB, classM1, classM2, classC];
    expect(interfaceType(classC).lookUpGetter(getterName, library), getterM2g);
  }

  void test_lookUpGetter_recursive() {
    //
    // class A extends B {}
    // class B extends A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    var classB = ElementFactory.classElement("B", typeA);
    classA.supertype = interfaceType(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpGetter_unimplemented() {
    //
    // class A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpMethod_implemented() {
    //
    // class A { m() {} }
    //
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[methodM];
    InterfaceType typeA = interfaceType(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpMethod(methodName, library), same(methodM));
  }

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
        ElementFactory.classElement("B", interfaceType(classA));
    InterfaceType typeB = interfaceType(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeB.lookUpMethod(methodName, library), same(methodM));
  }

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
        ElementFactory.classElement('C', interfaceType(classB));
    classC.mixins = <InterfaceType>[
      interfaceType(classM1),
      interfaceType(classM2)
    ];
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElementImpl unit = library.definingCompilationUnit;
    unit.types = <ClassElement>[classB, classM1, classM2, classC];
    expect(interfaceType(classC).lookUpMethod(methodName, library), methodM2m);
  }

  void test_lookUpMethod_parameterized() {
    //
    // class A<E> { E m(E p) {} }
    // class B<F> extends A<F> {}
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);
    DartType typeE = typeParameterType(E);
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeE, [typeE]);
    A.methods = <MethodElement>[methodM];
    methodM.type = new FunctionTypeImpl(methodM);

    var F = typeParameter('F');
    var B = class_(
      name: 'B',
      typeParameters: [F],
      superType: interfaceType(A, typeArguments: [
        typeParameterType(F),
      ]),
    );
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[A];
    //
    // B<I>
    //
    InterfaceType typeI = interfaceType(class_(name: 'I'));
    InterfaceTypeImpl typeBI = new InterfaceTypeImpl(B);
    typeBI.typeArguments = <DartType>[typeI];
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
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    var classB = ElementFactory.classElement("B", typeA);
    classA.supertype = interfaceType(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpMethod_unimplemented() {
    //
    // class A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpSetter_implemented() {
    //
    // class A { s(x) {} }
    //
    var classA = class_(name: 'A');
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setterS];
    InterfaceType typeA = interfaceType(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpSetter(setterName, library), same(setterS));
  }

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
        ElementFactory.classElement("B", interfaceType(classA));
    InterfaceType typeB = interfaceType(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeB.lookUpSetter(setterName, library), same(setterS));
  }

  void test_lookUpSetter_mixin_shadowing() {
    //
    // class B {}
    // class M1 { set s() {} }
    // class M2 { set s() {} }
    // class C extends B with M1, M2 {}
    //
    TestTypeProvider typeProvider = new TestTypeProvider();
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
        ElementFactory.classElement('C', interfaceType(classB));
    classC.mixins = <InterfaceType>[
      interfaceType(classM1),
      interfaceType(classM2)
    ];
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElementImpl unit = library.definingCompilationUnit;
    unit.types = <ClassElement>[classB, classM1, classM2, classC];
    expect(interfaceType(classC).lookUpGetter(setterName, library), setterM2g);
  }

  void test_lookUpSetter_recursive() {
    //
    // class A extends B {}
    // class B extends A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    var classB = ElementFactory.classElement("B", typeA);
    classA.supertype = interfaceType(classB);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeA.lookUpSetter("s", library), isNull);
  }

  void test_lookUpSetter_unimplemented() {
    //
    // class A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceType(classA);
    LibraryElementImpl library =
        ElementFactory.library(_analysisContext, "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpSetter("s", library), isNull);
  }

  void test_resolveToBound() {
    InterfaceTypeImpl type = interfaceType(ElementFactory.classElement2('A'));

    // Returns this.
    expect(type.resolveToBound(null), same(type));
  }

  void test_setTypeArguments() {
    InterfaceTypeImpl type = interfaceType(ElementFactory.classElement2('A'));
    List<DartType> typeArguments = <DartType>[
      interfaceType(class_(name: 'B')),
      interfaceType(class_(name: 'C'))
    ];
    type.typeArguments = typeArguments;
    expect(type.typeArguments, typeArguments);
  }

  void test_substitute_exception() {
    try {
      var classA = class_(name: 'A');
      InterfaceTypeImpl type = new InterfaceTypeImpl(classA);
      InterfaceType argumentType = interfaceType(class_(name: 'B'));
      type.substitute2(<DartType>[argumentType], <DartType>[]);
      fail(
          "Expected to encounter exception, argument and parameter type array lengths not equal.");
    } catch (e) {
      // Expected result
    }
  }

  void test_substitute_notEqual() {
    // The [test_substitute_equals] above has a slightly higher level
    // implementation.
    var classA = class_(name: 'A');
    TypeParameterElementImpl parameterElement =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    InterfaceTypeImpl type = new InterfaceTypeImpl(classA);
    TypeParameterTypeImpl parameter =
        new TypeParameterTypeImpl(parameterElement);
    type.typeArguments = <DartType>[parameter];
    InterfaceType argumentType = interfaceType(class_(name: 'B'));
    TypeParameterTypeImpl parameterType = new TypeParameterTypeImpl(
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("F")));
    InterfaceType result =
        type.substitute2(<DartType>[argumentType], <DartType>[parameterType]);
    expect(result.element, classA);
    List<DartType> resultArguments = result.typeArguments;
    expect(resultArguments, hasLength(1));
    expect(resultArguments[0], parameter);
  }
}

@reflectiveTest
class LibraryElementImplTest {
  void test_creation() {
    expect(
        new LibraryElementImpl.forNode(TestAnalysisContext(), null,
            AstTestFactory.libraryIdentifier2(["l"]), true),
        isNotNull);
  }

  void test_getImportedLibraries() {
    AnalysisContext context = TestAnalysisContext();
    LibraryElementImpl library1 = ElementFactory.library(context, "l1");
    LibraryElementImpl library2 = ElementFactory.library(context, "l2");
    LibraryElementImpl library3 = ElementFactory.library(context, "l3");
    LibraryElementImpl library4 = ElementFactory.library(context, "l4");
    PrefixElement prefixA =
        new PrefixElementImpl.forNode(AstTestFactory.identifier3("a"));
    PrefixElement prefixB =
        new PrefixElementImpl.forNode(AstTestFactory.identifier3("b"));
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
    PrefixElement prefixA =
        new PrefixElementImpl.forNode(AstTestFactory.identifier3("a"));
    PrefixElement prefixB =
        new PrefixElementImpl.forNode(AstTestFactory.identifier3("b"));
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
    LibraryElementImpl library = new LibraryElementImpl.forNode(
        context, null, AstTestFactory.libraryIdentifier2(["l1"]), true);
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
class PropertyAccessorElementImplTest {
  void test_matchesHandle_getter() {
    CompilationUnitElementImpl compilationUnitElement =
        ElementFactory.compilationUnit('foo.dart');
    ElementFactory.library(null, '')
      ..definingCompilationUnit = compilationUnitElement;
    PropertyAccessorElementImpl element =
        ElementFactory.getterElement('x', true, DynamicTypeImpl.instance);
    compilationUnitElement.accessors = <PropertyAccessorElement>[element];
    PropertyAccessorElementHandle handle =
        new PropertyAccessorElementHandle(null, element.location);
    expect(element.hashCode, handle.hashCode);
    // ignore: unrelated_type_equality_checks
    expect(element == handle, isTrue);
    // ignore: unrelated_type_equality_checks
    expect(handle == element, isTrue);
  }

  void test_matchesHandle_setter() {
    CompilationUnitElementImpl compilationUnitElement =
        ElementFactory.compilationUnit('foo.dart');
    ElementFactory.library(null, '')
      ..definingCompilationUnit = compilationUnitElement;
    PropertyAccessorElementImpl element =
        ElementFactory.setterElement('x', true, DynamicTypeImpl.instance);
    compilationUnitElement.accessors = <PropertyAccessorElement>[element];
    PropertyAccessorElementHandle handle =
        new PropertyAccessorElementHandle(null, element.location);
    expect(element.hashCode, handle.hashCode);
    // ignore: unrelated_type_equality_checks
    expect(element == handle, isTrue);
    // ignore: unrelated_type_equality_checks
    expect(handle == element, isTrue);
  }
}

class TestElementResynthesizer extends ElementResynthesizer {
  Map<ElementLocation, Element> locationMap;

  TestElementResynthesizer(AnalysisContext context, this.locationMap)
      : super(context, null);

  @override
  Element getElement(ElementLocation location) {
    return locationMap[location];
  }
}

@reflectiveTest
class TopLevelVariableElementImplTest extends DriverResolutionTest {
  test_computeConstantValue() async {
    newFile('/test/lib/a.dart', content: r'''
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
    expect(constant.constantValue, isNull);

    DartObject value = constant.computeConstantValue();
    expect(value, isNotNull);
    expect(value.toIntValue(), 42);
    expect(constant.constantValue, value);
  }
}

@reflectiveTest
class TypeParameterTypeImplTest extends AbstractTypeTest {
  void test_creation() {
    expect(
        new TypeParameterTypeImpl(new TypeParameterElementImpl.forNode(
            AstTestFactory.identifier3("E"))),
        isNotNull);
  }

  void test_getElement() {
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    expect(type.element, element);
  }

  void test_isMoreSpecificThan_typeArguments_dynamic() {
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    // E << dynamic
    expect(type.isMoreSpecificThan(DynamicTypeImpl.instance), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_object() {
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    // E << Object
    expect(type.isMoreSpecificThan(typeProvider.objectType), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_recursive() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl typeParameterU =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("U"));
    TypeParameterTypeImpl typeParameterTypeU =
        new TypeParameterTypeImpl(typeParameterU);
    TypeParameterElementImpl typeParameterT =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("T"));
    TypeParameterTypeImpl typeParameterTypeT =
        new TypeParameterTypeImpl(typeParameterT);
    typeParameterT.bound = typeParameterTypeU;
    typeParameterU.bound = typeParameterTypeU;
    // <T extends U> and <U extends T>
    // T << S
    expect(
        typeParameterTypeT.isMoreSpecificThan(interfaceType(classS)), isFalse);
  }

  void test_isMoreSpecificThan_typeArguments_self() {
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    // E << E
    expect(type.isMoreSpecificThan(type), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_transitivity_interfaceTypes() {
    //  class A {}
    //  class B extends A {}
    //
    ClassElement classA = class_(name: 'A');
    ClassElement classB = ElementFactory.classElement(
      "B",
      classA.instantiate(
        typeArguments: [],
        nullabilitySuffix: NullabilitySuffix.star,
      ),
    );
    InterfaceType typeA = classA.instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
    InterfaceType typeB = interfaceType(classB);
    TypeParameterElementImpl typeParameterT =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("T"));
    typeParameterT.bound = typeB;
    TypeParameterTypeImpl typeParameterTypeT =
        new TypeParameterTypeImpl(typeParameterT);
    // <T extends B>
    // T << A
    expect(typeParameterTypeT.isMoreSpecificThan(typeA), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_transitivity_typeParameters() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl typeParameterU =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("U"));
    typeParameterU.bound = interfaceType(classS);
    TypeParameterTypeImpl typeParameterTypeU =
        new TypeParameterTypeImpl(typeParameterU);
    TypeParameterElementImpl typeParameterT =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("T"));
    typeParameterT.bound = typeParameterTypeU;
    TypeParameterTypeImpl typeParameterTypeT =
        new TypeParameterTypeImpl(typeParameterT);
    // <T extends U> and <U extends S>
    // T << S
    expect(
        typeParameterTypeT.isMoreSpecificThan(interfaceType(classS)), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_upperBound() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl typeParameterT =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("T"));
    typeParameterT.bound = interfaceType(classS);
    TypeParameterTypeImpl typeParameterTypeT =
        new TypeParameterTypeImpl(typeParameterT);
    // <T extends S>
    // T << S
    expect(
        typeParameterTypeT.isMoreSpecificThan(interfaceType(classS)), isTrue);
  }

  void test_resolveToBound_bound() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    element.bound = interfaceType(classS);
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    expect(type.resolveToBound(null), interfaceType(classS));
  }

  void test_resolveToBound_bound_nullableInner() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    element.bound = (interfaceType(classS) as TypeImpl)
        .withNullability(NullabilitySuffix.question);
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    expect(type.resolveToBound(null), same(element.bound));
  }

  void test_resolveToBound_bound_nullableInnerOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    element.bound = (interfaceType(classS) as TypeImpl)
        .withNullability(NullabilitySuffix.question);
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element)
        .withNullability(NullabilitySuffix.question);
    expect(type.resolveToBound(null), same(element.bound));
  }

  void test_resolveToBound_bound_nullableInnerStarOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    element.bound = (interfaceType(classS) as TypeImpl)
        .withNullability(NullabilitySuffix.star);
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element)
        .withNullability(NullabilitySuffix.question);
    expect(
        type.resolveToBound(null),
        equals((interfaceType(classS) as TypeImpl)
            .withNullability(NullabilitySuffix.question)));
  }

  void test_resolveToBound_bound_nullableOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    element.bound = interfaceType(classS);
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element)
        .withNullability(NullabilitySuffix.question);
    expect(
        type.resolveToBound(null),
        equals((interfaceType(classS) as TypeImpl)
            .withNullability(NullabilitySuffix.question)));
  }

  void test_resolveToBound_bound_starInner() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    element.bound = (interfaceType(classS) as TypeImpl)
        .withNullability(NullabilitySuffix.star);
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    expect(type.resolveToBound(null), same(element.bound));
  }

  void test_resolveToBound_bound_starInnerNullableOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    element.bound = (interfaceType(classS) as TypeImpl)
        .withNullability(NullabilitySuffix.question);
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element)
        .withNullability(NullabilitySuffix.star);
    expect(type.resolveToBound(null), same(element.bound));
  }

  void test_resolveToBound_bound_starOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    element.bound = interfaceType(classS);
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element)
        .withNullability(NullabilitySuffix.star);
    expect(
        type.resolveToBound(null),
        (interfaceType(classS) as TypeImpl)
            .withNullability(NullabilitySuffix.star));
  }

  void test_resolveToBound_nestedBound() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl elementE =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    elementE.bound = interfaceType(classS);
    TypeParameterTypeImpl typeE = new TypeParameterTypeImpl(elementE);
    TypeParameterElementImpl elementF =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("F"));
    elementF.bound = typeE;
    TypeParameterTypeImpl typeF = new TypeParameterTypeImpl(elementE);
    expect(typeF.resolveToBound(null), interfaceType(classS));
  }

  void test_resolveToBound_unbound() {
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E")));
    // Returns whatever type is passed to resolveToBound().
    expect(type.resolveToBound(VoidTypeImpl.instance),
        same(VoidTypeImpl.instance));
  }

  void test_substitute_equal() {
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    InterfaceTypeImpl argument = new InterfaceTypeImpl(
        new ClassElementImpl.forNode(AstTestFactory.identifier3("A")));
    TypeParameterTypeImpl parameter = new TypeParameterTypeImpl(element);
    expect(type.substitute2(<DartType>[argument], <DartType>[parameter]),
        same(argument));
  }

  void test_substitute_notEqual() {
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E")));
    InterfaceTypeImpl argument = new InterfaceTypeImpl(
        new ClassElementImpl.forNode(AstTestFactory.identifier3("A")));
    TypeParameterTypeImpl parameter = new TypeParameterTypeImpl(
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("F")));
    expect(type.substitute2(<DartType>[argument], <DartType>[parameter]),
        same(type));
  }
}

@reflectiveTest
class VoidTypeImplTest extends AbstractTypeTest {
  /**
   * Reference {code VoidTypeImpl.getInstance()}.
   */
  DartType _voidType = VoidTypeImpl.instance;

  void test_isMoreSpecificThan_void_A() {
    ClassElement classA = class_(name: 'A');
    expect(
      // ignore: deprecated_member_use_from_same_package
      _voidType.isMoreSpecificThan(
        classA.instantiate(
          typeArguments: [],
          nullabilitySuffix: NullabilitySuffix.star,
        ),
      ),
      isFalse,
    );
  }

  void test_isMoreSpecificThan_void_dynamic() {
    // ignore: deprecated_member_use_from_same_package
    expect(_voidType.isMoreSpecificThan(DynamicTypeImpl.instance), isTrue);
  }

  void test_isMoreSpecificThan_void_void() {
    // ignore: deprecated_member_use_from_same_package
    expect(_voidType.isMoreSpecificThan(_voidType), isTrue);
  }

  void test_isSubtypeOf_void_A() {
    ClassElement classA = class_(name: 'A');
    expect(
      _voidType.isSubtypeOf(
        classA.instantiate(
          typeArguments: [],
          nullabilitySuffix: NullabilitySuffix.star,
        ),
      ),
      isFalse,
    );
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

  void test_resolveToBound() {
    // Returns this.
    expect(_voidType.resolveToBound(null), same(_voidType));
  }
}

class _FunctionTypeImplTest_isSubtypeOf_baseCase_classFunction
    extends InterfaceTypeImpl {
  _FunctionTypeImplTest_isSubtypeOf_baseCase_classFunction(ClassElement arg0)
      : super(arg0);

  @override
  bool get isDartCoreFunction => true;
}
