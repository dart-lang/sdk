// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchTest);
  });
}

class ExpectedResult {
  final Element enclosingElement;
  final SearchResultKind kind;
  final int offset;
  final int length;
  final bool isResolved;
  final bool isQualified;

  ExpectedResult(this.enclosingElement, this.kind, this.offset, this.length,
      {this.isResolved: true, this.isQualified: false});

  bool operator ==(Object result) {
    return result is SearchResult &&
        result.kind == this.kind &&
        result.isResolved == this.isResolved &&
        result.isQualified == this.isQualified &&
        result.offset == this.offset &&
        result.length == this.length &&
        result.enclosingElement == this.enclosingElement;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("ExpectedResult(kind=");
    buffer.write(kind);
    buffer.write(", enclosingElement=");
    buffer.write(enclosingElement);
    buffer.write(", offset=");
    buffer.write(offset);
    buffer.write(", length=");
    buffer.write(length);
    buffer.write(", isResolved=");
    buffer.write(isResolved);
    buffer.write(", isQualified=");
    buffer.write(isQualified);
    buffer.write(")");
    return buffer.toString();
  }
}

@reflectiveTest
class SearchTest extends BaseAnalysisDriverTest {
  static const testUri = 'package:test/test.dart';

  CompilationUnit testUnit;
  CompilationUnitElement testUnitElement;
  LibraryElement testLibraryElement;

