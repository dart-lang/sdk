// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.element_test;

import 'dart:collection';
import 'dart:io';
import 'package:analyzer-experimental/src/generated/java_core.dart';
import 'package:analyzer-experimental/src/generated/java_engine.dart';
import 'package:analyzer-experimental/src/generated/java_engine_io.dart';
import 'package:analyzer-experimental/src/generated/java_junit.dart';
import 'package:analyzer-experimental/src/generated/source_io.dart';
import 'package:analyzer-experimental/src/generated/error.dart';
import 'package:analyzer-experimental/src/generated/scanner.dart';
import 'package:analyzer-experimental/src/generated/utilities_dart.dart';
import 'package:analyzer-experimental/src/generated/ast.dart' hide Annotation;
import 'package:analyzer-experimental/src/generated/element.dart' hide Annotation;
import 'package:analyzer-experimental/src/generated/engine.dart' show AnalysisContext, AnalysisContextImpl;
import 'package:unittest/unittest.dart' as _ut;
import 'test_support.dart';
import 'scanner_test.dart' show TokenFactory;
import 'ast_test.dart' show ASTFactory;

class ElementLocationImplTest extends EngineTestCase {
  void test_create_encoding() {
    String encoding = "a;b;c";
    ElementLocationImpl location = new ElementLocationImpl.con2(encoding);
    JUnitTestCase.assertEquals(encoding, location.encoding);
  }
  void test_equals_equal() {
    String encoding = "a;b;c";
    ElementLocationImpl first = new ElementLocationImpl.con2(encoding);
    ElementLocationImpl second = new ElementLocationImpl.con2(encoding);
    JUnitTestCase.assertTrue(first == second);
  }
  void test_equals_notEqual_differentLengths() {
    ElementLocationImpl first = new ElementLocationImpl.con2("a;b;c");
    ElementLocationImpl second = new ElementLocationImpl.con2("a;b;c;d");
    JUnitTestCase.assertFalse(first == second);
  }
  void test_equals_notEqual_notLocation() {
    ElementLocationImpl first = new ElementLocationImpl.con2("a;b;c");
    JUnitTestCase.assertFalse(first == "a;b;d");
  }
  void test_equals_notEqual_sameLengths() {
    ElementLocationImpl first = new ElementLocationImpl.con2("a;b;c");
    ElementLocationImpl second = new ElementLocationImpl.con2("a;b;d");
    JUnitTestCase.assertFalse(first == second);
  }
  void test_getComponents() {
    String encoding = "a;b;c";
    ElementLocationImpl location = new ElementLocationImpl.con2(encoding);
    List<String> components2 = location.components;
    EngineTestCase.assertLength(3, components2);
    JUnitTestCase.assertEquals("a", components2[0]);
    JUnitTestCase.assertEquals("b", components2[1]);
    JUnitTestCase.assertEquals("c", components2[2]);
  }
  void test_getEncoding() {
    String encoding = "a;b;c;;d";
    ElementLocationImpl location = new ElementLocationImpl.con2(encoding);
    JUnitTestCase.assertEquals(encoding, location.encoding);
  }
  static dartSuite() {
    _ut.group('ElementLocationImplTest', () {
      _ut.test('test_create_encoding', () {
        final __test = new ElementLocationImplTest();
        runJUnitTest(__test, __test.test_create_encoding);
      });
      _ut.test('test_equals_equal', () {
        final __test = new ElementLocationImplTest();
        runJUnitTest(__test, __test.test_equals_equal);
      });
      _ut.test('test_equals_notEqual_differentLengths', () {
        final __test = new ElementLocationImplTest();
        runJUnitTest(__test, __test.test_equals_notEqual_differentLengths);
      });
      _ut.test('test_equals_notEqual_notLocation', () {
        final __test = new ElementLocationImplTest();
        runJUnitTest(__test, __test.test_equals_notEqual_notLocation);
      });
      _ut.test('test_equals_notEqual_sameLengths', () {
        final __test = new ElementLocationImplTest();
        runJUnitTest(__test, __test.test_equals_notEqual_sameLengths);
      });
      _ut.test('test_getComponents', () {
        final __test = new ElementLocationImplTest();
        runJUnitTest(__test, __test.test_getComponents);
      });
      _ut.test('test_getEncoding', () {
        final __test = new ElementLocationImplTest();
        runJUnitTest(__test, __test.test_getEncoding);
      });
    });
  }
}
class LibraryElementImplTest extends EngineTestCase {
  void test_creation() {
    JUnitTestCase.assertNotNull(new LibraryElementImpl(new AnalysisContextImpl(), ASTFactory.libraryIdentifier2(["l"])));
  }
  void test_getImportedLibraries() {
    AnalysisContext context = new AnalysisContextImpl();
    LibraryElementImpl library1 = ElementFactory.library(context, "l1");
    LibraryElementImpl library2 = ElementFactory.library(context, "l2");
    LibraryElementImpl library3 = ElementFactory.library(context, "l3");
    LibraryElementImpl library4 = ElementFactory.library(context, "l4");
    PrefixElement prefixA = new PrefixElementImpl(ASTFactory.identifier2("a"));
    PrefixElement prefixB = new PrefixElementImpl(ASTFactory.identifier2("b"));
    List<ImportElementImpl> imports = [ElementFactory.importFor(library2, null, []), ElementFactory.importFor(library2, prefixB, []), ElementFactory.importFor(library3, null, []), ElementFactory.importFor(library3, prefixA, []), ElementFactory.importFor(library3, prefixB, []), ElementFactory.importFor(library4, prefixA, [])];
    library1.imports = imports;
    List<LibraryElement> libraries = library1.importedLibraries;
    EngineTestCase.assertEqualsIgnoreOrder(<LibraryElement> [library2, library3, library4], libraries);
  }
  void test_getPrefixes() {
    AnalysisContext context = new AnalysisContextImpl();
    LibraryElementImpl library18 = ElementFactory.library(context, "l1");
    PrefixElement prefixA = new PrefixElementImpl(ASTFactory.identifier2("a"));
    PrefixElement prefixB = new PrefixElementImpl(ASTFactory.identifier2("b"));
    List<ImportElementImpl> imports = [ElementFactory.importFor(ElementFactory.library(context, "l2"), null, []), ElementFactory.importFor(ElementFactory.library(context, "l3"), null, []), ElementFactory.importFor(ElementFactory.library(context, "l4"), prefixA, []), ElementFactory.importFor(ElementFactory.library(context, "l5"), prefixA, []), ElementFactory.importFor(ElementFactory.library(context, "l6"), prefixB, [])];
    library18.imports = imports;
    List<PrefixElement> prefixes2 = library18.prefixes;
    EngineTestCase.assertLength(2, prefixes2);
    if (identical(prefixA, prefixes2[0])) {
      JUnitTestCase.assertSame(prefixB, prefixes2[1]);
    } else {
      JUnitTestCase.assertSame(prefixB, prefixes2[0]);
      JUnitTestCase.assertSame(prefixA, prefixes2[1]);
    }
  }
  void test_setImports() {
    AnalysisContext context = new AnalysisContextImpl();
    LibraryElementImpl library = new LibraryElementImpl(context, ASTFactory.libraryIdentifier2(["l1"]));
    List<ImportElementImpl> expectedImports = [ElementFactory.importFor(ElementFactory.library(context, "l2"), null, []), ElementFactory.importFor(ElementFactory.library(context, "l3"), null, [])];
    library.imports = expectedImports;
    List<ImportElement> actualImports = library.imports;
    EngineTestCase.assertLength(expectedImports.length, actualImports);
    for (int i = 0; i < actualImports.length; i++) {
      JUnitTestCase.assertSame(expectedImports[i], actualImports[i]);
    }
  }
  static dartSuite() {
    _ut.group('LibraryElementImplTest', () {
      _ut.test('test_creation', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_creation);
      });
      _ut.test('test_getImportedLibraries', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_getImportedLibraries);
      });
