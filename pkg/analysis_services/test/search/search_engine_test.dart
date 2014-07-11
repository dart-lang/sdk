// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.src.search.search_engine_test;

import 'dart:async';

import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analysis_testing/mocks.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../index/abstract_single_unit.dart';


main() {
  groupSep = ' | ';
  group('SearchEngineImplTest', () {
    runReflectiveTests(SearchEngineImplTest);
  });
}

class ExpectedMatch {
  final Element element;
  final MatchKind kind;
  SourceRange range;
  final bool isResolved;
  final bool isQualified;

  ExpectedMatch(this.element, this.kind, int offset, int length,
      {this.isResolved: true, this.isQualified: false}) {
    this.range = new SourceRange(offset, length);
  }

  bool operator ==(SearchMatch match) {
    return match.element == this.element &&
        match.kind == this.kind &&
        match.isResolved == this.isResolved &&
        match.isQualified == this.isQualified &&
        match.sourceRange == this.range;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("ExpectedMatch(kind=");
    buffer.write(kind);
    buffer.write(", element=");
    buffer.write(element != null ? element.displayName : 'null');
    buffer.write(", range=");
    buffer.write(range);
    buffer.write(", isResolved=");
    buffer.write(isResolved);
    buffer.write(", isQualified=");
    buffer.write(isQualified);
    buffer.write(")");
    return buffer.toString();
  }
}


