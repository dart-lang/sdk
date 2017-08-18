// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.dart.element.element_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/analysis_context_factory.dart'
    show AnalysisContextHelper;
import '../../../generated/resolver_test_case.dart';
import '../../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementAnnotationImplTest);
    defineReflectiveTests(FieldElementImplTest);
    defineReflectiveTests(FunctionTypeImplTest);
    defineReflectiveTests(InterfaceTypeImplTest);
    defineReflectiveTests(LocalVariableElementImplTest);
    defineReflectiveTests(TypeParameterTypeImplTest);
    defineReflectiveTests(VoidTypeImplTest);
    defineReflectiveTests(ClassElementImplTest);
    defineReflectiveTests(CompilationUnitElementImplTest);
    defineReflectiveTests(ElementLocationImplTest);
    defineReflectiveTests(ElementImplTest);
    defineReflectiveTests(LibraryElementImplTest);
    defineReflectiveTests(MethodElementImplTest);
    defineReflectiveTests(MethodMemberTest);
    defineReflectiveTests(MultiplyDefinedElementImplTest);
    defineReflectiveTests(ParameterElementImplTest);
    defineReflectiveTests(PropertyAccessorElementImplTest);
    defineReflectiveTests(TopLevelVariableElementImplTest);
  });
}

@reflectiveTest
class ClassElementImplTest extends EngineTestCase {
  void test_computeNode_ClassDeclaration() {
    AnalysisContextHelper contextHelper = new AnalysisContextHelper();
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
class A {}
@deprecated class B {}
enum C {C1, C2, C3}
@deprecated enum D {D1, D2, D3}''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    // A
    {
      ClassElement elementA = unitElement.getType("A");
      expect(elementA.isDeprecated, isFalse);
      expect(elementA.isEnum, isFalse);
      ClassDeclaration nodeA = elementA.computeNode();
      expect(nodeA, isNotNull);
      expect(nodeA.name.name, "A");
      expect(nodeA.element, same(elementA));
    }
    // B
    {
      ClassElement elementB = unitElement.getType("B");
      expect(elementB.isDeprecated, isTrue);
      expect(elementB.isEnum, isFalse);
      ClassDeclaration nodeB = elementB.computeNode();
      expect(nodeB, isNotNull);
      expect(nodeB.name.name, "B");
      expect(nodeB.element, same(elementB));
    }
    // C
    {
      ClassElement elementC = unitElement.getEnum("C");
      expect(elementC.isDeprecated, isFalse);
      expect(elementC.isEnum, isTrue);
      EnumDeclaration nodeC = elementC.computeNode();
      expect(nodeC, isNotNull);
      expect(nodeC.name.name, "C");
      expect(nodeC.element, same(elementC));
    }
    // D
    {
      ClassElement elementD = unitElement.getEnum("D");
      expect(elementD.isDeprecated, isTrue);
      expect(elementD.isEnum, isTrue);
      EnumDeclaration nodeC = elementD.computeNode();
      expect(nodeC, isNotNull);
      expect(nodeC.name.name, "D");
      expect(nodeC.element, same(elementD));
    }
  }

  void test_computeNode_ClassTypeAlias() {
    AnalysisContextHelper contextHelper = new AnalysisContextHelper();
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
abstract class A<K, V> = Object with MapMixin<K, V>;
''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    // A
    {
      ClassElement elementA = unitElement.getType("A");
      ClassTypeAlias nodeA = elementA.computeNode();
      expect(nodeA, isNotNull);
      expect(nodeA.name.name, "A");
      expect(nodeA.element, same(elementA));
    }
  }

  void test_constructors_mixinApplicationWithHandle() {
    AnalysisContext context = createAnalysisContext();
    context.sourceFactory = new SourceFactory([]);

    ElementLocation location = new ElementLocationImpl.con2('');
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.mixinApplication = true;
    TestElementResynthesizer resynthesizer =
        new TestElementResynthesizer(context, {location: classA});
    ClassElementHandle classAHandle =
        new ClassElementHandle(resynthesizer, location);
    ClassElementImpl classB =
        ElementFactory.classElement("B", new InterfaceTypeImpl(classAHandle));
    classB.mixinApplication = true;

    expect(classB.constructors, hasLength(1));
  }

  void test_getAllSupertypes_interface() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl elementC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = elementC.type;
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
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.supertype = classB.type;
    List<InterfaceType> supers = classB.allSupertypes;
    expect(supers, hasLength(1));
  }

  void test_getField() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[method];
    expect(classA.getMethod(methodName), same(method));
  }

  void test_getMethod_undeclared() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[method];
    expect(classA.getMethod("${methodName}x"), isNull);
  }

  void test_hasNonFinalField_false_const() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.fields = <FieldElement>[
      ElementFactory.fieldElement("f", false, false, true, classA.type)
    ];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_final() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.fields = <FieldElement>[
      ElementFactory.fieldElement("f", false, true, false, classA.type)
    ];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_recursive() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.supertype = classB.type;
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_true_immediate() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.fields = <FieldElement>[
      ElementFactory.fieldElement("f", false, false, false, classA.type)
    ];
    expect(classA.hasNonFinalField, isTrue);
  }

  void test_hasNonFinalField_true_inherited() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.fields = <FieldElement>[
      ElementFactory.fieldElement("f", false, false, false, classA.type)
    ];
    expect(classB.hasNonFinalField, isTrue);
  }

  void test_hasStaticMember_false_empty() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // no members
    expect(classA.hasStaticMember, isFalse);
  }

  void test_hasStaticMember_false_instanceMethod() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    MethodElement method = ElementFactory.methodElement("foo", null);
    classA.methods = <MethodElement>[method];
    expect(classA.hasStaticMember, isFalse);
  }

  void test_hasStaticMember_instanceGetter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    PropertyAccessorElement getter =
        ElementFactory.getterElement("foo", false, null);
    classA.accessors = <PropertyAccessorElement>[getter];
    expect(classA.hasStaticMember, isFalse);
  }

  void test_hasStaticMember_true_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    PropertyAccessorElementImpl getter =
        ElementFactory.getterElement("foo", false, null);
    classA.accessors = <PropertyAccessorElement>[getter];
    // "foo" is static
    getter.isStatic = true;
    expect(classA.hasStaticMember, isTrue);
  }

  void test_hasStaticMember_true_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    MethodElementImpl method = ElementFactory.methodElement("foo", null);
    classA.methods = <MethodElement>[method];
    // "foo" is static
    method.isStatic = true;
    expect(classA.hasStaticMember, isTrue);
  }

  void test_hasStaticMember_true_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
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
    EnumElementImpl enumE = ElementFactory
        .enumElement(new TestTypeProvider(), "E", [firstConst, secondConst]);

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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl method = ElementFactory.methodElement(methodName, null);
    method.abstract = true;
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    MethodElementImpl method = ElementFactory.methodElement(methodName, null);
    method.abstract = true;
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.abstract = true;
    String methodName = "m";
    MethodElementImpl inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    inheritedMethod.abstract = true;
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpConcreteMethod_undeclared() {
    // class A {
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpConcreteMethod("m", library), isNull);
  }

  void test_lookUpGetter_declared() {
    // class A {
    //   get g {}
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[getter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpGetter(getterName, library), same(getter));
  }

  void test_lookUpGetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpGetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpInheritedConcreteGetter_declared() {
    // class A {
    //   get g {}
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement inheritedGetter =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[inheritedGetter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedConcreteGetter(getterName, library),
        same(inheritedGetter));
  }

  void test_lookUpInheritedConcreteGetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedConcreteGetter("g", library), isNull);
  }

  void test_lookUpInheritedConcreteGetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classA.lookUpInheritedConcreteGetter("g", library), isNull);
  }

  void test_lookUpInheritedConcreteMethod_declared() {
    // class A {
    //   m() {}
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    MethodElementImpl method = ElementFactory.methodElement(methodName, null);
    method.abstract = true;
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.abstract = true;
    String methodName = "m";
    MethodElementImpl inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    inheritedMethod.abstract = true;
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    MethodElementImpl abstractMethod =
        ElementFactory.methodElement(methodName, null);
    abstractMethod.abstract = true;
    classB.methods = <MethodElement>[abstractMethod];
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedConcreteMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpInheritedConcreteMethod_undeclared() {
    // class A {
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedConcreteMethod("m", library), isNull);
  }

  void test_lookUpInheritedConcreteSetter_declared() {
    // class A {
    //   set g(x) {}
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setter =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedConcreteSetter(setterName, library),
        same(setter));
  }

  void test_lookUpInheritedConcreteSetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedConcreteSetter("s", library), isNull);
  }

  void test_lookUpInheritedConcreteSetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classA.lookUpInheritedConcreteSetter("s", library), isNull);
  }

  void test_lookUpInheritedMethod_declared() {
    // class A {
    //   m() {}
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement inheritedMethod =
        ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[inheritedMethod];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpInheritedMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpInheritedMethod_undeclared() {
    // class A {
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpInheritedMethod("m", library), isNull);
  }

  void test_lookUpMethod_declared() {
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpMethod(methodName, library), same(method));
  }

  void test_lookUpMethod_inherited() {
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[method];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpMethod(methodName, library), same(method));
  }

  void test_lookUpMethod_undeclared() {
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpMethod_undeclared_recursive() {
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpSetter_declared() {
    // class A {
    //   set g(x) {}
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
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
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setter =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classB.lookUpSetter(setterName, library), same(setter));
  }

  void test_lookUpSetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA];
    expect(classA.lookUpSetter("s", library), isNull);
  }

  void test_lookUpSetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classA, classB];
    expect(classA.lookUpSetter("s", library), isNull);
  }
}

