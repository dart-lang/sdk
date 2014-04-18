// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.element_test;

import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/java_junit.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext, AnalysisContextImpl;
import 'package:unittest/unittest.dart' as _ut;
import 'test_support.dart';
import 'ast_test.dart' show AstFactory;
import 'resolver_test.dart' show TestTypeProvider, AnalysisContextHelper;

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

  void test_equals_equalWithDifferentUriKind() {
    ElementLocationImpl first = new ElementLocationImpl.con2("fa;fb;c");
    ElementLocationImpl second = new ElementLocationImpl.con2("pa;pb;c");
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
    List<String> components = location.components;
    EngineTestCase.assertLength(3, components);
    JUnitTestCase.assertEquals("a", components[0]);
    JUnitTestCase.assertEquals("b", components[1]);
    JUnitTestCase.assertEquals("c", components[2]);
  }

  void test_getEncoding() {
    String encoding = "a;b;c;;d";
    ElementLocationImpl location = new ElementLocationImpl.con2(encoding);
    JUnitTestCase.assertEquals(encoding, location.encoding);
  }

  void test_hashCode_equal() {
    String encoding = "a;b;c";
    ElementLocationImpl first = new ElementLocationImpl.con2(encoding);
    ElementLocationImpl second = new ElementLocationImpl.con2(encoding);
    JUnitTestCase.assertTrue(first.hashCode == second.hashCode);
  }

  void test_hashCode_equalWithDifferentUriKind() {
    ElementLocationImpl first = new ElementLocationImpl.con2("fa;fb;c");
    ElementLocationImpl second = new ElementLocationImpl.con2("pa;pb;c");
    JUnitTestCase.assertTrue(first.hashCode == second.hashCode);
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
      _ut.test('test_equals_equalWithDifferentUriKind', () {
        final __test = new ElementLocationImplTest();
        runJUnitTest(__test, __test.test_equals_equalWithDifferentUriKind);
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
      _ut.test('test_hashCode_equal', () {
        final __test = new ElementLocationImplTest();
        runJUnitTest(__test, __test.test_hashCode_equal);
      });
      _ut.test('test_hashCode_equalWithDifferentUriKind', () {
        final __test = new ElementLocationImplTest();
        runJUnitTest(__test, __test.test_hashCode_equalWithDifferentUriKind);
      });
    });
  }
}

class HtmlElementImplTest extends EngineTestCase {
  void test_equals_differentSource() {
    AnalysisContextImpl context = createAnalysisContext();
    HtmlElementImpl elementA = ElementFactory.htmlUnit(context, "indexA.html");
    HtmlElementImpl elementB = ElementFactory.htmlUnit(context, "indexB.html");
    JUnitTestCase.assertFalse(elementA == elementB);
  }

  void test_equals_null() {
    AnalysisContextImpl context = createAnalysisContext();
    HtmlElementImpl element = ElementFactory.htmlUnit(context, "index.html");
    JUnitTestCase.assertFalse(element == null);
  }

  void test_equals_sameSource() {
    AnalysisContextImpl context = createAnalysisContext();
    HtmlElementImpl elementA = ElementFactory.htmlUnit(context, "index.html");
    HtmlElementImpl elementB = ElementFactory.htmlUnit(context, "index.html");
    JUnitTestCase.assertTrue(elementA == elementB);
  }

  void test_equals_self() {
    AnalysisContextImpl context = createAnalysisContext();
    HtmlElementImpl element = ElementFactory.htmlUnit(context, "index.html");
    JUnitTestCase.assertTrue(element == element);
  }

  static dartSuite() {
    _ut.group('HtmlElementImplTest', () {
      _ut.test('test_equals_differentSource', () {
        final __test = new HtmlElementImplTest();
        runJUnitTest(__test, __test.test_equals_differentSource);
      });
      _ut.test('test_equals_null', () {
        final __test = new HtmlElementImplTest();
        runJUnitTest(__test, __test.test_equals_null);
      });
      _ut.test('test_equals_sameSource', () {
        final __test = new HtmlElementImplTest();
        runJUnitTest(__test, __test.test_equals_sameSource);
      });
      _ut.test('test_equals_self', () {
        final __test = new HtmlElementImplTest();
        runJUnitTest(__test, __test.test_equals_self);
      });
    });
  }
}

class MultiplyDefinedElementImplTest extends EngineTestCase {
  void test_fromElements_conflicting() {
    Element firstElement = ElementFactory.localVariableElement2("xx");
    Element secondElement = ElementFactory.localVariableElement2("yy");
    Element result = MultiplyDefinedElementImpl.fromElements(null, firstElement, secondElement);
    EngineTestCase.assertInstanceOf((obj) => obj is MultiplyDefinedElement, MultiplyDefinedElement, result);
    List<Element> elements = (result as MultiplyDefinedElement).conflictingElements;
    EngineTestCase.assertLength(2, elements);
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
    EngineTestCase.assertLength(3, elements);
    for (int i = 0; i < elements.length; i++) {
      EngineTestCase.assertInstanceOf((obj) => obj is LocalVariableElement, LocalVariableElement, elements[i]);
    }
  }

  void test_fromElements_nonConflicting() {
    Element element = ElementFactory.localVariableElement2("xx");
    JUnitTestCase.assertSame(element, MultiplyDefinedElementImpl.fromElements(null, element, element));
  }

  static dartSuite() {
    _ut.group('MultiplyDefinedElementImplTest', () {
      _ut.test('test_fromElements_conflicting', () {
        final __test = new MultiplyDefinedElementImplTest();
        runJUnitTest(__test, __test.test_fromElements_conflicting);
      });
      _ut.test('test_fromElements_multiple', () {
        final __test = new MultiplyDefinedElementImplTest();
        runJUnitTest(__test, __test.test_fromElements_multiple);
      });
      _ut.test('test_fromElements_nonConflicting', () {
        final __test = new MultiplyDefinedElementImplTest();
        runJUnitTest(__test, __test.test_fromElements_nonConflicting);
      });
    });
  }
}

class LibraryElementImplTest extends EngineTestCase {
  void test_creation() {
    JUnitTestCase.assertNotNull(new LibraryElementImpl(createAnalysisContext(), AstFactory.libraryIdentifier2(["l"])));
  }

  void test_getImportedLibraries() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library1 = ElementFactory.library(context, "l1");
    LibraryElementImpl library2 = ElementFactory.library(context, "l2");
    LibraryElementImpl library3 = ElementFactory.library(context, "l3");
    LibraryElementImpl library4 = ElementFactory.library(context, "l4");
    PrefixElement prefixA = new PrefixElementImpl(AstFactory.identifier3("a"));
    PrefixElement prefixB = new PrefixElementImpl(AstFactory.identifier3("b"));
    List<ImportElementImpl> imports = [
        ElementFactory.importFor(library2, null, []),
        ElementFactory.importFor(library2, prefixB, []),
        ElementFactory.importFor(library3, null, []),
        ElementFactory.importFor(library3, prefixA, []),
        ElementFactory.importFor(library3, prefixB, []),
        ElementFactory.importFor(library4, prefixA, [])];
    library1.imports = imports;
    List<LibraryElement> libraries = library1.importedLibraries;
    EngineTestCase.assertEqualsIgnoreOrder(<LibraryElement> [library2, library3, library4], libraries);
  }

  void test_getPrefixes() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "l1");
    PrefixElement prefixA = new PrefixElementImpl(AstFactory.identifier3("a"));
    PrefixElement prefixB = new PrefixElementImpl(AstFactory.identifier3("b"));
    List<ImportElementImpl> imports = [
        ElementFactory.importFor(ElementFactory.library(context, "l2"), null, []),
        ElementFactory.importFor(ElementFactory.library(context, "l3"), null, []),
        ElementFactory.importFor(ElementFactory.library(context, "l4"), prefixA, []),
        ElementFactory.importFor(ElementFactory.library(context, "l5"), prefixA, []),
        ElementFactory.importFor(ElementFactory.library(context, "l6"), prefixB, [])];
    library.imports = imports;
    List<PrefixElement> prefixes = library.prefixes;
    EngineTestCase.assertLength(2, prefixes);
    if (identical(prefixA, prefixes[0])) {
      JUnitTestCase.assertSame(prefixB, prefixes[1]);
    } else {
      JUnitTestCase.assertSame(prefixB, prefixes[0]);
      JUnitTestCase.assertSame(prefixA, prefixes[1]);
    }
  }

  void test_getUnits() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "test");
    CompilationUnitElement unitLib = library.definingCompilationUnit;
    CompilationUnitElementImpl unitA = ElementFactory.compilationUnit("unit_a.dart");
    CompilationUnitElementImpl unitB = ElementFactory.compilationUnit("unit_b.dart");
    library.parts = <CompilationUnitElement> [unitA, unitB];
    EngineTestCase.assertEqualsIgnoreOrder(<CompilationUnitElement> [unitLib, unitA, unitB], library.units);
  }

  void test_getVisibleLibraries_cycle() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "app");
    LibraryElementImpl libraryA = ElementFactory.library(context, "A");
    libraryA.imports = <ImportElementImpl> [ElementFactory.importFor(library, null, [])];
    library.imports = <ImportElementImpl> [ElementFactory.importFor(libraryA, null, [])];
    List<LibraryElement> libraries = library.visibleLibraries;
    EngineTestCase.assertEqualsIgnoreOrder(<LibraryElement> [library, libraryA], libraries);
  }

  void test_getVisibleLibraries_directExports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "app");
    LibraryElementImpl libraryA = ElementFactory.library(context, "A");
    library.exports = <ExportElementImpl> [ElementFactory.exportFor(libraryA, [])];
    List<LibraryElement> libraries = library.visibleLibraries;
    EngineTestCase.assertEqualsIgnoreOrder(<LibraryElement> [library], libraries);
  }

  void test_getVisibleLibraries_directImports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "app");
    LibraryElementImpl libraryA = ElementFactory.library(context, "A");
    library.imports = <ImportElementImpl> [ElementFactory.importFor(libraryA, null, [])];
    List<LibraryElement> libraries = library.visibleLibraries;
    EngineTestCase.assertEqualsIgnoreOrder(<LibraryElement> [library, libraryA], libraries);
  }

  void test_getVisibleLibraries_indirectExports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "app");
    LibraryElementImpl libraryA = ElementFactory.library(context, "A");
    LibraryElementImpl libraryAA = ElementFactory.library(context, "AA");
    libraryA.exports = <ExportElementImpl> [ElementFactory.exportFor(libraryAA, [])];
    library.imports = <ImportElementImpl> [ElementFactory.importFor(libraryA, null, [])];
    List<LibraryElement> libraries = library.visibleLibraries;
    EngineTestCase.assertEqualsIgnoreOrder(<LibraryElement> [library, libraryA, libraryAA], libraries);
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
    EngineTestCase.assertEqualsIgnoreOrder(<LibraryElement> [library, libraryA, libraryAA, libraryB], libraries);
  }

  void test_getVisibleLibraries_noImports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = ElementFactory.library(context, "app");
    EngineTestCase.assertEqualsIgnoreOrder(<LibraryElement> [library], library.visibleLibraries);
  }

  void test_isUpToDate() {
    AnalysisContext context = createAnalysisContext();
    context.sourceFactory = new SourceFactory([]);
    LibraryElement library = ElementFactory.library(context, "foo");
    context.setContents(library.definingCompilationUnit.source, "sdfsdff");
    // Assert that we are not up to date if the target has an old time stamp.
    JUnitTestCase.assertFalse(library.isUpToDate(0));
    // Assert that we are up to date with a target modification time in the future.
    JUnitTestCase.assertTrue(library.isUpToDate(JavaSystem.currentTimeMillis() + 1000));
  }

  void test_setImports() {
    AnalysisContext context = createAnalysisContext();
    LibraryElementImpl library = new LibraryElementImpl(context, AstFactory.libraryIdentifier2(["l1"]));
    List<ImportElementImpl> expectedImports = [
        ElementFactory.importFor(ElementFactory.library(context, "l2"), null, []),
        ElementFactory.importFor(ElementFactory.library(context, "l3"), null, [])];
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
      _ut.test('test_getPrefixes', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_getPrefixes);
      });
      _ut.test('test_getUnits', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_getUnits);
      });
      _ut.test('test_getVisibleLibraries_cycle', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_getVisibleLibraries_cycle);
      });
      _ut.test('test_getVisibleLibraries_directExports', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_getVisibleLibraries_directExports);
      });
      _ut.test('test_getVisibleLibraries_directImports', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_getVisibleLibraries_directImports);
      });
      _ut.test('test_getVisibleLibraries_indirectExports', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_getVisibleLibraries_indirectExports);
      });
      _ut.test('test_getVisibleLibraries_indirectImports', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_getVisibleLibraries_indirectImports);
      });
      _ut.test('test_getVisibleLibraries_noImports', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_getVisibleLibraries_noImports);
      });
      _ut.test('test_isUpToDate', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_isUpToDate);
      });
      _ut.test('test_setImports', () {
        final __test = new LibraryElementImplTest();
        runJUnitTest(__test, __test.test_setImports);
      });
    });
  }
}

