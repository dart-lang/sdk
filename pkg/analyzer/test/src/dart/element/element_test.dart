// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: analyzer_use_new_elements

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';
import '../../../util/feature_sets.dart';
import '../../summary/elements_base.dart';
import '../resolution/context_collection_resolution.dart';
import 'string_types.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementAnnotationImplTest);
    defineReflectiveTests(FieldElementImplTest);
    defineReflectiveTests(FunctionTypeImplTest);
    defineReflectiveTests(InterfaceTypeImplTest);
    defineReflectiveTests(MaybeAugmentedInstanceElementMixinTest);
    defineReflectiveTests(MethodElementImplTest);
    defineReflectiveTests(TypeParameterTypeImplTest);
    defineReflectiveTests(ClassElementImplTest);
    defineReflectiveTests(MixinElementImplTest);
    defineReflectiveTests(ElementLocationImplTest);
    defineReflectiveTests(ElementImplTest);
    defineReflectiveTests(TopLevelVariableElementImplTest);
  });
}

@reflectiveTest
class ClassElementImplTest extends _AbstractTypeSystemTest {
  void test_getField() {
    var classA = class_3(name: 'A');
    String fieldName = "f";
    FieldElementImpl field =
        ElementFactory.fieldElement(fieldName, false, false, false, intNone);
    classA.fields = [field];
    expect(classA.getField(fieldName), same(field));
    expect(field.isEnumConstant, false);
    // no such field
    expect(classA.getField("noSuchField"), isNull);
  }

  void test_getMethod_declared() {
    var classA = class_3(name: 'A');
    String methodName = "m";
    var method = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [method];
    expect(classA.getMethod(methodName), same(method));
  }

  void test_getMethod_undeclared() {
    var classA = class_3(name: 'A');
    String methodName = "m";
    var method = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [method];
    expect(classA.getMethod("${methodName}x"), isNull);
  }

  void test_hasNonFinalField_false_const() {
    var classA = class_3(name: 'A');
    classA.fields = [
      ElementFactory.fieldElement(
          "f", false, false, true, interfaceTypeNone3(classA))
    ];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_final() {
    var classA = class_3(name: 'A');
    classA.fields = [
      ElementFactory.fieldElement(
          "f", false, true, false, interfaceTypeNone3(classA))
    ];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_recursive() {
    var classA = class_3(name: 'A');
    ClassElementImpl classB = class_3(
      name: 'B',
      superType: interfaceTypeNone3(classA),
    );
    classA.supertype = interfaceTypeNone3(classB);
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_true_immediate() {
    var classA = class_3(name: 'A');
    classA.fields = [
      ElementFactory.fieldElement(
          "f", false, false, false, interfaceTypeNone3(classA))
    ];
    expect(classA.hasNonFinalField, isTrue);
  }

  void test_hasNonFinalField_true_inherited() {
    var classA = class_3(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeNone3(classA));
    classA.fields = [
      ElementFactory.fieldElement(
          "f", false, false, false, interfaceTypeNone3(classA))
    ];
    expect(classB.hasNonFinalField, isTrue);
  }

  void test_isExhaustive() {
    var element = ElementFactory.classElement2("C");
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_base() {
    var element = ElementFactory.classElement4("C", isBase: true);
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_final() {
    var element = ElementFactory.classElement4("C", isFinal: true);
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_interface() {
    var element = ElementFactory.classElement4("C", isInterface: true);
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_mixinClass() {
    var element = ElementFactory.classElement4("C", isMixinClass: true);
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_sealed() {
    var element = ElementFactory.classElement4("C", isSealed: true);
    expect(element.isExhaustive, isTrue);
  }

  void test_isExtendableIn_base_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isBase: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isTrue);
  }

  void test_isExtendableIn_base_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isBase: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isExtendableIn_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement2("C");
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isTrue);
  }

  void test_isExtendableIn_final_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isFalse);
  }

  void test_isExtendableIn_final_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isExtendableIn_interface_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isFalse);
  }