  test_searchReferences_ClassElement_definedInside() async {
    await _resolveTestUnit('''
class A {};
main(A p) {
  A v;
}
class B1 extends A {} // extends
class B2 implements A {} // implements
class B3 extends Object with A {} // with
List<A> v2 = null;
''');
    ClassElement element = _findElementAtString('A {}');
    Element p = _findElement('p');
    Element main = _findElement('main');
    Element b1 = _findElement('B1');
    Element b2 = _findElement('B2');
    Element b3 = _findElement('B3');
    Element v2 = _findElement('v2');
    var expected = [
      _expectId(p, SearchResultKind.REFERENCE, 'A p'),
      _expectId(main, SearchResultKind.REFERENCE, 'A v'),
      _expectId(b1, SearchResultKind.REFERENCE, 'A {} // extends'),
      _expectId(b2, SearchResultKind.REFERENCE, 'A {} // implements'),
      _expectId(b3, SearchResultKind.REFERENCE, 'A {} // with'),
      _expectId(v2, SearchResultKind.REFERENCE, 'A> v2'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ClassElement_definedOutside() async {
    provider.newFile(
        _p('$testProject/lib.dart'),
        r'''
class A {};
''');
    await _resolveTestUnit('''
import 'lib.dart';
main(A p) {
  A v;
}
''');
    ClassElement element = _findElementAtString('A p');
    Element p = _findElement('p');
    Element main = _findElement('main');
    var expected = [
      _expectId(p, SearchResultKind.REFERENCE, 'A p'),
      _expectId(main, SearchResultKind.REFERENCE, 'A v')
    ];
    await _verifyReferences(element, expected);
  }

  @failingTest
  test_searchReferences_CompilationUnitElement() async {
    provider.newFile(
        _p('$testProject/my_part.dart'),
        '''
part of lib;
''');
    await _resolveTestUnit('''
library lib;
part 'my_part.dart';
''');
    CompilationUnitElement element = _findElementAtString('my_part');
    var expected = [
      _expectIdQ(element.library.definingCompilationUnit,
          SearchResultKind.REFERENCE, "'my_part.dart'",
          length: "'my_part.dart'".length)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ConstructorElement() async {
    await _resolveTestUnit('''
class A {
  A.named() {}
}
main() {
  new A.named();
}
''');
    ConstructorElement element = _findElement('named');
    Element mainElement = _findElement('main');
    var expected = [
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, '.named();',
          length: 6)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ConstructorElement_synthetic() async {
    await _resolveTestUnit('''
class A {
}
main() {
  new A();
}
''');
    ClassElement classElement = _findElement('A');
    ConstructorElement element = classElement.unnamedConstructor;
    Element mainElement = _findElement('main');
    var expected = [
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, '();', length: 0)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FieldElement() async {
    await _resolveTestUnit('''
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
    FieldElement element = _findElement('field', ElementKind.FIELD);
    Element main = _findElement('main');
    Element fieldParameter = _findElement('field', ElementKind.PARAMETER);
    var expected = [
      _expectIdQ(fieldParameter, SearchResultKind.WRITE, 'field}'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'field: 1'),
      _expectId(main, SearchResultKind.READ, 'field); // ref-nq'),
      _expectIdQ(main, SearchResultKind.READ, 'field); // ref-q'),
      _expectId(main, SearchResultKind.INVOCATION, 'field(); // inv-nq'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'field(); // inv-q'),
      _expectId(main, SearchResultKind.WRITE, 'field = 2; // ref-nq'),
      _expectIdQ(main, SearchResultKind.WRITE, 'field = 3; // ref-q'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FieldElement_ofEnum() async {
    await _resolveTestUnit('''
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
    ClassElement enumElement = _findElement('MyEnum');
    Element mainElement = _findElement('main');
    await _verifyReferences(enumElement.getField('index'),
        [_expectIdQ(mainElement, SearchResultKind.READ, 'index);')]);
    await _verifyReferences(enumElement.getField('values'),
        [_expectIdQ(mainElement, SearchResultKind.READ, 'values);')]);
    await _verifyReferences(enumElement.getField('A'), [
      _expectIdQ(mainElement, SearchResultKind.READ, 'A.index);'),
      _expectIdQ(mainElement, SearchResultKind.READ, 'A);')
    ]);
    await _verifyReferences(enumElement.getField('B'),
        [_expectIdQ(mainElement, SearchResultKind.READ, 'B);')]);
  }

  test_searchReferences_FieldElement_synthetic() async {
    await _resolveTestUnit('''
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
    FieldElement element = _findElement('field', ElementKind.FIELD);
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.READ, 'field); // ref-nq'),
      _expectIdQ(main, SearchResultKind.READ, 'field); // ref-q'),
      _expectId(main, SearchResultKind.INVOCATION, 'field(); // inv-nq'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'field(); // inv-q'),
      _expectId(main, SearchResultKind.WRITE, 'field = 2; // ref-nq'),
      _expectIdQ(main, SearchResultKind.WRITE, 'field = 3; // ref-q'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FunctionElement() async {
    await _resolveTestUnit('''
test() {}
main() {
  test();
  print(test);
}
''');
    FunctionElement element = _findElement('test');
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(mainElement, SearchResultKind.INVOCATION, 'test();'),
      _expectId(mainElement, SearchResultKind.REFERENCE, 'test);')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_FunctionElement_local() async {
    await _resolveTestUnit('''
main() {
  test() {}
  test();
  print(test);
}
''');
    FunctionElement element = _findElement('test');
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.INVOCATION, 'test();'),
      _expectId(main, SearchResultKind.REFERENCE, 'test);')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_LabelElement() async {
    await _resolveTestUnit('''
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
    Element element = _findElement('label');
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'label; // 1'),
      _expectId(main, SearchResultKind.REFERENCE, 'label; // 2')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_LocalVariableElement() async {
    await _resolveTestUnit(r'''
main() {
  var v;
  v = 1;
  v += 2;
  print(v);
  v();
}
''');
    Element element = _findElement('v');
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'v = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'v += 2;'),
      _expectId(main, SearchResultKind.READ, 'v);'),
      _expectId(main, SearchResultKind.INVOCATION, 'v();')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_localVariableElement_inForEachLoop() async {
    await _resolveTestUnit('''
main() {
  for (var v in []) {
    v = 1;
    v += 2;
    print(v);
    v();
  }
}
''');
    Element element = _findElementAtString('v in []');
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.WRITE, 'v = 1;'),
      _expectId(main, SearchResultKind.READ_WRITE, 'v += 2;'),
      _expectId(main, SearchResultKind.READ, 'v);'),
      _expectId(main, SearchResultKind.INVOCATION, 'v();')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_MethodElement() async {
    await _resolveTestUnit('''
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
    MethodElement method = _findElement('m');
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(mainElement, SearchResultKind.INVOCATION, 'm(); // 1'),
      _expectIdQ(mainElement, SearchResultKind.INVOCATION, 'm(); // 2'),
      _expectId(mainElement, SearchResultKind.REFERENCE, 'm); // 3'),
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, 'm); // 4')
    ];
    await _verifyReferences(method, expected);
  }

  test_searchReferences_MethodMember() async {
    await _resolveTestUnit('''
class A<T> {
  T m() => null;
}
main(A<int> a) {
  a.m(); // ref
}
''');
    MethodMember method = _findElementAtString('m(); // ref');
    Element mainElement = _findElement('main');
    var expected = [
      _expectIdQ(mainElement, SearchResultKind.INVOCATION, 'm(); // ref')
    ];
    await _verifyReferences(method, expected);
  }

  test_searchReferences_ParameterElement_ofConstructor() async {
    await _resolveTestUnit('''
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
    ParameterElement element = _findElement('p');
    ClassElement classC = _findElement('C');
    ConstructorElement constructorA = classC.unnamedConstructor;
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(constructorA, SearchResultKind.READ, 'p + 1 {'),
      _expectId(constructorA, SearchResultKind.WRITE, 'p = 2;'),
      _expectId(constructorA, SearchResultKind.READ_WRITE, 'p += 3;'),
      _expectId(constructorA, SearchResultKind.READ, 'p);'),
      _expectId(constructorA, SearchResultKind.INVOCATION, 'p();'),
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, 'p: 42')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ParameterElement_ofLocalFunction() async {
    await _resolveTestUnit('''
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
    ParameterElement element = _findElement('p');
    Element fooElement = _findElement('foo');
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(fooElement, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(fooElement, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(fooElement, SearchResultKind.READ, 'p);'),
      _expectId(fooElement, SearchResultKind.INVOCATION, 'p();'),
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, 'p: 42')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ParameterElement_ofMethod() async {
    await _resolveTestUnit('''
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
    ParameterElement element = _findElement('p');
    Element fooElement = _findElement('foo');
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(fooElement, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(fooElement, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(fooElement, SearchResultKind.READ, 'p);'),
      _expectId(fooElement, SearchResultKind.INVOCATION, 'p();'),
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, 'p: 42')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_ParameterElement_ofTopLevelFunction() async {
    await _resolveTestUnit('''
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
    ParameterElement element = _findElement('p');
    Element fooElement = _findElement('foo');
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(fooElement, SearchResultKind.WRITE, 'p = 1;'),
      _expectId(fooElement, SearchResultKind.READ_WRITE, 'p += 2;'),
      _expectId(fooElement, SearchResultKind.READ, 'p);'),
      _expectId(fooElement, SearchResultKind.INVOCATION, 'p();'),
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, 'p: 42')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PrefixElement() async {
    String partCode = r'''
part of my_lib;
ppp.Future c;
''';
    provider.newFile(_p('$testProject/my_part.dart'), partCode);
    await _resolveTestUnit('''
library my_lib;
import 'dart:async' as ppp;
part 'my_part.dart';
main() {
  ppp.Future a;
  ppp.Stream b;
}
''');
    PrefixElement element = _findElementAtString('ppp;');
    Element a = _findElement('a');
    Element b = _findElement('b');
    Element c = findChildElement(testLibraryElement, 'c');
    var expected = [
      _expectId(a, SearchResultKind.REFERENCE, 'ppp.Future'),
      _expectId(b, SearchResultKind.REFERENCE, 'ppp.Stream'),
      new ExpectedResult(c, SearchResultKind.REFERENCE,
          partCode.indexOf('ppp.Future c'), 'ppp'.length)
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PropertyAccessorElement_getter() async {
    await _resolveTestUnit('''
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
    PropertyAccessorElement element = _findElement('ggg', ElementKind.GETTER);
    Element main = _findElement('main');
    var expected = [
      _expectId(main, SearchResultKind.REFERENCE, 'ggg); // ref-nq'),
      _expectIdQ(main, SearchResultKind.REFERENCE, 'ggg); // ref-q'),
      _expectId(main, SearchResultKind.INVOCATION, 'ggg(); // inv-nq'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'ggg(); // inv-q'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_PropertyAccessorElement_setter() async {
    await _resolveTestUnit('''
class A {
  set s(x) {}
  main() {
    s = 1;
    this.s = 2;
  }
}
''');
    PropertyAccessorElement element = _findElement('s=');
    Element mainElement = _findElement('main');
    var expected = [
      _expectId(mainElement, SearchResultKind.REFERENCE, 's = 1'),
      _expectIdQ(mainElement, SearchResultKind.REFERENCE, 's = 2')
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_TopLevelVariableElement() async {
    provider.newFile(
        _p('$testProject/lib.dart'),
        '''
library lib;
var V;
''');
    await _resolveTestUnit('''
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
    Element main = _findElement('main');
    var expected = [
      _expectIdQ(testUnitElement, SearchResultKind.REFERENCE, 'V; // imp'),
      _expectIdQ(main, SearchResultKind.WRITE, 'V = 1; // q'),
      _expectIdQ(main, SearchResultKind.READ, 'V); // q'),
      _expectIdQ(main, SearchResultKind.INVOCATION, 'V(); // q'),
      _expectId(main, SearchResultKind.WRITE, 'V = 1; // nq'),
      _expectId(main, SearchResultKind.READ, 'V); // nq'),
      _expectId(main, SearchResultKind.INVOCATION, 'V(); // nq'),
    ];
    await _verifyReferences(variable, expected);
  }

  test_searchReferences_TypeParameterElement_ofClass() async {
    await _resolveTestUnit('''
class A<T> {
  foo(T a) {}
  bar(T b) {}
}
''');
    TypeParameterElement element = _findElement('T');
    Element a = _findElement('a');
    Element b = _findElement('b');
    var expected = [
      _expectId(a, SearchResultKind.REFERENCE, 'T a'),
      _expectId(b, SearchResultKind.REFERENCE, 'T b'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_TypeParameterElement_ofLocalFunction() async {
    await _resolveTestUnit('''
main() {
  void foo<T>(T a) {
    void bar(T b) {}
  }
}
''');
    TypeParameterElement element = _findElement('T');
    Element a = _findElement('a');
    Element b = _findElement('b');
    var expected = [
      _expectId(a, SearchResultKind.REFERENCE, 'T a'),
      _expectId(b, SearchResultKind.REFERENCE, 'T b'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_TypeParameterElement_ofMethod() async {
    await _resolveTestUnit('''
class A {
  foo<T>(T p) {}
}
''');
    TypeParameterElement element = _findElement('T');
    Element p = _findElement('p');
    var expected = [
      _expectId(p, SearchResultKind.REFERENCE, 'T p'),
    ];
    await _verifyReferences(element, expected);
  }

  test_searchReferences_TypeParameterElement_ofTopLevelFunction() async {
    await _resolveTestUnit('''
foo<T>(T a) {
  bar(T b) {}
}
''');
    TypeParameterElement element = _findElement('T');
    Element a = _findElement('a');
    Element b = _findElement('b');
    var expected = [
      _expectId(a, SearchResultKind.REFERENCE, 'T a'),
      _expectId(b, SearchResultKind.REFERENCE, 'T b'),
    ];
    await _verifyReferences(element, expected);
  }

  ExpectedResult _expectId(
      Element enclosingElement, SearchResultKind kind, String search,
      {int length, bool isResolved: true, bool isQualified: false}) {
    int offset = findOffset(search);
    if (length == null) {
      length = getLeadingIdentifierLength(search);
    }
    return new ExpectedResult(enclosingElement, kind, offset, length,
        isResolved: isResolved, isQualified: isQualified);
  }

  /**
   * Create [ExpectedResult] for a qualified and resolved match.
   */
  ExpectedResult _expectIdQ(
      Element element, SearchResultKind kind, String search,
      {int length, bool isResolved: true}) {
    return _expectId(element, kind, search, isQualified: true, length: length);
  }

  Element _findElement(String name, [ElementKind kind]) {
    return findChildElement(testUnit.element, name, kind);
  }

  Element _findElementAtString(String search) {
    int offset = findOffset(search);
    AstNode node = new NodeLocator(offset).searchWithin(testUnit);
    return ElementLocator.locate(node);
  }

  String _p(String path) => provider.convertPath(path);

  Future<Null> _resolveTestUnit(String code) async {
    addTestFile(code);
    if (testUnit == null) {
      AnalysisResult result = await driver.getResult(testFile);
      testUnit = result.unit;
      testUnitElement = testUnit.element;
      testLibraryElement = testUnitElement.library;
    }
  }

  Future _verifyReferences(
      Element element, List<ExpectedResult> expectedMatches) async {
    List<SearchResult> results = await driver.search.references(element);
    _assertResults(results, expectedMatches);
    expect(results, hasLength(expectedMatches.length));
  }

  static void _assertResults(
      List<SearchResult> matches, List<ExpectedResult> expectedMatches) {
    expect(matches, unorderedEquals(expectedMatches));
  }
}