class TypeParameterTypeImplTest extends EngineTestCase {
  void test_creation() {
    JUnitTestCase.assertNotNull(new TypeParameterTypeImpl(new TypeParameterElementImpl(AstFactory.identifier3("E"))));
  }

  void test_getElement() {
    TypeParameterElementImpl element = new TypeParameterElementImpl(AstFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    JUnitTestCase.assertEquals(element, type.element);
  }

  void test_isMoreSpecificThan_typeArguments_bottom() {
    TypeParameterElementImpl element = new TypeParameterElementImpl(AstFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    // E << bottom
    JUnitTestCase.assertTrue(type.isMoreSpecificThan(BottomTypeImpl.instance));
  }

  void test_isMoreSpecificThan_typeArguments_dynamic() {
    TypeParameterElementImpl element = new TypeParameterElementImpl(AstFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    // E << dynamic
    JUnitTestCase.assertTrue(type.isMoreSpecificThan(DynamicTypeImpl.instance));
  }

  void test_isMoreSpecificThan_typeArguments_object() {
    TypeParameterElementImpl element = new TypeParameterElementImpl(AstFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    // E << Object
    JUnitTestCase.assertTrue(type.isMoreSpecificThan(ElementFactory.object.type));
  }

  void test_isMoreSpecificThan_typeArguments_resursive() {
    ClassElementImpl classS = ElementFactory.classElement2("A", []);
    TypeParameterElementImpl typeParameterU = new TypeParameterElementImpl(AstFactory.identifier3("U"));
    TypeParameterTypeImpl typeParameterTypeU = new TypeParameterTypeImpl(typeParameterU);
    TypeParameterElementImpl typeParameterT = new TypeParameterElementImpl(AstFactory.identifier3("T"));
    TypeParameterTypeImpl typeParameterTypeT = new TypeParameterTypeImpl(typeParameterT);
    typeParameterT.bound = typeParameterTypeU;
    typeParameterU.bound = typeParameterTypeU;
    // <T extends U> and <U extends T>
    // T << S
    JUnitTestCase.assertFalse(typeParameterTypeT.isMoreSpecificThan(classS.type));
  }

  void test_isMoreSpecificThan_typeArguments_self() {
    TypeParameterElementImpl element = new TypeParameterElementImpl(AstFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    // E << E
    JUnitTestCase.assertTrue(type.isMoreSpecificThan(type));
  }

  void test_isMoreSpecificThan_typeArguments_transitivity_interfaceTypes() {
    //  class A {}
    //  class B extends A {}
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    TypeParameterElementImpl typeParameterT = new TypeParameterElementImpl(AstFactory.identifier3("T"));
    typeParameterT.bound = typeB;
    TypeParameterTypeImpl typeParameterTypeT = new TypeParameterTypeImpl(typeParameterT);
    // <T extends B>
    // T << A
    JUnitTestCase.assertTrue(typeParameterTypeT.isMoreSpecificThan(typeA));
  }

  void test_isMoreSpecificThan_typeArguments_transitivity_typeParameters() {
    ClassElementImpl classS = ElementFactory.classElement2("A", []);
    TypeParameterElementImpl typeParameterU = new TypeParameterElementImpl(AstFactory.identifier3("U"));
    typeParameterU.bound = classS.type;
    TypeParameterTypeImpl typeParameterTypeU = new TypeParameterTypeImpl(typeParameterU);
    TypeParameterElementImpl typeParameterT = new TypeParameterElementImpl(AstFactory.identifier3("T"));
    typeParameterT.bound = typeParameterTypeU;
    TypeParameterTypeImpl typeParameterTypeT = new TypeParameterTypeImpl(typeParameterT);
    // <T extends U> and <U extends S>
    // T << S
    JUnitTestCase.assertTrue(typeParameterTypeT.isMoreSpecificThan(classS.type));
  }

  void test_isMoreSpecificThan_typeArguments_upperBound() {
    ClassElementImpl classS = ElementFactory.classElement2("A", []);
    TypeParameterElementImpl typeParameterT = new TypeParameterElementImpl(AstFactory.identifier3("T"));
    typeParameterT.bound = classS.type;
    TypeParameterTypeImpl typeParameterTypeT = new TypeParameterTypeImpl(typeParameterT);
    // <T extends S>
    // T << S
    JUnitTestCase.assertTrue(typeParameterTypeT.isMoreSpecificThan(classS.type));
  }

  void test_substitute_equal() {
    TypeParameterElementImpl element = new TypeParameterElementImpl(AstFactory.identifier3("E"));
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(element);
    InterfaceTypeImpl argument = new InterfaceTypeImpl.con1(new ClassElementImpl(AstFactory.identifier3("A")));
    TypeParameterTypeImpl parameter = new TypeParameterTypeImpl(element);
    JUnitTestCase.assertSame(argument, type.substitute2(<DartType> [argument], <DartType> [parameter]));
  }

  void test_substitute_notEqual() {
    TypeParameterTypeImpl type = new TypeParameterTypeImpl(new TypeParameterElementImpl(AstFactory.identifier3("E")));
    InterfaceTypeImpl argument = new InterfaceTypeImpl.con1(new ClassElementImpl(AstFactory.identifier3("A")));
    TypeParameterTypeImpl parameter = new TypeParameterTypeImpl(new TypeParameterElementImpl(AstFactory.identifier3("F")));
    JUnitTestCase.assertSame(type, type.substitute2(<DartType> [argument], <DartType> [parameter]));
  }

  static dartSuite() {
    _ut.group('TypeParameterTypeImplTest', () {
      _ut.test('test_creation', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_creation);
      });
      _ut.test('test_getElement', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_getElement);
      });
      _ut.test('test_isMoreSpecificThan_typeArguments_bottom', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_typeArguments_bottom);
      });
      _ut.test('test_isMoreSpecificThan_typeArguments_dynamic', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_typeArguments_dynamic);
      });
      _ut.test('test_isMoreSpecificThan_typeArguments_object', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_typeArguments_object);
      });
      _ut.test('test_isMoreSpecificThan_typeArguments_resursive', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_typeArguments_resursive);
      });
      _ut.test('test_isMoreSpecificThan_typeArguments_self', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_typeArguments_self);
      });
      _ut.test('test_isMoreSpecificThan_typeArguments_transitivity_interfaceTypes', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_typeArguments_transitivity_interfaceTypes);
      });
      _ut.test('test_isMoreSpecificThan_typeArguments_transitivity_typeParameters', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_typeArguments_transitivity_typeParameters);
      });
      _ut.test('test_isMoreSpecificThan_typeArguments_upperBound', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_typeArguments_upperBound);
      });
      _ut.test('test_substitute_equal', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_substitute_equal);
      });
      _ut.test('test_substitute_notEqual', () {
        final __test = new TypeParameterTypeImplTest();
        runJUnitTest(__test, __test.test_substitute_notEqual);
      });
    });
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
    JUnitTestCase.assertEquals(2, InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type));
    JUnitTestCase.assertEquals(4, InterfaceTypeImpl.computeLongestInheritancePathToObject(classE.type));
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
    JUnitTestCase.assertEquals(2, InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type));
    JUnitTestCase.assertEquals(4, InterfaceTypeImpl.computeLongestInheritancePathToObject(classE.type));
  }

  void test_computeLongestInheritancePathToObject_object() {
    //
    //   Object
    //     |
    //     A
    //
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType object = classA.supertype;
    JUnitTestCase.assertEquals(0, InterfaceTypeImpl.computeLongestInheritancePathToObject(object));
  }

  void test_computeLongestInheritancePathToObject_recursion() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    JUnitTestCase.assertEquals(2, InterfaceTypeImpl.computeLongestInheritancePathToObject(classA.type));
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
    JUnitTestCase.assertEquals(1, InterfaceTypeImpl.computeLongestInheritancePathToObject(classA.type));
    JUnitTestCase.assertEquals(2, InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type));
    JUnitTestCase.assertEquals(3, InterfaceTypeImpl.computeLongestInheritancePathToObject(classC.type));
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
    JUnitTestCase.assertEquals(1, InterfaceTypeImpl.computeLongestInheritancePathToObject(classA.type));
    JUnitTestCase.assertEquals(2, InterfaceTypeImpl.computeLongestInheritancePathToObject(classB.type));
    JUnitTestCase.assertEquals(3, InterfaceTypeImpl.computeLongestInheritancePathToObject(classC.type));
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
    EngineTestCase.assertSizeOfSet(1, superinterfacesOfA);
    InterfaceType typeObject = ElementFactory.object.type;
    JUnitTestCase.assertTrue(superinterfacesOfA.contains(typeObject));
    // B<D>
    InterfaceTypeImpl typeBD = new InterfaceTypeImpl.con1(classB);
    typeBD.typeArguments = <DartType> [classD.type];
    Set<InterfaceType> superinterfacesOfBD = InterfaceTypeImpl.computeSuperinterfaceSet(typeBD);
    EngineTestCase.assertSizeOfSet(2, superinterfacesOfBD);
    JUnitTestCase.assertTrue(superinterfacesOfBD.contains(typeObject));
    JUnitTestCase.assertTrue(superinterfacesOfBD.contains(typeA));
    // C<D>
    InterfaceTypeImpl typeCD = new InterfaceTypeImpl.con1(classC);
    typeCD.typeArguments = <DartType> [classD.type];
    Set<InterfaceType> superinterfacesOfCD = InterfaceTypeImpl.computeSuperinterfaceSet(typeCD);
    EngineTestCase.assertSizeOfSet(3, superinterfacesOfCD);
    JUnitTestCase.assertTrue(superinterfacesOfCD.contains(typeObject));
    JUnitTestCase.assertTrue(superinterfacesOfCD.contains(typeA));
    JUnitTestCase.assertTrue(superinterfacesOfCD.contains(typeBD));
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
    EngineTestCase.assertSizeOfSet(1, superinterfacesOfA);
    InterfaceType typeObject = ElementFactory.object.type;
    JUnitTestCase.assertTrue(superinterfacesOfA.contains(typeObject));
    // B<D>
    InterfaceTypeImpl typeBD = new InterfaceTypeImpl.con1(classB);
    typeBD.typeArguments = <DartType> [classD.type];
    Set<InterfaceType> superinterfacesOfBD = InterfaceTypeImpl.computeSuperinterfaceSet(typeBD);
    EngineTestCase.assertSizeOfSet(2, superinterfacesOfBD);
    JUnitTestCase.assertTrue(superinterfacesOfBD.contains(typeObject));
    JUnitTestCase.assertTrue(superinterfacesOfBD.contains(typeA));
    // C<D>
    InterfaceTypeImpl typeCD = new InterfaceTypeImpl.con1(classC);
    typeCD.typeArguments = <DartType> [classD.type];
    Set<InterfaceType> superinterfacesOfCD = InterfaceTypeImpl.computeSuperinterfaceSet(typeCD);
    EngineTestCase.assertSizeOfSet(3, superinterfacesOfCD);
    JUnitTestCase.assertTrue(superinterfacesOfCD.contains(typeObject));
    JUnitTestCase.assertTrue(superinterfacesOfCD.contains(typeA));
    JUnitTestCase.assertTrue(superinterfacesOfCD.contains(typeBD));
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
    EngineTestCase.assertSizeOfSet(3, superinterfacesOfD);
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(classA.type));
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(classC.type));
    // E
    Set<InterfaceType> superinterfacesOfE = InterfaceTypeImpl.computeSuperinterfaceSet(classE.type);
    EngineTestCase.assertSizeOfSet(5, superinterfacesOfE);
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(classA.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(classB.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(classC.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(classD.type));
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
    EngineTestCase.assertSizeOfSet(3, superinterfacesOfD);
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(classA.type));
    JUnitTestCase.assertTrue(superinterfacesOfD.contains(classC.type));
    // E
    Set<InterfaceType> superinterfacesOfE = InterfaceTypeImpl.computeSuperinterfaceSet(classE.type);
    EngineTestCase.assertSizeOfSet(5, superinterfacesOfE);
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(classA.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(classB.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(classC.type));
    JUnitTestCase.assertTrue(superinterfacesOfE.contains(classD.type));
  }

  void test_computeSuperinterfaceSet_recursion() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    Set<InterfaceType> superinterfacesOfB = InterfaceTypeImpl.computeSuperinterfaceSet(classB.type);
    EngineTestCase.assertSizeOfSet(2, superinterfacesOfB);
  }

  void test_computeSuperinterfaceSet_singleInterfacePath() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    classB.interfaces = <InterfaceType> [classA.type];
    classC.interfaces = <InterfaceType> [classB.type];
    // A
    Set<InterfaceType> superinterfacesOfA = InterfaceTypeImpl.computeSuperinterfaceSet(classA.type);
    EngineTestCase.assertSizeOfSet(1, superinterfacesOfA);
    JUnitTestCase.assertTrue(superinterfacesOfA.contains(ElementFactory.object.type));
    // B
    Set<InterfaceType> superinterfacesOfB = InterfaceTypeImpl.computeSuperinterfaceSet(classB.type);
    EngineTestCase.assertSizeOfSet(2, superinterfacesOfB);
    JUnitTestCase.assertTrue(superinterfacesOfB.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfB.contains(classA.type));
    // C
    Set<InterfaceType> superinterfacesOfC = InterfaceTypeImpl.computeSuperinterfaceSet(classC.type);
    EngineTestCase.assertSizeOfSet(3, superinterfacesOfC);
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(classA.type));
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(classB.type));
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
    EngineTestCase.assertSizeOfSet(1, superinterfacesOfA);
    JUnitTestCase.assertTrue(superinterfacesOfA.contains(ElementFactory.object.type));
    // B
    Set<InterfaceType> superinterfacesOfB = InterfaceTypeImpl.computeSuperinterfaceSet(classB.type);
    EngineTestCase.assertSizeOfSet(2, superinterfacesOfB);
    JUnitTestCase.assertTrue(superinterfacesOfB.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfB.contains(classA.type));
    // C
    Set<InterfaceType> superinterfacesOfC = InterfaceTypeImpl.computeSuperinterfaceSet(classC.type);
    EngineTestCase.assertSizeOfSet(3, superinterfacesOfC);
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(ElementFactory.object.type));
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(classA.type));
    JUnitTestCase.assertTrue(superinterfacesOfC.contains(classB.type));
  }

  void test_creation() {
    JUnitTestCase.assertNotNull(new InterfaceTypeImpl.con1(ElementFactory.classElement2("A", [])));
  }

  void test_getAccessors() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A", []);
    PropertyAccessorElement getterG = ElementFactory.getterElement("g", false, null);
    PropertyAccessorElement getterH = ElementFactory.getterElement("h", false, null);
    typeElement.accessors = <PropertyAccessorElement> [getterG, getterH];
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(typeElement);
    JUnitTestCase.assertEquals(2, type.accessors.length);
  }

  void test_getAccessors_empty() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A", []);
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(typeElement);
    JUnitTestCase.assertEquals(0, type.accessors.length);
  }

  void test_getElement() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A", []);
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(typeElement);
    JUnitTestCase.assertEquals(typeElement, type.element);
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
    JUnitTestCase.assertSame(getterG, typeA.getGetter(getterName));
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
    JUnitTestCase.assertNotNull(getter);
    FunctionType getterType = getter.type;
    JUnitTestCase.assertSame(typeI, getterType.returnType);
  }

  void test_getGetter_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    JUnitTestCase.assertNull(typeA.getGetter("g"));
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
    EngineTestCase.assertLength(2, interfaces);
    if (identical(interfaces[0], typeA)) {
      JUnitTestCase.assertSame(typeB, interfaces[1]);
    } else {
      JUnitTestCase.assertSame(typeB, interfaces[0]);
      JUnitTestCase.assertSame(typeA, interfaces[1]);
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
    EngineTestCase.assertLength(1, interfaces);
    InterfaceType result = interfaces[0];
    JUnitTestCase.assertSame(classA, result.element);
    JUnitTestCase.assertSame(typeI, result.typeArguments[0]);
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
    JUnitTestCase.assertEquals(typeB, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeB, typeC.getLeastUpperBound(typeB));
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
    JUnitTestCase.assertEquals(typeB, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeB, typeC.getLeastUpperBound(typeB));
  }

  void test_getLeastUpperBound_functionType() {
    DartType interfaceType = ElementFactory.classElement2("A", []).type;
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(AstFactory.identifier3("f")));
    JUnitTestCase.assertNull(interfaceType.getLeastUpperBound(functionType));
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
    JUnitTestCase.assertEquals(typeA, typeD.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeA, typeC.getLeastUpperBound(typeD));
  }

  void test_getLeastUpperBound_null() {
    DartType interfaceType = ElementFactory.classElement2("A", []).type;
    JUnitTestCase.assertNull(interfaceType.getLeastUpperBound(null));
  }

  void test_getLeastUpperBound_object() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    DartType typeObject = typeA.element.supertype;
    // assert that object does not have a super type
    JUnitTestCase.assertNull((typeObject.element as ClassElement).supertype);
    // assert that both A and B have the same super type of Object
    JUnitTestCase.assertEquals(typeObject, typeB.element.supertype);
    // finally, assert that the only least upper bound of A and B is Object
    JUnitTestCase.assertEquals(typeObject, typeA.getLeastUpperBound(typeB));
  }

  void test_getLeastUpperBound_self() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    JUnitTestCase.assertEquals(typeA, typeA.getLeastUpperBound(typeA));
  }

  void test_getLeastUpperBound_sharedSuperclass1() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeA, typeC.getLeastUpperBound(typeB));
  }

  void test_getLeastUpperBound_sharedSuperclass2() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement("C", classA.type, []);
    ClassElementImpl classD = ElementFactory.classElement("D", classC.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    InterfaceType typeD = classD.type;
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeD));
    JUnitTestCase.assertEquals(typeA, typeD.getLeastUpperBound(typeB));
  }

  void test_getLeastUpperBound_sharedSuperclass3() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type, []);
    ClassElementImpl classD = ElementFactory.classElement("D", classB.type, []);
    InterfaceType typeB = classB.type;
    InterfaceType typeC = classC.type;
    InterfaceType typeD = classD.type;
    JUnitTestCase.assertEquals(typeB, typeC.getLeastUpperBound(typeD));
    JUnitTestCase.assertEquals(typeB, typeD.getLeastUpperBound(typeC));
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
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeA, typeC.getLeastUpperBound(typeB));
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
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeA, typeC.getLeastUpperBound(typeB));
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
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeD));
    JUnitTestCase.assertEquals(typeA, typeD.getLeastUpperBound(typeB));
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
    JUnitTestCase.assertEquals(typeB, typeC.getLeastUpperBound(typeD));
    JUnitTestCase.assertEquals(typeB, typeD.getLeastUpperBound(typeC));
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
    JUnitTestCase.assertEquals(typeA, typeB.getLeastUpperBound(typeC));
    JUnitTestCase.assertEquals(typeA, typeC.getLeastUpperBound(typeB));
  }

  void test_getLeastUpperBound_twoComparables() {
    InterfaceType string = _typeProvider.stringType;
    InterfaceType num = _typeProvider.numType;
    JUnitTestCase.assertEquals(_typeProvider.objectType, string.getLeastUpperBound(num));
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
    JUnitTestCase.assertEquals(_typeProvider.objectType, listOfIntType.getLeastUpperBound(listOfDoubleType));
  }

  void test_getLeastUpperBound_typeParameters_same() {
    //
    // List<int>
    // List<int>
    //
    InterfaceType listType = _typeProvider.listType;
    InterfaceType intType = _typeProvider.intType;
    InterfaceType listOfIntType = listType.substitute4(<DartType> [intType]);
    JUnitTestCase.assertEquals(listOfIntType, listOfIntType.getLeastUpperBound(listOfIntType));
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
    JUnitTestCase.assertSame(methodM, typeA.getMethod(methodName));
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
    JUnitTestCase.assertNotNull(method);
    FunctionType methodType = method.type;
    JUnitTestCase.assertSame(typeI, methodType.returnType);
    List<DartType> parameterTypes = methodType.normalParameterTypes;
    EngineTestCase.assertLength(1, parameterTypes);
    JUnitTestCase.assertSame(typeI, parameterTypes[0]);
  }

  void test_getMethod_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    JUnitTestCase.assertNull(typeA.getMethod("m"));
  }

  void test_getMethods() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A", []);
    MethodElementImpl methodOne = ElementFactory.methodElement("one", null, []);
    MethodElementImpl methodTwo = ElementFactory.methodElement("two", null, []);
    typeElement.methods = <MethodElement> [methodOne, methodTwo];
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(typeElement);
    JUnitTestCase.assertEquals(2, type.methods.length);
  }

  void test_getMethods_empty() {
    ClassElementImpl typeElement = ElementFactory.classElement2("A", []);
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(typeElement);
    JUnitTestCase.assertEquals(0, type.methods.length);
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
    EngineTestCase.assertLength(2, interfaces);
    if (identical(interfaces[0], typeA)) {
      JUnitTestCase.assertSame(typeB, interfaces[1]);
    } else {
      JUnitTestCase.assertSame(typeB, interfaces[0]);
      JUnitTestCase.assertSame(typeA, interfaces[1]);
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
    EngineTestCase.assertLength(1, interfaces);
    InterfaceType result = interfaces[0];
    JUnitTestCase.assertSame(classA, result.element);
    JUnitTestCase.assertSame(typeI, result.typeArguments[0]);
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
    JUnitTestCase.assertSame(setterS, typeA.getSetter(setterName));
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
    JUnitTestCase.assertNotNull(setter);
    FunctionType setterType = setter.type;
    List<DartType> parameterTypes = setterType.normalParameterTypes;
    EngineTestCase.assertLength(1, parameterTypes);
    JUnitTestCase.assertSame(typeI, parameterTypes[0]);
  }

  void test_getSetter_unimplemented() {
    //
    // class A {}
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    JUnitTestCase.assertNull(typeA.getSetter("s"));
  }

  void test_getSuperclass_nonParameterized() {
    //
    // class B extends A
    //
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    ClassElementImpl classB = ElementFactory.classElement("B", typeA, []);
    InterfaceType typeB = classB.type;
    JUnitTestCase.assertSame(typeA, typeB.superclass);
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
    JUnitTestCase.assertSame(classA, superclass.element);
    JUnitTestCase.assertSame(typeI, superclass.typeArguments[0]);
  }

  void test_getTypeArguments_empty() {
    InterfaceType type = ElementFactory.classElement2("A", []).type;
    EngineTestCase.assertLength(0, type.typeArguments);
  }

  void test_hashCode() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    JUnitTestCase.assertFalse(0 == typeA.hashCode);
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
    JUnitTestCase.assertFalse(typeAG.isAssignableTo(typeAF));
  }

  void test_isAssignableTo_void() {
    JUnitTestCase.assertFalse(VoidTypeImpl.instance.isAssignableTo(_typeProvider.intType));
  }

  void test_isDirectSupertypeOf_extends() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    JUnitTestCase.assertTrue(typeA.isDirectSupertypeOf(typeB));
  }

  void test_isDirectSupertypeOf_false() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement2("B", []);
    ClassElement classC = ElementFactory.classElement("C", classB.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    JUnitTestCase.assertFalse(typeA.isDirectSupertypeOf(typeC));
  }

  void test_isDirectSupertypeOf_implements() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    classB.interfaces = <InterfaceType> [typeA];
    JUnitTestCase.assertTrue(typeA.isDirectSupertypeOf(typeB));
  }

  void test_isDirectSupertypeOf_with() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    classB.mixins = <InterfaceType> [typeA];
    JUnitTestCase.assertTrue(typeA.isDirectSupertypeOf(typeB));
  }

  void test_isMoreSpecificThan_bottom() {
    DartType type = ElementFactory.classElement2("A", []).type;
    JUnitTestCase.assertTrue(BottomTypeImpl.instance.isMoreSpecificThan(type));
  }

  void test_isMoreSpecificThan_covariance() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classI = ElementFactory.classElement2("I", []);
    ClassElement classJ = ElementFactory.classElement("J", classI.type, []);
    InterfaceTypeImpl typeAI = new InterfaceTypeImpl.con1(classA);
    InterfaceTypeImpl typeAJ = new InterfaceTypeImpl.con1(classA);
    typeAI.typeArguments = <DartType> [classI.type];
    typeAJ.typeArguments = <DartType> [classJ.type];
    JUnitTestCase.assertTrue(typeAJ.isMoreSpecificThan(typeAI));
    JUnitTestCase.assertFalse(typeAI.isMoreSpecificThan(typeAJ));
  }

  void test_isMoreSpecificThan_directSupertype() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    JUnitTestCase.assertTrue(typeB.isMoreSpecificThan(typeA));
    // the opposite test tests a different branch in isMoreSpecificThan()
    JUnitTestCase.assertFalse(typeA.isMoreSpecificThan(typeB));
  }

  void test_isMoreSpecificThan_dynamic() {
    InterfaceType type = ElementFactory.classElement2("A", []).type;
    JUnitTestCase.assertTrue(type.isMoreSpecificThan(DynamicTypeImpl.instance));
  }

  void test_isMoreSpecificThan_self() {
    InterfaceType type = ElementFactory.classElement2("A", []).type;
    JUnitTestCase.assertTrue(type.isMoreSpecificThan(type));
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
    JUnitTestCase.assertTrue(typeC.isMoreSpecificThan(typeA));
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
    JUnitTestCase.assertTrue(typeC.isMoreSpecificThan(typeA));
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
    JUnitTestCase.assertFalse(typeA.isMoreSpecificThan(typeC));
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
    JUnitTestCase.assertTrue(typeC.isMoreSpecificThan(typeA));
  }

  void test_isSubtypeOf_directSubtype() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    JUnitTestCase.assertTrue(typeB.isSubtypeOf(typeA));
    JUnitTestCase.assertFalse(typeA.isSubtypeOf(typeB));
  }

  void test_isSubtypeOf_dynamic() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    DartType dynamicType = DynamicTypeImpl.instance;
    JUnitTestCase.assertTrue(dynamicType.isSubtypeOf(typeA));
    JUnitTestCase.assertTrue(typeA.isSubtypeOf(dynamicType));
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
    JUnitTestCase.assertTrue(classA.type.isSubtypeOf(functionType));
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
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeB));
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeObject));
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeA));
    JUnitTestCase.assertFalse(typeA.isSubtypeOf(typeC));
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
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeB));
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeObject));
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeA));
    JUnitTestCase.assertFalse(typeA.isSubtypeOf(typeC));
  }

  void test_isSubtypeOf_object() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeObject = classA.supertype;
    JUnitTestCase.assertTrue(typeA.isSubtypeOf(typeObject));
    JUnitTestCase.assertFalse(typeObject.isSubtypeOf(typeA));
  }

  void test_isSubtypeOf_self() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    JUnitTestCase.assertTrue(typeA.isSubtypeOf(typeA));
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
    JUnitTestCase.assertFalse(typeA.isSubtypeOf(typeC));
  }

  void test_isSubtypeOf_transitive_superclass() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElement classC = ElementFactory.classElement("C", classB.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    JUnitTestCase.assertTrue(typeC.isSubtypeOf(typeA));
    JUnitTestCase.assertFalse(typeA.isSubtypeOf(typeC));
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
    JUnitTestCase.assertTrue(typeAJ.isSubtypeOf(typeAI));
    JUnitTestCase.assertFalse(typeAI.isSubtypeOf(typeAJ));
    // A<I> <: A<I> since I <: I
    JUnitTestCase.assertTrue(typeAI.isSubtypeOf(typeAI));
    // A <: A<I> and A <: A<J>
    JUnitTestCase.assertTrue(typeA_dynamic.isSubtypeOf(typeAI));
    JUnitTestCase.assertTrue(typeA_dynamic.isSubtypeOf(typeAJ));
    // A<I> <: A and A<J> <: A
    JUnitTestCase.assertTrue(typeAI.isSubtypeOf(typeA_dynamic));
    JUnitTestCase.assertTrue(typeAJ.isSubtypeOf(typeA_dynamic));
    // A<I> !<: A<K> and A<K> !<: A<I>
    JUnitTestCase.assertFalse(typeAI.isSubtypeOf(typeAK));
    JUnitTestCase.assertFalse(typeAK.isSubtypeOf(typeAI));
  }

  void test_isSupertypeOf_directSupertype() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeB = classB.type;
    JUnitTestCase.assertFalse(typeB.isSupertypeOf(typeA));
    JUnitTestCase.assertTrue(typeA.isSupertypeOf(typeB));
  }

  void test_isSupertypeOf_dynamic() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    DartType dynamicType = DynamicTypeImpl.instance;
    JUnitTestCase.assertTrue(dynamicType.isSupertypeOf(typeA));
    JUnitTestCase.assertTrue(typeA.isSupertypeOf(dynamicType));
  }

  void test_isSupertypeOf_indirectSupertype() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    ClassElement classB = ElementFactory.classElement("B", classA.type, []);
    ClassElement classC = ElementFactory.classElement("C", classB.type, []);
    InterfaceType typeA = classA.type;
    InterfaceType typeC = classC.type;
    JUnitTestCase.assertFalse(typeC.isSupertypeOf(typeA));
    JUnitTestCase.assertTrue(typeA.isSupertypeOf(typeC));
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
    JUnitTestCase.assertTrue(typeB.isSupertypeOf(typeC));
    JUnitTestCase.assertTrue(typeObject.isSupertypeOf(typeC));
    JUnitTestCase.assertTrue(typeA.isSupertypeOf(typeC));
    JUnitTestCase.assertFalse(typeC.isSupertypeOf(typeA));
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
    JUnitTestCase.assertTrue(typeB.isSupertypeOf(typeC));
    JUnitTestCase.assertTrue(typeObject.isSupertypeOf(typeC));
    JUnitTestCase.assertTrue(typeA.isSupertypeOf(typeC));
    JUnitTestCase.assertFalse(typeC.isSupertypeOf(typeA));
  }

  void test_isSupertypeOf_object() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    InterfaceType typeObject = classA.supertype;
    JUnitTestCase.assertFalse(typeA.isSupertypeOf(typeObject));
    JUnitTestCase.assertTrue(typeObject.isSupertypeOf(typeA));
  }

  void test_isSupertypeOf_self() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    JUnitTestCase.assertTrue(typeA.isSupertypeOf(typeA));
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
    JUnitTestCase.assertSame(getterG, typeA.lookUpGetter(getterName, library));
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
    JUnitTestCase.assertSame(getterG, typeB.lookUpGetter(getterName, library));
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
    JUnitTestCase.assertNull(typeA.lookUpGetter("g", library));
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
    JUnitTestCase.assertNull(typeA.lookUpGetter("g", library));
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
    JUnitTestCase.assertSame(methodM, typeA.lookUpMethod(methodName, library));
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
    JUnitTestCase.assertSame(methodM, typeB.lookUpMethod(methodName, library));
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
    JUnitTestCase.assertNotNull(method);
    FunctionType methodType = method.type;
    JUnitTestCase.assertSame(typeI, methodType.returnType);
    List<DartType> parameterTypes = methodType.normalParameterTypes;
    EngineTestCase.assertLength(1, parameterTypes);
    JUnitTestCase.assertSame(typeI, parameterTypes[0]);
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
    JUnitTestCase.assertNull(typeA.lookUpMethod("m", library));
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
    JUnitTestCase.assertNull(typeA.lookUpMethod("m", library));
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
    JUnitTestCase.assertSame(setterS, typeA.lookUpSetter(setterName, library));
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
    JUnitTestCase.assertSame(setterS, typeB.lookUpSetter(setterName, library));
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
    JUnitTestCase.assertNull(typeA.lookUpSetter("s", library));
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
    JUnitTestCase.assertNull(typeA.lookUpSetter("s", library));
  }

  void test_setTypeArguments() {
    InterfaceTypeImpl type = ElementFactory.classElement2("A", []).type as InterfaceTypeImpl;
    List<DartType> typeArguments = <DartType> [
        ElementFactory.classElement2("B", []).type,
        ElementFactory.classElement2("C", []).type];
    type.typeArguments = typeArguments;
    JUnitTestCase.assertEquals(typeArguments, type.typeArguments);
  }

  void test_substitute_equal() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    TypeParameterElementImpl parameterElement = new TypeParameterElementImpl(AstFactory.identifier3("E"));
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(classA);
    TypeParameterTypeImpl parameter = new TypeParameterTypeImpl(parameterElement);
    type.typeArguments = <DartType> [parameter];
    InterfaceType argumentType = ElementFactory.classElement2("B", []).type;
    InterfaceType result = type.substitute2(<DartType> [argumentType], <DartType> [parameter]);
    JUnitTestCase.assertEquals(classA, result.element);
    List<DartType> resultArguments = result.typeArguments;
    EngineTestCase.assertLength(1, resultArguments);
    JUnitTestCase.assertEquals(argumentType, resultArguments[0]);
  }

  void test_substitute_exception() {
    try {
      ClassElementImpl classA = ElementFactory.classElement2("A", []);
      InterfaceTypeImpl type = new InterfaceTypeImpl.con1(classA);
      InterfaceType argumentType = ElementFactory.classElement2("B", []).type;
      type.substitute2(<DartType> [argumentType], <DartType> []);
      JUnitTestCase.fail("Expected to encounter exception, argument and parameter type array lengths not equal.");
    } on JavaException catch (e) {
    }
  }

  void test_substitute_notEqual() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    TypeParameterElementImpl parameterElement = new TypeParameterElementImpl(AstFactory.identifier3("E"));
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(classA);
    TypeParameterTypeImpl parameter = new TypeParameterTypeImpl(parameterElement);
    type.typeArguments = <DartType> [parameter];
    InterfaceType argumentType = ElementFactory.classElement2("B", []).type;
    TypeParameterTypeImpl parameterType = new TypeParameterTypeImpl(new TypeParameterElementImpl(AstFactory.identifier3("F")));
    InterfaceType result = type.substitute2(<DartType> [argumentType], <DartType> [parameterType]);
    JUnitTestCase.assertEquals(classA, result.element);
    List<DartType> resultArguments = result.typeArguments;
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
      _ut.test('test_computeLongestInheritancePathToObject_recursion', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeLongestInheritancePathToObject_recursion);
      });
      _ut.test('test_computeLongestInheritancePathToObject_singleInterfacePath', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeLongestInheritancePathToObject_singleInterfacePath);
      });
      _ut.test('test_computeLongestInheritancePathToObject_singleSuperclassPath', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeLongestInheritancePathToObject_singleSuperclassPath);
      });
      _ut.test('test_computeSuperinterfaceSet_genericInterfacePath', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeSuperinterfaceSet_genericInterfacePath);
      });
      _ut.test('test_computeSuperinterfaceSet_genericSuperclassPath', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeSuperinterfaceSet_genericSuperclassPath);
      });
      _ut.test('test_computeSuperinterfaceSet_multipleInterfacePaths', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeSuperinterfaceSet_multipleInterfacePaths);
      });
      _ut.test('test_computeSuperinterfaceSet_multipleSuperclassPaths', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeSuperinterfaceSet_multipleSuperclassPaths);
      });
      _ut.test('test_computeSuperinterfaceSet_recursion', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_computeSuperinterfaceSet_recursion);
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
      _ut.test('test_getAccessors', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getAccessors);
      });
      _ut.test('test_getAccessors_empty', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getAccessors_empty);
      });
      _ut.test('test_getElement', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getElement);
      });
      _ut.test('test_getGetter_implemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getGetter_implemented);
      });
      _ut.test('test_getGetter_parameterized', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getGetter_parameterized);
      });
      _ut.test('test_getGetter_unimplemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getGetter_unimplemented);
      });
      _ut.test('test_getInterfaces_nonParameterized', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getInterfaces_nonParameterized);
      });
      _ut.test('test_getInterfaces_parameterized', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getInterfaces_parameterized);
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
      _ut.test('test_getLeastUpperBound_twoComparables', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_twoComparables);
      });
      _ut.test('test_getLeastUpperBound_typeParameters_different', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_typeParameters_different);
      });
      _ut.test('test_getLeastUpperBound_typeParameters_same', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getLeastUpperBound_typeParameters_same);
      });
      _ut.test('test_getMethod_implemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getMethod_implemented);
      });
      _ut.test('test_getMethod_parameterized', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getMethod_parameterized);
      });
      _ut.test('test_getMethod_unimplemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getMethod_unimplemented);
      });
      _ut.test('test_getMethods', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getMethods);
      });
      _ut.test('test_getMethods_empty', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getMethods_empty);
      });
      _ut.test('test_getMixins_nonParameterized', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getMixins_nonParameterized);
      });
      _ut.test('test_getMixins_parameterized', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getMixins_parameterized);
      });
      _ut.test('test_getSetter_implemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getSetter_implemented);
      });
      _ut.test('test_getSetter_parameterized', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getSetter_parameterized);
      });
      _ut.test('test_getSetter_unimplemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getSetter_unimplemented);
      });
      _ut.test('test_getSuperclass_nonParameterized', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getSuperclass_nonParameterized);
      });
      _ut.test('test_getSuperclass_parameterized', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getSuperclass_parameterized);
      });
      _ut.test('test_getTypeArguments_empty', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_getTypeArguments_empty);
      });
      _ut.test('test_hashCode', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_hashCode);
      });
      _ut.test('test_isAssignableTo_typeVariables', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isAssignableTo_typeVariables);
      });
      _ut.test('test_isAssignableTo_void', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isAssignableTo_void);
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
      _ut.test('test_isMoreSpecificThan_self', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_self);
      });
      _ut.test('test_isMoreSpecificThan_transitive_interface', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_transitive_interface);
      });
      _ut.test('test_isMoreSpecificThan_transitive_mixin', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_transitive_mixin);
      });
      _ut.test('test_isMoreSpecificThan_transitive_recursive', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_transitive_recursive);
      });
      _ut.test('test_isMoreSpecificThan_transitive_superclass', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_transitive_superclass);
      });
      _ut.test('test_isSubtypeOf_directSubtype', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_directSubtype);
      });
      _ut.test('test_isSubtypeOf_dynamic', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_dynamic);
      });
      _ut.test('test_isSubtypeOf_function', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_function);
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
      _ut.test('test_isSubtypeOf_transitive_recursive', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_transitive_recursive);
      });
      _ut.test('test_isSubtypeOf_transitive_superclass', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_transitive_superclass);
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
      _ut.test('test_lookUpGetter_implemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpGetter_implemented);
      });
      _ut.test('test_lookUpGetter_inherited', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpGetter_inherited);
      });
      _ut.test('test_lookUpGetter_recursive', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpGetter_recursive);
      });
      _ut.test('test_lookUpGetter_unimplemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpGetter_unimplemented);
      });
      _ut.test('test_lookUpMethod_implemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpMethod_implemented);
      });
      _ut.test('test_lookUpMethod_inherited', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpMethod_inherited);
      });
      _ut.test('test_lookUpMethod_parameterized', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpMethod_parameterized);
      });
      _ut.test('test_lookUpMethod_recursive', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpMethod_recursive);
      });
      _ut.test('test_lookUpMethod_unimplemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpMethod_unimplemented);
      });
      _ut.test('test_lookUpSetter_implemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpSetter_implemented);
      });
      _ut.test('test_lookUpSetter_inherited', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpSetter_inherited);
      });
      _ut.test('test_lookUpSetter_recursive', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpSetter_recursive);
      });
      _ut.test('test_lookUpSetter_unimplemented', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_lookUpSetter_unimplemented);
      });
      _ut.test('test_setTypeArguments', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_setTypeArguments);
      });
      _ut.test('test_substitute_equal', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_substitute_equal);
      });
      _ut.test('test_substitute_exception', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_substitute_exception);
      });
      _ut.test('test_substitute_notEqual', () {
        final __test = new InterfaceTypeImplTest();
        runJUnitTest(__test, __test.test_substitute_notEqual);
      });
    });
  }
}