  void test_isExtendableIn_interface_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isExtendableIn_mixinClass_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isTrue);
  }

  void test_isExtendableIn_mixinClass_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isExtendableIn_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement2("C");
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isExtendableIn_sealed_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isFalse);
  }

  void test_isExtendableIn_sealed_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isImplementableIn_base_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isBase: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isFalse);
  }

  void test_isImplementableIn_base_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isBase: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement2("C");
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isTrue);
  }

  void test_isImplementableIn_final_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isFalse);
  }

  void test_isImplementableIn_final_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_interface_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isTrue);
  }

  void test_isImplementableIn_interface_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_mixinClass_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isTrue);
  }

  void test_isImplementableIn_mixinClass_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement2("C");
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_sealed_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isFalse);
  }

  void test_isImplementableIn_sealed_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isMixableIn_base_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isBase: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_base_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isBase: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement2("C");
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_differentLibrary_oldVersion() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.language_2_19);
    var classElement = ElementFactory.classElement2("C");
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isTrue);
  }

  void test_isMixableIn_final_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_final_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_interface_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_interface_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_mixinClass_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isTrue);
  }

  void test_isMixableIn_mixinClass_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement2("C");
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_sealed_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_sealed_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_lookUpConcreteMethod_declared() {
    // class A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    String methodName = "m";
    var method = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [method];
    library.definingCompilationUnit.classes = [classA];
    expect(classA.lookUpConcreteMethod(methodName, library), same(method));
  }

  void test_lookUpConcreteMethod_declaredAbstract() {
    // class A {
    //   m();
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    String methodName = "m";
    MethodElementImpl method =
        ElementFactory.methodElement(methodName, intNone);
    method.isAbstract = true;
    classA.methods = [method];
    library.definingCompilationUnit.classes = [classA];
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
    var classA = class_3(name: 'A');
    String methodName = "m";
    var inheritedMethod = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeNone3(classA));
    MethodElementImpl method =
        ElementFactory.methodElement(methodName, intNone);
    method.isAbstract = true;
    classB.methods = [method];
    library.definingCompilationUnit.classes = [classA, classB];
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
    var classA = class_3(name: 'A');
    String methodName = "m";
    var inheritedMethod = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeNone3(classA));
    var method = ElementFactory.methodElement(methodName, intNone);
    classB.methods = [method];
    library.definingCompilationUnit.classes = [classA, classB];
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
    var classA = class_3(name: 'A');
    classA.isAbstract = true;
    String methodName = "m";
    MethodElementImpl inheritedMethod =
        ElementFactory.methodElement(methodName, intNone);
    inheritedMethod.isAbstract = true;
    classA.methods = [inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeNone3(classA));
    var method = ElementFactory.methodElement(methodName, intNone);
    classB.methods = [method];
    library.definingCompilationUnit.classes = [classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library), same(method));
  }

  void test_lookUpConcreteMethod_inherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    String methodName = "m";
    var inheritedMethod = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeNone3(classA));
    library.definingCompilationUnit.classes = [classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpConcreteMethod_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    library.definingCompilationUnit.classes = [classA];
    expect(classA.lookUpConcreteMethod("m", library), isNull);
  }

  void test_lookUpGetter_declared() {
    // class A {
    //   get g {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    String getterName = "g";
    var getter = ElementFactory.getterElement(getterName, false, intNone);
    classA.accessors = [getter];
    library.definingCompilationUnit.classes = [classA];
    // ignore: deprecated_member_use_from_same_package
    expect(classA.lookUpGetter(getterName, library), same(getter));
  }

  void test_lookUpGetter_inherited() {
    // class A {
    //   get g {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    String getterName = "g";
    var getter = ElementFactory.getterElement(getterName, false, intNone);
    classA.accessors = [getter];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeNone3(classA));
    library.definingCompilationUnit.classes = [classA, classB];
    // ignore: deprecated_member_use_from_same_package
    expect(classB.lookUpGetter(getterName, library), same(getter));
  }

  void test_lookUpGetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    library.definingCompilationUnit.classes = [classA];
    // ignore: deprecated_member_use_from_same_package
    expect(classA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpGetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeNone3(classA));
    classA.supertype = interfaceTypeNone3(classB);
    library.definingCompilationUnit.classes = [classA, classB];
    // ignore: deprecated_member_use_from_same_package
    expect(classA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpMethod_declared() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    String methodName = "m";
    var method = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [method];
    library.definingCompilationUnit.classes = [classA];
    // ignore: deprecated_member_use_from_same_package
    expect(classA.lookUpMethod(methodName, library), same(method));
  }

  void test_lookUpMethod_inherited() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    String methodName = "m";
    var method = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [method];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeNone3(classA));
    library.definingCompilationUnit.classes = [classA, classB];
    // ignore: deprecated_member_use_from_same_package
    expect(classB.lookUpMethod(methodName, library), same(method));
  }

  void test_lookUpMethod_undeclared() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    library.definingCompilationUnit.classes = [classA];
    // ignore: deprecated_member_use_from_same_package
    expect(classA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpMethod_undeclared_recursive() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeNone3(classA));
    classA.supertype = interfaceTypeNone3(classB);
    library.definingCompilationUnit.classes = [classA, classB];
    // ignore: deprecated_member_use_from_same_package
    expect(classA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpSetter_declared() {
    // class A {
    //   set g(x) {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    String setterName = "s";
    var setter = ElementFactory.setterElement(setterName, false, intNone);
    classA.accessors = [setter];
    library.definingCompilationUnit.classes = [classA];
    // ignore: deprecated_member_use_from_same_package
    expect(classA.lookUpSetter(setterName, library), same(setter));
  }

  void test_lookUpSetter_inherited() {
    // class A {
    //   set g(x) {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    String setterName = "s";
    var setter = ElementFactory.setterElement(setterName, false, intNone);
    classA.accessors = [setter];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeNone3(classA));
    library.definingCompilationUnit.classes = [classA, classB];
    // ignore: deprecated_member_use_from_same_package
    expect(classB.lookUpSetter(setterName, library), same(setter));
  }

  void test_lookUpSetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    library.definingCompilationUnit.classes = [classA];
    // ignore: deprecated_member_use_from_same_package
    expect(classA.lookUpSetter("s", library), isNull);
  }

  void test_lookUpSetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_3(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeNone3(classA));
    classA.supertype = interfaceTypeNone3(classB);
    library.definingCompilationUnit.classes = [classA, classB];
    // ignore: deprecated_member_use_from_same_package
    expect(classA.lookUpSetter("s", library), isNull);
  }

  LibraryElementImpl _newLibrary() =>
      ElementFactory.library(analysisContext, 'lib');
}