//      _ut.test('test_getPrefixes', () {
//        final __test = new LibraryElementImplTest();
//        runJUnitTest(__test, __test.test_getPrefixes);
//      });
      _ut.test('test_setImports', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_setImports);
      });
    });
  }
}
class InterfaceTypeImplTest extends EngineTestCase {
  void test_computeLongestInheritancePathToObject_multipleInterfacePaths() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    ClassElementImpl elementD = ElementFactory.classElement2("D", []);
    ClassElementImpl elementE = ElementFactory.classElement2("E", []);
    elementB.interfaces = <InterfaceType> [elementA.type];
    elementC.interfaces = <InterfaceType> [elementA.type];
    elementD.interfaces = <InterfaceType> [elementC.type];
    elementE.interfaces = <InterfaceType> [elementB.type, elementD.type];
    JUnitTestCase.assertEquals(2, InterfaceTypeImpl.computeLongestInheritancePathToObject(elementB.type));
    JUnitTestCase.assertEquals(4, InterfaceTypeImpl.computeLongestInheritancePathToObject(elementE.type));
  }
  void test_computeLongestInheritancePathToObject_multipleSuperclassPaths() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElement elementC = ElementFactory.classElement("C", elementA.type, []);
    ClassElement elementD = ElementFactory.classElement("D", elementC.type, []);
    ClassElementImpl elementE = ElementFactory.classElement("E", elementB.type, []);
    elementE.interfaces = <InterfaceType> [elementD.type];
    JUnitTestCase.assertEquals(2, InterfaceTypeImpl.computeLongestInheritancePathToObject(elementB.type));
    JUnitTestCase.assertEquals(4, InterfaceTypeImpl.computeLongestInheritancePathToObject(elementE.type));
  }
  void test_computeLongestInheritancePathToObject_object() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    InterfaceType object = elementA.supertype;
    JUnitTestCase.assertEquals(0, InterfaceTypeImpl.computeLongestInheritancePathToObject(object));
  }
  void test_computeLongestInheritancePathToObject_singleInterfacePath() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    elementB.interfaces = <InterfaceType> [elementA.type];
    elementC.interfaces = <InterfaceType> [elementB.type];
    JUnitTestCase.assertEquals(1, InterfaceTypeImpl.computeLongestInheritancePathToObject(elementA.type));
    JUnitTestCase.assertEquals(2, InterfaceTypeImpl.computeLongestInheritancePathToObject(elementB.type));
    JUnitTestCase.assertEquals(3, InterfaceTypeImpl.computeLongestInheritancePathToObject(elementC.type));
  }
  void test_computeLongestInheritancePathToObject_singleSuperclassPath() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElement elementC = ElementFactory.classElement("C", elementB.type, []);
    JUnitTestCase.assertEquals(1, InterfaceTypeImpl.computeLongestInheritancePathToObject(elementA.type));
    JUnitTestCase.assertEquals(2, InterfaceTypeImpl.computeLongestInheritancePathToObject(elementB.type));
    JUnitTestCase.assertEquals(3, InterfaceTypeImpl.computeLongestInheritancePathToObject(elementC.type));
  }
  void test_computeSuperinterfaceSet_multipleInterfacePaths() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    ClassElementImpl elementD = ElementFactory.classElement2("D", []);
    ClassElementImpl elementE = ElementFactory.classElement2("E", []);
    elementB.interfaces = <InterfaceType> [elementA.type];
    elementC.interfaces = <InterfaceType> [elementA.type];
    elementD.interfaces = <InterfaceType> [elementC.type];
    elementE.interfaces = <InterfaceType> [elementB.type, elementD.type];
    Set<InterfaceType> superinterfacesOfD = InterfaceTypeImpl.computeSuperinterfaceSet(elementD.type);
    JUnitTestCase.assertNotNull(superinterfacesOfD);
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(elementA.type));
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(elementC.type));
    JUnitTestCase.assertEquals(3, superinterfacesOfD.length);
    Set<InterfaceType> superinterfacesOfE = InterfaceTypeImpl.computeSuperinterfaceSet(elementE.type);
    JUnitTestCase.assertNotNull(superinterfacesOfE);
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(elementA.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(elementB.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(elementC.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(elementD.type));
    JUnitTestCase.assertEquals(5, superinterfacesOfE.length);
  }
  void test_computeSuperinterfaceSet_multipleSuperclassPaths() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElement elementC = ElementFactory.classElement("C", elementA.type, []);
    ClassElement elementD = ElementFactory.classElement("D", elementC.type, []);
    ClassElementImpl elementE = ElementFactory.classElement("E", elementB.type, []);
    elementE.interfaces = <InterfaceType> [elementD.type];
    Set<InterfaceType> superinterfacesOfD = InterfaceTypeImpl.computeSuperinterfaceSet(elementD.type);
    JUnitTestCase.assertNotNull(superinterfacesOfD);
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(elementA.type));
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(elementC.type));
    JUnitTestCase.assertEquals(3, superinterfacesOfD.length);
    Set<InterfaceType> superinterfacesOfE = InterfaceTypeImpl.computeSuperinterfaceSet(elementE.type);
    JUnitTestCase.assertNotNull(superinterfacesOfE);
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(elementA.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(elementB.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(elementC.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(elementD.type));
    JUnitTestCase.assertEquals(5, superinterfacesOfE.length);
  }
  void test_computeSuperinterfaceSet_singleInterfacePath() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    elementB.interfaces = <InterfaceType> [elementA.type];
    elementC.interfaces = <InterfaceType> [elementB.type];
    Set<InterfaceType> superinterfacesOfA = InterfaceTypeImpl.computeSuperinterfaceSet(elementA.type);
    JUnitTestCase.assertNotNull(superinterfacesOfA);
    JUnitTestCase.assertTrue(superinterfacesOfA.contains(ElementFactory.object.type));
    JUnitTestCase.assertEquals(1, superinterfacesOfA.length);
    Set<InterfaceType> superinterfacesOfB = InterfaceTypeImpl.computeSuperinterfaceSet(elementB.type);
    JUnitTestCase.assertNotNull(superinterfacesOfB);
    JUnitTestCase.assertTrue(superinterfacesOfB.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfB.contains(elementA.type));
    JUnitTestCase.assertEquals(2, superinterfacesOfB.length);
    Set<InterfaceType> superinterfacesOfC = InterfaceTypeImpl.computeSuperinterfaceSet(elementC.type);
    JUnitTestCase.assertNotNull(superinterfacesOfC);
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(elementA.type));
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(elementB.type));
    JUnitTestCase.assertEquals(3, superinterfacesOfC.length);
  }
  void test_computeSuperinterfaceSet_singleSuperclassPath() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElement elementC = ElementFactory.classElement("C", elementB.type, []);
    Set<InterfaceType> superinterfacesOfA = InterfaceTypeImpl.computeSuperinterfaceSet(elementA.type);
    JUnitTestCase.assertNotNull(superinterfacesOfA);
    JUnitTestCase.assertTrue(superinterfacesOfA.contains(ElementFactory.object.type));
    JUnitTestCase.assertEquals(1, superinterfacesOfA.length);
    Set<InterfaceType> superinterfacesOfB = InterfaceTypeImpl.computeSuperinterfaceSet(elementB.type);
    JUnitTestCase.assertNotNull(superinterfacesOfB);
    JUnitTestCase.assertTrue(superinterfacesOfB.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfB.contains(elementA.type));
    JUnitTestCase.assertEquals(2, superinterfacesOfB.length);
    Set<InterfaceType> superinterfacesOfC = InterfaceTypeImpl.computeSuperinterfaceSet(elementC.type);
    JUnitTestCase.assertNotNull(superinterfacesOfC);
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(elementA.type));
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(elementB.type));
    JUnitTestCase.assertEquals(3, superinterfacesOfC.length);
  }
  void test_creation() {
    JUnitTestCase.assertNotNull(new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("A"))));
  }
  void test_getElement() {
    ClassElementImpl typeElement = new ClassElementImpl(ASTFactory.identifier2("A"));
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(typeElement);
    JUnitTestCase.assertEquals(typeElement, type.element);
  }
  void test_getLeastUpperBound_directInterfaceCase() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    elementB.interfaces = <InterfaceType> [typeA];
    elementC.interfaces = <InterfaceType> [typeB];
    JUnitTestCase.assertEquals(typeB, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeB, typeC.getLeastUpperBound(typeB));
  }
  void test_getLeastUpperBound_directSubclassCase() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement("C", elementB.type, []);
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    JUnitTestCase.assertEquals(typeB, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeB, typeC.getLeastUpperBound(typeB));
  }
  void test_getLeastUpperBound_functionType() {
    Type2 interfaceType = ElementFactory.classElement2("A", []).type;
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    JUnitTestCase.assertNull(interfaceType.getLeastUpperBound(functionType));
  }
  void test_getLeastUpperBound_mixinCase() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElement elementC = ElementFactory.classElement("C", elementA.type, []);
    ClassElementImpl elementD = ElementFactory.classElement("D", elementB.type, []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeC = elementC.type;
    InterfaceType typeD = elementD.type;
    elementD.mixins = <InterfaceType> [ElementFactory.classElement2("M", []).type, ElementFactory.classElement2("N", []).type, ElementFactory.classElement2("O", []).type, ElementFactory.classElement2("P", []).type];
    JUnitTestCase.assertEquals(typeA, typeD.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeA, typeC.getLeastUpperBound(typeD));
  }
  void test_getLeastUpperBound_null() {
    Type2 interfaceType = ElementFactory.classElement2("A", []).type;
    JUnitTestCase.assertNull(interfaceType.getLeastUpperBound(null));
  }
  void test_getLeastUpperBound_object() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    Type2 typeObject = typeA.element.supertype;
    JUnitTestCase.assertNull(((typeObject.element as ClassElement)).supertype);
    JUnitTestCase.assertEquals(typeObject, typeB.element.supertype);
    JUnitTestCase.assertEquals(typeObject, typeA.getLeastUpperBound(typeB));
  }
  void test_getLeastUpperBound_self() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = elementA.type;
    JUnitTestCase.assertEquals(typeA, typeA.getLeastUpperBound(typeA));
  }
  void test_getLeastUpperBound_sharedSuperclass1() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement("C", elementA.type, []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeA, typeC.getLeastUpperBound(typeB));
  }
  void test_getLeastUpperBound_sharedSuperclass2() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement("C", elementA.type, []);
    ClassElementImpl elementD = ElementFactory.classElement("D", elementC.type, []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeD = elementD.type;
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeD));
    JUnitTestCase.assertEquals(typeA, typeD.getLeastUpperBound(typeB));
  }
  void test_getLeastUpperBound_sharedSuperclass3() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement("C", elementB.type, []);
    ClassElementImpl elementD = ElementFactory.classElement("D", elementB.type, []);
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    InterfaceType typeD = elementD.type;
    JUnitTestCase.assertEquals(typeB, typeC.getLeastUpperBound(typeD));
    JUnitTestCase.assertEquals(typeB, typeD.getLeastUpperBound(typeC));
  }
  void test_getLeastUpperBound_sharedSuperclass4() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementA2 = ElementFactory.classElement2("A2", []);
    ClassElement elementA3 = ElementFactory.classElement2("A3", []);
    ClassElementImpl elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement("C", elementA.type, []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeA2 = elementA2.type;
    InterfaceType typeA3 = elementA3.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    elementB.interfaces = <InterfaceType> [typeA2];
    elementC.interfaces = <InterfaceType> [typeA3];
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeA, typeC.getLeastUpperBound(typeB));
  }
  void test_getLeastUpperBound_sharedSuperinterface1() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    elementB.interfaces = <InterfaceType> [typeA];
    elementC.interfaces = <InterfaceType> [typeA];
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeA, typeC.getLeastUpperBound(typeB));
  }
  void test_getLeastUpperBound_sharedSuperinterface2() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    ClassElementImpl elementD = ElementFactory.classElement2("D", []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    InterfaceType typeD = elementD.type;
    elementB.interfaces = <InterfaceType> [typeA];
    elementC.interfaces = <InterfaceType> [typeA];
    elementD.interfaces = <InterfaceType> [typeC];
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeD));
    JUnitTestCase.assertEquals(typeA, typeD.getLeastUpperBound(typeB));
  }
  void test_getLeastUpperBound_sharedSuperinterface3() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    ClassElementImpl elementD = ElementFactory.classElement2("D", []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    InterfaceType typeD = elementD.type;
    elementB.interfaces = <InterfaceType> [typeA];
    elementC.interfaces = <InterfaceType> [typeB];
    elementD.interfaces = <InterfaceType> [typeB];
    JUnitTestCase.assertEquals(typeB, typeC.getLeastUpperBound(typeD));
    JUnitTestCase.assertEquals(typeB, typeD.getLeastUpperBound(typeC));
  }
  void test_getLeastUpperBound_sharedSuperinterface4() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementA2 = ElementFactory.classElement2("A2", []);
    ClassElement elementA3 = ElementFactory.classElement2("A3", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeA2 = elementA2.type;
    InterfaceType typeA3 = elementA3.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    elementB.interfaces = <InterfaceType> [typeA, typeA2];
    elementC.interfaces = <InterfaceType> [typeA, typeA3];
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeA, typeC.getLeastUpperBound(typeB));
  }
  void test_getTypeArguments() {
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("A")));
    EngineTestCase.assertLength(0, type.typeArguments);
  }
  void test_isDirectSupertypeOf_extends() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    InterfaceTypeImpl typeA = new InterfaceTypeImpl.con1(elementA);
    InterfaceTypeImpl typeB = new InterfaceTypeImpl.con1(elementB);
    JUnitTestCase.assertTrue(typeA.isDirectSupertypeOf(typeB));
  }
  void test_isDirectSupertypeOf_false() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement2("B", []);
    ClassElement elementC = ElementFactory.classElement("C", elementB.type, []);
    InterfaceTypeImpl typeA = new InterfaceTypeImpl.con1(elementA);
    InterfaceTypeImpl typeC = new InterfaceTypeImpl.con1(elementC);
    JUnitTestCase.assertFalse(typeA.isDirectSupertypeOf(typeC));
  }
  void test_isDirectSupertypeOf_implements() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    elementB.interfaces = <InterfaceType> [elementA.type];
    InterfaceTypeImpl typeA = new InterfaceTypeImpl.con1(elementA);
    InterfaceTypeImpl typeB = new InterfaceTypeImpl.con1(elementB);
    JUnitTestCase.assertTrue(typeA.isDirectSupertypeOf(typeB));
  }
  void test_isDirectSupertypeOf_with() {
    ClassElementImpl elementA = ElementFactory.classElement2("A", []);
    ClassElementImpl elementB = ElementFactory.classElement2("B", []);
    elementB.mixins = <InterfaceType> [elementA.type];
    InterfaceTypeImpl typeA = new InterfaceTypeImpl.con1(elementA);
    InterfaceTypeImpl typeB = new InterfaceTypeImpl.con1(elementB);
    JUnitTestCase.assertTrue(typeA.isDirectSupertypeOf(typeB));
  }
  void test_isMoreSpecificThan_bottom() {
    Type2 type24 = ElementFactory.classElement2("A", []).type;
    JUnitTestCase.assertTrue(BottomTypeImpl.instance.isMoreSpecificThan(type24));
  }
  void test_isMoreSpecificThan_covariance() {
    ClassElement elementA = ElementFactory.classElement2("A", ["E"]);
    ClassElement elementI = ElementFactory.classElement2("I", []);
    ClassElement elementJ = ElementFactory.classElement("J", elementI.type, []);
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl.con1(elementA);
    InterfaceTypeImpl typeAJ = new InterfaceTypeImpl.con1(elementA);
    typeAI.typeArguments = <Type2> [elementI.type];
    typeAJ.typeArguments = <Type2> [elementJ.type];
    JUnitTestCase.assertTrue(typeAJ.isMoreSpecificThan(typeAI));
    JUnitTestCase.assertFalse(typeAI.isMoreSpecificThan(typeAJ));
  }
  void test_isMoreSpecificThan_directSupertype() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    JUnitTestCase.assertTrue(typeB.isMoreSpecificThan(typeA));
    JUnitTestCase.assertFalse(typeA.isMoreSpecificThan(typeB));
  }
  void test_isMoreSpecificThan_dynamic() {
    InterfaceType type25 = ElementFactory.classElement2("A", []).type;
    JUnitTestCase.assertTrue(type25.isMoreSpecificThan(DynamicTypeImpl.instance));
  }
  void test_isMoreSpecificThan_indirectSupertype() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElement elementC = ElementFactory.classElement("C", elementB.type, []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeC = elementC.type;
    JUnitTestCase.assertTrue(typeC.isMoreSpecificThan(typeA));
  }
  void test_isMoreSpecificThan_self() {
    InterfaceType type26 = ElementFactory.classElement2("A", []).type;
    JUnitTestCase.assertTrue(type26.isMoreSpecificThan(type26));
  }
  void test_isSubtypeOf_directSubtype() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    JUnitTestCase.assertTrue(typeB.isSubtypeOf(typeA));
    JUnitTestCase.assertFalse(typeA.isSubtypeOf(typeB));
  }
  void test_isSubtypeOf_dynamic() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = elementA.type;
    Type2 dynamicType = DynamicTypeImpl.instance;
    JUnitTestCase.assertFalse(dynamicType.isSubtypeOf(typeA));
    JUnitTestCase.assertTrue(typeA.isSubtypeOf(dynamicType));
  }
  void test_isSubtypeOf_indirectSubtype() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElement elementC = ElementFactory.classElement("C", elementB.type, []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeC = elementC.type;
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeA));
    JUnitTestCase.assertFalse(typeA.isSubtypeOf(typeC));
  }
  void test_isSubtypeOf_interface() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = elementA.supertype;
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    elementC.interfaces = <InterfaceType> [typeB];
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeB));
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeObject));
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeA));
    JUnitTestCase.assertFalse(typeA.isSubtypeOf(typeC));
  }
  void test_isSubtypeOf_mixins() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = elementA.supertype;
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    elementC.mixins = <InterfaceType> [typeB];
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeB));
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeObject));
    JUnitTestCase.assertFalse(typeC.isSubtypeOf(typeA));
    JUnitTestCase.assertFalse(typeA.isSubtypeOf(typeC));
  }
  void test_isSubtypeOf_object() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeObject = elementA.supertype;
    JUnitTestCase.assertTrue(typeA.isSubtypeOf(typeObject));
    JUnitTestCase.assertFalse(typeObject.isSubtypeOf(typeA));
  }
  void test_isSubtypeOf_self() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = elementA.type;
    JUnitTestCase.assertTrue(typeA.isSubtypeOf(typeA));
  }
  void test_isSubtypeOf_typeArguments() {
    ClassElement elementA = ElementFactory.classElement2("A", ["E"]);
    ClassElement elementI = ElementFactory.classElement2("I", []);
    ClassElement elementJ = ElementFactory.classElement("J", elementI.type, []);
    ClassElement elementK = ElementFactory.classElement2("K", []);
    InterfaceType typeA = elementA.type;
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl.con1(elementA);
    InterfaceTypeImpl typeAJ = new InterfaceTypeImpl.con1(elementA);
    InterfaceTypeImpl typeAK = new InterfaceTypeImpl.con1(elementA);
    typeAI.typeArguments = <Type2> [elementI.type];
    typeAJ.typeArguments = <Type2> [elementJ.type];
    typeAK.typeArguments = <Type2> [elementK.type];
    JUnitTestCase.assertTrue(typeAJ.isSubtypeOf(typeAI));
    JUnitTestCase.assertFalse(typeAI.isSubtypeOf(typeAJ));
    JUnitTestCase.assertTrue(typeAI.isSubtypeOf(typeAI));
    JUnitTestCase.assertTrue(typeA.isSubtypeOf(typeAI));
    JUnitTestCase.assertTrue(typeA.isSubtypeOf(typeAJ));
    JUnitTestCase.assertTrue(typeAI.isSubtypeOf(typeA));
    JUnitTestCase.assertTrue(typeAJ.isSubtypeOf(typeA));
    JUnitTestCase.assertFalse(typeAI.isSubtypeOf(typeAK));
    JUnitTestCase.assertFalse(typeAK.isSubtypeOf(typeAI));
  }
  void test_isSupertypeOf_directSupertype() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    JUnitTestCase.assertFalse(typeB.isSupertypeOf(typeA));
    JUnitTestCase.assertTrue(typeA.isSupertypeOf(typeB));
  }
  void test_isSupertypeOf_dynamic() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = elementA.type;
    Type2 dynamicType = DynamicTypeImpl.instance;
    JUnitTestCase.assertTrue(dynamicType.isSupertypeOf(typeA));
    JUnitTestCase.assertFalse(typeA.isSupertypeOf(dynamicType));
  }
  void test_isSupertypeOf_indirectSupertype() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElement elementC = ElementFactory.classElement("C", elementB.type, []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeC = elementC.type;
    JUnitTestCase.assertFalse(typeC.isSupertypeOf(typeA));
    JUnitTestCase.assertTrue(typeA.isSupertypeOf(typeC));
  }
  void test_isSupertypeOf_interface() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = elementA.supertype;
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    elementC.interfaces = <InterfaceType> [typeB];
    JUnitTestCase.assertTrue(typeB.isSupertypeOf(typeC));
    JUnitTestCase.assertTrue(typeObject.isSupertypeOf(typeC));
    JUnitTestCase.assertTrue(typeA.isSupertypeOf(typeC));
    JUnitTestCase.assertFalse(typeC.isSupertypeOf(typeA));
  }
  void test_isSupertypeOf_mixins() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = elementA.supertype;
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    elementC.mixins = <InterfaceType> [typeB];
    JUnitTestCase.assertTrue(typeB.isSupertypeOf(typeC));
    JUnitTestCase.assertTrue(typeObject.isSupertypeOf(typeC));
    JUnitTestCase.assertFalse(typeA.isSupertypeOf(typeC));
    JUnitTestCase.assertFalse(typeC.isSupertypeOf(typeA));
  }
  void test_isSupertypeOf_object() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = elementA.type;
    InterfaceType typeObject = elementA.supertype;
    JUnitTestCase.assertFalse(typeA.isSupertypeOf(typeObject));
    JUnitTestCase.assertTrue(typeObject.isSupertypeOf(typeA));
  }
  void test_isSupertypeOf_self() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = elementA.type;
    JUnitTestCase.assertTrue(typeA.isSupertypeOf(typeA));
  }
  void test_setTypeArguments() {
    InterfaceTypeImpl type27 = ElementFactory.classElement2("A", []).type as InterfaceTypeImpl;
    List<Type2> typeArguments = <Type2> [new InterfaceTypeImpl.con1(ElementFactory.classElement2("B", [])), new InterfaceTypeImpl.con1(ElementFactory.classElement2("C", []))];
    type27.typeArguments = typeArguments;
    JUnitTestCase.assertEquals(typeArguments, type27.typeArguments);
  }
  void test_substitute_equal() {
    ClassElementImpl classElement = new ClassElementImpl(ASTFactory.identifier2("A"));
    TypeVariableElementImpl parameterElement = new TypeVariableElementImpl(ASTFactory.identifier2("E"));
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(classElement);
    TypeVariableTypeImpl parameter = new TypeVariableTypeImpl(parameterElement);
    type.typeArguments = <Type2> [parameter];
    InterfaceTypeImpl argumentType = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("B")));
    InterfaceType result = type.substitute2(<Type2> [argumentType], <Type2> [parameter]);
    JUnitTestCase.assertEquals(classElement, result.element);
    List<Type2> resultArguments = result.typeArguments;
    EngineTestCase.assertLength(1, resultArguments);
    JUnitTestCase.assertEquals(argumentType, resultArguments[0]);
  }
  void test_substitute_notEqual() {
    ClassElementImpl classElement = new ClassElementImpl(ASTFactory.identifier2("A"));
    TypeVariableElementImpl parameterElement = new TypeVariableElementImpl(ASTFactory.identifier2("E"));
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(classElement);
    TypeVariableTypeImpl parameter = new TypeVariableTypeImpl(parameterElement);
    type.typeArguments = <Type2> [parameter];
    InterfaceTypeImpl argumentType = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("B")));
    TypeVariableTypeImpl parameterType = new TypeVariableTypeImpl(new TypeVariableElementImpl(ASTFactory.identifier2("F")));
    InterfaceType result = type.substitute2(<Type2> [argumentType], <Type2> [parameterType]);
    JUnitTestCase.assertEquals(classElement, result.element);
    List<Type2> resultArguments = result.typeArguments;
    EngineTestCase.assertLength(1, resultArguments);
    JUnitTestCase.assertEquals(parameter, resultArguments[0]);
  }
  static dartSuite() {
    _ut.group('InterfaceTypeImplTest', () {
      _ut.test('test_computeLongestInheritancePathToObject_multipleInterfacePaths', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeLongestInheritancePathToObject_multipleInterfacePaths);
      });
      _ut.test('test_computeLongestInheritancePathToObject_multipleSuperclassPaths', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeLongestInheritancePathToObject_multipleSuperclassPaths);
      });
      _ut.test('test_computeLongestInheritancePathToObject_object', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeLongestInheritancePathToObject_object);
      });
      _ut.test('test_computeLongestInheritancePathToObject_singleInterfacePath', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeLongestInheritancePathToObject_singleInterfacePath);
      });
      _ut.test('test_computeLongestInheritancePathToObject_singleSuperclassPath', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeLongestInheritancePathToObject_singleSuperclassPath);
      });
      _ut.test('test_computeSuperinterfaceSet_multipleInterfacePaths', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeSuperinterfaceSet_multipleInterfacePaths);
      });
      _ut.test('test_computeSuperinterfaceSet_multipleSuperclassPaths', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeSuperinterfaceSet_multipleSuperclassPaths);
      });
      _ut.test('test_computeSuperinterfaceSet_singleInterfacePath', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeSuperinterfaceSet_singleInterfacePath);
      });
      _ut.test('test_computeSuperinterfaceSet_singleSuperclassPath', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeSuperinterfaceSet_singleSuperclassPath);
      });
      _ut.test('test_creation', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_creation);
      });
      _ut.test('test_getElement', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getElement);
      });
      _ut.test('test_getLeastUpperBound_directInterfaceCase', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_directInterfaceCase);
      });
      _ut.test('test_getLeastUpperBound_directSubclassCase', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_directSubclassCase);
      });
      _ut.test('test_getLeastUpperBound_functionType', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_functionType);
      });
      _ut.test('test_getLeastUpperBound_mixinCase', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_mixinCase);
      });
      _ut.test('test_getLeastUpperBound_null', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_null);
      });
      _ut.test('test_getLeastUpperBound_object', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_object);
      });
      _ut.test('test_getLeastUpperBound_self', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_self);
      });
      _ut.test('test_getLeastUpperBound_sharedSuperclass1', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_sharedSuperclass1);
      });
      _ut.test('test_getLeastUpperBound_sharedSuperclass2', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_sharedSuperclass2);
      });
      _ut.test('test_getLeastUpperBound_sharedSuperclass3', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_sharedSuperclass3);
      });
      _ut.test('test_getLeastUpperBound_sharedSuperclass4', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_sharedSuperclass4);
      });
      _ut.test('test_getLeastUpperBound_sharedSuperinterface1', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_sharedSuperinterface1);
      });
      _ut.test('test_getLeastUpperBound_sharedSuperinterface2', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_sharedSuperinterface2);
      });
      _ut.test('test_getLeastUpperBound_sharedSuperinterface3', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_sharedSuperinterface3);
      });
      _ut.test('test_getLeastUpperBound_sharedSuperinterface4', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_sharedSuperinterface4);
      });
      _ut.test('test_getTypeArguments', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getTypeArguments);
      });
      _ut.test('test_isDirectSupertypeOf_extends', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isDirectSupertypeOf_extends);
      });
      _ut.test('test_isDirectSupertypeOf_false', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isDirectSupertypeOf_false);
      });
      _ut.test('test_isDirectSupertypeOf_implements', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isDirectSupertypeOf_implements);
      });
      _ut.test('test_isDirectSupertypeOf_with', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isDirectSupertypeOf_with);
      });
      _ut.test('test_isMoreSpecificThan_bottom', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_bottom);
      });
      _ut.test('test_isMoreSpecificThan_covariance', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_covariance);
      });
      _ut.test('test_isMoreSpecificThan_directSupertype', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_directSupertype);
      });
      _ut.test('test_isMoreSpecificThan_dynamic', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_dynamic);
      });
      _ut.test('test_isMoreSpecificThan_indirectSupertype', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_indirectSupertype);
      });
      _ut.test('test_isMoreSpecificThan_self', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_self);
      });
      _ut.test('test_isSubtypeOf_directSubtype', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_directSubtype);
      });
      _ut.test('test_isSubtypeOf_dynamic', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_dynamic);
      });
      _ut.test('test_isSubtypeOf_indirectSubtype', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_indirectSubtype);
      });
      _ut.test('test_isSubtypeOf_interface', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_interface);
      });
      _ut.test('test_isSubtypeOf_mixins', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_mixins);
      });
      _ut.test('test_isSubtypeOf_object', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_object);
      });
      _ut.test('test_isSubtypeOf_self', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_self);
      });
      _ut.test('test_isSubtypeOf_typeArguments', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_typeArguments);
      });
      _ut.test('test_isSupertypeOf_directSupertype', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSupertypeOf_directSupertype);
      });
      _ut.test('test_isSupertypeOf_dynamic', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSupertypeOf_dynamic);
      });
      _ut.test('test_isSupertypeOf_indirectSupertype', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSupertypeOf_indirectSupertype);
      });
      _ut.test('test_isSupertypeOf_interface', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSupertypeOf_interface);
      });
      _ut.test('test_isSupertypeOf_mixins', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSupertypeOf_mixins);
      });
      _ut.test('test_isSupertypeOf_object', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSupertypeOf_object);
      });
      _ut.test('test_isSupertypeOf_self', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSupertypeOf_self);
      });
      _ut.test('test_setTypeArguments', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_setTypeArguments);
      });
      _ut.test('test_substitute_equal', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_substitute_equal);
      });
      _ut.test('test_substitute_notEqual', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_substitute_notEqual);
      });
    });
  }
}
class TypeVariableTypeImplTest extends EngineTestCase {
  void test_creation() {
    JUnitTestCase.assertNotNull(new TypeVariableTypeImpl(new TypeVariableElementImpl(ASTFactory.identifier2("E"))));
  }
  void test_getElement() {
    TypeVariableElementImpl element = new TypeVariableElementImpl(ASTFactory.identifier2("E"));
    TypeVariableTypeImpl type = new TypeVariableTypeImpl(element);
    JUnitTestCase.assertEquals(element, type.element);
  }
  void test_substitute_equal() {
    TypeVariableElementImpl element = new TypeVariableElementImpl(ASTFactory.identifier2("E"));
    TypeVariableTypeImpl type = new TypeVariableTypeImpl(element);
    InterfaceTypeImpl argument = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("A")));
    TypeVariableTypeImpl parameter = new TypeVariableTypeImpl(element);
    JUnitTestCase.assertSame(argument, type.substitute2(<Type2> [argument], <Type2> [parameter]));
  }
  void test_substitute_notEqual() {
    TypeVariableTypeImpl type = new TypeVariableTypeImpl(new TypeVariableElementImpl(ASTFactory.identifier2("E")));
    InterfaceTypeImpl argument = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("A")));
    TypeVariableTypeImpl parameter = new TypeVariableTypeImpl(new TypeVariableElementImpl(ASTFactory.identifier2("F")));
    JUnitTestCase.assertSame(type, type.substitute2(<Type2> [argument], <Type2> [parameter]));
  }
  static dartSuite() {
    _ut.group('TypeVariableTypeImplTest', () {
      _ut.test('test_creation', () {
        final __test = new TypeVariableTypeImplTest();
        runJUnitTest(__test, __test.test_creation);
      });
      _ut.test('test_getElement', () {
        final __test = new TypeVariableTypeImplTest();
        runJUnitTest(__test, __test.test_getElement);
      });
      _ut.test('test_substitute_equal', () {
        final __test = new TypeVariableTypeImplTest();
        runJUnitTest(__test, __test.test_substitute_equal);
      });
      _ut.test('test_substitute_notEqual', () {
        final __test = new TypeVariableTypeImplTest();
        runJUnitTest(__test, __test.test_substitute_notEqual);
      });
    });
  }
}
/**
 * The class {@code ElementFactory} defines utility methods used to create elements for testing
 * purposes. The elements that are created are complete in the sense that as much of the element
 * model as can be created, given the provided information, has been created.
 */