class VoidTypeImplTest extends EngineTestCase {
  /**
   * Reference {code VoidTypeImpl.getInstance()}.
   */
  DartType _voidType = VoidTypeImpl.instance;

  void test_isMoreSpecificThan_void_A() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    JUnitTestCase.assertFalse(_voidType.isMoreSpecificThan(classA.type));
  }

  void test_isMoreSpecificThan_void_dynamic() {
    JUnitTestCase.assertTrue(_voidType.isMoreSpecificThan(DynamicTypeImpl.instance));
  }

  void test_isMoreSpecificThan_void_void() {
    JUnitTestCase.assertTrue(_voidType.isMoreSpecificThan(_voidType));
  }

  void test_isSubtypeOf_void_A() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    JUnitTestCase.assertFalse(_voidType.isSubtypeOf(classA.type));
  }

  void test_isSubtypeOf_void_dynamic() {
    JUnitTestCase.assertTrue(_voidType.isSubtypeOf(DynamicTypeImpl.instance));
  }

  void test_isSubtypeOf_void_void() {
    JUnitTestCase.assertTrue(_voidType.isSubtypeOf(_voidType));
  }

  void test_isVoid() {
    JUnitTestCase.assertTrue(_voidType.isVoid);
  }

  static dartSuite() {
    _ut.group('VoidTypeImplTest', () {
      _ut.test('test_isMoreSpecificThan_void_A', () {
        final __test = new VoidTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_void_A);
      });
      _ut.test('test_isMoreSpecificThan_void_dynamic', () {
        final __test = new VoidTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_void_dynamic);
      });
      _ut.test('test_isMoreSpecificThan_void_void', () {
        final __test = new VoidTypeImplTest();
        runJUnitTest(__test, __test.test_isMoreSpecificThan_void_void);
      });
      _ut.test('test_isSubtypeOf_void_A', () {
        final __test = new VoidTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_void_A);
      });
      _ut.test('test_isSubtypeOf_void_dynamic', () {
        final __test = new VoidTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_void_dynamic);
      });
      _ut.test('test_isSubtypeOf_void_void', () {
        final __test = new VoidTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_void_void);
      });
      _ut.test('test_isVoid', () {
        final __test = new VoidTypeImplTest();
        runJUnitTest(__test, __test.test_isVoid);
      });
    });
  }
}