class MockAngularComponentElement extends TypedMock implements
    AngularComponentElement {
  final kind = ElementKind.ANGULAR_COMPONENT;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockAngularControllerElement extends TypedMock implements
    AngularControllerElement {
  final kind = ElementKind.ANGULAR_CONTROLLER;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockAngularFormatterElement extends TypedMock implements
    AngularFormatterElement {
  final kind = ElementKind.ANGULAR_FORMATTER;
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class MockIndex extends TypedMock implements Index {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


@ReflectiveTestCase()
class SearchEngineImplTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;

//  void mockLocation(Element element, Relationship relationship,
//      Location location) {
//    mockLocations(element, relationship, [location]);
//  }
//
//  void mockLocations(Element element, Relationship relationship,
//      List<Location> locations) {
//    index.getRelationships(element, relationship);
//    when(null).thenReturn(new Future.value(locations));
//  }

  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
  }

  Future test_searchMemberDeclarations() {
    _indexTestUnit('''
class A {
  test() {}
}
class B {
  int test = 42;
}
''');
    NameElement element = new NameElement('test');
    ClassElement elementA = findElement('A');
    ClassElement elementB = findElement('B');
    var expected = [
        _expectId(elementA.methods[0], MatchKind.NAME_DECLARATION, 'test() {}'),
        _expectId(elementB.fields[0], MatchKind.NAME_DECLARATION, 'test = 42;')];
    return searchEngine.searchMemberDeclarations('test').then((matches) {
      _assertMatches(matches, expected);
    });
  }

  Future test_searchReferences_AngularComponentElement() {
    // use mocks
    index = new MockIndex();
    searchEngine = new SearchEngineImpl(index);
    Element elementA = new MockElement('A');
    Element elementB = new MockElement('B');
    // fill mocks
    AngularComponentElement element = new MockAngularComponentElement();
    void mockLocation(Element element, Relationship relationship,
        Location location) {
      index.getRelationships(element, relationship);
      when(null).thenReturn(new Future.value([location]));
    }
    mockLocation(
        element,
        IndexConstants.ANGULAR_REFERENCE,
        new Location(elementA, 1, 10));
    mockLocation(
        element,
        IndexConstants.ANGULAR_CLOSING_TAG_REFERENCE,
        new Location(elementB, 2, 20));
    var expected = [
        new ExpectedMatch(elementA, MatchKind.ANGULAR_REFERENCE, 1, 10),
        new ExpectedMatch(elementB, MatchKind.ANGULAR_CLOSING_TAG_REFERENCE, 2, 20)];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_ClassElement() {
    _indexTestUnit('''
class A {}
main(A p) {
  A v;
}
''');
    ClassElement element = findElement('A');
    Element pElement = findElement('p');
    Element vElement = findElement('v');
    var expected = [
        _expectId(pElement, MatchKind.TYPE_REFERENCE, 'A p'),
        _expectId(vElement, MatchKind.TYPE_REFERENCE, 'A v')];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_CompilationUnitElement() {
    addSource('/my_part.dart', '''
part of lib;
''');
    _indexTestUnit('''
library lib;
part 'my_part.dart';
''');
    CompilationUnitElement element = testLibraryElement.parts[0];
    var expected = [
        _expectId(
            testUnitElement,
            MatchKind.UNIT_REFERENCE,
            "'my_part.dart'",
            length: "'my_part.dart'".length)];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_ConstructorElement() {
    _indexTestUnit('''
class A {
  A.named() {}
}
main() {
  new A.named();
}
''');
    ConstructorElement element = findElement('named');
    ClassElement elementA = findElement('A');
    Element mainElement = findElement('main');
    var expected = [
        _expectId(
            elementA,
            MatchKind.CONSTRUCTOR_DECLARATION,
            '.named() {}',
            length: 6),
        _expectId(
            mainElement,
            MatchKind.CONSTRUCTOR_REFERENCE,
            '.named();',
            length: 6)];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_Element_unknown() {
    return _verifyReferences(UniverseElement.INSTANCE, []);
  }

  Future test_searchReferences_FieldElement() {
    _indexTestUnit('''
class A {
  var field;
  A({this.field});
  main() {
    new A(field: 1);
    // getter
    print(field); // ref-nq
    print(this.field); // ref-q
    field(); // inv-nq
    this.field(); // inv-q
    // setter
    field = 2; // ref-nq;
    this.field = 3; // ref-q;
  }
}
''');
    FieldElement element = findElement('field');
    Element main = findElement('main');
    Element fieldParameter = findElement('field', ElementKind.PARAMETER);
    var expected = [
        _expectIdQ(fieldParameter, MatchKind.FIELD_REFERENCE, 'field}'),
        _expectIdQ(main, MatchKind.FIELD_REFERENCE, 'field: 1'),
        _expectId(main, MatchKind.FIELD_READ, 'field); // ref-nq'),
        _expectIdQ(main, MatchKind.FIELD_READ, 'field); // ref-q'),
        _expectId(main, MatchKind.FIELD_INVOCATION, 'field(); // inv-nq'),
        _expectIdQ(main, MatchKind.FIELD_INVOCATION, 'field(); // inv-q'),
        _expectId(main, MatchKind.FIELD_WRITE, 'field = 2; // ref-nq'),
        _expectIdQ(main, MatchKind.FIELD_WRITE, 'field = 3; // ref-q')];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_FunctionElement() {
    _indexTestUnit('''
test() {}
main() {
  test();
  print(test);
}
''');
    FunctionElement element = findElement('test');
    Element mainElement = findElement('main');
    var expected = [
        _expectId(mainElement, MatchKind.FUNCTION_EXECUTION, 'test();'),
        _expectId(mainElement, MatchKind.FUNCTION_REFERENCE, 'test);')];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_FunctionTypeAliasElement() {
    _indexTestUnit('''
typedef Test();
main() {
  Test a;
  Test b;
}
''');
    FunctionTypeAliasElement element = findElement('Test');
    Element aElement = findElement('a');
    Element bElement = findElement('b');
    var expected = [
        _expectId(aElement, MatchKind.FUNCTION_TYPE_REFERENCE, 'Test a;'),
        _expectId(bElement, MatchKind.FUNCTION_TYPE_REFERENCE, 'Test b;')];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_ImportElement_noPrefix() {
    _indexTestUnit('''
import 'dart:math';
main() {
  print(E);
}
''');
    ImportElement element = testLibraryElement.imports[0];
    Element mainElement = findElement('main');
    var kind = MatchKind.IMPORT_REFERENCE;
    var expected = [_expectId(mainElement, kind, 'E);', length: 0)];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_ImportElement_withPrefix() {
    _indexTestUnit('''
import 'dart:math' as math;
main() {
  print(math.PI);
}
''');
    ImportElement element = testLibraryElement.imports[0];
    Element mainElement = findElement('main');
    var kind = MatchKind.IMPORT_REFERENCE;
    var expected = [
        _expectId(mainElement, kind, 'math.PI);', length: 'math.'.length)];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_LibraryElement() {
    var codeA = 'part of lib; // A';
    var codeB = 'part of lib; // B';
    var sourceA = addSource('/unitA.dart', codeA);
    var sourceB = addSource('/unitB.dart', codeB);
    _indexTestUnit('''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
    LibraryElement element = testLibraryElement;
    CompilationUnitElement elementA = element.parts[0];
    CompilationUnitElement elementB = element.parts[1];
    index.indexUnit(context, elementA.node);
    index.indexUnit(context, elementB.node);
    Element mainElement = findElement('main');
    var expected = [
        new ExpectedMatch(
            elementA,
            MatchKind.LIBRARY_REFERENCE,
            codeA.indexOf('lib; // A'),
            'lib'.length),
        new ExpectedMatch(
            elementB,
            MatchKind.LIBRARY_REFERENCE,
            codeB.indexOf('lib; // B'),
            'lib'.length),];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_LocalVariableElement() {
    _indexTestUnit('''
main() {
  var v;
  v = 1;
  v += 2;
  print(v);
  v();
}
''');
    LocalVariableElement element = findElement('v');
    Element mainElement = findElement('main');
    var expected = [
        _expectId(mainElement, MatchKind.VARIABLE_WRITE, 'v = 1;'),
        _expectId(mainElement, MatchKind.VARIABLE_READ_WRITE, 'v += 2;'),
        _expectId(mainElement, MatchKind.VARIABLE_READ, 'v);'),
        _expectId(mainElement, MatchKind.FUNCTION_EXECUTION, 'v();')];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_MethodElement() {
    _indexTestUnit('''
class A {
  m() {}
  main() {
    m(); // 1
    this.m(); // 2
    print(m); // 3
    print(this.m); // 4
  }
}
''');
    MethodElement method = findElement('m');
    Element mainElement = findElement('main');
    var expected = [
        _expectId(mainElement, MatchKind.METHOD_INVOCATION, 'm(); // 1'),
        _expectIdQ(mainElement, MatchKind.METHOD_INVOCATION, 'm(); // 2'),
        _expectId(mainElement, MatchKind.METHOD_REFERENCE, 'm); // 3'),
        _expectIdQ(mainElement, MatchKind.METHOD_REFERENCE, 'm); // 4')];
    return _verifyReferences(method, expected);
  }

  Future test_searchReferences_MethodMember() {
    _indexTestUnit('''
class A<T> {
  T m() => null;
}
main(A<int> a) {
  a.m(); // ref
}
''');
    MethodMember method = findNodeElementAtString('m(); // ref');
    Element mainElement = findElement('main');
    var expected = [
        _expectIdQ(mainElement, MatchKind.METHOD_INVOCATION, 'm(); // ref')];
    return _verifyReferences(method, expected);
  }

  Future test_searchReferences_ParameterElement() {
    _indexTestUnit('''
foo({p}) {
  p = 1;
  p += 2;
  print(p);
  p();
}
main() {
  foo(p: 42);
}
''');
    ParameterElement element = findElement('p');
    Element fooElement = findElement('foo');
    Element mainElement = findElement('main');
    var expected = [
        _expectId(fooElement, MatchKind.VARIABLE_WRITE, 'p = 1;'),
        _expectId(fooElement, MatchKind.VARIABLE_READ_WRITE, 'p += 2;'),
        _expectId(fooElement, MatchKind.VARIABLE_READ, 'p);'),
        _expectId(fooElement, MatchKind.FUNCTION_EXECUTION, 'p();'),
        _expectId(mainElement, MatchKind.NAMED_PARAMETER_REFERENCE, 'p: 42')];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_PropertyAccessorElement_getter() {
    _indexTestUnit('''
class A {
  get g => null;
  main() {
    g; // 1
    this.g; // 2
  }
}
''');
    PropertyAccessorElement element = findElement('g', ElementKind.GETTER);
    Element mainElement = findElement('main');
    var expected = [
        _expectId(mainElement, MatchKind.PROPERTY_ACCESSOR_REFERENCE, 'g; // 1'),
        _expectIdQ(mainElement, MatchKind.PROPERTY_ACCESSOR_REFERENCE, 'g; // 2')];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_PropertyAccessorElement_setter() {
    _indexTestUnit('''
class A {
  set s(x) {}
  main() {
    s = 1;
    this.s = 2;
  }
}
''');
    PropertyAccessorElement element = findElement('s=');
    Element mainElement = findElement('main');
    var expected = [
        _expectId(mainElement, MatchKind.PROPERTY_ACCESSOR_REFERENCE, 's = 1'),
        _expectIdQ(mainElement, MatchKind.PROPERTY_ACCESSOR_REFERENCE, 's = 2')];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_TopLevelVariableElement() {
    addSource('/lib.dart', '''
library lib;
var V;
''');
    _indexTestUnit('''
import 'lib.dart' show V; // imp
import 'lib.dart' as pref;
main() {
  V = 1;
  print(V);
  V();
}
mainQ() {
  pref.V = 1; // Q
  print(pref.V); // Q
  pref.V(); // Q
}
''');
    ImportElement importElement = testLibraryElement.imports[0];
    CompilationUnitElement impUnit =
        importElement.importedLibrary.definingCompilationUnit;
    TopLevelVariableElement variable = impUnit.topLevelVariables[0];
    Element main = findElement('main');
    Element mainQ = findElement('mainQ');
    var expected = [
        _expectIdQ(testUnitElement, MatchKind.FIELD_REFERENCE, 'V; // imp'),
        _expectId(main, MatchKind.FIELD_WRITE, 'V = 1;'),
        _expectId(main, MatchKind.FIELD_READ, 'V);'),
        _expectId(main, MatchKind.FIELD_INVOCATION, 'V();'),
        _expectIdQ(mainQ, MatchKind.FIELD_WRITE, 'V = 1; // Q'),
        _expectIdQ(mainQ, MatchKind.FIELD_READ, 'V); // Q'),
        _expectIdQ(mainQ, MatchKind.FIELD_INVOCATION, 'V(); // Q')];
    return _verifyReferences(variable, expected);
  }

  Future test_searchReferences_TypeParameterElement() {
    _indexTestUnit('''
class A<T> {
  main(T a, T b) {}
}
''');
    TypeParameterElement element = findElement('T');
    Element aElement = findElement('a');
    Element bElement = findElement('b');
    var expected = [
        _expectId(aElement, MatchKind.TYPE_PARAMETER_REFERENCE, 'T a'),
        _expectId(bElement, MatchKind.TYPE_PARAMETER_REFERENCE, 'T b')];
    return _verifyReferences(element, expected);
  }

  Future test_searchSubtypes() {
    _indexTestUnit('''
class T {}
class A extends T {} // A
class B = Object with T; // B
class C implements T {} // C
''');
    ClassElement element = findElement('T');
    ClassElement elementA = findElement('A');
    ClassElement elementB = findElement('B');
    ClassElement elementC = findElement('C');
    var expected = [
        _expectId(elementA, MatchKind.EXTENDS_REFERENCE, 'T {} // A'),
        _expectId(elementB, MatchKind.WITH_REFERENCE, 'T; // B'),
        _expectId(elementC, MatchKind.IMPLEMENTS_REFERENCE, 'T {} // C')];
    return searchEngine.searchSubtypes(element).then((matches) {
      _assertMatches(matches, expected);
    });
  }

  Future test_searchMemberReferences() {
    _indexTestUnit('''
class A {
  var test; // A
  mainA() {
    test(); // a-inv-r-nq
    test = 1; // a-write-r-nq
    test += 2; // a-read-write-r-nq
    print(test); // a-read-r-nq
  }
}
main(A a, p) {
  a.test(); // a-inv-r-q
  a.test = 1; // a-write-r-q
  a.test += 2; // a-read-write-r-q
  print(a.test); // a-read-r-q
  p.test(); // p-inv-ur-q
  p.test = 1; // p-write-ur-q
  p.test += 2; // p-read-write-ur-q
  print(p.test); // p-read-ur-q
}
''');
    ClassElement elementA = findElement('A');
    ClassElement elementB = findElement('B');
    Element mainA = findElement('mainA');
    Element main = findElement('main');
    var expected = [
        _expectId(mainA, MatchKind.NAME_INVOCATION_RESOLVED, 'test(); // a-inv-r-nq'),
        _expectId(mainA, MatchKind.NAME_WRITE_RESOLVED, 'test = 1; // a-write-r-nq'),
        _expectId(mainA, MatchKind.NAME_READ_WRITE_RESOLVED, 'test += 2; // a-read-write-r-nq'),
        _expectId(mainA, MatchKind.NAME_READ_RESOLVED, 'test); // a-read-r-nq'),
        _expectId(main, MatchKind.NAME_INVOCATION_RESOLVED, 'test(); // a-inv-r-q'),
        _expectId(main, MatchKind.NAME_WRITE_RESOLVED, 'test = 1; // a-write-r-q'),
        _expectId(main, MatchKind.NAME_READ_WRITE_RESOLVED, 'test += 2; // a-read-write-r-q'),
        _expectId(main, MatchKind.NAME_READ_RESOLVED, 'test); // a-read-r-q'),
        _expectIdU(main, MatchKind.NAME_INVOCATION_UNRESOLVED, 'test(); // p-inv-ur-q'),
        _expectIdU(main, MatchKind.NAME_WRITE_UNRESOLVED, 'test = 1; // p-write-ur-q'),
        _expectIdU(main, MatchKind.NAME_READ_WRITE_UNRESOLVED, 'test += 2; // p-read-write-ur-q'),
        _expectIdU(main, MatchKind.NAME_READ_UNRESOLVED, 'test); // p-read-ur-q'),
        ];
    return searchEngine.searchMemberReferences('test').then((matches) {
      _assertMatches(matches, expected);
    });
  }

  Future test_searchTopLevelDeclarations() {
    _indexTestUnit('''
class A {} // A
class B = Object with A;
typedef C();
D() {}
var E = null;
class NoMatchABCDE {}
''');
    NameElement element = new NameElement('test');
    Element topA = findElement('A');
    Element topB = findElement('B');
    Element topC = findElement('C');
    Element topD = findElement('D');
    Element topE = findElement('E');
    Element topNoMatch = new MockElement('NoMatchABCDE');
    var expected = [
        _expectId(topA, MatchKind.CLASS_DECLARATION, 'A {} // A'),
        _expectId(topB, MatchKind.CLASS_ALIAS_DECLARATION, 'B ='),
        _expectId(topC, MatchKind.FUNCTION_TYPE_DECLARATION, 'C()'),
        _expectId(topD, MatchKind.FUNCTION_DECLARATION, 'D() {}'),
        _expectId(topE, MatchKind.VARIABLE_DECLARATION, 'E = null')];
    return _verifyTopLevelDeclarations('^[A-E]\$', expected);
  }

  ExpectedMatch _expectId(Element element, MatchKind kind, String search,
      {int length, bool isResolved: true, bool isQualified: false}) {
    int offset = findOffset(search);
    if (length == null) {
      length = getLeadingIdentifierLength(search);
    }
    return new ExpectedMatch(
        element,
        kind,
        offset,
        length,
        isResolved: isResolved,
        isQualified: isQualified);
  }

  ExpectedMatch _expectIdQ(Element element, MatchKind kind, String search) {
    return _expectId(element, kind, search, isQualified: true);
  }

  ExpectedMatch _expectIdU(Element element, MatchKind kind, String search) {
    return _expectId(element, kind, search, isResolved: false);
  }

  void _indexTestUnit(String code) {
    resolveTestUnit(code);
    index.indexUnit(context, testUnit);
  }

  Future _verifyReferences(Element element,
      List<ExpectedMatch> expectedMatches) {
    return searchEngine.searchReferences(
        element).then((List<SearchMatch> matches) {
      _assertMatches(matches, expectedMatches);
    });
  }

  Future _verifyTopLevelDeclarations(String pattern,
      List<ExpectedMatch> expectedMatches) {
    return searchEngine.searchTopLevelDeclarations(
        pattern).then((List<SearchMatch> matches) {
      _assertMatches(matches, expectedMatches);
    });
  }

  static void _assertMatches(List<SearchMatch> matches,
      List<ExpectedMatch> expectedMatches) {
    expect(matches, unorderedEquals(expectedMatches));
  }
}
