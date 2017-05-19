// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/ast_provider_context.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchEngineImplTest);
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

  bool operator ==(Object match) {
    return match is SearchMatch &&
        match.element == this.element &&
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

@reflectiveTest
class SearchEngineImplTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;

  @override
  bool get enableNewAnalysisDriver => false;

  void setUp() {
    super.setUp();
    index = createMemoryIndex();
    searchEngine =
        new SearchEngineImpl(index, (_) => new AstProviderForContext(context));
  }

  test_searchAllSubtypes() async {
    await _indexTestUnit('''
class T {}
class A extends T {}
class B extends A {}
class C implements B {}
''');
    ClassElement element = findElement('T');
    Set<ClassElement> subtypes = await searchEngine.searchAllSubtypes(element);
    expect(subtypes, hasLength(3));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'A')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'B')));
    expect(subtypes, contains(predicate((ClassElement e) => e.name == 'C')));
  }

  test_searchMemberDeclarations() async {
    await _indexTestUnit('''
class A {
  test() {}
}
class B {
  int test = 1;
  int testTwo = 2;
  main() {
    int test = 3;
  }
}
''');
    ClassElement elementA = findElement('A');
    ClassElement elementB = findElement('B');
    var expected = [
      _expectId(elementA.methods[0], MatchKind.DECLARATION, 'test() {}'),
      _expectId(elementB.fields[0], MatchKind.DECLARATION, 'test = 1;')
    ];
    List<SearchMatch> matches =
        await searchEngine.searchMemberDeclarations('test');
    _assertMatches(matches, expected);
  }

  test_searchMemberReferences_qualified_resolved() async {
    await _indexTestUnit('''
class C {
  var test;
}
main(C c) {
  print(c.test);
  c.test = 1;
  c.test += 2;
  c.test();
}
''');
    List<SearchMatch> matches =
        await searchEngine.searchMemberReferences('test');
    expect(matches, isEmpty);
  }

  test_searchMemberReferences_qualified_unresolved() async {
    await _indexTestUnit('''
main(p) {
  print(p.test);
  p.test = 1;
  p.test += 2;
  p.test();
}
''');
    Element main = findElement('main');
    var expected = [
      _expectIdQU(main, MatchKind.READ, 'test);'),
      _expectIdQU(main, MatchKind.WRITE, 'test = 1;'),
      _expectIdQU(main, MatchKind.READ_WRITE, 'test += 2;'),
      _expectIdQU(main, MatchKind.INVOCATION, 'test();'),
    ];
    List<SearchMatch> matches =
        await searchEngine.searchMemberReferences('test');
    _assertMatches(matches, expected);
  }

  test_searchMemberReferences_unqualified_resolved() async {
    await _indexTestUnit('''
class C {
  var test;
  main() {
    print(test);
    test = 1;
    test += 2;
    test();
  }
}
''');
    List<SearchMatch> matches =
        await searchEngine.searchMemberReferences('test');
    expect(matches, isEmpty);
  }

  test_searchMemberReferences_unqualified_unresolved() async {
    verifyNoTestUnitErrors = false;
    await _indexTestUnit('''
class C {
  main() {
    print(test);
    test = 1;
    test += 2;
    test();
  }
}
''');
    Element main = findElement('main');
    var expected = [
      _expectIdU(main, MatchKind.READ, 'test);'),
      _expectIdU(main, MatchKind.WRITE, 'test = 1;'),
      _expectIdU(main, MatchKind.READ_WRITE, 'test += 2;'),
      _expectIdU(main, MatchKind.INVOCATION, 'test();'),
    ];
    List<SearchMatch> matches =
        await searchEngine.searchMemberReferences('test');
    _assertMatches(matches, expected);
  }

  test_searchReferences_ClassElement() async {
    await _indexTestUnit('''
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
    await _verifyReferences(element, expected);
  }

  test_searchReferences_CompilationUnitElement() async {
    addSource(
        '/my_part.dart',
        '''
part of lib;
''');
    await _indexTestUnit('''
library lib;
part 'my_part.dart';
''');
    CompilationUnitElement element = testLibraryElement.parts[0];
    var expected = [
      _expectIdQ(testUnitElement, MatchKind.REFERENCE, "'my_part.dart'",
          length: "'my_part.dart'".length)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ConstructorElement() async {
    await _indexTestUnit('''
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
      _expectIdQ(mainElement, MatchKind.REFERENCE, '.named();', length: 6)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ConstructorElement_synthetic() async {
    await _indexTestUnit('''
class A {
}
main() {
  new A();
}
''');
    ClassElement classElement = findElement('A');
    ConstructorElement element = classElement.unnamedConstructor;
    Element mainElement = findElement('main');
    var expected = [
      _expectIdQ(mainElement, MatchKind.REFERENCE, '();', length: 0)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_Element_unknown() async {
    await _verifyReferences(DynamicElementImpl.instance, []);
  }

  test_searchReferences_FieldElement() async {
    await _indexTestUnit('''
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
    FieldElement element = findElement('field', ElementKind.FIELD);
    Element main = findElement('main');
    Element fieldParameter = findElement('field', ElementKind.PARAMETER);
    var expected = [
      _expectIdQ(fieldParameter, MatchKind.WRITE, 'field}'),
      _expectIdQ(main, MatchKind.REFERENCE, 'field: 1'),
      _expectId(main, MatchKind.READ, 'field); // ref-nq'),
      _expectIdQ(main, MatchKind.READ, 'field); // ref-q'),
      _expectId(main, MatchKind.INVOCATION, 'field(); // inv-nq'),
      _expectIdQ(main, MatchKind.INVOCATION, 'field(); // inv-q'),
      _expectId(main, MatchKind.WRITE, 'field = 2; // ref-nq'),
      _expectIdQ(main, MatchKind.WRITE, 'field = 3; // ref-q'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FieldElement_ofEnum() async {
    await _indexTestUnit('''
enum MyEnum {
  A, B, C
}
main() {
  print(MyEnum.A.index);
  print(MyEnum.values);
  print(MyEnum.A);
  print(MyEnum.B);
}
''');
    ClassElement enumElement = findElement('MyEnum');
    Element mainElement = findElement('main');
    await _verifyReferences(enumElement.getField('index'),
        [_expectIdQ(mainElement, MatchKind.READ, 'index);')]);
    await _verifyReferences(enumElement.getField('values'),
        [_expectIdQ(mainElement, MatchKind.READ, 'values);')]);
    await _verifyReferences(enumElement.getField('A'), [
      _expectIdQ(mainElement, MatchKind.READ, 'A.index);'),
      _expectIdQ(mainElement, MatchKind.READ, 'A);')
    ]);
    await _verifyReferences(enumElement.getField('B'),
        [_expectIdQ(mainElement, MatchKind.READ, 'B);')]);
  }

  test_searchReferences_FieldElement_synthetic() async {
    await _indexTestUnit('''
class A {
  get field => null;
  set field(x) {}
  main() {
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
    FieldElement element = findElement('field', ElementKind.FIELD);
    Element main = findElement('main');
    var expected = [
      _expectId(main, MatchKind.READ, 'field); // ref-nq'),
      _expectIdQ(main, MatchKind.READ, 'field); // ref-q'),
      _expectId(main, MatchKind.INVOCATION, 'field(); // inv-nq'),
      _expectIdQ(main, MatchKind.INVOCATION, 'field(); // inv-q'),
      _expectId(main, MatchKind.WRITE, 'field = 2; // ref-nq'),
      _expectIdQ(main, MatchKind.WRITE, 'field = 3; // ref-q'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FunctionElement() async {
    await _indexTestUnit('''
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
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FunctionElement_local() async {
    await _indexTestUnit('''
main() {
  test() {}
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
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FunctionTypeAliasElement() async {
    await _indexTestUnit('''
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
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ImportElement_noPrefix() async {
    await _indexTestUnit('''
import 'dart:math' show max, PI, Random hide min;
export 'dart:math' show max, PI, Random hide min;
main() {
  print(PI);
  print(new Random());
  print(max(1, 2));
}
Random bar() => null;
''');
    ImportElement element = testLibraryElement.imports[0];
    Element mainElement = findElement('main');
    Element barElement = findElement('bar');
    var kind = MatchKind.REFERENCE;
    var expected = [
      _expectId(mainElement, kind, 'PI);', length: 0),
      _expectId(mainElement, kind, 'Random()', length: 0),
      _expectId(mainElement, kind, 'max(', length: 0),
      _expectId(barElement, kind, 'Random bar()', length: 0),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ImportElement_withPrefix() async {
    await _indexTestUnit('''
import 'dart:math' as math show max, PI, Random hide min;
export 'dart:math' show max, PI, Random hide min;
main() {
  print(math.PI);
  print(new math.Random());
  print(math.max(1, 2));
}
math.Random bar() => null;
''');
    ImportElement element = testLibraryElement.imports[0];
    Element mainElement = findElement('main');
    Element barElement = findElement('bar');
    var kind = MatchKind.REFERENCE;
    var length = 'math.'.length;
    var expected = [
      _expectId(mainElement, kind, 'math.PI);', length: length),
      _expectId(mainElement, kind, 'math.Random()', length: length),
      _expectId(mainElement, kind, 'math.max(', length: length),
      _expectId(barElement, kind, 'math.Random bar()', length: length),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ImportElement_withPrefix_forMultipleImports() async {
    await _indexTestUnit('''
import 'dart:async' as p;
import 'dart:math' as p;
main() {
  p.Random;
  p.Future;
}
''');
    Element mainElement = findElement('main');
    var kind = MatchKind.REFERENCE;
    var length = 'p.'.length;
    {
      ImportElement element = testLibraryElement.imports[0];
      var expected = [
        _expectId(mainElement, kind, 'p.Future;', length: length),
      ];
      await _verifyReferences(element, expected);
    }
    {
      ImportElement element = testLibraryElement.imports[1];
      var expected = [
        _expectId(mainElement, kind, 'p.Random', length: length),
      ];
      await _verifyReferences(element, expected);
    }
  }

  test_searchReferences_LabelElement() async {
    await _indexTestUnit('''
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
    await _verifyReferences(element, expected);
  }

  test_searchReferences_LibraryElement() async {
    var codeA = 'part of lib; // A';
    var codeB = 'part of lib; // B';
    var sourceA = addSource('/unitA.dart', codeA);
    var sourceB = addSource('/unitB.dart', codeB);
    await _indexTestUnit('''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
    LibraryElement element = testLibraryElement;
    CompilationUnitElement unitElementA = element.parts[0];
    CompilationUnitElement unitElementB = element.parts[1];
    index.indexUnit(
        context.resolveCompilationUnit2(sourceA, testLibraryElement.source));
    index.indexUnit(
        context.resolveCompilationUnit2(sourceB, testLibraryElement.source));
    var expected = [
      new ExpectedMatch(unitElementA, MatchKind.REFERENCE,
          codeA.indexOf('lib; // A'), 'lib'.length),
      new ExpectedMatch(unitElementB, MatchKind.REFERENCE,
          codeB.indexOf('lib; // B'), 'lib'.length),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_LocalVariableElement() async {
    await _indexTestUnit('''
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
    await _verifyReferences(element, expected);
  }

  test_searchReferences_LocalVariableElement_inForEachLoop() async {
    await _indexTestUnit('''
main() {
  for (var v in []) {
    v = 1;
    v += 2;
    print(v);
    v();
  }
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
    await _verifyReferences(element, expected);
  }

  test_searchReferences_MethodElement() async {
    await _indexTestUnit('''
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
    await _verifyReferences(method, expected);
  }

  test_searchReferences_MethodMember() async {
    await _indexTestUnit('''
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
    await _verifyReferences(method, expected);
  }

  test_searchReferences_null_noUnitElement() async {
    await _indexTestUnit('''
class A {
  m() {}
}
main(A a) {
  a.m();
}
''');
    MethodElement method = findElement('m');
    List<SearchMatch> matches = await searchEngine.searchReferences(method);
    expect(matches, hasLength(1));
    // Set the source contents, so the element is invalidated.
    context.setContents(testSource, '');
    expect(matches.single.element, isNull);
  }

  test_searchReferences_ParameterElement_ofConstructor() async {
    await _indexTestUnit('''
class C {
  var f;
  C({p}) : f = p + 1 {
    p = 2;
    p += 3;
    print(p);
    p();
  }
}
main() {
  new C(p: 42);
}
''');
    ParameterElement element = findElement('p');
    ClassElement classC = findElement('C');
    ConstructorElement constructorA = classC.unnamedConstructor;
    Element mainElement = findElement('main');
    var expected = [
      _expectId(constructorA, MatchKind.READ, 'p + 1 {'),
      _expectId(constructorA, MatchKind.WRITE, 'p = 2;'),
      _expectId(constructorA, MatchKind.READ_WRITE, 'p += 3;'),
      _expectId(constructorA, MatchKind.READ, 'p);'),
      _expectId(constructorA, MatchKind.INVOCATION, 'p();'),
      _expectIdQ(mainElement, MatchKind.REFERENCE, 'p: 42')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ParameterElement_ofLocalFunction() async {
    await _indexTestUnit('''
main() {
  foo({p}) {
    p = 1;
    p += 2;
    print(p);
    p();
  }
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
      _expectIdQ(mainElement, MatchKind.REFERENCE, 'p: 42')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ParameterElement_ofMethod() async {
    await _indexTestUnit('''
class C {
  foo({p}) {
    p = 1;
    p += 2;
    print(p);
    p();
  }
}
main(C c) {
  c.foo(p: 42);
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
      _expectIdQ(mainElement, MatchKind.REFERENCE, 'p: 42')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ParameterElement_ofTopLevelFunction() async {
    await _indexTestUnit('''
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
      _expectIdQ(mainElement, MatchKind.REFERENCE, 'p: 42')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PrefixElement() async {
    await _indexTestUnit('''
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
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PropertyAccessorElement_getter() async {
    await _indexTestUnit('''
class A {
  get ggg => null;
  main() {
    print(ggg); // ref-nq
    print(this.ggg); // ref-q
    ggg(); // inv-nq
    this.ggg(); // inv-q
  }
}
''');
    PropertyAccessorElement element = findElement('ggg', ElementKind.GETTER);
    Element main = findElement('main');
    var expected = [
      _expectId(main, MatchKind.REFERENCE, 'ggg); // ref-nq'),
      _expectIdQ(main, MatchKind.REFERENCE, 'ggg); // ref-q'),
      _expectId(main, MatchKind.INVOCATION, 'ggg(); // inv-nq'),
      _expectIdQ(main, MatchKind.INVOCATION, 'ggg(); // inv-q'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PropertyAccessorElement_setter() async {
    await _indexTestUnit('''
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
    await _verifyReferences(element, expected);
  }

  test_searchReferences_TopLevelVariableElement() async {
    addSource(
        '/lib.dart',
        '''
library lib;
var V;
''');
    await _indexTestUnit('''
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
      _expectIdQ(testUnitElement, MatchKind.REFERENCE, 'V; // imp'),
      _expectIdQ(main, MatchKind.WRITE, 'V = 1; // q'),
      _expectIdQ(main, MatchKind.READ, 'V); // q'),
      _expectIdQ(main, MatchKind.INVOCATION, 'V(); // q'),
      _expectId(main, MatchKind.WRITE, 'V = 1; // nq'),
      _expectId(main, MatchKind.READ, 'V); // nq'),
      _expectId(main, MatchKind.INVOCATION, 'V(); // nq'),
    ];
    await _verifyReferences(variable, expected);
  }

  test_searchReferences_TypeParameterElement() async {
    await _indexTestUnit('''
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
    await _verifyReferences(element, expected);
  }

  test_searchSubtypes() async {
    await _indexTestUnit('''
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
    List<SearchMatch> matches = await searchEngine.searchSubtypes(element);
    _assertMatches(matches, expected);
  }

  test_searchTopLevelDeclarations() async {
    await _indexTestUnit('''
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
    List<SearchMatch> matches =
        await searchEngine.searchTopLevelDeclarations(r'^[A-E]$');
    _assertMatches(matches, expected);
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

  /**
   * Create [ExpectedMatch] for a qualified and resolved match.
   */
  ExpectedMatch _expectIdQ(Element element, MatchKind kind, String search,
      {int length, bool isResolved: true}) {
    return _expectId(element, kind, search, isQualified: true, length: length);
  }

  /**
   * Create [ExpectedMatch] for a qualified and unresolved match.
   */
  ExpectedMatch _expectIdQU(Element element, MatchKind kind, String search,
      {int length}) {
    return _expectId(element, kind, search,
        isQualified: true, isResolved: false, length: length);
  }

  /**
   * Create [ExpectedMatch] for a unqualified and unresolved match.
   */
  ExpectedMatch _expectIdU(Element element, MatchKind kind, String search,
      {int length}) {
    return _expectId(element, kind, search,
        isQualified: false, isResolved: false, length: length);
  }

  Future<Null> _indexTestUnit(String code) async {
    await resolveTestUnit(code);
    index.indexUnit(testUnit);
  }

  Future _verifyReferences(
      Element element, List<ExpectedMatch> expectedMatches) async {
    List<SearchMatch> matches = await searchEngine.searchReferences(element);
    _assertMatches(matches, expectedMatches);
    expect(matches, hasLength(expectedMatches.length));
  }

  static void _assertMatches(
      List<SearchMatch> matches, List<ExpectedMatch> expectedMatches) {
    expect(matches, unorderedEquals(expectedMatches));
  }
}