/**
 * The class `ElementFactory` defines utility methods used to create elements for testing
 * purposes. The elements that are created are complete in the sense that as much of the element
 * model as can be created, given the provided information, has been created.
 */
class ElementFactory {
  /**
   * The element representing the class 'Object'.
   */
  static ClassElementImpl _objectElement;

  static ClassElementImpl classElement(String typeName, InterfaceType superclassType, List<String> parameterNames) {
    ClassElementImpl element = new ClassElementImpl(AstFactory.identifier3(typeName));
    element.supertype = superclassType;
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(element);
    element.type = type;
    int count = parameterNames.length;
    if (count > 0) {
      List<TypeParameterElementImpl> typeParameters = new List<TypeParameterElementImpl>(count);
      List<TypeParameterTypeImpl> typeParameterTypes = new List<TypeParameterTypeImpl>(count);
      for (int i = 0; i < count; i++) {
        TypeParameterElementImpl typeParameter = new TypeParameterElementImpl(AstFactory.identifier3(parameterNames[i]));
        typeParameters[i] = typeParameter;
        typeParameterTypes[i] = new TypeParameterTypeImpl(typeParameter);
        typeParameter.type = typeParameterTypes[i];
      }
      element.typeParameters = typeParameters;
      type.typeArguments = typeParameterTypes;
    }
    return element;
  }