@reflectiveTest
class CompilationUnitElementImplTest extends EngineTestCase {
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
class ElementAnnotationImplTest extends ResolverTestCase {
  void test_computeConstantValue() {
    addNamedSource('/a.dart', r'''
class A {
  final String f;
  const A(this.f);
}
void f(@A('x') int p) {}
''');
    Source source = addSource(r'''
import 'a.dart';
main() {
  f(3);
}
''');
    LibraryElement library = resolve2(source);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration main = unit.declarations[0];
    BlockFunctionBody body = main.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;
    ParameterElement parameter =
        invocation.argumentList.arguments[0].bestParameterElement;
    ElementAnnotation annotation = parameter.metadata[0];
    expect(annotation.constantValue, isNull);
    DartObject value = annotation.computeConstantValue();
    expect(value, isNotNull);
    expect(value.getField('f').toStringValue(), 'x');
    expect(annotation.constantValue, value);
  }
}

@reflectiveTest
class ElementImplTest extends EngineTestCase {
  void test_equals() {
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classElement = ElementFactory.classElement2("C");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    FieldElement field = ElementFactory.fieldElement(
        "next", false, false, false, classElement.type);
    classElement.fields = <FieldElement>[field];
    expect(field == field, isTrue);
    expect(field == field.getter, isFalse);
    expect(field == field.setter, isFalse);
    expect(field.getter == field.setter, isFalse);
  }

  void test_isAccessibleIn_private_differentLibrary() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library1 = ElementFactory.library(context, "lib1");
    ClassElement classElement = ElementFactory.classElement2("_C");
    (library1.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    LibraryElementImpl library2 = ElementFactory.library(context, "lib2");
    expect(classElement.isAccessibleIn(library2), isFalse);
  }

  void test_isAccessibleIn_private_sameLibrary() {
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    ClassElement classElement = ElementFactory.classElement2("_C");
    (library.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    expect(classElement.isAccessibleIn(library), isTrue);
  }

  void test_isAccessibleIn_public_differentLibrary() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library1 = ElementFactory.library(context, "lib1");
    ClassElement classElement = ElementFactory.classElement2("C");
    (library1.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    LibraryElementImpl library2 = ElementFactory.library(context, "lib2");
    expect(classElement.isAccessibleIn(library2), isTrue);
  }

  void test_isAccessibleIn_public_sameLibrary() {
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
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
    ClassElementImpl classElementA = ElementFactory.classElement2("A");
    classElementA.nameOffset = 1;
    ClassElementImpl classElementB = ElementFactory.classElement2("B");
    classElementB.nameOffset = 2;
    expect(Element.SORT_BY_OFFSET(classElementA, classElementA), 0);
    expect(Element.SORT_BY_OFFSET(classElementA, classElementB) < 0, isTrue);
    expect(Element.SORT_BY_OFFSET(classElementB, classElementA) > 0, isTrue);
  }
}

@reflectiveTest
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

@reflectiveTest
class FieldElementImplTest extends EngineTestCase {
  void test_computeNode() {
    AnalysisContextHelper contextHelper = new AnalysisContextHelper();
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
class A {
  int a;
}
enum B {B1, B2, B3}''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    // A
    {
      FieldElement elementA = unitElement.getType("A").getField('a');
      VariableDeclaration nodeA = elementA.computeNode();
      expect(nodeA, isNotNull);
      expect(nodeA.name.name, "a");
      expect(nodeA.element, same(elementA));
    }
    // B
    {
      FieldElement elementB = unitElement.getEnum("B").getField('B2');
      EnumConstantDeclaration nodeB = elementB.computeNode();
      expect(nodeB, isNotNull);
      expect(nodeB.name.name, "B2");
      expect(nodeB.element, same(elementB));
    }
  }

  void test_isEnumConstant() {
    AnalysisContextHelper contextHelper = new AnalysisContextHelper();
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
enum B {B1, B2, B3}
''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;

    FieldElement b2Element = unitElement.getEnum("B").getField('B2');
    expect(b2Element.isEnumConstant, isTrue);

    FieldElement indexElement = unitElement.getEnum("B").getField('index');
    expect(indexElement.isEnumConstant, isFalse);
  }
}

@reflectiveTest
class FunctionTypeImplTest extends EngineTestCase {
  void test_creation() {
    expect(
        new FunctionTypeImpl(
            new FunctionElementImpl.forNode(AstTestFactory.identifier3("f"))),
        isNotNull);
  }

  void test_equality_recursive() {
    FunctionTypeAliasElementImpl s =
        ElementFactory.functionTypeAliasElement('s');
    FunctionTypeAliasElementImpl t =
        ElementFactory.functionTypeAliasElement('t');
    FunctionTypeAliasElementImpl u =
        ElementFactory.functionTypeAliasElement('u');
    FunctionTypeAliasElementImpl v =
        ElementFactory.functionTypeAliasElement('v');
    s.returnType = t.type;
    t.returnType = s.type;
    u.returnType = v.type;
    v.returnType = u.type;
    // We don't care whether the types compare equal or not.  We just need the
    // computation to terminate.
    expect(s.type == u.type, new isInstanceOf<bool>());
  }

  void test_getElement() {
    FunctionElementImpl typeElement =
        new FunctionElementImpl.forNode(AstTestFactory.identifier3("f"));
    FunctionTypeImpl type = new FunctionTypeImpl(typeElement);
    expect(type.element, typeElement);
  }