@reflectiveTest
class ElementAnnotationImplTest extends PubPackageResolutionTest {
  test_computeConstantValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
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
    var parameter = argument.correspondingParameter!;

    ElementAnnotation annotation = parameter.metadata[0];

    DartObject value = annotation.computeConstantValue()!;
    expect(value.getField('f')!.toStringValue(), 'x');
  }
}

@reflectiveTest
class ElementImplTest extends AbstractTypeSystemTest {
  void test_equals() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    ClassElementImpl classElement = ElementFactory.classElement2("C");
    library.definingCompilationUnit.classes = [classElement];
    var field = ElementFactory.fieldElement(
      "next",
      false,
      false,
      false,
      classElement.instantiateImpl(
        typeArguments: [],
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
    classElement.fields = [field];
    expect(field == field, isTrue);
    // ignore: unrelated_type_equality_checks
    expect(field == field.getter, isFalse);
    // ignore: unrelated_type_equality_checks
    expect(field == field.setter, isFalse);
    expect(field.getter == field.setter, isFalse);
  }

  void test_isAccessibleIn_private_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement2("_C");
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isAccessibleIn(library2), isFalse);
  }

  void test_isAccessibleIn_private_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement2("_C");
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isAccessibleIn(library), isTrue);
  }

  void test_isAccessibleIn_public_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement2("C");
    library1.definingCompilationUnit.classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isAccessibleIn(library2), isTrue);
  }

  void test_isAccessibleIn_public_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement2("C");
    library.definingCompilationUnit.classes = [classElement];
    expect(classElement.isAccessibleIn(library), isTrue);
  }

  void test_isPrivate_false() {
    Element element = ElementFactory.classElement2("C");
    expect(element.isPrivate, isFalse);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  void test_isPrivate_null() {
    Element element = ElementFactory.classElement2('A');
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

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  void test_isPublic_null() {
    Element element = ElementFactory.classElement2('A');
    expect(element.isPublic, isFalse);
  }

  void test_isPublic_true() {
    Element element = ElementFactory.classElement2("C");
    expect(element.isPublic, isTrue);
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

    FieldElement b2Element = B.getField('B2')!;
    expect(b2Element.isEnumConstant, isTrue);

    FieldElement valuesElement = B.getField('values')!;
    expect(valuesElement.isEnumConstant, isFalse);
  }
}

@reflectiveTest
class FunctionTypeImplTest extends AbstractTypeSystemTest {
  void assertType(DartType type, String expected) {
    var typeStr = type.getDisplayString();
    expect(typeStr, expected);
  }

  void test_getNamedParameterTypes_namedParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [
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
      typeParameters: [],
      formalParameters: [
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
      typeParameters: [],
      formalParameters: [],
      returnType: voidNone,
    );
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_noNormalParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [
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
      typeParameters: [],
      formalParameters: [],
      returnType: voidNone,
    );
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_normalParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [
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
      typeParameters: [],
      formalParameters: [
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
      typeParameters: [],
      formalParameters: [],
      returnType: voidNone,
    );
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getOptionalParameterTypes_optionalParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [
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
}

@reflectiveTest
class InterfaceTypeImplTest extends _AbstractTypeSystemTest with StringTypes {
  void test_allSupertypes() {
    void check(InterfaceType type, List<String> expected) {
      var actual = type.allSupertypes.map((e) {
        return e.getDisplayString();
      }).toList()
        ..sort();
      expect(actual, expected);
    }

    check(objectNone, []);
    check(numNone, ['Comparable<num>', 'Object']);
    check(intNone, ['Comparable<num>', 'Object', 'num']);
    check(intQuestion, ['Comparable<num>?', 'Object?', 'num?']);
    check(listNone(intQuestion), ['Iterable<int?>', 'Object']);
  }

  test_asInstanceOf_explicitGeneric() {
    // class A<E> {}
    // class B implements A<C> {}
    // class C {}
    var A = class_3(name: 'A', typeParameters: [
      typeParameter('E'),
    ]);
    var C = class_3(name: 'C');

    var AofC = A.instantiateImpl(
      typeArguments: [
        interfaceTypeNone3(C),
      ],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var B = class_3(
      name: 'B',
      interfaces: [AofC],
    );
    var targetType = interfaceTypeNone3(B);
    var result = targetType.asInstanceOf2(A.asElement2);
    expect(result, AofC);
  }

  test_asInstanceOf_passThroughGeneric() {
    // class A<E> {}
    // class B<E> implements A<E> {}
    // class C {}
    var AE = typeParameter('E');
    var A = class_3(name: 'A', typeParameters: [AE]);

    var BE = typeParameter('E');
    var B = class_3(
      name: 'B',
      typeParameters: [BE],
      interfaces: [
        A.instantiateImpl(
          typeArguments: [typeParameterTypeNone(BE)],
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      ],
    );

    var C = class_3(name: 'C');

    var targetType = B.instantiateImpl(
      typeArguments: [interfaceTypeNone3(C)],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var result = targetType.asInstanceOf2(A.asElement2);
    expect(
      result,
      A.instantiateImpl(
        typeArguments: [interfaceTypeNone3(C)],
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
  }

  void test_creation() {
    expect(interfaceTypeNone3(class_3(name: 'A')), isNotNull);
  }

  void test_getConstructors() {
    ClassElementImpl typeElement = class_3(name: 'A');
    ConstructorElementImpl constructorOne =
        ElementFactory.constructorElement(typeElement, 'one', false);
    ConstructorElementImpl constructorTwo =
        ElementFactory.constructorElement(typeElement, 'two', false);
    typeElement.constructors = [constructorOne, constructorTwo];
    InterfaceType type = interfaceTypeNone3(typeElement);
    expect(type.constructors2, hasLength(2));
  }

  void test_getConstructors_empty() {
    ClassElementImpl typeElement = class_3(name: 'A');
    typeElement.constructors = const <ConstructorElementImpl>[];
    InterfaceType type = interfaceTypeNone3(typeElement);
    expect(type.constructors2, isEmpty);
  }

  void test_getElement() {
    ClassElementImpl typeElement = class_3(name: 'A');
    InterfaceType type = interfaceTypeNone3(typeElement);
    expect(type.element3.asElement, typeElement);
  }

  void test_getGetter_implemented() {
    //
    // class A { g {} }
    //
    var classA = class_3(name: 'A');
    String getterName = "g";
    var getterG = ElementFactory.getterElement(getterName, false, intNone);
    classA.accessors = [getterG];
    InterfaceType typeA = interfaceTypeNone3(classA);
    expect(typeA.getGetter2(getterName).asElement, same(getterG));
  }

  void test_getGetter_parameterized() {
    //
    // class A<E> { E get g {} }
    //
    var AE = typeParameter('E');
    var A = class_3(name: 'A', typeParameters: [AE]);

    var typeAE = typeParameterTypeNone(AE);
    String getterName = "g";
    PropertyAccessorElementImpl getterG =
        ElementFactory.getterElement(getterName, false, typeAE);
    A.accessors = [getterG];
    //
    // A<I>
    //
    var I = interfaceTypeNone3(class_3(name: 'I'));
    var AofI = A.instantiateImpl(
      typeArguments: [I],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    PropertyAccessorElement getter = AofI.getGetter(getterName)!;
    expect(getter, isNotNull);
    FunctionType getterType = getter.type;
    expect(getterType.returnType, same(I));
  }

  void test_getGetter_unimplemented() {
    //
    // class A {}
    //
    var classA = class_3(name: 'A');
    InterfaceType typeA = interfaceTypeNone3(classA);
    expect(typeA.getGetter2("g").asElement, isNull);
  }

  void test_getGetters() {
    ClassElementImpl typeElement = class_3(name: 'A');
    var getterG = ElementFactory.getterElement("g", false, intNone);
    var getterH = ElementFactory.getterElement("h", false, intNone);
    typeElement.accessors = [getterG, getterH];
    InterfaceType type = interfaceTypeNone3(typeElement);
    expect(type.getters.length, 2);
  }

  void test_getGetters_empty() {
    ClassElementImpl typeElement = class_3(name: 'A');
    InterfaceType type = interfaceTypeNone3(typeElement);
    expect(type.getters.length, 0);
  }

  void test_getInterfaces_nonParameterized() {
    //
    // class C implements A, B
    //
    var A = class_3(name: 'A');
    var B = class_3(name: 'B');
    var C = class_3(
      name: 'C',
      interfaces: [
        interfaceTypeNone3(A),
        interfaceTypeNone3(B),
      ],
    );

    void check(NullabilitySuffix nullabilitySuffix, String expected) {
      var type = interfaceType(C, nullabilitySuffix: nullabilitySuffix);
      expect(typesString(type.interfaces), expected);
    }

    check(NullabilitySuffix.none, r'''
A
B
''');

    check(NullabilitySuffix.question, r'''
A?
B?
''');
  }

  void test_getInterfaces_parameterized() {
    //
    // class A<E>
    // class B<F> implements A<F>
    //
    var E = typeParameter('E');
    var A = class_3(name: 'A', typeParameters: [E]);
    var F = typeParameter('F');
    var B = class_3(
      name: 'B',
      typeParameters: [F],
      interfaces: [
        A.instantiateImpl(
          typeArguments: [typeParameterTypeNone(F)],
          nullabilitySuffix: NullabilitySuffix.none,
        )
      ],
    );

    //
    // B<int>
    //

    void check(NullabilitySuffix nullabilitySuffix, String expected) {
      var type = interfaceType(
        B,
        typeArguments: [intNone],
        nullabilitySuffix: nullabilitySuffix,
      );
      expect(typesString(type.interfaces), expected);
    }

    check(NullabilitySuffix.none, r'''
A<int>
''');

    check(NullabilitySuffix.question, r'''
A<int>?
''');
  }

  void test_getMethod_implemented() {
    //
    // class A { m() {} }
    //
    var classA = class_3(name: 'A');
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, intNone);
    classA.methods = [methodM];
    InterfaceType typeA = interfaceTypeNone3(classA);
    expect(typeA.getMethod2(methodName).asElement, same(methodM));
  }

  void test_getMethod_parameterized_usesTypeParameter() {
    //
    // class A<E> { E m(E p) {} }
    //
    var E = typeParameter('E');
    var A = class_3(name: 'A', typeParameters: [E]);
    var typeE = typeParameterTypeNone(E);
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeE, [typeE]);
    A.methods = [methodM];
    //
    // A<I>
    //
    var typeI = interfaceTypeNone3(class_3(name: 'I'));
    var typeAI = interfaceTypeNone3(A, typeArguments: [typeI]);
    var method = typeAI.getMethod(methodName)!;
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
    var classA = class_3(name: 'A');
    InterfaceType typeA = interfaceTypeNone3(classA);
    expect(typeA.getMethod2("m"), isNull);
  }

  void test_getMethods() {
    ClassElementImpl typeElement = class_3(name: 'A');
    MethodElementImpl methodOne = ElementFactory.methodElement("one", intNone);
    MethodElementImpl methodTwo = ElementFactory.methodElement("two", intNone);
    typeElement.methods = [methodOne, methodTwo];
    InterfaceType type = interfaceTypeNone3(typeElement);
    expect(type.methods2.length, 2);
  }

  void test_getMethods_empty() {
    ClassElementImpl typeElement = class_3(name: 'A');
    InterfaceType type = interfaceTypeNone3(typeElement);
    expect(type.methods2.length, 0);
  }

  void test_getMixins_nonParameterized() {
    //
    // class C extends Object with A, B
    //
    var A = class_3(name: 'A');
    var B = class_3(name: 'B');
    var C = class_3(
      name: 'C',
      mixins: [
        interfaceTypeNone3(A),
        interfaceTypeNone3(B),
      ],
    );

    void check(NullabilitySuffix nullabilitySuffix, String expected) {
      var type = interfaceType(C, nullabilitySuffix: nullabilitySuffix);
      expect(typesString(type.mixins), expected);
    }

    check(NullabilitySuffix.none, r'''
A
B
''');

    check(NullabilitySuffix.question, r'''
A?
B?
''');
  }

  void test_getMixins_parameterized() {
    //
    // class A<E>
    // class B<F> extends Object with A<F>
    //
    var E = typeParameter('E');
    var A = class_3(name: 'A', typeParameters: [E]);

    var F = typeParameter('F');
    var B = class_3(
      name: 'B',
      typeParameters: [F],
      mixins: [
        interfaceTypeNone3(A, typeArguments: [
          typeParameterTypeNone(F),
        ]),
      ],
    );

    void check(NullabilitySuffix nullabilitySuffix, String expected) {
      var type = interfaceType(
        B,
        typeArguments: [intNone],
        nullabilitySuffix: nullabilitySuffix,
      );
      expect(typesString(type.mixins), expected);
    }

    check(NullabilitySuffix.none, r'''
A<int>
''');

    check(NullabilitySuffix.question, r'''
A<int>?
''');
  }

  void test_getSetter_implemented() {
    //
    // class A { s() {} }
    //
    var classA = class_3(name: 'A');
    String setterName = "s";
    var setterS = ElementFactory.setterElement(setterName, false, intNone);
    classA.accessors = [setterS];
    InterfaceType typeA = interfaceTypeNone3(classA);
    expect(typeA.getSetter2(setterName).asElement, same(setterS));
  }

  void test_getSetter_parameterized() {
    //
    // class A<E> { set s(E p) {} }
    //
    var E = typeParameter('E');
    var A = class_3(name: 'A', typeParameters: [E]);
    var typeE = typeParameterTypeNone(E);
    String setterName = "s";
    PropertyAccessorElementImpl setterS =
        ElementFactory.setterElement(setterName, false, typeE);
    A.accessors = [setterS];
    //
    // A<I>
    //
    var typeI = interfaceTypeNone3(class_3(name: 'I'));
    var typeAI = interfaceTypeNone3(A, typeArguments: [typeI]);
    PropertyAccessorElement setter = typeAI.getSetter(setterName)!;
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
    var classA = class_3(name: 'A');
    InterfaceType typeA = interfaceTypeNone3(classA);
    expect(typeA.getSetter2("s").asElement, isNull);
  }

  void test_getSuperclass_nonParameterized() {
    //
    // class B extends A
    //
    var A = class_3(name: 'A');
    var B = class_3(name: 'B', superType: interfaceTypeNone3(A));

    var B_none = interfaceTypeNone3(B);
    expect(typeString(B_none.superclass!), 'A');

    var B_question = interfaceTypeQuestion(B);
    expect(typeString(B_question.superclass!), 'A?');
  }

  void test_getSuperclass_parameterized() {
    //
    // class A<E>
    // class B<F> extends A<F>
    //
    var E = typeParameter('E');
    var A = class_3(name: 'A', typeParameters: [E]);

    var F = typeParameter('F');
    var B = class_3(
      name: 'B',
      typeParameters: [F],
      superType: interfaceTypeNone3(
        A,
        typeArguments: [
          typeParameterTypeNone(F),
        ],
      ),
    );

    var B_none = interfaceTypeNone3(B, typeArguments: [intNone]);
    expect(typeString(B_none.superclass!), 'A<int>');

    var B_question = interfaceTypeQuestion(B, typeArguments: [intNone]);
    expect(typeString(B_question.superclass!), 'A<int>?');
  }

  void test_getTypeArguments_empty() {
    InterfaceType type = interfaceTypeNone3(ElementFactory.classElement2('A'));
    expect(type.typeArguments, hasLength(0));
  }

  void test_hashCode() {
    var classA = class_3(name: 'A');
    InterfaceType typeA = interfaceTypeNone3(classA);
    expect(0 == typeA.hashCode, isFalse);
  }

  void test_superclassConstraints_nonParameterized() {
    //
    // class A
    // mixin M on A
    //
    var A = class_3(name: 'A');
    var M = mixin_3(
      name: 'M',
      constraints: [
        interfaceTypeNone3(A),
      ],
    );

    void check(NullabilitySuffix nullabilitySuffix, String expected) {
      var type = interfaceType(M, nullabilitySuffix: nullabilitySuffix);
      expect(typesString(type.superclassConstraints), expected);
    }

    check(NullabilitySuffix.none, r'''
A
''');

    check(NullabilitySuffix.question, r'''
A?
''');
  }

  void test_superclassConstraints_parameterized() {
    //
    // class A<T>
    // mixin M<U> on A<U>
    //
    var T = typeParameter('T');
    var A = class_3(name: 'A', typeParameters: [T]);
    var U = typeParameter('F');
    var M = mixin_3(
      name: 'M',
      typeParameters: [U],
      constraints: [
        interfaceTypeNone3(A, typeArguments: [
          typeParameterTypeNone(U),
        ]),
      ],
    );

    //
    // M<int>
    //

    void check(NullabilitySuffix nullabilitySuffix, String expected) {
      var type = interfaceType(
        M,
        typeArguments: [intNone],
        nullabilitySuffix: nullabilitySuffix,
      );
      expect(typesString(type.superclassConstraints), expected);
    }

    check(NullabilitySuffix.none, r'''
A<int>
''');

    check(NullabilitySuffix.question, r'''
A<int>?
''');
  }
}

@reflectiveTest
class MaybeAugmentedInstanceElementMixinTest extends ElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  test_lookUpGetter_declared() async {
    var library = await buildLibrary('''
class A {
  int get g {}
}
''');
    var elementA = library.getClass2('A')!;
    var getter = elementA.getGetter2('g');
    expect(elementA.lookUpGetter2(name: 'g', library: library), same(getter));
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_lookUpGetter_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  int get g {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
''');
    var elementA = library.getClass2('A')!;
    var getter = elementA.getGetter2('g')!;
    expect(elementA.lookUpGetter2(name: 'g', library: library), same(getter));
  }

  test_lookUpGetter_inherited() async {
    var library = await buildLibrary('''
class A {
  int get g {}
}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var getter = classA.getGetter2('g');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpGetter2(name: 'g', library: library), same(getter));
  }

  test_lookUpGetter_inherited_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  int get g {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var getter = classA.getGetter2('g');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpGetter2(name: 'g', library: library), same(getter));
  }

  test_lookUpGetter_inherited_fromMixin() async {
    var library = await buildLibrary('''
mixin A {
  int get g {}
}
class B with A {}
''');
    var mixinA = library.getMixin2('A')!;
    var getter = mixinA.getGetter2('g');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpGetter2(name: 'g', library: library), same(getter));
  }

  test_lookUpGetter_undeclared() async {
    var library = await buildLibrary('''
class A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpGetter2(name: 'g', library: library), isNull);
  }

  test_lookUpGetter_undeclared_recursive() async {
    var library = await buildLibrary('''
class A extends B {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpGetter2(name: 'g', library: library), isNull);
  }

  test_lookUpMethod_declared() async {
    var library = await buildLibrary('''
class A {
  int m() {}
}
''');
    var classA = library.getClass2('A')!;
    var method = classA.getMethod2('m')!;
    expect(classA.lookUpMethod2(name: 'm', library: library), same(method));
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_lookUpMethod_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  int m() {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
''');
    var classA = library.getClass2('A')!;
    var method = classA.getMethod2('m')!;
    expect(classA.lookUpMethod2(name: 'm', library: library), same(method));
  }

  test_lookUpMethod_inherited() async {
    var library = await buildLibrary('''
class A {
  int m() {}
}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var method = classA.getMethod2('m');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpMethod2(name: 'm', library: library), same(method));
  }

  test_lookUpMethod_inherited_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  int m() {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var method = classA.getMethod2('m');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpMethod2(name: 'm', library: library), same(method));
  }

  test_lookUpMethod_inherited_fromMixin() async {
    var library = await buildLibrary('''
mixin A {
  int m() {}
}
class B with A {}
''');
    var mixinA = library.getMixin2('A')!;
    var method = mixinA.getMethod2('m');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpMethod2(name: 'm', library: library), same(method));
  }

  test_lookUpMethod_undeclared() async {
    var library = await buildLibrary('''
class A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpMethod2(name: 'm', library: library), isNull);
  }

  test_lookUpMethod_undeclared_recursive() async {
    var library = await buildLibrary('''
class A extends B {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpMethod2(name: 'm', library: library), isNull);
  }

  test_lookUpSetter_declared() async {
    var library = await buildLibrary('''
class A {
  set s(x) {}
}
''');
    var classA = library.getClass2('A')!;
    var setter = classA.getSetter2('s')!;
    expect(classA.lookUpSetter2(name: 's', library: library), same(setter));
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_lookUpSetter_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  set s(x) {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
''');
    var classA = library.getClass2('A')!;
    var setter = classA.getSetter2('s')!;
    expect(classA.lookUpSetter2(name: 's', library: library), same(setter));
  }

  test_lookUpSetter_inherited() async {
    var library = await buildLibrary('''
class A {
  set s(x) {}
}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var setter = classA.getSetter2('s')!;
    var classB = library.getClass2('B')!;
    expect(classB.lookUpSetter2(name: 's', library: library), same(setter));
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_lookUpSetter_inherited_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  set s(x) {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var setter = classA.getSetter2('s')!;
    var classB = library.getClass2('B')!;
    expect(classB.lookUpSetter2(name: 's', library: library), same(setter));
  }

  test_lookUpSetter_inherited_fromMixin() async {
    var library = await buildLibrary('''
mixin A {
  set s(x) {}
}
class B with A {}
''');
    var mixinA = library.getMixin2('A')!;
    var setter = mixinA.getSetter2('s')!;
    var classB = library.getClass2('B')!;
    expect(classB.lookUpSetter2(name: 's', library: library), same(setter));
  }

  test_lookUpSetter_undeclared() async {
    var library = await buildLibrary('''
class A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpSetter2(name: 's', library: library), isNull);
  }

  test_lookUpSetter_undeclared_recursive() async {
    var library = await buildLibrary('''
class A extends B {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpSetter2(name: 's', library: library), isNull);
  }
}

@reflectiveTest
class MethodElementImplTest extends _AbstractTypeSystemTest {
  void test_equal() {
    var foo = method('foo', intNone);
    var T = typeParameter('T');
    var A = class_3(
      name: 'A',
      typeParameters: [T],
      methods: [foo],
    );

    // MethodElementImpl is equal to itself.
    expect(foo == foo, isTrue);

    // MethodMember is not equal to MethodElementImpl.
    var foo_int = A.instantiateImpl(
      typeArguments: [intNone],
      nullabilitySuffix: NullabilitySuffix.none,
    ).getMethod('foo')!;
    expect(foo == foo_int, isFalse);
    expect(foo_int == foo, isFalse);
  }
}

@reflectiveTest
class MixinElementImplTest extends AbstractTypeSystemTest {
  void test_isImplementableIn_base_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement(name: "C", isBase: true);
    library1.definingCompilationUnit.mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isImplementableIn(library2), isFalse);
  }

  void test_isImplementableIn_base_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement(name: "C", isBase: true);
    library.definingCompilationUnit.mixins = [mixinElement];
    expect(mixinElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement(name: "C");
    library1.definingCompilationUnit.mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isImplementableIn(library2), isTrue);
  }

  void test_isImplementableIn_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement(name: "C");
    library.definingCompilationUnit.mixins = [mixinElement];
    expect(mixinElement.isImplementableIn(library), isTrue);
  }
}

@reflectiveTest
class TopLevelVariableElementImplTest extends PubPackageResolutionTest {
  test_computeConstantValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
const int C = 42;
''');
    await resolveTestCode(r'''
import 'a.dart';
main() {
  print(C);
}
''');
    SimpleIdentifier argument = findNode.simple('C);');
    var getter = argument.element?.asElement as PropertyAccessorElementImpl;
    var constant = getter.variable2 as TopLevelVariableElement;

    DartObject value = constant.computeConstantValue()!;
    expect(value, isNotNull);
    expect(value.toIntValue(), 42);
  }
}

@reflectiveTest
class TypeParameterTypeImplTest extends AbstractTypeSystemTest {
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
    var element = typeParameter('E');
    expect(typeParameterTypeNone(element), isNotNull);
  }

  void test_getElement() {
    var element = typeParameter('E');
    TypeParameterTypeImpl type = typeParameterTypeNone(element);
    expect(type.element3, element);
  }

  void _assert_asInstanceOf(
    TypeImpl type,
    ClassElement element,
    String? expected,
  ) {
    var result = type.asInstanceOf(element);
    expect(
      result?.getDisplayString(),
      expected,
    );
  }
}

// TODO(scheglov): rewrite these tests
class _AbstractTypeSystemTest extends AbstractTypeSystemTest {
  ClassElementImpl class_3({
    required String name,
    bool isAbstract = false,
    bool isAugmentation = false,
    bool isSealed = false,
    InterfaceType? superType,
    List<TypeParameterElementImpl2> typeParameters = const [],
    List<InterfaceType> interfaces = const [],
    List<InterfaceType> mixins = const [],
    List<MethodElementImpl> methods = const [],
  }) {
    var fragment = ClassElementImpl(name, 0);
    fragment.isAbstract = isAbstract;
    fragment.isAugmentation = isAugmentation;
    fragment.isSealed = isSealed;
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters.map((e) => e.asElement).toList();
    fragment.supertype = superType ?? typeProvider.objectType;
    fragment.interfaces = interfaces;
    fragment.mixins = mixins;
    fragment.methods = methods;

    ClassElementImpl2(Reference.root(), fragment);

    return fragment;
  }

  InterfaceTypeImpl interfaceTypeNone3(
    InterfaceElementImpl element, {
    List<TypeImpl> typeArguments = const [],
  }) {
    return element.instantiateImpl(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  MixinElementImpl mixin_3({
    required String name,
    bool isAugmentation = false,
    List<TypeParameterElementImpl2> typeParameters = const [],
    List<InterfaceType>? constraints,
    List<InterfaceType> interfaces = const [],
  }) {
    var fragment = MixinElementImpl(name, 0);
    fragment.isAugmentation = isAugmentation;
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters.map((e) => e.asElement).toList();
    fragment.superclassConstraints = constraints ?? [typeProvider.objectType];
    fragment.interfaces = interfaces;
    fragment.constructors = const <ConstructorElementImpl>[];

    var element = MixinElementImpl2(Reference.root(), fragment);
    element.superclassConstraints = fragment.superclassConstraints;

    return fragment;
  }
}