  static ClassElementImpl classElement2(String typeName, List<String> parameterNames) => classElement(typeName, object.type, parameterNames);

  static CompilationUnitElementImpl compilationUnit(String fileName) {
    FileBasedSource source = new FileBasedSource.con1(FileUtilities2.createFile(fileName));
    CompilationUnitElementImpl unit = new CompilationUnitElementImpl(fileName);
    unit.source = source;
    return unit;
  }

  static ConstructorElementImpl constructorElement(ClassElement definingClass, String name, bool isConst, List<DartType> argumentTypes) {
    DartType type = definingClass.type;
    ConstructorElementImpl constructor = new ConstructorElementImpl.con1(name == null ? null : AstFactory.identifier3(name));
    constructor.const2 = isConst;
    int count = argumentTypes.length;
    List<ParameterElement> parameters = new List<ParameterElement>(count);
    for (int i = 0; i < count; i++) {
      ParameterElementImpl parameter = new ParameterElementImpl.con1(AstFactory.identifier3("a${i}"));
      parameter.type = argumentTypes[i];
      parameter.parameterKind = ParameterKind.REQUIRED;
      parameters[i] = parameter;
    }
    constructor.parameters = parameters;
    constructor.returnType = type;
    FunctionTypeImpl constructorType = new FunctionTypeImpl.con1(constructor);
    constructor.type = constructorType;
    return constructor;
  }

  static ConstructorElementImpl constructorElement2(ClassElement definingClass, String name, List<DartType> argumentTypes) => constructorElement(definingClass, name, false, argumentTypes);

  static ExportElementImpl exportFor(LibraryElement exportedLibrary, List<NamespaceCombinator> combinators) {
    ExportElementImpl spec = new ExportElementImpl();
    spec.exportedLibrary = exportedLibrary;
    spec.combinators = combinators;
    return spec;
  }

  static FieldElementImpl fieldElement(String name, bool isStatic, bool isFinal, bool isConst, DartType type) {
    FieldElementImpl field = new FieldElementImpl.con1(AstFactory.identifier3(name));
    field.const3 = isConst;
    field.final2 = isFinal;
    field.static = isStatic;
    field.type = type;
    PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con2(field);
    getter.getter = true;
    getter.static = isStatic;
    getter.synthetic = true;
    getter.variable = field;
    getter.returnType = type;
    field.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
    getter.type = getterType;
    if (!isConst && !isFinal) {
      PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.con2(field);
      setter.setter = true;
      setter.static = isStatic;
      setter.synthetic = true;
      setter.variable = field;
      setter.parameters = <ParameterElement> [requiredParameter2("_${name}", type)];
      setter.returnType = VoidTypeImpl.instance;
      setter.type = new FunctionTypeImpl.con1(setter);
      field.setter = setter;
    }
    return field;
  }

  static FieldFormalParameterElementImpl fieldFormalParameter(Identifier name) => new FieldFormalParameterElementImpl(name);

  static FunctionElementImpl functionElement(String functionName) => functionElement4(functionName, null, null, null, null);

  static FunctionElementImpl functionElement2(String functionName, ClassElement returnElement) => functionElement3(functionName, returnElement, null, null);

  static FunctionElementImpl functionElement3(String functionName, ClassElement returnElement, List<ClassElement> normalParameters, List<ClassElement> optionalParameters) {
    // We don't create parameter elements because we don't have parameter names
    FunctionElementImpl functionElement = new FunctionElementImpl.con1(AstFactory.identifier3(functionName));
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    functionElement.type = functionType;
    // return type
    if (returnElement == null) {
      functionElement.returnType = VoidTypeImpl.instance;
    } else {
      functionElement.returnType = returnElement.type;
    }
    // parameters
    int normalCount = normalParameters == null ? 0 : normalParameters.length;
    int optionalCount = optionalParameters == null ? 0 : optionalParameters.length;
    int totalCount = normalCount + optionalCount;
    List<ParameterElement> parameters = new List<ParameterElement>(totalCount);
    for (int i = 0; i < totalCount; i++) {
      ParameterElementImpl parameter = new ParameterElementImpl.con1(AstFactory.identifier3("a${i}"));
      if (i < normalCount) {
        parameter.type = normalParameters[i].type;
        parameter.parameterKind = ParameterKind.REQUIRED;
      } else {
        parameter.type = optionalParameters[i - normalCount].type;
        parameter.parameterKind = ParameterKind.POSITIONAL;
      }
      parameters[i] = parameter;
    }
    functionElement.parameters = parameters;
    // done
    return functionElement;
  }

  static FunctionElementImpl functionElement4(String functionName, ClassElement returnElement, List<ClassElement> normalParameters, List<String> names, List<ClassElement> namedParameters) {
    FunctionElementImpl functionElement = new FunctionElementImpl.con1(AstFactory.identifier3(functionName));
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    functionElement.type = functionType;
    // parameters
    int normalCount = normalParameters == null ? 0 : normalParameters.length;
    int nameCount = names == null ? 0 : names.length;
    int typeCount = namedParameters == null ? 0 : namedParameters.length;
    if (names != null && nameCount != typeCount) {
      throw new IllegalStateException("The passed String[] and ClassElement[] arrays had different lengths.");
    }
    int totalCount = normalCount + nameCount;
    List<ParameterElement> parameters = new List<ParameterElement>(totalCount);
    for (int i = 0; i < totalCount; i++) {
      if (i < normalCount) {
        ParameterElementImpl parameter = new ParameterElementImpl.con1(AstFactory.identifier3("a${i}"));
        parameter.type = normalParameters[i].type;
        parameter.parameterKind = ParameterKind.REQUIRED;
        parameters[i] = parameter;
      } else {
        ParameterElementImpl parameter = new ParameterElementImpl.con1(AstFactory.identifier3(names[i - normalCount]));
        parameter.type = namedParameters[i - normalCount].type;
        parameter.parameterKind = ParameterKind.NAMED;
        parameters[i] = parameter;
      }
    }
    functionElement.parameters = parameters;
    // return type
    if (returnElement == null) {
      functionElement.returnType = VoidTypeImpl.instance;
    } else {
      functionElement.returnType = returnElement.type;
    }
    return functionElement;
  }

  static FunctionElementImpl functionElement5(String functionName, List<ClassElement> normalParameters) => functionElement3(functionName, null, normalParameters, null);

  static FunctionElementImpl functionElement6(String functionName, List<ClassElement> normalParameters, List<ClassElement> optionalParameters) => functionElement3(functionName, null, normalParameters, optionalParameters);

  static FunctionElementImpl functionElement7(String functionName, List<ClassElement> normalParameters, List<String> names, List<ClassElement> namedParameters) => functionElement4(functionName, null, normalParameters, names, namedParameters);

  static ClassElementImpl get object {
    if (_objectElement == null) {
      _objectElement = classElement("Object", null, []);
    }
    return _objectElement;
  }

  static PropertyAccessorElementImpl getterElement(String name, bool isStatic, DartType type) {
    FieldElementImpl field = new FieldElementImpl.con1(AstFactory.identifier3(name));
    field.static = isStatic;
    field.synthetic = true;
    field.type = type;
    PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con2(field);
    getter.getter = true;
    getter.static = isStatic;
    getter.variable = field;
    getter.returnType = type;
    field.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
    getter.type = getterType;
    return getter;
  }

  static HtmlElementImpl htmlUnit(AnalysisContext context, String fileName) {
    FileBasedSource source = new FileBasedSource.con1(FileUtilities2.createFile(fileName));
    HtmlElementImpl unit = new HtmlElementImpl(context, fileName);
    unit.source = source;
    return unit;
  }

  static ImportElementImpl importFor(LibraryElement importedLibrary, PrefixElement prefix, List<NamespaceCombinator> combinators) {
    ImportElementImpl spec = new ImportElementImpl(0);
    spec.importedLibrary = importedLibrary;
    spec.prefix = prefix;
    spec.combinators = combinators;
    return spec;
  }