  void test_getNamedParameterTypes_namedParameters() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    FunctionElement element = ElementFactory
        .functionElementWithParameters('f', VoidTypeImpl.instance, [
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
    FunctionElement element = ElementFactory
        .functionElementWithParameters('f', VoidTypeImpl.instance, [
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
    FunctionElement element = ElementFactory
        .functionElementWithParameters('f', VoidTypeImpl.instance, [
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
    FunctionElement element = ElementFactory
        .functionElementWithParameters('f', VoidTypeImpl.instance, [
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
    FunctionElement element = ElementFactory
        .functionElementWithParameters('f', VoidTypeImpl.instance, [
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
    FunctionElement element = ElementFactory
        .functionElementWithParameters('f', VoidTypeImpl.instance, [
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
    FunctionTypeAliasElementImpl s =
        ElementFactory.functionTypeAliasElement('s');
    FunctionTypeAliasElementImpl t =
        ElementFactory.functionTypeAliasElement('t');
    s.returnType = t.type;
    t.returnType = s.type;
    // We don't care what the hash code is.  We just need its computation to
    // terminate.
    expect(t.type.hashCode, new isInstanceOf<int>());
  }

  void test_isAssignableTo_normalAndPositionalArgs() {
    // ([a]) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A");
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement5("s", <ClassElement>[a]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
    // assignable iff subtype
    expect(t.isAssignableTo(s), isTrue);
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
    InterfaceType t = ElementFactory.classElement2("C").type;
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
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["name"], <ClassElement>[a]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["name"], <ClassElement>[b]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_namedParameters_isNotAssignable() {
    // ! ({name: A}) -> void <: ({name: B}) -> void
    FunctionType t = ElementFactory.functionElement4(
        "t",
        null,
        null,
        <String>["name"],
        <ClassElement>[ElementFactory.classElement2("A")]).type;
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
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
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
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["A", "B"], <ClassElement>[a, b]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["B", "A"], <ClassElement>[b, a]).type;
    expect(t.isSubtypeOf(s), isTrue);
  }

  void test_isSubtypeOf_namedParameters_orderOfParams2() {
    // B extends A
    // ! ({B: B}) -> void <: ({B: B, A: A}) -> void
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["B"], <ClassElement>[b]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["B", "A"], <ClassElement>[b, a]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_namedParameters_orderOfParams3() {
    // B extends A
    // ({A: A, B: B}) -> void <: ({A: A}) -> void
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["A", "B"], <ClassElement>[a, b]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["B"], <ClassElement>[b]).type;
    expect(t.isSubtypeOf(s), isTrue);
  }

  void test_isSubtypeOf_namedParameters_sHasMoreParams() {
    // B extends A
    // ! ({name: A}) -> void <: ({name: B, name2: B}) -> void
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["name"], <ClassElement>[a]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["name", "name2"], <ClassElement>[b, b]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_namedParameters_tHasMoreParams() {
    // B extends A
    // ({name: A, name2: A}) -> void <: ({name: B}) -> void
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
    FunctionType t = ElementFactory.functionElement4(
        "t", null, null, <String>["name", "name2"], <ClassElement>[a, a]).type;
    FunctionType s = ElementFactory.functionElement4(
        "s", null, null, <String>["name"], <ClassElement>[b]).type;
    expect(t.isSubtypeOf(s), isTrue);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_1() {
    // ([a]) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A");
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement5("s", <ClassElement>[a]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_2() {
    // (a, [a]) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A");
    FunctionType t = ElementFactory
        .functionElement6("t", <ClassElement>[a], <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement5("s", <ClassElement>[a]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_3() {
    // ([a]) -> void <: () -> void
    ClassElement a = ElementFactory.classElement2("A");
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a]).type;
    FunctionType s = ElementFactory.functionElement("s").type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalAndPositionalArgs_4() {
    // (a, b, [c, d, e]) -> void <: (a, b, c, [d]) -> void
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement2("B");
    ClassElement c = ElementFactory.classElement2("C");
    ClassElement d = ElementFactory.classElement2("D");
    ClassElement e = ElementFactory.classElement2("E");
    FunctionType t = ElementFactory.functionElement6(
        "t", <ClassElement>[a, b], <ClassElement>[c, d, e]).type;
    FunctionType s = ElementFactory
        .functionElement6("s", <ClassElement>[a, b, c], <ClassElement>[d]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_normalParameters_isAssignable() {
    // B extends A
    // (a) -> void <: (b) -> void
    // (b) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
    FunctionType t =
        ElementFactory.functionElement5("t", <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement5("s", <ClassElement>[b]).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_normalParameters_isNotAssignable() {
    // ! (a) -> void <: (b) -> void
    FunctionType t = ElementFactory.functionElement5(
        "t", <ClassElement>[ElementFactory.classElement2("A")]).type;
    FunctionType s = ElementFactory.functionElement5(
        "s", <ClassElement>[ElementFactory.classElement2("B")]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_normalParameters_sHasMoreParams() {
    // B extends A
    // ! (a) -> void <: (b, b) -> void
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
    FunctionType t =
        ElementFactory.functionElement5("t", <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement5("s", <ClassElement>[b, b]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_normalParameters_tHasMoreParams() {
    // B extends A
    // ! (a, a) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
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
    InterfaceType t = ElementFactory.object.type;
    expect(f.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_positionalParameters_isAssignable() {
    // B extends A
    // ([a]) -> void <: ([b]) -> void
    // ([b]) -> void <: ([a]) -> void
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
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
        "t", null, <ClassElement>[ElementFactory.classElement2("A")]).type;
    FunctionType s = ElementFactory.functionElement6(
        "s", null, <ClassElement>[ElementFactory.classElement2("B")]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_positionalParameters_sHasMoreParams() {
    // B extends A
    // ! ([a]) -> void <: ([b, b]) -> void
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a]).type;
    FunctionType s =
        ElementFactory.functionElement6("s", null, <ClassElement>[b, b]).type;
    expect(t.isSubtypeOf(s), isFalse);
  }

  void test_isSubtypeOf_positionalParameters_tHasMoreParams() {
    // B extends A
    // ([a, a]) -> void <: ([b]) -> void
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
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
    ClassElement a = ElementFactory.classElement2("A");
    ClassElement b = ElementFactory.classElement("B", a.type);
    FunctionType t = ElementFactory.functionElement2("t", a.type).type;
    FunctionType s = ElementFactory.functionElement2("s", b.type).type;
    expect(t.isSubtypeOf(s), isTrue);
    expect(s.isSubtypeOf(t), isTrue);
  }

  void test_isSubtypeOf_returnType_tNotAssignableToS() {
    // ! () -> A <: () -> B
    FunctionType t = ElementFactory
        .functionElement2("t", ElementFactory.classElement2("A").type)
        .type;
    FunctionType s = ElementFactory
        .functionElement2("s", ElementFactory.classElement2("B").type)
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
    ClassElement a = ElementFactory.classElement2("A");
    FunctionType t =
        ElementFactory.functionElement5("t", <ClassElement>[a]).type;
    FunctionType s = ElementFactory
        .functionElement7("s", null, <String>["name"], <ClassElement>[a]).type;
    expect(t.isSubtypeOf(s), isFalse);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_isSubtypeOf_wrongFunctionType_optional_named() {
    // ! ([a]) -> void <: ({name: A}) -> void
    // ! ({name: A}) -> void <: ([a]) -> void
    ClassElement a = ElementFactory.classElement2("A");
    FunctionType t =
        ElementFactory.functionElement6("t", null, <ClassElement>[a]).type;
    FunctionType s = ElementFactory
        .functionElement7("s", null, <String>["name"], <ClassElement>[a]).type;
    expect(t.isSubtypeOf(s), isFalse);
    expect(s.isSubtypeOf(t), isFalse);
  }

  void test_namedParameterTypes_pruned_no_type_arguments() {
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    FunctionTypeAliasElementImpl g =
        ElementFactory.functionTypeAliasElement('g');
    f.parameters = [ElementFactory.namedParameter2('x', g.type)];
    FunctionTypeImpl paramType = f.type.namedParameterTypes['x'];
    expect(paramType.prunedTypedefs, hasLength(1));
    expect(paramType.prunedTypedefs[0], same(f));
  }

  void test_namedParameterTypes_pruned_with_type_arguments() {
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    FunctionTypeAliasElementImpl g =
        ElementFactory.functionTypeAliasElement('g');
    f.typeParameters = [ElementFactory.typeParameterElement('T')];
    f.parameters = [ElementFactory.namedParameter2('x', g.type)];
    FunctionTypeImpl paramType = f.type.namedParameterTypes['x'];
    expect(paramType.prunedTypedefs, hasLength(1));
    expect(paramType.prunedTypedefs[0], same(f));
  }

  void test_newPrune_no_previous_prune() {
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    FunctionTypeImpl type = f.type;
    List<FunctionTypeAliasElement> pruneList = type.newPrune;
    expect(pruneList, hasLength(1));
    expect(pruneList[0], same(f));
  }

  void test_newPrune_non_typedef() {
    // No pruning needs to be done for function types that aren't associated
    // with typedefs because those types can't be directly referred to by the
    // user (and hence can't participate in circularities).
    FunctionElementImpl f = ElementFactory.functionElement('f');
    FunctionTypeImpl type = f.type;
    expect(type.newPrune, isNull);
  }

  void test_newPrune_synthetic_typedef() {
    // No pruning needs to be done for function types that are associated with
    // synthetic typedefs because those types are only created for
    // function-typed formal parameters, which can't be directly referred to by
    // the user (and hence can't participate in circularities).
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    f.isSynthetic = true;
    FunctionTypeImpl type = f.type;
    expect(type.newPrune, isNull);
  }

  void test_newPrune_with_previous_prune() {
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    FunctionTypeAliasElementImpl g =
        ElementFactory.functionTypeAliasElement('g');
    FunctionTypeImpl type = f.type;
    FunctionTypeImpl prunedType = type.pruned([g]);
    List<FunctionTypeAliasElement> pruneList = prunedType.newPrune;
    expect(pruneList, hasLength(2));
    expect(pruneList, contains(f));
    expect(pruneList, contains(g));
  }

  void test_normalParameterTypes_pruned_no_type_arguments() {
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    FunctionTypeAliasElementImpl g =
        ElementFactory.functionTypeAliasElement('g');
    f.parameters = [ElementFactory.requiredParameter2('x', g.type)];
    FunctionTypeImpl paramType = f.type.normalParameterTypes[0];
    expect(paramType.prunedTypedefs, hasLength(1));
    expect(paramType.prunedTypedefs[0], same(f));
  }

  void test_normalParameterTypes_pruned_with_type_arguments() {
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    FunctionTypeAliasElementImpl g =
        ElementFactory.functionTypeAliasElement('g');
    f.typeParameters = [ElementFactory.typeParameterElement('T')];
    f.parameters = [ElementFactory.requiredParameter2('x', g.type)];
    FunctionTypeImpl paramType = f.type.normalParameterTypes[0];
    expect(paramType.prunedTypedefs, hasLength(1));
    expect(paramType.prunedTypedefs[0], same(f));
  }

  void test_optionalParameterTypes_pruned_no_type_arguments() {
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    FunctionTypeAliasElementImpl g =
        ElementFactory.functionTypeAliasElement('g');
    f.parameters = [ElementFactory.positionalParameter2('x', g.type)];
    FunctionTypeImpl paramType = f.type.optionalParameterTypes[0];
    expect(paramType.prunedTypedefs, hasLength(1));
    expect(paramType.prunedTypedefs[0], same(f));
  }

  void test_optionalParameterTypes_pruned_with_type_arguments() {
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    FunctionTypeAliasElementImpl g =
        ElementFactory.functionTypeAliasElement('g');
    f.typeParameters = [ElementFactory.typeParameterElement('T')];
    f.parameters = [ElementFactory.positionalParameter2('x', g.type)];
    FunctionTypeImpl paramType = f.type.optionalParameterTypes[0];
    expect(paramType.prunedTypedefs, hasLength(1));
    expect(paramType.prunedTypedefs[0], same(f));
  }

  void test_resolveToBound() {
    FunctionElementImpl f = ElementFactory.functionElement('f');
    FunctionTypeImpl type = f.type;

    // Returns this.
    expect(type.resolveToBound(null), same(type));
  }

  void test_returnType_pruned_no_type_arguments() {
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    FunctionTypeAliasElementImpl g =
        ElementFactory.functionTypeAliasElement('g');
    f.returnType = g.type;
    FunctionTypeImpl paramType = f.type.returnType;
    expect(paramType.prunedTypedefs, hasLength(1));
    expect(paramType.prunedTypedefs[0], same(f));
  }

  void test_returnType_pruned_with_type_arguments() {
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    FunctionTypeAliasElementImpl g =
        ElementFactory.functionTypeAliasElement('g');
    f.typeParameters = [ElementFactory.typeParameterElement('T')];
    f.returnType = g.type;
    FunctionTypeImpl paramType = f.type.returnType;
    expect(paramType.prunedTypedefs, hasLength(1));
    expect(paramType.prunedTypedefs[0], same(f));
  }

  void test_substitute2_equal() {
    ClassElementImpl definingClass = ElementFactory.classElement2("C", ["E"]);
    TypeParameterType parameterType = definingClass.typeParameters[0].type;
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
    FunctionTypeAliasElementImpl t =
        ElementFactory.functionTypeAliasElement("t");
    FunctionTypeAliasElementImpl s =
        ElementFactory.functionTypeAliasElement("s");
    t.returnType = s.type;
    s.returnType = t.type;
    expect(t.type.toString(), '() \u2192 () \u2192 ...');
  }

  void test_toString_recursive_via_interface_type() {
    FunctionTypeAliasElementImpl f =
        ElementFactory.functionTypeAliasElement('f');
    ClassElementImpl c = ElementFactory.classElement2('C', ['T']);
    f.returnType = c.type.instantiate([f.type]);
    expect(f.type.toString(), '() \u2192 C<...>');
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
    function.returnType = function.typeParameters[0].type;
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
    ClassElementImpl classElement = ElementFactory.classElement2('C');
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
    ClassElementImpl classElement = ElementFactory.classElement2('C');
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
    DartType expectedType = enclosingClass.typeParameters[0].type;
    List<DartType> arguments = type.typeArguments;
    expect(arguments, hasLength(1));
    expect(arguments[0], expectedType);
  }

  Iterable<DartType> _toTypes(List<TypeParameterElement> typeParameters) {
    return typeParameters.map((TypeParameterElement element) => element.type);
  }
}

@reflectiveTest
class InterfaceTypeImplTest extends EngineTestCase {
  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  @override
  void setUp() {
    super.setUp();
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    ClassElementImpl classD = ElementFactory.classElement2("D");
    ClassElementImpl classE = ElementFactory.classElement2("E");
    classB.interfaces = <InterfaceType>[classA.type];
    classC.interfaces = <InterfaceType>[classA.type];
    classD.interfaces = <InterfaceType>[classC.type];
    classE.interfaces = <InterfaceType>[classB.type, classD.type];
    // assertion: even though the longest path to Object for typeB is 2, and
    // typeE implements typeB, the longest path for typeE is 4 since it also
    // implements typeD
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type),
        2);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classE.type),
        4);
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
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElement classC = ElementFactory.classElement("C", classA.type);
    ClassElement classD = ElementFactory.classElement("D", classC.type);
    ClassElementImpl classE = ElementFactory.classElement("E", classB.type);
    classE.interfaces = <InterfaceType>[classD.type];
    // assertion: even though the longest path to Object for typeB is 2, and
    // typeE extends typeB, the longest path for typeE is 4 since it also
    // implements typeD
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type),
        2);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classE.type),
        4);
  }

  void test_computeLongestInheritancePathToObject_object() {
    //
    //   Object
    //     |
    //     A
    //
    ClassElement classA = ElementFactory.classElement2("A");
    InterfaceType object = classA.supertype;
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(object), 0);
  }

  void test_computeLongestInheritancePathToObject_recursion() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.supertype = classB.type;
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classA.type),
        2);
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classB.interfaces = <InterfaceType>[classA.type];
    classC.interfaces = <InterfaceType>[classB.type];
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classA.type),
        1);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type),
        2);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classC.type),
        3);
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
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElement classC = ElementFactory.classElement("C", classB.type);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classA.type),
        1);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type),
        2);
    expect(InterfaceTypeImpl.computeLongestInheritancePathToObject(classC.type),
        3);
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B", ["T"]);
    ClassElementImpl classC = ElementFactory.classElement2("C", ["T"]);
    ClassElement classD = ElementFactory.classElement2("D");
    InterfaceType typeA = classA.type;
    classB.interfaces = <InterfaceType>[typeA];
    InterfaceTypeImpl typeBT = new InterfaceTypeImpl(classB);
    DartType typeT = classC.type.typeArguments[0];
    typeBT.typeArguments = <DartType>[typeT];
    classC.interfaces = <InterfaceType>[typeBT];
    // A
    Set<InterfaceType> superinterfacesOfA =
        InterfaceTypeImpl.computeSuperinterfaceSet(typeA);
    expect(superinterfacesOfA, hasLength(1));
    InterfaceType typeObject = ElementFactory.object.type;
    expect(superinterfacesOfA.contains(typeObject), isTrue);
    // B<D>
    InterfaceTypeImpl typeBD = new InterfaceTypeImpl(classB);
    typeBD.typeArguments = <DartType>[classD.type];
    Set<InterfaceType> superinterfacesOfBD =
        InterfaceTypeImpl.computeSuperinterfaceSet(typeBD);
    expect(superinterfacesOfBD, hasLength(2));
    expect(superinterfacesOfBD.contains(typeObject), isTrue);
    expect(superinterfacesOfBD.contains(typeA), isTrue);
    // C<D>
    InterfaceTypeImpl typeCD = new InterfaceTypeImpl(classC);
    typeCD.typeArguments = <DartType>[classD.type];
    Set<InterfaceType> superinterfacesOfCD =
        InterfaceTypeImpl.computeSuperinterfaceSet(typeCD);
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
    ClassElement classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    ClassElement classB = ElementFactory.classElement("B", typeA, ["T"]);
    ClassElementImpl classC = ElementFactory.classElement2("C", ["T"]);
    InterfaceTypeImpl typeBT = new InterfaceTypeImpl(classB);
    DartType typeT = classC.type.typeArguments[0];
    typeBT.typeArguments = <DartType>[typeT];
    classC.supertype = typeBT;
    ClassElement classD = ElementFactory.classElement2("D");
    // A
    Set<InterfaceType> superinterfacesOfA =
        InterfaceTypeImpl.computeSuperinterfaceSet(typeA);
    expect(superinterfacesOfA, hasLength(1));
    InterfaceType typeObject = ElementFactory.object.type;
    expect(superinterfacesOfA.contains(typeObject), isTrue);
    // B<D>
    InterfaceTypeImpl typeBD = new InterfaceTypeImpl(classB);
    typeBD.typeArguments = <DartType>[classD.type];
    Set<InterfaceType> superinterfacesOfBD =
        InterfaceTypeImpl.computeSuperinterfaceSet(typeBD);
    expect(superinterfacesOfBD, hasLength(2));
    expect(superinterfacesOfBD.contains(typeObject), isTrue);
    expect(superinterfacesOfBD.contains(typeA), isTrue);
    // C<D>
    InterfaceTypeImpl typeCD = new InterfaceTypeImpl(classC);
    typeCD.typeArguments = <DartType>[classD.type];
    Set<InterfaceType> superinterfacesOfCD =
        InterfaceTypeImpl.computeSuperinterfaceSet(typeCD);
    expect(superinterfacesOfCD, hasLength(3));
    expect(superinterfacesOfCD.contains(typeObject), isTrue);
    expect(superinterfacesOfCD.contains(typeA), isTrue);
    expect(superinterfacesOfCD.contains(typeBD), isTrue);
  }

  void test_computeSuperinterfaceSet_multipleInterfacePaths() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    ClassElementImpl classD = ElementFactory.classElement2("D");
    ClassElementImpl classE = ElementFactory.classElement2("E");
    classB.interfaces = <InterfaceType>[classA.type];
    classC.interfaces = <InterfaceType>[classA.type];
    classD.interfaces = <InterfaceType>[classC.type];
    classE.interfaces = <InterfaceType>[classB.type, classD.type];
    // D
    Set<InterfaceType> superinterfacesOfD =
        InterfaceTypeImpl.computeSuperinterfaceSet(classD.type);
    expect(superinterfacesOfD, hasLength(3));
    expect(superinterfacesOfD.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfD.contains(classA.type), isTrue);
    expect(superinterfacesOfD.contains(classC.type), isTrue);
    // E
    Set<InterfaceType> superinterfacesOfE =
        InterfaceTypeImpl.computeSuperinterfaceSet(classE.type);
    expect(superinterfacesOfE, hasLength(5));
    expect(superinterfacesOfE.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfE.contains(classA.type), isTrue);
    expect(superinterfacesOfE.contains(classB.type), isTrue);
    expect(superinterfacesOfE.contains(classC.type), isTrue);
    expect(superinterfacesOfE.contains(classD.type), isTrue);
  }

  void test_computeSuperinterfaceSet_multipleSuperclassPaths() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElement classC = ElementFactory.classElement("C", classA.type);
    ClassElement classD = ElementFactory.classElement("D", classC.type);
    ClassElementImpl classE = ElementFactory.classElement("E", classB.type);
    classE.interfaces = <InterfaceType>[classD.type];
    // D
    Set<InterfaceType> superinterfacesOfD =
        InterfaceTypeImpl.computeSuperinterfaceSet(classD.type);
    expect(superinterfacesOfD, hasLength(3));
    expect(superinterfacesOfD.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfD.contains(classA.type), isTrue);
    expect(superinterfacesOfD.contains(classC.type), isTrue);
    // E
    Set<InterfaceType> superinterfacesOfE =
        InterfaceTypeImpl.computeSuperinterfaceSet(classE.type);
    expect(superinterfacesOfE, hasLength(5));
    expect(superinterfacesOfE.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfE.contains(classA.type), isTrue);
    expect(superinterfacesOfE.contains(classB.type), isTrue);
    expect(superinterfacesOfE.contains(classC.type), isTrue);
    expect(superinterfacesOfE.contains(classD.type), isTrue);
  }

  void test_computeSuperinterfaceSet_recursion() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.supertype = classB.type;
    Set<InterfaceType> superinterfacesOfB =
        InterfaceTypeImpl.computeSuperinterfaceSet(classB.type);
    expect(superinterfacesOfB, hasLength(2));
  }

  void test_computeSuperinterfaceSet_singleInterfacePath() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classB.interfaces = <InterfaceType>[classA.type];
    classC.interfaces = <InterfaceType>[classB.type];
    // A
    Set<InterfaceType> superinterfacesOfA =
        InterfaceTypeImpl.computeSuperinterfaceSet(classA.type);
    expect(superinterfacesOfA, hasLength(1));
    expect(superinterfacesOfA.contains(ElementFactory.object.type), isTrue);
    // B
    Set<InterfaceType> superinterfacesOfB =
        InterfaceTypeImpl.computeSuperinterfaceSet(classB.type);
    expect(superinterfacesOfB, hasLength(2));
    expect(superinterfacesOfB.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfB.contains(classA.type), isTrue);
    // C
    Set<InterfaceType> superinterfacesOfC =
        InterfaceTypeImpl.computeSuperinterfaceSet(classC.type);
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
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElement classC = ElementFactory.classElement("C", classB.type);
    // A
    Set<InterfaceType> superinterfacesOfA =
        InterfaceTypeImpl.computeSuperinterfaceSet(classA.type);
    expect(superinterfacesOfA, hasLength(1));
    expect(superinterfacesOfA.contains(ElementFactory.object.type), isTrue);
    // B
    Set<InterfaceType> superinterfacesOfB =
        InterfaceTypeImpl.computeSuperinterfaceSet(classB.type);
    expect(superinterfacesOfB, hasLength(2));
    expect(superinterfacesOfB.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfB.contains(classA.type), isTrue);
    // C
    Set<InterfaceType> superinterfacesOfC =
        InterfaceTypeImpl.computeSuperinterfaceSet(classC.type);
    expect(superinterfacesOfC, hasLength(3));
    expect(superinterfacesOfC.contains(ElementFactory.object.type), isTrue);
    expect(superinterfacesOfC.contains(classA.type), isTrue);
    expect(superinterfacesOfC.contains(classB.type), isTrue);
  }

  void test_creation() {
    expect(new InterfaceTypeImpl(ElementFactory.classElement2("A")), isNotNull);
  }

  void test_getAccessors() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A");
    PropertyAccessorElement getterG =
        ElementFactory.getterElement("g", false, null);
    PropertyAccessorElement getterH =
        ElementFactory.getterElement("h", false, null);
    typeElement.accessors = <PropertyAccessorElement>[getterG, getterH];
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
    expect(type.accessors.length, 2);
  }

  void test_getAccessors_empty() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A");
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
    expect(type.accessors.length, 0);
  }

  void test_getConstructors() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A");
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
    ClassElementImpl typeElement = ElementFactory.classElement2("A");
    typeElement.constructors = ConstructorElement.EMPTY_LIST;
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
    expect(type.constructors, isEmpty);
  }

