// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.search.search_engine;

import 'dart:async';

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_single_unit.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(SearchEngineImplTest);
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

class MockIndex extends TypedMock implements Index {}

@reflectiveTest
class SearchEngineImplTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;

  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
  }

  Future test_searchAllSubtypes() {
    _indexTestUnit('''
class T {}
class A extends T {}
class B extends A {}
class C implements B {}
''');
    ClassElement element = findElement('T');
    ClassElement elementA = findElement('A');
    ClassElement elementB = findElement('B');
    ClassElement elementC = findElement('C');
    var expected = [
      _expectId(elementA, MatchKind.DECLARATION, 'A extends T'),
      _expectId(elementB, MatchKind.DECLARATION, 'B extends A'),
      _expectId(elementC, MatchKind.DECLARATION, 'C implements B')
    ];
    return searchEngine.searchAllSubtypes(element).then((matches) {
      _assertMatches(matches, expected);
    });
  }

  Future test_searchElementDeclarations() {
    _indexTestUnit('''
class A {
  test() {}
}
class B {
  int test = 1;
  main() {
    int test = 2;
  }
}
''');
    ClassElement elementA = findElement('A');
    ClassElement elementB = findElement('B');
    Element element_test = findElement('test', ElementKind.LOCAL_VARIABLE);
    var expected = [
      _expectId(elementA.methods[0], MatchKind.DECLARATION, 'test() {}'),
      _expectId(elementB.fields[0], MatchKind.DECLARATION, 'test = 1;'),
      _expectId(element_test, MatchKind.DECLARATION, 'test = 2;'),
    ];
    return searchEngine.searchElementDeclarations('test').then((matches) {
      _assertMatches(matches, expected);
    });
  }

  Future test_searchMemberDeclarations() {
    _indexTestUnit('''
class A {
  test() {}
}
class B {
  int test = 1;
  main() {
    int test = 2;
  }
}
''');
    ClassElement elementA = findElement('A');
    ClassElement elementB = findElement('B');
    var expected = [
      _expectId(elementA.methods[0], MatchKind.DECLARATION, 'test() {}'),
      _expectId(elementB.fields[0], MatchKind.DECLARATION, 'test = 1;')
    ];
    return searchEngine.searchMemberDeclarations('test').then((matches) {
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
    Element mainA = findElement('mainA');
    Element main = findElement('main');
    var expected = [
      _expectId(mainA, MatchKind.INVOCATION, 'test(); // a-inv-r-nq'),
      _expectId(mainA, MatchKind.WRITE, 'test = 1; // a-write-r-nq'),
      _expectId(mainA, MatchKind.READ_WRITE, 'test += 2; // a-read-write-r-nq'),
      _expectId(mainA, MatchKind.READ, 'test); // a-read-r-nq'),
      _expectIdQ(main, MatchKind.INVOCATION, 'test(); // a-inv-r-q'),
      _expectIdQ(main, MatchKind.WRITE, 'test = 1; // a-write-r-q'),
      _expectIdQ(main, MatchKind.READ_WRITE, 'test += 2; // a-read-write-r-q'),
      _expectIdQ(main, MatchKind.READ, 'test); // a-read-r-q'),
      _expectIdU(main, MatchKind.INVOCATION, 'test(); // p-inv-ur-q'),
      _expectIdU(main, MatchKind.WRITE, 'test = 1; // p-write-ur-q'),
      _expectIdU(main, MatchKind.READ_WRITE, 'test += 2; // p-read-write-ur-q'),
      _expectIdU(main, MatchKind.READ, 'test); // p-read-ur-q'),
    ];
    return searchEngine.searchMemberReferences('test').then((matches) {
      _assertMatches(matches, expected);
    });
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
      _expectId(pElement, MatchKind.REFERENCE, 'A p'),
      _expectId(vElement, MatchKind.REFERENCE, 'A v')
    ];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_CompilationUnitElement() {
    addSource(
        '/my_part.dart',
        '''
part of lib;
''');
    _indexTestUnit('''
library lib;
part 'my_part.dart';
''');
    CompilationUnitElement element = testLibraryElement.parts[0];
    var expected = [
      _expectId(testUnitElement, MatchKind.REFERENCE, "'my_part.dart'",
          length: "'my_part.dart'".length)
    ];
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
    Element mainElement = findElement('main');
    var expected = [
      _expectId(mainElement, MatchKind.REFERENCE, '.named();', length: 6)
    ];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_Element_unknown() {
    return _verifyReferences(DynamicElementImpl.instance, []);
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
      _expectId(fieldParameter, MatchKind.WRITE, 'field}'),
      _expectId(main, MatchKind.REFERENCE, 'field: 1'),
      _expectId(main, MatchKind.READ, 'field); // ref-nq'),
      _expectIdQ(main, MatchKind.READ, 'field); // ref-q'),
      _expectId(main, MatchKind.INVOCATION, 'field(); // inv-nq'),
      _expectIdQ(main, MatchKind.INVOCATION, 'field(); // inv-q'),
      _expectId(main, MatchKind.WRITE, 'field = 2; // ref-nq'),
      _expectIdQ(main, MatchKind.WRITE, 'field = 3; // ref-q'),
    ];
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
      _expectId(mainElement, MatchKind.INVOCATION, 'test();'),
      _expectId(mainElement, MatchKind.REFERENCE, 'test);')
    ];
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
      _expectId(aElement, MatchKind.REFERENCE, 'Test a;'),
      _expectId(bElement, MatchKind.REFERENCE, 'Test b;')
    ];
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
    var kind = MatchKind.REFERENCE;
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
    var kind = MatchKind.REFERENCE;
    var expected = [
      _expectId(mainElement, kind, 'math.PI);', length: 'math.'.length)
    ];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_LabelElement() {
    _indexTestUnit('''
main() {
label:
  while (true) {
    if (true) {
      break label; // 1
    }
    break label; // 2
  }
}
''');
    LabelElement element = findElement('label');
    Element mainElement = findElement('main');
    var expected = [
      _expectId(mainElement, MatchKind.REFERENCE, 'label; // 1'),
      _expectId(mainElement, MatchKind.REFERENCE, 'label; // 2')
    ];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_LibraryElement() {
    var codeA = 'part of lib; // A';
    var codeB = 'part of lib; // B';
    addSource('/unitA.dart', codeA);
    addSource('/unitB.dart', codeB);
    _indexTestUnit('''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
    LibraryElement element = testLibraryElement;
    CompilationUnitElement elementA = element.parts[0];
    CompilationUnitElement elementB = element.parts[1];
    index.index(context, elementA.computeNode());
    index.index(context, elementB.computeNode());
    var expected = [
      new ExpectedMatch(elementA, MatchKind.REFERENCE,
          codeA.indexOf('lib; // A'), 'lib'.length),
      new ExpectedMatch(elementB, MatchKind.REFERENCE,
          codeB.indexOf('lib; // B'), 'lib'.length),
    ];
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
      _expectId(mainElement, MatchKind.WRITE, 'v = 1;'),
      _expectId(mainElement, MatchKind.READ_WRITE, 'v += 2;'),
      _expectId(mainElement, MatchKind.READ, 'v);'),
      _expectId(mainElement, MatchKind.INVOCATION, 'v();')
    ];
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
      _expectId(mainElement, MatchKind.INVOCATION, 'm(); // 1'),
      _expectIdQ(mainElement, MatchKind.INVOCATION, 'm(); // 2'),
      _expectId(mainElement, MatchKind.REFERENCE, 'm); // 3'),
      _expectIdQ(mainElement, MatchKind.REFERENCE, 'm); // 4')
    ];
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
      _expectIdQ(mainElement, MatchKind.INVOCATION, 'm(); // ref')
    ];
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
      _expectId(fooElement, MatchKind.WRITE, 'p = 1;'),
      _expectId(fooElement, MatchKind.READ_WRITE, 'p += 2;'),
      _expectId(fooElement, MatchKind.READ, 'p);'),
      _expectId(fooElement, MatchKind.INVOCATION, 'p();'),
      _expectId(mainElement, MatchKind.REFERENCE, 'p: 42')
    ];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_PrefixElement() {
    _indexTestUnit('''
import 'dart:async' as ppp;
main() {
  ppp.Future a;
  ppp.Stream b;
}
''');
    PrefixElement element = findNodeElementAtString('ppp;');
    Element elementA = findElement('a');
    Element elementB = findElement('b');
    var expected = [
      _expectId(elementA, MatchKind.REFERENCE, 'ppp.Future'),
      _expectId(elementB, MatchKind.REFERENCE, 'ppp.Stream')
    ];
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
      _expectId(mainElement, MatchKind.REFERENCE, 'g; // 1'),
      _expectIdQ(mainElement, MatchKind.REFERENCE, 'g; // 2')
    ];
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
      _expectId(mainElement, MatchKind.REFERENCE, 's = 1'),
      _expectIdQ(mainElement, MatchKind.REFERENCE, 's = 2')
    ];
    return _verifyReferences(element, expected);
  }

  Future test_searchReferences_TopLevelVariableElement() {
    addSource(
        '/lib.dart',
        '''
library lib;
var V;
''');
    _indexTestUnit('''
import 'lib.dart' show V; // imp
import 'lib.dart' as pref;
main() {
  pref.V = 1; // q
  print(pref.V); // q
  pref.V(); // q
  V = 1; // nq
  print(V); // nq
  V(); // nq
}
''');
    ImportElement importElement = testLibraryElement.imports[0];
    CompilationUnitElement impUnit =
        importElement.importedLibrary.definingCompilationUnit;
    TopLevelVariableElement variable = impUnit.topLevelVariables[0];
    Element main = findElement('main');
    var expected = [
      _expectId(testUnitElement, MatchKind.REFERENCE, 'V; // imp'),
      _expectId(main, MatchKind.WRITE, 'V = 1; // q'),
      _expectId(main, MatchKind.READ, 'V); // q'),
      _expectId(main, MatchKind.INVOCATION, 'V(); // q'),
      _expectId(main, MatchKind.WRITE, 'V = 1; // nq'),
      _expectId(main, MatchKind.READ, 'V); // nq'),
      _expectId(main, MatchKind.INVOCATION, 'V(); // nq'),
    ];
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
      _expectId(aElement, MatchKind.REFERENCE, 'T a'),
      _expectId(bElement, MatchKind.REFERENCE, 'T b')
    ];
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
      _expectId(elementA, MatchKind.REFERENCE, 'T {} // A'),
      _expectId(elementB, MatchKind.REFERENCE, 'T; // B'),
      _expectId(elementC, MatchKind.REFERENCE, 'T {} // C')
    ];
    return searchEngine.searchSubtypes(element).then((matches) {
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
    Element topA = findElement('A');
    Element topB = findElement('B');
    Element topC = findElement('C');
    Element topD = findElement('D');
    Element topE = findElement('E');
    var expected = [
      _expectId(topA, MatchKind.DECLARATION, 'A {} // A'),
      _expectId(topB, MatchKind.DECLARATION, 'B ='),
      _expectId(topC, MatchKind.DECLARATION, 'C()'),
      _expectId(topD, MatchKind.DECLARATION, 'D() {}'),
      _expectId(topE, MatchKind.DECLARATION, 'E = null')
    ];
    return _verifyTopLevelDeclarations('^[A-E]\$', expected);
  }

  ExpectedMatch _expectId(Element element, MatchKind kind, String search,
      {int length, bool isResolved: true, bool isQualified: false}) {
    int offset = findOffset(search);
    if (length == null) {
      length = getLeadingIdentifierLength(search);
    }
    return new ExpectedMatch(element, kind, offset, length,
        isResolved: isResolved, isQualified: isQualified);
  }

  ExpectedMatch _expectIdQ(Element element, MatchKind kind, String search) {
    return _expectId(element, kind, search, isQualified: true);
  }

  ExpectedMatch _expectIdU(Element element, MatchKind kind, String search) {
    return _expectId(element, kind, search,
        isQualified: true, isResolved: false);
  }

  void _indexTestUnit(String code) {
    resolveTestUnit(code);
    index.index(context, testUnit);
  }

  Future _verifyReferences(
      Element element, List<ExpectedMatch> expectedMatches) {
    return searchEngine
        .searchReferences(element)
        .then((List<SearchMatch> matches) {
      _assertMatches(matches, expectedMatches);
    });
  }

  Future _verifyTopLevelDeclarations(
      String pattern, List<ExpectedMatch> expectedMatches) {
    return searchEngine
        .searchTopLevelDeclarations(pattern)
        .then((List<SearchMatch> matches) {
      _assertMatches(matches, expectedMatches);
    });
  }

  static void _assertMatches(
      List<SearchMatch> matches, List<ExpectedMatch> expectedMatches) {
    expect(matches, unorderedEquals(expectedMatches));
  }
}