  static LibraryElementImpl library(AnalysisContext context, String libraryName) {
    String fileName = "/${libraryName}.dart";
    CompilationUnitElementImpl unit = compilationUnit(fileName);
    LibraryElementImpl library = new LibraryElementImpl(context, AstFactory.libraryIdentifier2([libraryName]));
    library.definingCompilationUnit = unit;
    return library;
  }

  static LocalVariableElementImpl localVariableElement(Identifier name) => new LocalVariableElementImpl(name);

  static LocalVariableElementImpl localVariableElement2(String name) => new LocalVariableElementImpl(AstFactory.identifier3(name));

  static MethodElementImpl methodElement(String methodName, DartType returnType, List<DartType> argumentTypes) {
    MethodElementImpl method = new MethodElementImpl.con1(AstFactory.identifier3(methodName));
    int count = argumentTypes.length;
    List<ParameterElement> parameters = new List<ParameterElement>(count);
    for (int i = 0; i < count; i++) {
      ParameterElementImpl parameter = new ParameterElementImpl.con1(AstFactory.identifier3("a${i}"));
      parameter.type = argumentTypes[i];
      parameter.parameterKind = ParameterKind.REQUIRED;
      parameters[i] = parameter;
    }
    method.parameters = parameters;
    method.returnType = returnType;
    FunctionTypeImpl methodType = new FunctionTypeImpl.con1(method);
    method.type = methodType;
    return method;
  }

  static ParameterElementImpl namedParameter(String name) {
    ParameterElementImpl parameter = new ParameterElementImpl.con1(AstFactory.identifier3(name));
    parameter.parameterKind = ParameterKind.NAMED;
    return parameter;
  }

  static ParameterElementImpl namedParameter2(String name, DartType type) {
    ParameterElementImpl parameter = new ParameterElementImpl.con1(AstFactory.identifier3(name));
    parameter.parameterKind = ParameterKind.NAMED;
    parameter.type = type;
    return parameter;
  }

  static ParameterElementImpl positionalParameter(String name) {
    ParameterElementImpl parameter = new ParameterElementImpl.con1(AstFactory.identifier3(name));
    parameter.parameterKind = ParameterKind.POSITIONAL;
    return parameter;
  }

  static ParameterElementImpl positionalParameter2(String name, DartType type) {
    ParameterElementImpl parameter = new ParameterElementImpl.con1(AstFactory.identifier3(name));
    parameter.parameterKind = ParameterKind.POSITIONAL;
    parameter.type = type;
    return parameter;
  }

  static PrefixElementImpl prefix(String name) => new PrefixElementImpl(AstFactory.identifier3(name));

  static ParameterElementImpl requiredParameter(String name) {
    ParameterElementImpl parameter = new ParameterElementImpl.con1(AstFactory.identifier3(name));
    parameter.parameterKind = ParameterKind.REQUIRED;
    return parameter;
  }

  static ParameterElementImpl requiredParameter2(String name, DartType type) {
    ParameterElementImpl parameter = new ParameterElementImpl.con1(AstFactory.identifier3(name));
    parameter.parameterKind = ParameterKind.REQUIRED;
    parameter.type = type;
    return parameter;
  }

  static PropertyAccessorElementImpl setterElement(String name, bool isStatic, DartType type) {
    FieldElementImpl field = new FieldElementImpl.con1(AstFactory.identifier3(name));
    field.static = isStatic;
    field.synthetic = true;
    field.type = type;
    PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con2(field);
    getter.getter = true;
    getter.static = isStatic;
    getter.variable = field;
    getter.returnType = type;
    field.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
    getter.type = getterType;
    ParameterElementImpl parameter = requiredParameter2("a", type);
    PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.con2(field);
    setter.setter = true;
    setter.static = isStatic;
    setter.synthetic = true;
    setter.variable = field;
    setter.parameters = <ParameterElement> [parameter];
    setter.returnType = VoidTypeImpl.instance;
    setter.type = new FunctionTypeImpl.con1(setter);
    field.setter = setter;
    return setter;
  }

  static TopLevelVariableElementImpl topLevelVariableElement(Identifier name) => new TopLevelVariableElementImpl.con1(name);

  static TopLevelVariableElementImpl topLevelVariableElement2(String name) => new TopLevelVariableElementImpl.con2(name);

  static TopLevelVariableElementImpl topLevelVariableElement3(String name, bool isConst, bool isFinal, DartType type) {
    TopLevelVariableElementImpl variable = new TopLevelVariableElementImpl.con2(name);
    variable.const3 = isConst;
    variable.final2 = isFinal;
    PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con2(variable);
    getter.getter = true;
    getter.static = true;
    getter.synthetic = true;
    getter.variable = variable;
    getter.returnType = type;
    variable.getter = getter;
    FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
    getter.type = getterType;
    if (!isFinal) {
      PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.con2(variable);
      setter.setter = true;
      setter.static = true;
      setter.synthetic = true;
      setter.variable = variable;
      setter.parameters = <ParameterElement> [requiredParameter2("_${name}", type)];
      setter.returnType = VoidTypeImpl.instance;
      setter.type = new FunctionTypeImpl.con1(setter);
      variable.setter = setter;
    }
    return variable;
  }
}

class ElementKindTest extends EngineTestCase {
  void test_of_nonNull() {
    JUnitTestCase.assertSame(ElementKind.CLASS, ElementKind.of(ElementFactory.classElement2("A", [])));
  }

  void test_of_null() {
    JUnitTestCase.assertSame(ElementKind.ERROR, ElementKind.of(null));
  }

  static dartSuite() {
    _ut.group('ElementKindTest', () {
      _ut.test('test_of_nonNull', () {
        final __test = new ElementKindTest();
        runJUnitTest(__test, __test.test_of_nonNull);
      });
      _ut.test('test_of_null', () {
        final __test = new ElementKindTest();
        runJUnitTest(__test, __test.test_of_null);
      });
    });
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
    JUnitTestCase.assertTrue(types.contains(typeA));
    JUnitTestCase.assertTrue(types.contains(typeB));
    JUnitTestCase.assertTrue(types.contains(typeObject));
    JUnitTestCase.assertFalse(types.contains(typeC));
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
    JUnitTestCase.assertFalse(types.contains(typeA));
    JUnitTestCase.assertTrue(types.contains(typeB));
    JUnitTestCase.assertTrue(types.contains(typeObject));
    JUnitTestCase.assertFalse(types.contains(typeC));
  }

  void test_getAllSupertypes_recursive() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    List<InterfaceType> supers = classB.allSupertypes;
    EngineTestCase.assertLength(1, supers);
  }

  void test_getField() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String fieldName = "f";
    FieldElementImpl field = ElementFactory.fieldElement(fieldName, false, false, false, null);
    classA.fields = <FieldElement> [field];
    JUnitTestCase.assertSame(field, classA.getField(fieldName));
    // no such field
    JUnitTestCase.assertSame(null, classA.getField("noSuchField"));
  }

  void test_getMethod_declared() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    JUnitTestCase.assertSame(method, classA.getMethod(methodName));
  }

  void test_getMethod_undeclared() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    JUnitTestCase.assertNull(classA.getMethod("${methodName}x"));
  }

  void test_getNode() {
    AnalysisContextHelper contextHelper = new AnalysisContextHelper();
    AnalysisContext context = contextHelper.context;
    Source source = contextHelper.addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B {}"]));
    // prepare CompilationUnitElement
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
    // A
    {
      ClassElement elementA = unitElement.getType("A");
      ClassDeclaration nodeA = elementA.node;
      JUnitTestCase.assertNotNull(nodeA);
      JUnitTestCase.assertEquals("A", nodeA.name.name);
      JUnitTestCase.assertSame(elementA, nodeA.element);
    }
    // B
    {
      ClassElement elementB = unitElement.getType("B");
      ClassDeclaration nodeB = elementB.node;
      JUnitTestCase.assertNotNull(nodeB);
      JUnitTestCase.assertEquals("B", nodeB.name.name);
      JUnitTestCase.assertSame(elementB, nodeB.element);
    }
  }

  void test_hasNonFinalField_false_const() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.fields = <FieldElement> [ElementFactory.fieldElement("f", false, false, true, classA.type)];
    JUnitTestCase.assertFalse(classA.hasNonFinalField);
  }

  void test_hasNonFinalField_false_final() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.fields = <FieldElement> [ElementFactory.fieldElement("f", false, true, false, classA.type)];
    JUnitTestCase.assertFalse(classA.hasNonFinalField);
  }

  void test_hasNonFinalField_false_recursive() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    JUnitTestCase.assertFalse(classA.hasNonFinalField);
  }

  void test_hasNonFinalField_true_immediate() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.fields = <FieldElement> [ElementFactory.fieldElement("f", false, false, false, classA.type)];
    JUnitTestCase.assertTrue(classA.hasNonFinalField);
  }

  void test_hasNonFinalField_true_inherited() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.fields = <FieldElement> [ElementFactory.fieldElement("f", false, false, false, classA.type)];
    JUnitTestCase.assertTrue(classB.hasNonFinalField);
  }

  void test_hasStaticMember_false_empty() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    // no members
    JUnitTestCase.assertFalse(classA.hasStaticMember);
  }

  void test_hasStaticMember_false_instanceMethod() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    MethodElement method = ElementFactory.methodElement("foo", null, []);
    classA.methods = <MethodElement> [method];
    JUnitTestCase.assertFalse(classA.hasStaticMember);
  }

  void test_hasStaticMember_instanceGetter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    PropertyAccessorElement getter = ElementFactory.getterElement("foo", false, null);
    classA.accessors = <PropertyAccessorElement> [getter];
    JUnitTestCase.assertFalse(classA.hasStaticMember);
  }

  void test_hasStaticMember_true_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    PropertyAccessorElementImpl getter = ElementFactory.getterElement("foo", false, null);
    classA.accessors = <PropertyAccessorElement> [getter];
    // "foo" is static
    getter.static = true;
    JUnitTestCase.assertTrue(classA.hasStaticMember);
  }

  void test_hasStaticMember_true_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    MethodElementImpl method = ElementFactory.methodElement("foo", null, []);
    classA.methods = <MethodElement> [method];
    // "foo" is static
    method.static = true;
    JUnitTestCase.assertTrue(classA.hasStaticMember);
  }

  void test_hasStaticMember_true_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    PropertyAccessorElementImpl setter = ElementFactory.setterElement("foo", false, null);
    classA.accessors = <PropertyAccessorElement> [setter];
    // "foo" is static
    setter.static = true;
    JUnitTestCase.assertTrue(classA.hasStaticMember);
  }

  void test_lookUpGetter_declared() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getter = ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement> [getter];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    JUnitTestCase.assertSame(getter, classA.lookUpGetter(getterName, library));
  }

  void test_lookUpGetter_inherited() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getter = ElementFactory.getterElement(getterName, false, null);
    classA.accessors = <PropertyAccessorElement> [getter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    JUnitTestCase.assertSame(getter, classB.lookUpGetter(getterName, library));
  }

  void test_lookUpGetter_undeclared() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    JUnitTestCase.assertNull(classA.lookUpGetter("g", library));
  }

  void test_lookUpGetter_undeclared_recursive() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    JUnitTestCase.assertNull(classA.lookUpGetter("g", library));
  }

  void test_lookUpMethod_declared() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    JUnitTestCase.assertSame(method, classA.lookUpMethod(methodName, library));
  }

  void test_lookUpMethod_inherited() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement method = ElementFactory.methodElement(methodName, null, []);
    classA.methods = <MethodElement> [method];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    JUnitTestCase.assertSame(method, classB.lookUpMethod(methodName, library));
  }

  void test_lookUpMethod_undeclared() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    JUnitTestCase.assertNull(classA.lookUpMethod("m", library));
  }

  void test_lookUpMethod_undeclared_recursive() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    JUnitTestCase.assertNull(classA.lookUpMethod("m", library));
  }

  void test_lookUpSetter_declared() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setter = ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement> [setter];
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    JUnitTestCase.assertSame(setter, classA.lookUpSetter(setterName, library));
  }

  void test_lookUpSetter_inherited() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setter = ElementFactory.setterElement(setterName, false, null);
    classA.accessors = <PropertyAccessorElement> [setter];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    JUnitTestCase.assertSame(setter, classB.lookUpSetter(setterName, library));
  }

  void test_lookUpSetter_undeclared() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA];
    JUnitTestCase.assertNull(classA.lookUpSetter("s", library));
  }

  void test_lookUpSetter_undeclared_recursive() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    classA.supertype = classB.type;
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classA, classB];
    JUnitTestCase.assertNull(classA.lookUpSetter("s", library));
  }

  static dartSuite() {
    _ut.group('ClassElementImplTest', () {
      _ut.test('test_getAllSupertypes_interface', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_getAllSupertypes_interface);
      });
      _ut.test('test_getAllSupertypes_mixins', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_getAllSupertypes_mixins);
      });
      _ut.test('test_getAllSupertypes_recursive', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_getAllSupertypes_recursive);
      });
      _ut.test('test_getField', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_getField);
      });
      _ut.test('test_getMethod_declared', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_getMethod_declared);
      });
      _ut.test('test_getMethod_undeclared', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_getMethod_undeclared);
      });
      _ut.test('test_getNode', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_getNode);
      });
      _ut.test('test_hasNonFinalField_false_const', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_hasNonFinalField_false_const);
      });
      _ut.test('test_hasNonFinalField_false_final', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_hasNonFinalField_false_final);
      });
      _ut.test('test_hasNonFinalField_false_recursive', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_hasNonFinalField_false_recursive);
      });
      _ut.test('test_hasNonFinalField_true_immediate', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_hasNonFinalField_true_immediate);
      });
      _ut.test('test_hasNonFinalField_true_inherited', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_hasNonFinalField_true_inherited);
      });
      _ut.test('test_hasStaticMember_false_empty', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_hasStaticMember_false_empty);
      });
      _ut.test('test_hasStaticMember_false_instanceMethod', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_hasStaticMember_false_instanceMethod);
      });
      _ut.test('test_hasStaticMember_instanceGetter', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_hasStaticMember_instanceGetter);
      });
      _ut.test('test_hasStaticMember_true_getter', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_hasStaticMember_true_getter);
      });
      _ut.test('test_hasStaticMember_true_method', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_hasStaticMember_true_method);
      });
      _ut.test('test_hasStaticMember_true_setter', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_hasStaticMember_true_setter);
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
      _ut.test('test_lookUpGetter_undeclared_recursive', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpGetter_undeclared_recursive);
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
      _ut.test('test_lookUpMethod_undeclared_recursive', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpMethod_undeclared_recursive);
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
      _ut.test('test_lookUpSetter_undeclared_recursive', () {
        final __test = new ClassElementImplTest();
        runJUnitTest(__test, __test.test_lookUpSetter_undeclared_recursive);
      });
    });
  }
}