  void test_getElement() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A");
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
    expect(type.element, typeElement);
  }

  void test_getGetter_implemented() {
    //
    // class A { g {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[getterG];
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
    PropertyAccessorElementImpl getterG =
        ElementFactory.getterElement(getterName, false, typeE);
    classA.accessors = <PropertyAccessorElement>[getterG];
    getterG.type = new FunctionTypeImpl(getterG);
    //
    // A<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I").type;
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(classA);
    typeAI.typeArguments = <DartType>[typeI];
    PropertyAccessorElement getter = typeAI.getGetter(getterName);
    expect(getter, isNotNull);
    FunctionType getterType = getter.type;
    expect(getterType.returnType, same(typeI));
  }

  void test_getGetter_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    expect(typeA.getGetter("g"), isNull);
  }

  void test_getInterfaces_nonParameterized() {
    //
    // class C implements A, B
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement2("B");
    InterfaceType typeB = classB.type;
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classC.interfaces = <InterfaceType>[typeA, typeB];
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
    InterfaceTypeImpl typeAF = new InterfaceTypeImpl(classA);
    typeAF.typeArguments = <DartType>[typeB.typeArguments[0]];
    classB.interfaces = <InterfaceType>[typeAF];
    //
    // B<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I").type;
    InterfaceTypeImpl typeBI = new InterfaceTypeImpl(classB);
    typeBI.typeArguments = <DartType>[typeI];
    List<InterfaceType> interfaces = typeBI.interfaces;
    expect(interfaces, hasLength(1));
    InterfaceType result = interfaces[0];
    expect(result.element, same(classA));
    expect(result.typeArguments[0], same(typeI));
  }