class ElementFactory {
  /**
   * The element representing the class 'Object'.
   */
  static ClassElementImpl _objectElement;
  static ClassElementImpl classElement(String typeName, InterfaceType superclassType, List<String> parameterNames) {
    ClassElementImpl element = new ClassElementImpl(ASTFactory.identifier2(typeName));
    element.supertype = superclassType;
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(element);
    element.type = type;
    int count = parameterNames.length;
    if (count > 0) {
      List<TypeVariableElementImpl> typeVariables = new List<TypeVariableElementImpl>(count);
      List<TypeVariableTypeImpl> typeArguments = new List<TypeVariableTypeImpl>(count);
      for (int i = 0; i < count; i++) {
        TypeVariableElementImpl variable = new TypeVariableElementImpl(ASTFactory.identifier2(parameterNames[i]));
        typeVariables[i] = variable;
        typeArguments[i] = new TypeVariableTypeImpl(variable);
        variable.type = typeArguments[i];
      }
      element.typeVariables = typeVariables;
      type.typeArguments = typeArguments;
    }
    return element;
  }
  static ClassElementImpl classElement2(String typeName, List<String> parameterNames) => classElement(typeName, object.type, parameterNames);
  static ConstructorElementImpl constructorElement(String name) => new ConstructorElementImpl(name == null ? null : ASTFactory.identifier2(name));
  static ExportElementImpl exportFor(LibraryElement exportedLibrary4, List<NamespaceCombinator> combinators4) {
    ExportElementImpl spec = new ExportElementImpl();
    spec.exportedLibrary = exportedLibrary4;
    spec.combinators = combinators4;
    return spec;
  }
  static FieldElementImpl fieldElement(String name, bool isStatic, bool isFinal, bool isConst, Type2 type32) {
    FieldElementImpl field = new FieldElementImpl.con1(ASTFactory.identifier2(name));
    field.const2 = isConst;
    field.final2 = isFinal;
    field.static = isStatic;
    field.type = type32;
    PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con2(field);
    getter.getter = true;
    getter.synthetic = true;
    field.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
    getterType.returnType = type32;
    getter.type = getterType;
    if (!isConst && !isFinal) {
      PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.con2(field);
      setter.setter = true;
      setter.synthetic = true;
      field.setter = setter;
      FunctionTypeImpl setterType = new FunctionTypeImpl.con1(getter);
      setterType.normalParameterTypes = <Type2> [type32];
      setterType.returnType = VoidTypeImpl.instance;
      setter.type = setterType;
    }
    return field;
  }
  static FunctionElementImpl functionElement(String functionName) => functionElement4(functionName, null, null, null, null);
  static FunctionElementImpl functionElement2(String functionName, ClassElement returnElement) => functionElement3(functionName, returnElement, null, null);
  static FunctionElementImpl functionElement3(String functionName, ClassElement returnElement, List<ClassElement> normalParameters, List<ClassElement> optionalParameters) {
    FunctionElementImpl functionElement = new FunctionElementImpl.con1(ASTFactory.identifier2(functionName));
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    functionElement.type = functionType;
    if (returnElement != null) {
      functionType.returnType = returnElement.type;
    }
    int count = normalParameters == null ? 0 : normalParameters.length;
    if (count > 0) {
      List<InterfaceType> normalParameterTypes = new List<InterfaceType>(count);
      for (int i = 0; i < count; i++) {
        normalParameterTypes[i] = normalParameters[i].type;
      }
      functionType.normalParameterTypes = normalParameterTypes;
    }
    count = optionalParameters == null ? 0 : optionalParameters.length;
    if (count > 0) {
      List<InterfaceType> optionalParameterTypes = new List<InterfaceType>(count);
      for (int i = 0; i < count; i++) {
        optionalParameterTypes[i] = optionalParameters[i].type;
      }
      functionType.optionalParameterTypes = optionalParameterTypes;
    }
    return functionElement;
  }
  static FunctionElementImpl functionElement4(String functionName, ClassElement returnElement, List<ClassElement> normalParameters, List<String> names, List<ClassElement> namedParameters) {
    FunctionElementImpl functionElement = new FunctionElementImpl.con1(ASTFactory.identifier2(functionName));
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    functionElement.type = functionType;
    if (returnElement != null) {
      functionType.returnType = returnElement.type;
    }
    int count = normalParameters == null ? 0 : normalParameters.length;
    if (count > 0) {
      List<InterfaceType> normalParameterTypes = new List<InterfaceType>(count);
      for (int i = 0; i < count; i++) {
        normalParameterTypes[i] = normalParameters[i].type;
      }
      functionType.normalParameterTypes = normalParameterTypes;
    }
    if (names != null && names.length > 0 && names.length == namedParameters.length) {
      LinkedHashMap<String, Type2> map = new LinkedHashMap<String, Type2>();
      for (int i = 0; i < names.length; i++) {
        map[names[i]] = namedParameters[i].type;
      }
      functionType.namedParameterTypes = map;
    } else if (names != null) {
      throw new IllegalStateException("The passed String[] and ClassElement[] arrays had different lengths.");
    }
    return functionElement;
  }
  static FunctionElementImpl functionElement5(String functionName, List<ClassElement> normalParameters) => functionElement3(functionName, null, normalParameters, null);
  static FunctionElementImpl functionElement6(String functionName, List<ClassElement> normalParameters, List<ClassElement> optionalParameters) => functionElement3(functionName, null, normalParameters, optionalParameters);
  static FunctionElementImpl functionElement7(String functionName, List<ClassElement> normalParameters, List<String> names, List<ClassElement> namedParameters) => functionElement4(functionName, null, normalParameters, names, namedParameters);
  static ClassElementImpl get object {
    if (_objectElement == null) {
      _objectElement = classElement("Object", (null as InterfaceType), []);
    }
    return _objectElement;
  }
  static PropertyAccessorElementImpl getterElement(String name, bool isStatic, Type2 type33) {
    FieldElementImpl field = new FieldElementImpl.con1(ASTFactory.identifier2(name));
    field.static = isStatic;
    field.synthetic = true;
    field.type = type33;
    PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con2(field);
    getter.getter = true;
    field.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
    getterType.returnType = type33;
    getter.type = getterType;
    return getter;
  }
  static ImportElementImpl importFor(LibraryElement importedLibrary5, PrefixElement prefix13, List<NamespaceCombinator> combinators5) {
    ImportElementImpl spec = new ImportElementImpl();
    spec.importedLibrary = importedLibrary5;
    spec.prefix = prefix13;
    spec.combinators = combinators5;
    return spec;
  }
  static LibraryElementImpl library(AnalysisContext context, String libraryName) {
    String fileName = "${libraryName}.dart";
    FileBasedSource source = new FileBasedSource.con1(null, FileUtilities2.createFile(fileName));
    CompilationUnitElementImpl unit = new CompilationUnitElementImpl(fileName);
    unit.source = source;
    LibraryElementImpl library = new LibraryElementImpl(context, ASTFactory.libraryIdentifier2([libraryName]));
    library.definingCompilationUnit = unit;
    return library;
  }
  static LocalVariableElementImpl localVariableElement(Identifier name) => new LocalVariableElementImpl(name);
  static LocalVariableElementImpl localVariableElement2(String name) => new LocalVariableElementImpl(ASTFactory.identifier2(name));
  static MethodElementImpl methodElement(String methodName, Type2 returnType12, List<Type2> argumentTypes) {
    MethodElementImpl method = new MethodElementImpl.con1(ASTFactory.identifier2(methodName));
    int count = argumentTypes.length;
    List<ParameterElement> parameters = new List<ParameterElement>(count);
    for (int i = 0; i < count; i++) {
      ParameterElementImpl parameter = new ParameterElementImpl(ASTFactory.identifier2("a${i}"));
      parameter.type = argumentTypes[i];
      parameters[i] = parameter;
    }
    method.parameters = parameters;
    FunctionTypeImpl methodType = new FunctionTypeImpl.con1(method);
    methodType.normalParameterTypes = argumentTypes;
    methodType.returnType = returnType12;
    method.type = methodType;
    return method;
  }
  static ParameterElementImpl namedParameter(String name) {
    ParameterElementImpl parameter = new ParameterElementImpl(ASTFactory.identifier2(name));
    parameter.parameterKind = ParameterKind.NAMED;
    return parameter;
  }
  static ParameterElementImpl positionalParameter(String name) {
    ParameterElementImpl parameter = new ParameterElementImpl(ASTFactory.identifier2(name));
    parameter.parameterKind = ParameterKind.POSITIONAL;
    return parameter;
  }
  static PrefixElementImpl prefix(String name) => new PrefixElementImpl(ASTFactory.identifier2(name));
  static ParameterElementImpl requiredParameter(String name) {
    ParameterElementImpl parameter = new ParameterElementImpl(ASTFactory.identifier2(name));
    parameter.parameterKind = ParameterKind.REQUIRED;
    return parameter;
  }
  static PropertyAccessorElementImpl setterElement(String name, bool isStatic, Type2 type34) {
    FieldElementImpl field = new FieldElementImpl.con1(ASTFactory.identifier2(name));
    field.static = isStatic;
    field.synthetic = true;
    field.type = type34;
    PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con2(field);
    getter.getter = true;
    field.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
    getterType.returnType = type34;
    getter.type = getterType;
    PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.con2(field);
    setter.setter = true;
    setter.synthetic = true;
    field.setter = setter;
    FunctionTypeImpl setterType = new FunctionTypeImpl.con1(getter);
    setterType.normalParameterTypes = <Type2> [type34];
    setterType.returnType = VoidTypeImpl.instance;
    setter.type = setterType;
    return setter;
  }
  static TopLevelVariableElementImpl topLevelVariableElement(Identifier name) => new TopLevelVariableElementImpl.con1(name);
  static TopLevelVariableElementImpl topLevelVariableElement2(String name) => new TopLevelVariableElementImpl.con2(name);
  /**
   * Prevent the creation of instances of this class.
   */
  ElementFactory() {
  }
}
class ClassElementImplTest extends EngineTestCase {
  void test_allSupertypes_interface() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = elementA.supertype;
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    elementC.interfaces = <InterfaceType> [typeB];
    List<InterfaceType> supers = elementC.allSupertypes;
    List<InterfaceType> types = new List<InterfaceType>();
    types.addAll(supers);
    JUnitTestCase.assertTrue(types.contains(typeA));
    JUnitTestCase.assertTrue(types.contains(typeB));
    JUnitTestCase.assertTrue(types.contains(typeObject));
    JUnitTestCase.assertFalse(types.contains(typeC));
  }
  void test_allSupertypes_mixins() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement("B", elementA.type, []);
    ClassElementImpl elementC = ElementFactory.classElement2("C", []);
    InterfaceType typeObject = elementA.supertype;
    InterfaceType typeA = elementA.type;
    InterfaceType typeB = elementB.type;
    InterfaceType typeC = elementC.type;
    elementC.mixins = <InterfaceType> [typeB];
    List<InterfaceType> supers = elementC.allSupertypes;
    List<InterfaceType> types = new List<InterfaceType>();
    types.addAll(supers);
    JUnitTestCase.assertFalse(types.contains(typeA));
    JUnitTestCase.assertTrue(types.contains(typeB));
    JUnitTestCase.assertTrue(types.contains(typeObject));
    JUnitTestCase.assertFalse(types.contains(typeC));
  }
  void test_lookUpGetter_declared() {
    LibraryElementImpl library6 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getter = ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement> [getter];
    ((library6.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classA];
    JUnitTestCase.assertSame(getter, classA.lookUpGetter(getterName, library6));
  }
  void test_lookUpGetter_inherited() {
    LibraryElementImpl library7 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getter = ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement> [getter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ((library7.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classA, classB];
    JUnitTestCase.assertSame(getter, classB.lookUpGetter(getterName, library7));
  }
  void test_lookUpGetter_undeclared() {
    LibraryElementImpl library8 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ((library8.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classA];
    JUnitTestCase.assertNull(classA.lookUpGetter("g", library8));
  }
  void test_lookUpMethod_declared() {
    LibraryElementImpl library9 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    ((library9.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classA];
    JUnitTestCase.assertSame(method, classA.lookUpMethod(methodName, library9));
  }
  void test_lookUpMethod_inherited() {
    LibraryElementImpl library10 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ((library10.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classA, classB];
    JUnitTestCase.assertSame(method, classB.lookUpMethod(methodName, library10));
  }
  void test_lookUpMethod_undeclared() {
    LibraryElementImpl library11 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ((library11.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classA];
    JUnitTestCase.assertNull(classA.lookUpMethod("m", library11));
  }
  void test_lookUpSetter_declared() {
    LibraryElementImpl library12 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setter = ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement> [setter];
    ((library12.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classA];
    JUnitTestCase.assertSame(setter, classA.lookUpSetter(setterName, library12));
  }
  void test_lookUpSetter_inherited() {
    LibraryElementImpl library13 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setter = ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement> [setter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ((library13.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classA, classB];
    JUnitTestCase.assertSame(setter, classB.lookUpSetter(setterName, library13));
  }
  void test_lookUpSetter_undeclared() {
    LibraryElementImpl library14 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ((library14.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classA];
    JUnitTestCase.assertNull(classA.lookUpSetter("s", library14));
  }
  static dartSuite() {
    _ut.group('ClassElementImplTest', () {
      _ut.test('test_allSupertypes_interface', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_allSupertypes_interface);
      });
      _ut.test('test_allSupertypes_mixins', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_allSupertypes_mixins);
      });
      _ut.test('test_lookUpGetter_declared', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpGetter_declared);
      });
      _ut.test('test_lookUpGetter_inherited', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpGetter_inherited);
      });
      _ut.test('test_lookUpGetter_undeclared', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpGetter_undeclared);
      });
      _ut.test('test_lookUpMethod_declared', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpMethod_declared);
      });
      _ut.test('test_lookUpMethod_inherited', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpMethod_inherited);
      });
      _ut.test('test_lookUpMethod_undeclared', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpMethod_undeclared);
      });
      _ut.test('test_lookUpSetter_declared', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpSetter_declared);
      });
      _ut.test('test_lookUpSetter_inherited', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpSetter_inherited);
      });
      _ut.test('test_lookUpSetter_undeclared', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpSetter_undeclared);
      });
    });
  }
}
class ElementImplTest extends EngineTestCase {
  void test_equals() {
    LibraryElementImpl library15 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElementImpl classElement = ElementFactory.classElement2("C", []);
    ((library15.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classElement];
    FieldElement field = ElementFactory.fieldElement("next", false, false, false, classElement.type);
    classElement.fields = <FieldElement> [field];
    JUnitTestCase.assertTrue(field == field);
    JUnitTestCase.assertFalse(field == field.getter);
    JUnitTestCase.assertFalse(field == field.setter);
    JUnitTestCase.assertFalse(field.getter == field.setter);
  }
  void test_isAccessibleIn_private_differentLibrary() {
    AnalysisContextImpl context = new AnalysisContextImpl();
    LibraryElementImpl library1 = ElementFactory.library(context, "lib1");
    ClassElement classElement = ElementFactory.classElement2("_C", []);
    ((library1.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classElement];
    LibraryElementImpl library2 = ElementFactory.library(context, "lib2");
    JUnitTestCase.assertFalse(classElement.isAccessibleIn(library2));
  }
  void test_isAccessibleIn_private_sameLibrary() {
    LibraryElementImpl library16 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElement classElement = ElementFactory.classElement2("_C", []);
    ((library16.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classElement];
    JUnitTestCase.assertTrue(classElement.isAccessibleIn(library16));
  }
  void test_isAccessibleIn_public_differentLibrary() {
    AnalysisContextImpl context = new AnalysisContextImpl();
    LibraryElementImpl library1 = ElementFactory.library(context, "lib1");
    ClassElement classElement = ElementFactory.classElement2("C", []);
    ((library1.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classElement];
    LibraryElementImpl library2 = ElementFactory.library(context, "lib2");
    JUnitTestCase.assertTrue(classElement.isAccessibleIn(library2));
  }
  void test_isAccessibleIn_public_sameLibrary() {
    LibraryElementImpl library17 = ElementFactory.library(new AnalysisContextImpl(), "lib");
    ClassElement classElement = ElementFactory.classElement2("C", []);
    ((library17.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [classElement];
    JUnitTestCase.assertTrue(classElement.isAccessibleIn(library17));
  }
  static dartSuite() {
    _ut.group('ElementImplTest', () {
//      _ut.test('test_equals', () {
//        final __test = new ElementImplTest();
//        runJUnitTest(__test, __test.test_equals);
//      });
      _ut.test('test_isAccessibleIn_private_differentLibrary', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_isAccessibleIn_private_differentLibrary);
      });
      _ut.test('test_isAccessibleIn_private_sameLibrary', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_isAccessibleIn_private_sameLibrary);
      });
      _ut.test('test_isAccessibleIn_public_differentLibrary', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_isAccessibleIn_public_differentLibrary);
      });
      _ut.test('test_isAccessibleIn_public_sameLibrary', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_isAccessibleIn_public_sameLibrary);
      });
    });
  }
}
class FunctionTypeImplTest extends EngineTestCase {
  void test_creation() {
    JUnitTestCase.assertNotNull(new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f"))));
  }
  void test_getElement() {
    FunctionElementImpl typeElement = new FunctionElementImpl.con1(ASTFactory.identifier2("f"));
    FunctionTypeImpl type = new FunctionTypeImpl.con1(typeElement);
    JUnitTestCase.assertEquals(typeElement, type.element);
  }
  void test_getNamedParameterTypes() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    Map<String, Type2> types = type.namedParameterTypes;
    EngineTestCase.assertSize2(0, types);
  }
  void test_getNormalParameterTypes() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    List<Type2> types = type.normalParameterTypes;
    EngineTestCase.assertLength(0, types);
  }
  void test_getReturnType() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    Type2 returnType8 = type.returnType;
    JUnitTestCase.assertEquals(VoidTypeImpl.instance, returnType8);
  }
  void test_getTypeArguments() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    List<Type2> types = type.typeArguments;
    EngineTestCase.assertLength(0, types);
  }
  void test_hashCode_element() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    type.hashCode;
  }
  void test_hashCode_noElement() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1((null as ExecutableElement));
    type.hashCode;
  }
  void test_isSubtypeOf_baseCase_classFunction() {
    ClassElementImpl functionElement = ElementFactory.classElement2("Function", []);
    InterfaceTypeImpl functionType = new InterfaceTypeImpl_11(functionElement);
    FunctionType f = ElementFactory.functionElement("f").type;
    JUnitTestCase.assertTrue(f.isSubtypeOf(functionType));
  }
  void test_isSubtypeOf_baseCase_notFunctionType() {
    FunctionType f = ElementFactory.functionElement("f").type;
    InterfaceType t = ElementFactory.classElement2("C", []).type;
    JUnitTestCase.assertFalse(f.isSubtypeOf(t));
  }
  void test_isSubtypeOf_baseCase_null() {
    FunctionType f = ElementFactory.functionElement("f").type;
    JUnitTestCase.assertFalse(f.isSubtypeOf(null));
  }
  void test_isSubtypeOf_baseCase_self() {
    FunctionType f = ElementFactory.functionElement("f").type;
    JUnitTestCase.assertTrue(f.isSubtypeOf(f));
  }
  void test_isSubtypeOf_namedParameters_isAssignable() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name"], <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name"], <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertTrue(s.isSubtypeOf(t));
  }
  void test_isSubtypeOf_namedParameters_isNotAssignable() {
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name"], <ClassElement> [ElementFactory.classElement2("A", [])]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name"], <ClassElement> [ElementFactory.classElement2("B", [])]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_namedParameters_namesDifferent() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name"], <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["diff"], <ClassElement> [b]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
  }
  void test_isSubtypeOf_namedParameters_orderOfParams() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["A", "B"], <ClassElement> [a, b]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["B", "A"], <ClassElement> [b, a]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_namedParameters_orderOfParams2() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["B"], <ClassElement> [b]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["B", "A"], <ClassElement> [b, a]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_namedParameters_orderOfParams3() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["A", "B"], <ClassElement> [a, b]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["B"], <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_namedParameters_sHasMoreParams() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name"], <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name", "name2"], <ClassElement> [b, b]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_namedParameters_tHasMoreParams() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name", "name2"], <ClassElement> [a, a]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name"], <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_normalParameters_isAssignable() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertTrue(s.isSubtypeOf(t));
  }
  void test_isSubtypeOf_normalParameters_isNotAssignable() {
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [ElementFactory.classElement2("A", [])]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [ElementFactory.classElement2("B", [])]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_normalParameters_sHasMoreParams() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [b, b]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_normalParameters_tHasMoreParams() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a, a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [b]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_optionalParameters_isAssignable() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertTrue(s.isSubtypeOf(t));
  }
  void test_isSubtypeOf_optionalParameters_isNotAssignable() {
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [ElementFactory.classElement2("A", [])]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [ElementFactory.classElement2("B", [])]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_optionalParameters_sHasMoreParams() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [b, b]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_optionalParameters_tHasMoreParams() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a, a]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_returnType_sIsVoid() {
    FunctionType t = ElementFactory.functionElement2("t", ElementFactory.classElement2("A", [])).type;
    FunctionType s = ElementFactory.functionElement("s").type;
    JUnitTestCase.assertTrue(VoidTypeImpl.instance == s.returnType);
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_returnType_tAssignableToS() {
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement2("t", a).type;
    FunctionType s = ElementFactory.functionElement2("s", b).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertTrue(s.isSubtypeOf(t));
  }
  void test_isSubtypeOf_returnType_tNotAssignableToS() {
    FunctionType t = ElementFactory.functionElement2("t", ElementFactory.classElement2("A", [])).type;
    FunctionType s = ElementFactory.functionElement2("s", ElementFactory.classElement2("B", [])).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }
  void test_isSubtypeOf_wrongFunctionType_normal_named() {
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement7("s", null, <String> ["name"], <ClassElement> [a]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
  }
  void test_isSubtypeOf_wrongFunctionType_normal_optional() {
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [a]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
  }
  void test_isSubtypeOf_wrongFunctionType_optional_named() {
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement7("s", null, <String> ["name"], <ClassElement> [a]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
  }
  void test_setNamedParameterTypes() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    LinkedHashMap<String, Type2> expectedTypes = new LinkedHashMap<String, Type2>();
    expectedTypes["a"] = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("C")));
    type.namedParameterTypes = expectedTypes;
    Map<String, Type2> types = type.namedParameterTypes;
    JUnitTestCase.assertEquals(expectedTypes, types);
  }
  void test_setNormalParameterTypes() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    List<Type2> expectedTypes = <Type2> [new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("C")))];
    type.normalParameterTypes = expectedTypes;
    List<Type2> types = type.normalParameterTypes;
    JUnitTestCase.assertEquals(expectedTypes, types);
  }
  void test_setReturnType() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    Type2 expectedType = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("C")));
    type.returnType = expectedType;
    Type2 returnType9 = type.returnType;
    JUnitTestCase.assertEquals(expectedType, returnType9);
  }
  void test_setTypeArguments() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    Type2 expectedType = new TypeVariableTypeImpl(new TypeVariableElementImpl(ASTFactory.identifier2("C")));
    type.typeArguments = <Type2> [expectedType];
    List<Type2> arguments = type.typeArguments;
    EngineTestCase.assertLength(1, arguments);
    JUnitTestCase.assertEquals(expectedType, arguments[0]);
  }
  void test_substitute2_equal() {
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    TypeVariableTypeImpl parameterType = new TypeVariableTypeImpl(new TypeVariableElementImpl(ASTFactory.identifier2("E")));
    functionType.returnType = parameterType;
    functionType.normalParameterTypes = <Type2> [parameterType];
    functionType.optionalParameterTypes = <Type2> [parameterType];
    LinkedHashMap<String, Type2> namedParameterTypes = new LinkedHashMap<String, Type2>();
    String namedParameterName = "c";
    namedParameterTypes[namedParameterName] = parameterType;
    functionType.namedParameterTypes = namedParameterTypes;
    InterfaceTypeImpl argumentType = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("D")));
    FunctionType result = functionType.substitute2(<Type2> [argumentType], <Type2> [parameterType]);
    JUnitTestCase.assertEquals(argumentType, result.returnType);
    List<Type2> normalParameters = result.normalParameterTypes;
    EngineTestCase.assertLength(1, normalParameters);
    JUnitTestCase.assertEquals(argumentType, normalParameters[0]);
    List<Type2> optionalParameters = result.optionalParameterTypes;
    EngineTestCase.assertLength(1, optionalParameters);
    JUnitTestCase.assertEquals(argumentType, optionalParameters[0]);
    Map<String, Type2> namedParameters = result.namedParameterTypes;
    EngineTestCase.assertSize2(1, namedParameters);
    JUnitTestCase.assertEquals(argumentType, namedParameters[namedParameterName]);
  }
  void test_substitute2_notEqual() {
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(ASTFactory.identifier2("f")));
    Type2 returnType = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("R")));
    Type2 normalParameterType = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("A")));
    Type2 optionalParameterType = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("B")));
    Type2 namedParameterType = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("C")));
    functionType.returnType = returnType;
    functionType.normalParameterTypes = <Type2> [normalParameterType];
    functionType.optionalParameterTypes = <Type2> [optionalParameterType];
    LinkedHashMap<String, Type2> namedParameterTypes = new LinkedHashMap<String, Type2>();
    String namedParameterName = "c";
    namedParameterTypes[namedParameterName] = namedParameterType;
    functionType.namedParameterTypes = namedParameterTypes;
    InterfaceTypeImpl argumentType = new InterfaceTypeImpl.con1(new ClassElementImpl(ASTFactory.identifier2("D")));
    TypeVariableTypeImpl parameterType = new TypeVariableTypeImpl(new TypeVariableElementImpl(ASTFactory.identifier2("E")));
    FunctionType result = functionType.substitute2(<Type2> [argumentType], <Type2> [parameterType]);
    JUnitTestCase.assertEquals(returnType, result.returnType);
    List<Type2> normalParameters = result.normalParameterTypes;
    EngineTestCase.assertLength(1, normalParameters);
    JUnitTestCase.assertEquals(normalParameterType, normalParameters[0]);
    List<Type2> optionalParameters = result.optionalParameterTypes;
    EngineTestCase.assertLength(1, optionalParameters);
    JUnitTestCase.assertEquals(optionalParameterType, optionalParameters[0]);
    Map<String, Type2> namedParameters = result.namedParameterTypes;
    EngineTestCase.assertSize2(1, namedParameters);
    JUnitTestCase.assertEquals(namedParameterType, namedParameters[namedParameterName]);
  }
  static dartSuite() {
    _ut.group('FunctionTypeImplTest', () {
      _ut.test('test_creation', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_creation);
      });
      _ut.test('test_getElement', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_getElement);
      });
      _ut.test('test_getNamedParameterTypes', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_getNamedParameterTypes);
      });
      _ut.test('test_getNormalParameterTypes', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_getNormalParameterTypes);
      });
      _ut.test('test_getReturnType', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_getReturnType);
      });
      _ut.test('test_getTypeArguments', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_getTypeArguments);
      });
      _ut.test('test_hashCode_element', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_hashCode_element);
      });
      _ut.test('test_hashCode_noElement', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_hashCode_noElement);
      });
      _ut.test('test_isSubtypeOf_baseCase_classFunction', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_baseCase_classFunction);
      });
      _ut.test('test_isSubtypeOf_baseCase_notFunctionType', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_baseCase_notFunctionType);
      });
      _ut.test('test_isSubtypeOf_baseCase_null', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_baseCase_null);
      });
      _ut.test('test_isSubtypeOf_baseCase_self', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_baseCase_self);
      });
      _ut.test('test_isSubtypeOf_namedParameters_isAssignable', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_namedParameters_isAssignable);
      });
      _ut.test('test_isSubtypeOf_namedParameters_isNotAssignable', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_namedParameters_isNotAssignable);
      });
      _ut.test('test_isSubtypeOf_namedParameters_namesDifferent', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_namedParameters_namesDifferent);
      });
      _ut.test('test_isSubtypeOf_namedParameters_orderOfParams', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_namedParameters_orderOfParams);
      });
      _ut.test('test_isSubtypeOf_namedParameters_orderOfParams2', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_namedParameters_orderOfParams2);
      });
      _ut.test('test_isSubtypeOf_namedParameters_orderOfParams3', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_namedParameters_orderOfParams3);
      });
      _ut.test('test_isSubtypeOf_namedParameters_sHasMoreParams', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_namedParameters_sHasMoreParams);
      });
      _ut.test('test_isSubtypeOf_namedParameters_tHasMoreParams', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_namedParameters_tHasMoreParams);
      });
      _ut.test('test_isSubtypeOf_normalParameters_isAssignable', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_normalParameters_isAssignable);
      });
      _ut.test('test_isSubtypeOf_normalParameters_isNotAssignable', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_normalParameters_isNotAssignable);
      });
      _ut.test('test_isSubtypeOf_normalParameters_sHasMoreParams', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_normalParameters_sHasMoreParams);
      });
      _ut.test('test_isSubtypeOf_normalParameters_tHasMoreParams', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_normalParameters_tHasMoreParams);
      });
      _ut.test('test_isSubtypeOf_optionalParameters_isAssignable', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_optionalParameters_isAssignable);
      });
      _ut.test('test_isSubtypeOf_optionalParameters_isNotAssignable', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_optionalParameters_isNotAssignable);
      });
      _ut.test('test_isSubtypeOf_optionalParameters_sHasMoreParams', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_optionalParameters_sHasMoreParams);
      });
      _ut.test('test_isSubtypeOf_optionalParameters_tHasMoreParams', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_optionalParameters_tHasMoreParams);
      });
      _ut.test('test_isSubtypeOf_returnType_sIsVoid', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_returnType_sIsVoid);
      });
      _ut.test('test_isSubtypeOf_returnType_tAssignableToS', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_returnType_tAssignableToS);
      });
      _ut.test('test_isSubtypeOf_returnType_tNotAssignableToS', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_returnType_tNotAssignableToS);
      });
      _ut.test('test_isSubtypeOf_wrongFunctionType_normal_named', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_wrongFunctionType_normal_named);
      });
      _ut.test('test_isSubtypeOf_wrongFunctionType_normal_optional', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_wrongFunctionType_normal_optional);
      });
      _ut.test('test_isSubtypeOf_wrongFunctionType_optional_named', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_wrongFunctionType_optional_named);
      });
      _ut.test('test_setNamedParameterTypes', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_setNamedParameterTypes);
      });
      _ut.test('test_setNormalParameterTypes', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_setNormalParameterTypes);
      });
      _ut.test('test_setReturnType', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_setReturnType);
      });
      _ut.test('test_setTypeArguments', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_setTypeArguments);
      });
      _ut.test('test_substitute2_equal', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_substitute2_equal);
      });
      _ut.test('test_substitute2_notEqual', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_substitute2_notEqual);
      });
    });
  }
}
class InterfaceTypeImpl_11 extends InterfaceTypeImpl {
  InterfaceTypeImpl_11(ClassElement arg0) : super.con1(arg0);
  bool isDartCoreFunction() => true;
}
main() {
  FunctionTypeImplTest.dartSuite();
  InterfaceTypeImplTest.dartSuite();
  TypeVariableTypeImplTest.dartSuite();
  ClassElementImplTest.dartSuite();
  ElementLocationImplTest.dartSuite();
  ElementImplTest.dartSuite();
  LibraryElementImplTest.dartSuite();
}