class AngularPropertyKindTest extends EngineTestCase {
  void test_ATTR() {
    AngularPropertyKind kind = AngularPropertyKind.ATTR;
    JUnitTestCase.assertFalse(kind.callsGetter());
    JUnitTestCase.assertTrue(kind.callsSetter());
  }

  void test_CALLBACK() {
    AngularPropertyKind kind = AngularPropertyKind.CALLBACK;
    JUnitTestCase.assertFalse(kind.callsGetter());
    JUnitTestCase.assertTrue(kind.callsSetter());
  }

  void test_ONE_WAY() {
    AngularPropertyKind kind = AngularPropertyKind.ONE_WAY;
    JUnitTestCase.assertFalse(kind.callsGetter());
    JUnitTestCase.assertTrue(kind.callsSetter());
  }

  void test_ONE_WAY_ONE_TIME() {
    AngularPropertyKind kind = AngularPropertyKind.ONE_WAY_ONE_TIME;
    JUnitTestCase.assertFalse(kind.callsGetter());
    JUnitTestCase.assertTrue(kind.callsSetter());
  }

  void test_TWO_WAY() {
    AngularPropertyKind kind = AngularPropertyKind.TWO_WAY;
    JUnitTestCase.assertTrue(kind.callsGetter());
    JUnitTestCase.assertTrue(kind.callsSetter());
  }

  static dartSuite() {
    _ut.group('AngularPropertyKindTest', () {
      _ut.test('test_ATTR', () {
        final __test = new AngularPropertyKindTest();
        runJUnitTest(__test, __test.test_ATTR);
      });
      _ut.test('test_CALLBACK', () {
        final __test = new AngularPropertyKindTest();
        runJUnitTest(__test, __test.test_CALLBACK);
      });
      _ut.test('test_ONE_WAY', () {
        final __test = new AngularPropertyKindTest();
        runJUnitTest(__test, __test.test_ONE_WAY);
      });
      _ut.test('test_ONE_WAY_ONE_TIME', () {
        final __test = new AngularPropertyKindTest();
        runJUnitTest(__test, __test.test_ONE_WAY_ONE_TIME);
      });
      _ut.test('test_TWO_WAY', () {
        final __test = new AngularPropertyKindTest();
        runJUnitTest(__test, __test.test_TWO_WAY);
      });
    });
  }
}

class ElementImplTest extends EngineTestCase {
  void test_equals() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElementImpl classElement = ElementFactory.classElement2("C", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classElement];
    FieldElement field = ElementFactory.fieldElement("next", false, false, false, classElement.type);
    classElement.fields = <FieldElement> [field];
    JUnitTestCase.assertTrue(field == field);
    JUnitTestCase.assertFalse(field == field.getter);
    JUnitTestCase.assertFalse(field == field.setter);
    JUnitTestCase.assertFalse(field.getter == field.setter);
  }

  void test_isAccessibleIn_private_differentLibrary() {
    AnalysisContextImpl context = createAnalysisContext();
    LibraryElementImpl library1 = ElementFactory.library(context, "lib1");
    ClassElement classElement = ElementFactory.classElement2("_C", []);
    (library1.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classElement];
    LibraryElementImpl library2 = ElementFactory.library(context, "lib2");
    JUnitTestCase.assertFalse(classElement.isAccessibleIn(library2));
  }

  void test_isAccessibleIn_private_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElement classElement = ElementFactory.classElement2("_C", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classElement];
    JUnitTestCase.assertTrue(classElement.isAccessibleIn(library));
  }

  void test_isAccessibleIn_public_differentLibrary() {
    AnalysisContextImpl context = createAnalysisContext();
    LibraryElementImpl library1 = ElementFactory.library(context, "lib1");
    ClassElement classElement = ElementFactory.classElement2("C", []);
    (library1.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classElement];
    LibraryElementImpl library2 = ElementFactory.library(context, "lib2");
    JUnitTestCase.assertTrue(classElement.isAccessibleIn(library2));
  }

  void test_isAccessibleIn_public_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(createAnalysisContext(), "lib");
    ClassElement classElement = ElementFactory.classElement2("C", []);
    (library.definingCompilationUnit as CompilationUnitElementImpl).types = <ClassElement> [classElement];
    JUnitTestCase.assertTrue(classElement.isAccessibleIn(library));
  }

  void test_isPrivate_false() {
    Element element = ElementFactory.classElement2("C", []);
    JUnitTestCase.assertFalse(element.isPrivate);
  }

  void test_isPrivate_null() {
    Element element = ElementFactory.classElement2(null, []);
    JUnitTestCase.assertTrue(element.isPrivate);
  }

  void test_isPrivate_true() {
    Element element = ElementFactory.classElement2("_C", []);
    JUnitTestCase.assertTrue(element.isPrivate);
  }

  void test_isPublic_false() {
    Element element = ElementFactory.classElement2("_C", []);
    JUnitTestCase.assertFalse(element.isPublic);
  }

  void test_isPublic_null() {
    Element element = ElementFactory.classElement2(null, []);
    JUnitTestCase.assertFalse(element.isPublic);
  }

  void test_isPublic_true() {
    Element element = ElementFactory.classElement2("C", []);
    JUnitTestCase.assertTrue(element.isPublic);
  }

  void test_SORT_BY_OFFSET() {
    ClassElementImpl classElementA = ElementFactory.classElement2("A", []);
    classElementA.nameOffset = 1;
    ClassElementImpl classElementB = ElementFactory.classElement2("B", []);
    classElementB.nameOffset = 2;
    JUnitTestCase.assertEquals(0, Element.SORT_BY_OFFSET(classElementA, classElementA));
    JUnitTestCase.assertTrue(Element.SORT_BY_OFFSET(classElementA, classElementB) < 0);
    JUnitTestCase.assertTrue(Element.SORT_BY_OFFSET(classElementB, classElementA) > 0);
  }

  static dartSuite() {
    _ut.group('ElementImplTest', () {
      _ut.test('test_SORT_BY_OFFSET', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_SORT_BY_OFFSET);
      });
      _ut.test('test_equals', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_equals);
      });
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
      _ut.test('test_isPrivate_false', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_isPrivate_false);
      });
      _ut.test('test_isPrivate_null', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_isPrivate_null);
      });
      _ut.test('test_isPrivate_true', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_isPrivate_true);
      });
      _ut.test('test_isPublic_false', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_isPublic_false);
      });
      _ut.test('test_isPublic_null', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_isPublic_null);
      });
      _ut.test('test_isPublic_true', () {
        final __test = new ElementImplTest();
        runJUnitTest(__test, __test.test_isPublic_true);
      });
    });
  }
}

class FunctionTypeImplTest extends EngineTestCase {
  void test_creation() {
    JUnitTestCase.assertNotNull(new FunctionTypeImpl.con1(new FunctionElementImpl.con1(AstFactory.identifier3("f"))));
  }

  void test_getElement() {
    FunctionElementImpl typeElement = new FunctionElementImpl.con1(AstFactory.identifier3("f"));
    FunctionTypeImpl type = new FunctionTypeImpl.con1(typeElement);
    JUnitTestCase.assertEquals(typeElement, type.element);
  }