  void test_getMethod_implemented() {
    //
    // class A { m() {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[methodM];
    InterfaceType typeA = classA.type;
    expect(typeA.getMethod(methodName), same(methodM));
  }

  void test_getMethod_parameterized_doesNotUseTypeParameter() {
    //
    // class A<E> { void m() {} }
    // class B {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", ["E"]);
    InterfaceType typeB = ElementFactory.classElement2("B").type;
    DartType typeE = classA.type.typeArguments[0];
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeB, []);
    classA.methods = <MethodElement>[methodM];
    methodM.type = new FunctionTypeImpl(methodM);
    //
    // A<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I").type;
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(classA);
    typeAI.typeArguments = <DartType>[typeI];
    MethodElement method = typeAI.getMethod(methodName);
    expect(method, isNotNull);
    FunctionType methodType = method.type;
    expect(methodType.typeParameters, [same(typeE.element)]);
    expect(methodType.typeArguments, [same(typeI)]);
  }

  void test_getMethod_parameterized_flushCached_whenVersionChanges() {
    //
    // class A<E> { E m(E p) {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", ["E"]);
    DartType typeE = classA.type.typeArguments[0];
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeE, [typeE]);
    classA.methods = <MethodElement>[methodM];
    methodM.type = new FunctionTypeImpl(methodM);
    //
    // A<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I").type;
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(classA);
    typeAI.typeArguments = <DartType>[typeI];
    // Methods list is cached.
    MethodElement method = typeAI.methods.single;
    expect(typeAI.methods.single, same(method));
    // Methods list is flushed on version change.
    classA.version++;
    expect(typeAI.methods.single, isNot(same(method)));
  }

  void test_getMethod_parameterized_usesTypeParameter() {
    //
    // class A<E> { E m(E p) {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", ["E"]);
    DartType typeE = classA.type.typeArguments[0];
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeE, [typeE]);
    classA.methods = <MethodElement>[methodM];
    methodM.type = new FunctionTypeImpl(methodM);
    //
    // A<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I").type;
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(classA);
    typeAI.typeArguments = <DartType>[typeI];
    MethodElement method = typeAI.getMethod(methodName);
    expect(method, isNotNull);
    FunctionType methodType = method.type;
    expect(methodType.typeParameters, [same(typeE.element)]);
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    expect(typeA.getMethod("m"), isNull);
  }

  void test_getMethods() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A");
    MethodElementImpl methodOne = ElementFactory.methodElement("one", null);
    MethodElementImpl methodTwo = ElementFactory.methodElement("two", null);
    typeElement.methods = <MethodElement>[methodOne, methodTwo];
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
    expect(type.methods.length, 2);
  }

  void test_getMethods_empty() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A");
    InterfaceTypeImpl type = new InterfaceTypeImpl(typeElement);
    expect(type.methods.length, 0);
  }

  void test_getMixins_nonParameterized() {
    //
    // class C extends Object with A, B
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement2("B");
    InterfaceType typeB = classB.type;
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classC.mixins = <InterfaceType>[typeA, typeB];
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
    InterfaceTypeImpl typeAF = new InterfaceTypeImpl(classA);
    typeAF.typeArguments = <DartType>[typeB.typeArguments[0]];
    classB.mixins = <InterfaceType>[typeAF];
    //
    // B<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I").type;
    InterfaceTypeImpl typeBI = new InterfaceTypeImpl(classB);
    typeBI.typeArguments = <DartType>[typeI];
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setterS];
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
    PropertyAccessorElementImpl setterS =
        ElementFactory.setterElement(setterName, false, typeE);
    classA.accessors = <PropertyAccessorElement>[setterS];
    setterS.type = new FunctionTypeImpl(setterS);
    //
    // A<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I").type;
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(classA);
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    expect(typeA.getSetter("s"), isNull);
  }

  void test_getSuperclass_nonParameterized() {
    //
    // class B extends A
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement("B", typeA);
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
    InterfaceTypeImpl typeAF = new InterfaceTypeImpl(classA);
    typeAF.typeArguments = <DartType>[typeB.typeArguments[0]];
    classB.supertype = typeAF;
    //
    // B<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I").type;
    InterfaceTypeImpl typeBI = new InterfaceTypeImpl(classB);
    typeBI.typeArguments = <DartType>[typeI];
    InterfaceType superclass = typeBI.superclass;
    expect(superclass.element, same(classA));
    expect(superclass.typeArguments[0], same(typeI));
  }

  void test_getTypeArguments_empty() {
    InterfaceType type = ElementFactory.classElement2("A").type;
    expect(type.typeArguments, hasLength(0));
  }

  void test_hashCode() {
    ClassElement classA = ElementFactory.classElement2("A");
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
    InterfaceTypeImpl typeAF = new InterfaceTypeImpl(classA);
    typeAF.typeArguments = <DartType>[classB.typeParameters[0].type];
    InterfaceTypeImpl typeAG = new InterfaceTypeImpl(classA);
    typeAG.typeArguments = <DartType>[classB.typeParameters[1].type];
    expect(typeAG.isAssignableTo(typeAF), isFalse);
  }

  void test_isAssignableTo_void() {
    InterfaceTypeImpl intType = _typeProvider.intType;
    expect(VoidTypeImpl.instance.isAssignableTo(intType), isFalse);
  }

  void test_isDirectSupertypeOf_extends() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    expect(typeA.isDirectSupertypeOf(typeB), isTrue);
  }

  void test_isDirectSupertypeOf_false() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement2("B");
    ClassElement classC = ElementFactory.classElement("C", classB.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    expect(typeA.isDirectSupertypeOf(typeC), isFalse);
  }

  void test_isDirectSupertypeOf_implements() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    classB.interfaces = <InterfaceType>[typeA];
    expect(typeA.isDirectSupertypeOf(typeB), isTrue);
  }

  void test_isDirectSupertypeOf_with() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    classB.mixins = <InterfaceType>[typeA];
    expect(typeA.isDirectSupertypeOf(typeB), isTrue);
  }

  void test_isMoreSpecificThan_bottom() {
    DartType type = ElementFactory.classElement2("A").type;
    expect(BottomTypeImpl.instance.isMoreSpecificThan(type), isTrue);
  }

  void test_isMoreSpecificThan_covariance() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classI = ElementFactory.classElement2("I");
    ClassElement classJ = ElementFactory.classElement("J", classI.type);
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(classA);
    InterfaceTypeImpl typeAJ = new InterfaceTypeImpl(classA);
    typeAI.typeArguments = <DartType>[classI.type];
    typeAJ.typeArguments = <DartType>[classJ.type];
    expect(typeAJ.isMoreSpecificThan(typeAI), isTrue);
    expect(typeAI.isMoreSpecificThan(typeAJ), isFalse);
  }

  void test_isMoreSpecificThan_directSupertype() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    expect(typeB.isMoreSpecificThan(typeA), isTrue);
    // the opposite test tests a different branch in isMoreSpecificThan()
    expect(typeA.isMoreSpecificThan(typeB), isFalse);
  }

  void test_isMoreSpecificThan_dynamic() {
    InterfaceType type = ElementFactory.classElement2("A").type;
    expect(type.isMoreSpecificThan(DynamicTypeImpl.instance), isTrue);
  }

  void test_isMoreSpecificThan_generic() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classB = ElementFactory.classElement2("B");
    DartType dynamicType = DynamicTypeImpl.instance;
    InterfaceType typeAOfDynamic =
        classA.type.instantiate(<DartType>[dynamicType]);
    InterfaceType typeAOfB = classA.type.instantiate(<DartType>[classB.type]);
    expect(typeAOfDynamic.isMoreSpecificThan(typeAOfB), isFalse);
    expect(typeAOfB.isMoreSpecificThan(typeAOfDynamic), isTrue);
  }

  void test_isMoreSpecificThan_self() {
    InterfaceType type = ElementFactory.classElement2("A").type;
    expect(type.isMoreSpecificThan(type), isTrue);
  }

  void test_isMoreSpecificThan_transitive_interface() {
    //
    //  class A {}
    //  class B extends A {}
    //  class C implements B {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classC.interfaces = <InterfaceType>[classB.type];
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classC.mixins = <InterfaceType>[classB.type];
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement2("C");
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
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElement classC = ElementFactory.classElement("C", classB.type);
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
    ClassElement classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement2("B");
    TypeParameterElementImpl parameterEA =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    TypeParameterType parameterAEType = new TypeParameterTypeImpl(parameterEA);
    parameterEA.bound = typeA;
    parameterEA.type = parameterAEType;
    classB.typeParameters = <TypeParameterElementImpl>[parameterEA];
    expect(parameterAEType.isMoreSpecificThan(typeA), isTrue);
  }

  void test_isSubtypeOf_directSubtype() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    expect(typeB.isSubtypeOf(typeA), isTrue);
    expect(typeA.isSubtypeOf(typeB), isFalse);
  }

  void test_isSubtypeOf_dynamic() {
    ClassElement classA = ElementFactory.classElement2("A");
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.methods = <MethodElement>[
      ElementFactory.methodElement("call", VoidTypeImpl.instance, [stringType])
    ];
    FunctionType functionType = ElementFactory
        .functionElement5("f", <ClassElement>[stringType.element]).type;
    expect(classA.type.isSubtypeOf(functionType), isTrue);
  }

  void test_isSubtypeOf_generic() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classB = ElementFactory.classElement2("B");
    DartType dynamicType = DynamicTypeImpl.instance;
    InterfaceType typeAOfDynamic =
        classA.type.instantiate(<DartType>[dynamicType]);
    InterfaceType typeAOfB = classA.type.instantiate(<DartType>[classB.type]);
    expect(typeAOfDynamic.isSubtypeOf(typeAOfB), isTrue);
    expect(typeAOfB.isSubtypeOf(typeAOfDynamic), isTrue);
  }

  void test_isSubtypeOf_interface() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
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
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classC.mixins = <InterfaceType>[typeB];
    expect(typeC.isSubtypeOf(typeB), isTrue);
    expect(typeC.isSubtypeOf(typeObject), isTrue);
    expect(typeC.isSubtypeOf(typeA), isTrue);
    expect(typeA.isSubtypeOf(typeC), isFalse);
  }

  void test_isSubtypeOf_object() {
    ClassElement classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    InterfaceType typeObject = classA.supertype;
    expect(typeA.isSubtypeOf(typeObject), isTrue);
    expect(typeObject.isSubtypeOf(typeA), isFalse);
  }

  void test_isSubtypeOf_self() {
    ClassElement classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    expect(typeA.isSubtypeOf(typeA), isTrue);
  }

  void test_isSubtypeOf_transitive_recursive() {
    //
    //  class A extends B {}
    //  class B extends A {}
    //  class C {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    classA.supertype = classB.type;
    expect(typeA.isSubtypeOf(typeC), isFalse);
  }

  void test_isSubtypeOf_transitive_superclass() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElement classC = ElementFactory.classElement("C", classB.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    expect(typeC.isSubtypeOf(typeA), isTrue);
    expect(typeA.isSubtypeOf(typeC), isFalse);
  }

  void test_isSubtypeOf_typeArguments() {
    DartType dynamicType = DynamicTypeImpl.instance;
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classI = ElementFactory.classElement2("I");
    ClassElement classJ = ElementFactory.classElement("J", classI.type);
    ClassElement classK = ElementFactory.classElement2("K");
    InterfaceType typeA = classA.type;
    InterfaceType typeA_dynamic = typeA.instantiate(<DartType>[dynamicType]);
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl(classA);
    InterfaceTypeImpl typeAJ = new InterfaceTypeImpl(classA);
    InterfaceTypeImpl typeAK = new InterfaceTypeImpl(classA);
    typeAI.typeArguments = <DartType>[classI.type];
    typeAJ.typeArguments = <DartType>[classJ.type];
    typeAK.typeArguments = <DartType>[classK.type];
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
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    expect(typeB.isSupertypeOf(typeA), isFalse);
    expect(typeA.isSupertypeOf(typeB), isTrue);
  }

  void test_isSupertypeOf_dynamic() {
    ClassElement classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    DartType dynamicType = DynamicTypeImpl.instance;
    expect(dynamicType.isSupertypeOf(typeA), isTrue);
    expect(typeA.isSupertypeOf(dynamicType), isTrue);
  }

  void test_isSupertypeOf_indirectSupertype() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElement classC = ElementFactory.classElement("C", classB.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    expect(typeC.isSupertypeOf(typeA), isFalse);
    expect(typeA.isSupertypeOf(typeC), isTrue);
  }

  void test_isSupertypeOf_interface() {
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classC.interfaces = <InterfaceType>[typeB];
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
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement2("C");
    InterfaceType typeObject = classA.supertype;
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    classC.mixins = <InterfaceType>[typeB];
    expect(typeB.isSupertypeOf(typeC), isTrue);
    expect(typeObject.isSupertypeOf(typeC), isTrue);
    expect(typeA.isSupertypeOf(typeC), isTrue);
    expect(typeC.isSupertypeOf(typeA), isFalse);
  }

  void test_isSupertypeOf_object() {
    ClassElement classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    InterfaceType typeObject = classA.supertype;
    expect(typeA.isSupertypeOf(typeObject), isFalse);
    expect(typeObject.isSupertypeOf(typeA), isTrue);
  }

  void test_isSupertypeOf_self() {
    ClassElement classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    expect(typeA.isSupertypeOf(typeA), isTrue);
  }

  void test_lookUpGetter_implemented() {
    //
    // class A { g {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[getterG];
    InterfaceType typeA = classA.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpGetter(getterName, library), same(getterG));
  }

  void test_lookUpGetter_inherited() {
    //
    // class A { g {} }
    // class B extends A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    InterfaceType typeB = classB.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
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
    ClassElementImpl classB = ElementFactory.classElement2('B');
    ClassElementImpl classM1 = ElementFactory.classElement2('M1');
    PropertyAccessorElementImpl getterM1g = ElementFactory.getterElement(
        getterName, false, typeProvider.dynamicType);
    classM1.accessors = <PropertyAccessorElement>[getterM1g];
    ClassElementImpl classM2 = ElementFactory.classElement2('M2');
    PropertyAccessorElementImpl getterM2g = ElementFactory.getterElement(
        getterName, false, typeProvider.dynamicType);
    classM2.accessors = <PropertyAccessorElement>[getterM2g];
    ClassElementImpl classC = ElementFactory.classElement('C', classB.type);
    classC.mixins = <InterfaceType>[classM1.type, classM2.type];
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElementImpl unit = library.definingCompilationUnit;
    unit.types = <ClassElement>[classB, classM1, classM2, classC];
    expect(classC.type.lookUpGetter(getterName, library), getterM2g);
  }

  void test_lookUpGetter_recursive() {
    //
    // class A extends B {}
    // class B extends A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement("B", typeA);
    classA.supertype = classB.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpGetter_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpMethod_implemented() {
    //
    // class A { m() {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[methodM];
    InterfaceType typeA = classA.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpMethod(methodName, library), same(methodM));
  }

  void test_lookUpMethod_inherited() {
    //
    // class A { m() {} }
    // class B extends A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl methodM = ElementFactory.methodElement(methodName, null);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    InterfaceType typeB = classB.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
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
    ClassElementImpl classB = ElementFactory.classElement2('B');
    ClassElementImpl classM1 = ElementFactory.classElement2('M1');
    MethodElementImpl methodM1m =
        ElementFactory.methodElement(methodName, null);
    classM1.methods = <MethodElement>[methodM1m];
    ClassElementImpl classM2 = ElementFactory.classElement2('M2');
    MethodElementImpl methodM2m =
        ElementFactory.methodElement(methodName, null);
    classM2.methods = <MethodElement>[methodM2m];
    ClassElementImpl classC = ElementFactory.classElement('C', classB.type);
    classC.mixins = <InterfaceType>[classM1.type, classM2.type];
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElementImpl unit = library.definingCompilationUnit;
    unit.types = <ClassElement>[classB, classM1, classM2, classC];
    expect(classC.type.lookUpMethod(methodName, library), methodM2m);
  }

  void test_lookUpMethod_parameterized() {
    //
    // class A<E> { E m(E p) {} }
    // class B<F> extends A<F> {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", ["E"]);
    DartType typeE = classA.type.typeArguments[0];
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeE, [typeE]);
    classA.methods = <MethodElement>[methodM];
    methodM.type = new FunctionTypeImpl(methodM);
    ClassElementImpl classB = ElementFactory.classElement2("B", ["F"]);
    InterfaceType typeB = classB.type;
    InterfaceTypeImpl typeAF = new InterfaceTypeImpl(classA);
    typeAF.typeArguments = <DartType>[typeB.typeArguments[0]];
    classB.supertype = typeAF;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    //
    // B<I>
    //
    InterfaceType typeI = ElementFactory.classElement2("I").type;
    InterfaceTypeImpl typeBI = new InterfaceTypeImpl(classB);
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement("B", typeA);
    classA.supertype = classB.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpMethod_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpSetter_implemented() {
    //
    // class A { s(x) {} }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setterS];
    InterfaceType typeA = classA.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpSetter(setterName, library), same(setterS));
  }

  void test_lookUpSetter_inherited() {
    //
    // class A { s(x) {} }
    // class B extends A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "g";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement>[setterS];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    InterfaceType typeB = classB.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
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
    ClassElementImpl classB = ElementFactory.classElement2('B');
    ClassElementImpl classM1 = ElementFactory.classElement2('M1');
    PropertyAccessorElementImpl setterM1g = ElementFactory.setterElement(
        setterName, false, typeProvider.dynamicType);
    classM1.accessors = <PropertyAccessorElement>[setterM1g];
    ClassElementImpl classM2 = ElementFactory.classElement2('M2');
    PropertyAccessorElementImpl setterM2g = ElementFactory.getterElement(
        setterName, false, typeProvider.dynamicType);
    classM2.accessors = <PropertyAccessorElement>[setterM2g];
    ClassElementImpl classC = ElementFactory.classElement('C', classB.type);
    classC.mixins = <InterfaceType>[classM1.type, classM2.type];
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElementImpl unit = library.definingCompilationUnit;
    unit.types = <ClassElement>[classB, classM1, classM2, classC];
    expect(classC.type.lookUpGetter(setterName, library), setterM2g);
  }

  void test_lookUpSetter_recursive() {
    //
    // class A extends B {}
    // class B extends A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement("B", typeA);
    classA.supertype = classB.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA, classB];
    expect(typeA.lookUpSetter("s", library), isNull);
  }

  void test_lookUpSetter_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    LibraryElementImpl library =
        ElementFactory.library(createAnalysisContext(), "lib");
    CompilationUnitElement unit = library.definingCompilationUnit;
    (unit as CompilationUnitElementImpl).types = <ClassElement>[classA];
    expect(typeA.lookUpSetter("s", library), isNull);
  }

  void test_resolveToBound() {
    InterfaceTypeImpl type =
        ElementFactory.classElement2("A").type as InterfaceTypeImpl;

    // Returns this.
    expect(type.resolveToBound(null), same(type));
  }

  void test_setTypeArguments() {
    InterfaceTypeImpl type =
        ElementFactory.classElement2("A").type as InterfaceTypeImpl;
    List<DartType> typeArguments = <DartType>[
      ElementFactory.classElement2("B").type,
      ElementFactory.classElement2("C").type
    ];
    type.typeArguments = typeArguments;
    expect(type.typeArguments, typeArguments);
  }

  void test_substitute_equal() {
    ClassElement classAE = ElementFactory.classElement2("A", ["E"]);
    InterfaceType typeAE = classAE.type;
    InterfaceType argumentType = ElementFactory.classElement2("B").type;
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
      ClassElementImpl classA = ElementFactory.classElement2("A");
      InterfaceTypeImpl type = new InterfaceTypeImpl(classA);
      InterfaceType argumentType = ElementFactory.classElement2("B").type;
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
    ClassElementImpl classA = ElementFactory.classElement2("A");
    TypeParameterElementImpl parameterElement =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    InterfaceTypeImpl type = new InterfaceTypeImpl(classA);
    TypeParameterTypeImpl parameter =
        new TypeParameterTypeImpl(parameterElement);
    type.typeArguments = <DartType>[parameter];
    InterfaceType argumentType = ElementFactory.classElement2("B").type;
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
class LibraryElementImplTest extends EngineTestCase {
  void test_creation() {
    expect(
        new LibraryElementImpl.forNode(
            createAnalysisContext(), AstTestFactory.libraryIdentifier2(["l"])),
        isNotNull);
  }

  void test_getImportedLibraries() {
    AnalysisContext context = createAnalysisContext();
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
    AnalysisContext context = createAnalysisContext();
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
    AnalysisContext context = createAnalysisContext();
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

  void test_invalidateLibraryCycles_withHandle() {
    AnalysisContext context = createAnalysisContext();
    context.sourceFactory = new SourceFactory([]);
    LibraryElementImpl library = ElementFactory.library(context, "foo");
    LibraryElementImpl importedLibrary = ElementFactory.library(context, "bar");
    ElementLocation location = new ElementLocationImpl.con2('');
    TestElementResynthesizer resynthesizer =
        new TestElementResynthesizer(context, {location: importedLibrary});
    LibraryElement importedLibraryHandle =
        new LibraryElementHandle(resynthesizer, location);
    ImportElementImpl import =
        ElementFactory.importFor(importedLibraryHandle, null);
    library.imports = <ImportElement>[import];
    library.libraryCycle; // Force computation of the cycle.

    library.invalidateLibraryCycles();
  }

  void test_setImports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = new LibraryElementImpl.forNode(
        context, AstTestFactory.libraryIdentifier2(["l1"]));
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
class LocalVariableElementImplTest extends EngineTestCase {}

@reflectiveTest
class MethodElementImplTest extends EngineTestCase {
  void test_computeNode() {
    AnalysisContextHelper contextHelper = new AnalysisContextHelper();
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
abstract class A {
  String m1() => null;
  m2();
}
''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    // m1
    {
      MethodElement m1Element = unitElement.getType("A").getMethod('m1');
      MethodDeclaration m1Node = m1Element.computeNode();
      expect(m1Node, isNotNull);
      expect(m1Node.name.name, "m1");
      expect(m1Node.element, same(m1Element));
    }
    // m2
    {
      MethodElement m2Element = unitElement.getType("A").getMethod('m2');
      MethodDeclaration m2Node = m2Element.computeNode();
      expect(m2Node, isNotNull);
      expect(m2Node.name.name, "m2");
      expect(m2Node.element, same(m2Element));
    }
  }

  void test_computeNode_withoutFunctionBody() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.analyzeFunctionBodies = false;
    AnalysisContextHelper contextHelper = new AnalysisContextHelper(options);
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
abstract class A {
  String m1() => null;
  m2();
}
''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    // m1
    {
      MethodElement m1Element = unitElement.getType("A").getMethod('m1');
      MethodDeclaration m1Node = m1Element.computeNode();
      expect(m1Node, isNotNull);
      expect(m1Node.name.name, "m1");
      expect(m1Node.element, same(m1Element));
    }
    // m2
    {
      MethodElement m2Element = unitElement.getType("A").getMethod('m2');
      MethodDeclaration m2Node = m2Element.computeNode();
      expect(m2Node, isNotNull);
      expect(m2Node.name.name, "m2");
      expect(m2Node.element, same(m2Element));
    }
  }
}

@reflectiveTest
class MethodMemberTest extends EngineTestCase {
  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  @override
  void setUp() {
    super.setUp();
    _typeProvider = new TestTypeProvider();
  }

  void test_getReifiedType_substituteFor() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.analyzeFunctionBodies = false;
    AnalysisContextHelper contextHelper = new AnalysisContextHelper(options);
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
class A<T> {
  T f(T x) => x;
}
class B<S> extends A<S> {
  S f(S x) => x;
}
''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    DartType objectType = _typeProvider.objectType;
    // B.f
    ClassElement elementB = unitElement.getType("B");
    MethodElement BfElement = elementB.type
        .lookUpInheritedMethod("f", library: libraryElement, thisType: true);
    MethodElement AfElement = elementB.type
        .lookUpInheritedMethod("f", library: libraryElement, thisType: false);
    expect(BfElement.getReifiedType(objectType),
        equals(AfElement.getReifiedType(objectType)));
  }
}

@reflectiveTest
class MultiplyDefinedElementImplTest extends EngineTestCase {
  void test_fromElements_conflicting() {
    TopLevelVariableElement firstElement =
        ElementFactory.topLevelVariableElement2('xx');
    TopLevelVariableElement secondElement =
        ElementFactory.topLevelVariableElement2('yy');
    _addToLibrary([firstElement, secondElement]);
    Element result = MultiplyDefinedElementImpl.fromElements(
        null, firstElement, secondElement);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MultiplyDefinedElement, MultiplyDefinedElement, result);
    List<Element> elements =
        (result as MultiplyDefinedElement).conflictingElements;
    expect(elements, hasLength(2));
    for (int i = 0; i < elements.length; i++) {
      EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement,
          TopLevelVariableElement, elements[i]);
    }
  }

  void test_fromElements_multiple() {
    TopLevelVariableElement firstElement =
        ElementFactory.topLevelVariableElement2('xx');
    TopLevelVariableElement secondElement =
        ElementFactory.topLevelVariableElement2('yy');
    TopLevelVariableElement thirdElement =
        ElementFactory.topLevelVariableElement2('zz');
    _addToLibrary([firstElement, secondElement, thirdElement]);
    Element result = MultiplyDefinedElementImpl.fromElements(
        null,
        MultiplyDefinedElementImpl.fromElements(
            null, firstElement, secondElement),
        thirdElement);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MultiplyDefinedElement, MultiplyDefinedElement, result);
    List<Element> elements =
        (result as MultiplyDefinedElement).conflictingElements;
    expect(elements, hasLength(3));
    for (int i = 0; i < elements.length; i++) {
      EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement,
          TopLevelVariableElement, elements[i]);
    }
  }

  void test_fromElements_nonConflicting() {
    TopLevelVariableElement element =
        ElementFactory.topLevelVariableElement2('xx');
    _addToLibrary([element]);
    expect(MultiplyDefinedElementImpl.fromElements(null, element, element),
        same(element));
  }

  void _addToLibrary(List<TopLevelVariableElement> variables) {
    CompilationUnitElementImpl compilationUnit =
        ElementFactory.compilationUnit('lib.dart');
    LibraryElementImpl library = ElementFactory.library(null, 'lib');
    library.definingCompilationUnit = compilationUnit;
    compilationUnit.topLevelVariables = variables;
  }
}

@reflectiveTest
class ParameterElementImplTest extends EngineTestCase {
  void test_computeNode_DefaultFormalParameter() {
    AnalysisContextHelper contextHelper = new AnalysisContextHelper();
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
main([int p = 42]) {
}''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    // p
    {
      ParameterElement element = unitElement.functions[0].parameters[0];
      DefaultFormalParameter node = element.computeNode();
      expect(node, isNotNull);
      expect(node.identifier.name, 'p');
      expect(node.element, same(element));
    }
  }

  void test_computeNode_FieldFormalParameter() {
    AnalysisContextHelper contextHelper = new AnalysisContextHelper();
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
class A {
  int p;
  A(this.p) {
  }
}''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    // p
    {
      ClassElement classA = unitElement.types[0];
      ConstructorElement constructorA = classA.constructors[0];
      FieldFormalParameterElement element = constructorA.parameters[0];
      FieldFormalParameter node = element.computeNode();
      expect(node, isNotNull);
      expect(node.identifier.name, 'p');
      expect(node.element, same(element));
    }
  }

  void test_computeNode_FunctionTypedFormalParameter() {
    AnalysisContextHelper contextHelper = new AnalysisContextHelper();
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
main(p(int a, int b)) {
}''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    // p
    {
      ParameterElement element = unitElement.functions[0].parameters[0];
      FunctionTypedFormalParameter node = element.computeNode();
      expect(node, isNotNull);
      expect(node.identifier.name, 'p');
      expect(node.element, same(element));
    }
  }