  void test_getNamedParameterTypes() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(AstFactory.identifier3("f")));
    Map<String, DartType> types = type.namedParameterTypes;
    EngineTestCase.assertSizeOfMap(0, types);
  }

  void test_getNormalParameterTypes() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(AstFactory.identifier3("f")));
    List<DartType> types = type.normalParameterTypes;
    EngineTestCase.assertLength(0, types);
  }

  void test_getReturnType() {
    DartType expectedReturnType = VoidTypeImpl.instance;
    FunctionElementImpl functionElement = new FunctionElementImpl.con1(AstFactory.identifier3("f"));
    functionElement.returnType = expectedReturnType;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(functionElement);
    DartType returnType = type.returnType;
    JUnitTestCase.assertEquals(expectedReturnType, returnType);
  }

  void test_getTypeArguments() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(AstFactory.identifier3("f")));
    List<DartType> types = type.typeArguments;
    EngineTestCase.assertLength(0, types);
  }

  void test_hashCode_element() {
    FunctionTypeImpl type = new FunctionTypeImpl.con1(new FunctionElementImpl.con1(AstFactory.identifier3("f")));
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
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
    // assignable iff subtype
    JUnitTestCase.assertTrue(t.isAssignableTo(s));
    JUnitTestCase.assertFalse(s.isAssignableTo(t));
  }

  void test_isSubtypeOf_baseCase_classFunction() {
    // () -> void <: Function
    ClassElementImpl functionElement = ElementFactory.classElement2("Function", []);
    InterfaceTypeImpl functionType = new InterfaceTypeImpl_FunctionTypeImplTest_test_isSubtypeOf_baseCase_classFunction(functionElement);
    FunctionType f = ElementFactory.functionElement("f").type;
    JUnitTestCase.assertTrue(f.isSubtypeOf(functionType));
  }

  void test_isSubtypeOf_baseCase_notFunctionType() {
    // class C
    // ! () -> void <: C
    FunctionType f = ElementFactory.functionElement("f").type;
    InterfaceType t = ElementFactory.classElement2("C", []).type;
    JUnitTestCase.assertFalse(f.isSubtypeOf(t));
  }

  void test_isSubtypeOf_baseCase_null() {
    // ! () -> void <: null
    FunctionType f = ElementFactory.functionElement("f").type;
    JUnitTestCase.assertFalse(f.isSubtypeOf(null));
  }

  void test_isSubtypeOf_baseCase_self() {
    // () -> void <: () -> void
    FunctionType f = ElementFactory.functionElement("f").type;
    JUnitTestCase.assertTrue(f.isSubtypeOf(f));
  }

  void test_isSubtypeOf_namedParameters_isAssignable() {
    // B extends A
    // ({name: A}) -> void <: ({name: B}) -> void
    // ({name: B}) -> void <: ({name: A}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name"], <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name"], <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertTrue(s.isSubtypeOf(t));
  }

  void test_isSubtypeOf_namedParameters_isNotAssignable() {
    // ! ({name: A}) -> void <: ({name: B}) -> void
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name"], <ClassElement> [ElementFactory.classElement2("A", [])]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name"], <ClassElement> [ElementFactory.classElement2("B", [])]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
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
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
  }

  void test_isSubtypeOf_namedParameters_orderOfParams() {
    // B extends A
    // ({A: A, B: B}) -> void <: ({B: B, A: A}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["A", "B"], <ClassElement> [a, b]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["B", "A"], <ClassElement> [b, a]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_namedParameters_orderOfParams2() {
    // B extends A
    // ! ({B: B}) -> void <: ({B: B, A: A}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["B"], <ClassElement> [b]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["B", "A"], <ClassElement> [b, a]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_namedParameters_orderOfParams3() {
    // B extends A
    // ({A: A, B: B}) -> void <: ({A: A}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["A", "B"], <ClassElement> [a, b]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["B"], <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_namedParameters_sHasMoreParams() {
    // B extends A
    // ! ({name: A}) -> void <: ({name: B, name2: B}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name"], <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name", "name2"], <ClassElement> [b, b]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_namedParameters_tHasMoreParams() {
    // B extends A
    // ({name: A, name2: A}) -> void <: ({name: B}) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement4("t", null, null, <String> ["name", "name2"], <ClassElement> [a, a]).type;
    FunctionType s = ElementFactory.functionElement4("s", null, null, <String> ["name"], <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_normalAndPositionalArgs_1() {
    // ([a]) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [a]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
  }

  void test_isSubtypeOf_normalAndPositionalArgs_2() {
    // (a, [a]) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", <ClassElement> [a], <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [a]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
  }

  void test_isSubtypeOf_normalAndPositionalArgs_3() {
    // ([a]) -> void <: () -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement("s").type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
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
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
  }

  void test_isSubtypeOf_normalParameters_isAssignable() {
    // B extends A
    // (a) -> void <: (b) -> void
    // (b) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertTrue(s.isSubtypeOf(t));
  }

  void test_isSubtypeOf_normalParameters_isNotAssignable() {
    // ! (a) -> void <: (b) -> void
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [ElementFactory.classElement2("A", [])]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [ElementFactory.classElement2("B", [])]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_normalParameters_sHasMoreParams() {
    // B extends A
    // ! (a) -> void <: (b, b) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement5("s", <ClassElement> [b, b]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
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
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_Object() {
    // () -> void <: Object
    FunctionType f = ElementFactory.functionElement("f").type;
    InterfaceType t = ElementFactory.object.type;
    JUnitTestCase.assertTrue(f.isSubtypeOf(t));
  }

  void test_isSubtypeOf_positionalParameters_isAssignable() {
    // B extends A
    // ([a]) -> void <: ([b]) -> void
    // ([b]) -> void <: ([a]) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertTrue(s.isSubtypeOf(t));
  }

  void test_isSubtypeOf_positionalParameters_isNotAssignable() {
    // ! ([a]) -> void <: ([b]) -> void
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [ElementFactory.classElement2("A", [])]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [ElementFactory.classElement2("B", [])]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_positionalParameters_sHasMoreParams() {
    // B extends A
    // ! ([a]) -> void <: ([b, b]) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [b, b]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_positionalParameters_tHasMoreParams() {
    // B extends A
    // ([a, a]) -> void <: ([b]) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a, a]).type;
    FunctionType s = ElementFactory.functionElement6("s", null, <ClassElement> [b]).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_returnType_sIsVoid() {
    // () -> void <: void
    FunctionType t = ElementFactory.functionElement("t").type;
    FunctionType s = ElementFactory.functionElement("s").type;
    // function s has the implicit return type of void, we assert it here
    JUnitTestCase.assertTrue(VoidTypeImpl.instance == s.returnType);
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_returnType_tAssignableToS() {
    // B extends A
    // () -> A <: () -> B
    // () -> B <: () -> A
    ClassElement a = ElementFactory.classElement2("A", []);
    ClassElement b = ElementFactory.classElement("B", a.type, []);
    FunctionType t = ElementFactory.functionElement2("t", a).type;
    FunctionType s = ElementFactory.functionElement2("s", b).type;
    JUnitTestCase.assertTrue(t.isSubtypeOf(s));
    JUnitTestCase.assertTrue(s.isSubtypeOf(t));
  }

  void test_isSubtypeOf_returnType_tNotAssignableToS() {
    // ! () -> A <: () -> B
    FunctionType t = ElementFactory.functionElement2("t", ElementFactory.classElement2("A", [])).type;
    FunctionType s = ElementFactory.functionElement2("s", ElementFactory.classElement2("B", [])).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
  }

  void test_isSubtypeOf_typeParameters_matchesBounds() {
    TestTypeProvider provider = new TestTypeProvider();
    InterfaceType boolType = provider.boolType;
    InterfaceType stringType = provider.stringType;
    TypeParameterElementImpl parameterB = new TypeParameterElementImpl(AstFactory.identifier3("B"));
    parameterB.bound = boolType;
    TypeParameterTypeImpl typeB = new TypeParameterTypeImpl(parameterB);
    TypeParameterElementImpl parameterS = new TypeParameterElementImpl(AstFactory.identifier3("S"));
    parameterS.bound = stringType;
    TypeParameterTypeImpl typeS = new TypeParameterTypeImpl(parameterS);
    FunctionElementImpl functionAliasElement = new FunctionElementImpl.con1(AstFactory.identifier3("func"));
    functionAliasElement.parameters = <ParameterElement> [
        ElementFactory.requiredParameter2("a", typeB),
        ElementFactory.positionalParameter2("b", typeS)];
    functionAliasElement.returnType = stringType;
    FunctionTypeImpl functionAliasType = new FunctionTypeImpl.con1(functionAliasElement);
    functionAliasElement.type = functionAliasType;
    FunctionElementImpl functionElement = new FunctionElementImpl.con1(AstFactory.identifier3("f"));
    functionElement.parameters = <ParameterElement> [
        ElementFactory.requiredParameter2("c", boolType),
        ElementFactory.positionalParameter2("d", stringType)];
    functionElement.returnType = provider.dynamicType;
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    functionElement.type = functionType;
    JUnitTestCase.assertTrue(functionType.isAssignableTo(functionAliasType));
  }

  void test_isSubtypeOf_wrongFunctionType_normal_named() {
    // ! (a) -> void <: ({name: A}) -> void
    // ! ({name: A}) -> void <: (a) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement5("t", <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement7("s", null, <String> ["name"], <ClassElement> [a]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
  }

  void test_isSubtypeOf_wrongFunctionType_optional_named() {
    // ! ([a]) -> void <: ({name: A}) -> void
    // ! ({name: A}) -> void <: ([a]) -> void
    ClassElement a = ElementFactory.classElement2("A", []);
    FunctionType t = ElementFactory.functionElement6("t", null, <ClassElement> [a]).type;
    FunctionType s = ElementFactory.functionElement7("s", null, <String> ["name"], <ClassElement> [a]).type;
    JUnitTestCase.assertFalse(t.isSubtypeOf(s));
    JUnitTestCase.assertFalse(s.isSubtypeOf(t));
  }

  void test_setTypeArguments() {
    ClassElementImpl enclosingClass = ElementFactory.classElement2("C", ["E"]);
    MethodElementImpl methodElement = new MethodElementImpl.con1(AstFactory.identifier3("m"));
    enclosingClass.methods = <MethodElement> [methodElement];
    FunctionTypeImpl type = new FunctionTypeImpl.con1(methodElement);
    DartType expectedType = enclosingClass.typeParameters[0].type;
    type.typeArguments = <DartType> [expectedType];
    List<DartType> arguments = type.typeArguments;
    EngineTestCase.assertLength(1, arguments);
    JUnitTestCase.assertEquals(expectedType, arguments[0]);
  }

  void test_substitute2_equal() {
    ClassElementImpl definingClass = ElementFactory.classElement2("C", ["E"]);
    TypeParameterType parameterType = definingClass.typeParameters[0].type;
    MethodElementImpl functionElement = new MethodElementImpl.con1(AstFactory.identifier3("m"));
    String namedParameterName = "c";
    functionElement.parameters = <ParameterElement> [
        ElementFactory.requiredParameter2("a", parameterType),
        ElementFactory.positionalParameter2("b", parameterType),
        ElementFactory.namedParameter2(namedParameterName, parameterType)];
    functionElement.returnType = parameterType;
    definingClass.methods = <MethodElement> [functionElement];
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    functionType.typeArguments = <DartType> [parameterType];
    InterfaceTypeImpl argumentType = new InterfaceTypeImpl.con1(new ClassElementImpl(AstFactory.identifier3("D")));
    FunctionType result = functionType.substitute2(<DartType> [argumentType], <DartType> [parameterType]);
    JUnitTestCase.assertEquals(argumentType, result.returnType);
    List<DartType> normalParameters = result.normalParameterTypes;
    EngineTestCase.assertLength(1, normalParameters);
    JUnitTestCase.assertEquals(argumentType, normalParameters[0]);
    List<DartType> optionalParameters = result.optionalParameterTypes;
    EngineTestCase.assertLength(1, optionalParameters);
    JUnitTestCase.assertEquals(argumentType, optionalParameters[0]);
    Map<String, DartType> namedParameters = result.namedParameterTypes;
    EngineTestCase.assertSizeOfMap(1, namedParameters);
    JUnitTestCase.assertEquals(argumentType, namedParameters[namedParameterName]);
  }

  void test_substitute2_notEqual() {
    DartType returnType = new InterfaceTypeImpl.con1(new ClassElementImpl(AstFactory.identifier3("R")));
    DartType normalParameterType = new InterfaceTypeImpl.con1(new ClassElementImpl(AstFactory.identifier3("A")));
    DartType optionalParameterType = new InterfaceTypeImpl.con1(new ClassElementImpl(AstFactory.identifier3("B")));
    DartType namedParameterType = new InterfaceTypeImpl.con1(new ClassElementImpl(AstFactory.identifier3("C")));
    FunctionElementImpl functionElement = new FunctionElementImpl.con1(AstFactory.identifier3("f"));
    String namedParameterName = "c";
    functionElement.parameters = <ParameterElement> [
        ElementFactory.requiredParameter2("a", normalParameterType),
        ElementFactory.positionalParameter2("b", optionalParameterType),
        ElementFactory.namedParameter2(namedParameterName, namedParameterType)];
    functionElement.returnType = returnType;
    FunctionTypeImpl functionType = new FunctionTypeImpl.con1(functionElement);
    InterfaceTypeImpl argumentType = new InterfaceTypeImpl.con1(new ClassElementImpl(AstFactory.identifier3("D")));
    TypeParameterTypeImpl parameterType = new TypeParameterTypeImpl(new TypeParameterElementImpl(AstFactory.identifier3("E")));
    FunctionType result = functionType.substitute2(<DartType> [argumentType], <DartType> [parameterType]);
    JUnitTestCase.assertEquals(returnType, result.returnType);
    List<DartType> normalParameters = result.normalParameterTypes;
    EngineTestCase.assertLength(1, normalParameters);
    JUnitTestCase.assertEquals(normalParameterType, normalParameters[0]);
    List<DartType> optionalParameters = result.optionalParameterTypes;
    EngineTestCase.assertLength(1, optionalParameters);
    JUnitTestCase.assertEquals(optionalParameterType, optionalParameters[0]);
    Map<String, DartType> namedParameters = result.namedParameterTypes;
    EngineTestCase.assertSizeOfMap(1, namedParameters);
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
      _ut.test('test_isAssignableTo_normalAndPositionalArgs', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isAssignableTo_normalAndPositionalArgs);
      });
      _ut.test('test_isSubtypeOf_Object', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_Object);
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
      _ut.test('test_isSubtypeOf_normalAndPositionalArgs_1', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_normalAndPositionalArgs_1);
      });
      _ut.test('test_isSubtypeOf_normalAndPositionalArgs_2', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_normalAndPositionalArgs_2);
      });
      _ut.test('test_isSubtypeOf_normalAndPositionalArgs_3', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_normalAndPositionalArgs_3);
      });
      _ut.test('test_isSubtypeOf_normalAndPositionalArgs_4', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_normalAndPositionalArgs_4);
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
      _ut.test('test_isSubtypeOf_positionalParameters_isAssignable', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_positionalParameters_isAssignable);
      });
      _ut.test('test_isSubtypeOf_positionalParameters_isNotAssignable', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_positionalParameters_isNotAssignable);
      });
      _ut.test('test_isSubtypeOf_positionalParameters_sHasMoreParams', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_positionalParameters_sHasMoreParams);
      });
      _ut.test('test_isSubtypeOf_positionalParameters_tHasMoreParams', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_positionalParameters_tHasMoreParams);
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
      _ut.test('test_isSubtypeOf_typeParameters_matchesBounds', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_typeParameters_matchesBounds);
      });
      _ut.test('test_isSubtypeOf_wrongFunctionType_normal_named', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_wrongFunctionType_normal_named);
      });
      _ut.test('test_isSubtypeOf_wrongFunctionType_optional_named', () {
        final __test = new FunctionTypeImplTest();
        runJUnitTest(__test, __test.test_isSubtypeOf_wrongFunctionType_optional_named);
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

class InterfaceTypeImpl_FunctionTypeImplTest_test_isSubtypeOf_baseCase_classFunction extends InterfaceTypeImpl {
  InterfaceTypeImpl_FunctionTypeImplTest_test_isSubtypeOf_baseCase_classFunction(ClassElement arg0) : super.con1(arg0);

  @override
  bool get isDartCoreFunction => true;
}

main() {
  ElementKindTest.dartSuite();
  AngularPropertyKindTest.dartSuite();
  FunctionTypeImplTest.dartSuite();
  InterfaceTypeImplTest.dartSuite();
  TypeParameterTypeImplTest.dartSuite();
  VoidTypeImplTest.dartSuite();
  ClassElementImplTest.dartSuite();
  ElementLocationImplTest.dartSuite();
  ElementImplTest.dartSuite();
  HtmlElementImplTest.dartSuite();
  LibraryElementImplTest.dartSuite();
  MultiplyDefinedElementImplTest.dartSuite();
}