  void test_computeNode_SimpleFormalParameter() {
    AnalysisContextHelper contextHelper = new AnalysisContextHelper();
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", r'''
main(int p) {
}''');
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    // p
    {
      ParameterElement element = unitElement.functions[0].parameters[0];
      SimpleFormalParameter node = element.computeNode();
      expect(node, isNotNull);
      expect(node.identifier.name, 'p');
      expect(node.element, same(element));
    }
  }
}

@reflectiveTest
class PropertyAccessorElementImplTest extends EngineTestCase {
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
    expect(element == handle, isTrue);
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
    expect(element == handle, isTrue);
    expect(handle == element, isTrue);
  }
}

class TestElementResynthesizer extends ElementResynthesizer {
  Map<ElementLocation, Element> locationMap;

  TestElementResynthesizer(AnalysisContext context, this.locationMap)
      : super(context);

  @override
  Element getElement(ElementLocation location) {
    return locationMap[location];
  }
}

@reflectiveTest
class TopLevelVariableElementImplTest extends ResolverTestCase {
  void test_computeConstantValue() {
    addNamedSource('/a.dart', r'''
const int C = 42;
''');
    Source source = addSource(r'''
import 'a.dart';
main() {
  print(C);
}
''');
    LibraryElement library = resolve2(source);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration main = unit.declarations[0];
    BlockFunctionBody body = main.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;
    SimpleIdentifier argument = invocation.argumentList.arguments[0];
    PropertyAccessorElementImpl getter = argument.bestElement;
    TopLevelVariableElement constant = getter.variable;
    expect(constant.constantValue, isNull);
    DartObject value = constant.computeConstantValue();
    expect(value, isNotNull);
    expect(value.toIntValue(), 42);
    expect(constant.constantValue, value);
  }
}

@reflectiveTest
class TypeParameterTypeImplTest extends EngineTestCase {
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
    expect(type.isMoreSpecificThan(ElementFactory.object.type), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_recursive() {
    ClassElementImpl classS = ElementFactory.classElement2("A");
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
    expect(typeParameterTypeT.isMoreSpecificThan(classS.type), isFalse);
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
    ClassElement classA = ElementFactory.classElement2("A");
    ClassElement classB = ElementFactory.classElement("B", classA.type);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
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
    ClassElementImpl classS = ElementFactory.classElement2("A");
    TypeParameterElementImpl typeParameterU =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("U"));
    typeParameterU.bound = classS.type;
    TypeParameterTypeImpl typeParameterTypeU =
        new TypeParameterTypeImpl(typeParameterU);
    TypeParameterElementImpl typeParameterT =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("T"));
    typeParameterT.bound = typeParameterTypeU;
    TypeParameterTypeImpl typeParameterTypeT =
        new TypeParameterTypeImpl(typeParameterT);
    // <T extends U> and <U extends S>
    // T << S
    expect(typeParameterTypeT.isMoreSpecificThan(classS.type), isTrue);
  }

  void test_isMoreSpecificThan_typeArguments_upperBound() {
    ClassElementImpl classS = ElementFactory.classElement2("A");
    TypeParameterElementImpl typeParameterT =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("T"));
    typeParameterT.bound = classS.type;
    TypeParameterTypeImpl typeParameterTypeT =
        new TypeParameterTypeImpl(typeParameterT);
    // <T extends S>
    // T << S
    expect(typeParameterTypeT.isMoreSpecificThan(classS.type), isTrue);
  }

  void test_resolveToBound_bound() {
    ClassElementImpl classS = ElementFactory.classElement2("A");
    TypeParameterElementImpl element =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    element.bound = classS.type;
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    expect(type.resolveToBound(null), same(classS.type));
  }

  void test_resolveToBound_nestedBound() {
    ClassElementImpl classS = ElementFactory.classElement2("A");
    TypeParameterElementImpl elementE =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("E"));
    elementE.bound = classS.type;
    TypeParameterTypeImpl typeE = new TypeParameterTypeImpl(elementE);
    TypeParameterElementImpl elementF =
        new TypeParameterElementImpl.forNode(AstTestFactory.identifier3("F"));
    elementF.bound = typeE;
    TypeParameterTypeImpl typeF = new TypeParameterTypeImpl(elementE);
    expect(typeF.resolveToBound(null), same(classS.type));
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
class VoidTypeImplTest extends EngineTestCase {
  /**
   * Reference {code VoidTypeImpl.getInstance()}.
   */
  DartType _voidType = VoidTypeImpl.instance;

  void test_isMoreSpecificThan_void_A() {
    ClassElement classA = ElementFactory.classElement2("A");
    expect(_voidType.isMoreSpecificThan(classA.type), isFalse);
  }

  void test_isMoreSpecificThan_void_dynamic() {
    expect(_voidType.isMoreSpecificThan(DynamicTypeImpl.instance), isTrue);
  }

  void test_isMoreSpecificThan_void_void() {
    expect(_voidType.isMoreSpecificThan(_voidType), isTrue);
  }

  void test_isSubtypeOf_void_A() {
    ClassElement classA = ElementFactory.classElement2("A");
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
