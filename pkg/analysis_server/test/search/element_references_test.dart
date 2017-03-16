// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.search.element_references;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_search_domain.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementReferencesTest);
    defineReflectiveTests(_NoSearchEngine);
  });
}

@reflectiveTest
class ElementReferencesTest extends AbstractSearchDomainTest {
  Element searchElement;

  void assertHasRef(SearchResultKind kind, String search, bool isPotential) {
    assertHasResult(kind, search);
    expect(result.isPotential, isPotential);
  }

  Future<Null> findElementReferences(
      String search, bool includePotential) async {
    int offset = findOffset(search);
    await waitForTasksFinished();
    Request request = new SearchFindElementReferencesParams(
            testFile, offset, includePotential)
        .toRequest('0');
    Response response = await waitResponse(request);
    var result = new SearchFindElementReferencesResult.fromResponse(response);
    searchId = result.id;
    searchElement = result.element;
    if (searchId != null) {
      await waitForSearchResults();
    }
    expect(serverErrors, isEmpty);
  }

  test_constructor_named() async {
    addTestFile('''
class A {
  A.named(p);
}
main() {
  new A.named(1);
  new A.named(2);
}
''');
    await findElementReferences('named(p)', false);
    expect(searchElement.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, '.named(1)', 6);
    assertHasResult(SearchResultKind.REFERENCE, '.named(2)', 6);
  }

  test_constructor_named_potential() async {
    // Constructors in other classes shouldn't be considered potential matches,
    // nor should unresolved method calls, since constructor call sites are
    // statically bound to their targets).
    addTestFile('''
class A {
  A.named(p); // A
}
class B {
  B.named(p);
}
f(x) {
  new A.named(1);
  new B.named(2);
  x.named(3);
}
''');
    await findElementReferences('named(p); // A', true);
    expect(searchElement.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, '.named(1)', 6);
  }

  test_constructor_unnamed() async {
    addTestFile('''
class A {
  A(p);
}
main() {
  new A(1);
  new A(2);
}
''');
    await findElementReferences('A(p)', false);
    expect(searchElement.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, '(1)', 0);
    assertHasResult(SearchResultKind.REFERENCE, '(2)', 0);
  }

  test_constructor_unnamed_potential() async {
    // Constructors in other classes shouldn't be considered potential matches,
    // even if they are also unnamed (since constructor call sites are
    // statically bound to their targets).
    // Also, assignments to local variables shouldn't be considered potential
    // matches.
    addTestFile('''
class A {
  A(p); // A
}
class B {
  B(p);
  foo() {
    int k;
    k = 3;
  }
}
main() {
  new A(1);
  new B(2);
}
''');
    await findElementReferences('A(p)', true);
    expect(searchElement.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, '(1)', 0);
  }

  test_field_explicit() async {
    addTestFile('''
class A {
  var fff; // declaration
  A(this.fff); // in constructor
  A.named() : fff = 1;
  m() {
    fff = 2;
    fff += 3;
    print(fff); // in m()
    fff(); // in m()
  }
}
main(A a) {
  a.fff = 20;
  a.fff += 30;
  print(a.fff); // in main()
  a.fff(); // in main()
}
''');
    await findElementReferences('fff; // declaration', false);
    expect(searchElement.kind, ElementKind.FIELD);
    expect(results, hasLength(10));
    assertHasResult(SearchResultKind.WRITE, 'fff); // in constructor');
    assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
    // m()
    assertHasResult(SearchResultKind.WRITE, 'fff = 2;');
    assertHasResult(SearchResultKind.WRITE, 'fff += 3;');
    assertHasResult(SearchResultKind.READ, 'fff); // in m()');
    assertHasResult(SearchResultKind.INVOCATION, 'fff(); // in m()');
    // main()
    assertHasResult(SearchResultKind.WRITE, 'fff = 20;');
    assertHasResult(SearchResultKind.WRITE, 'fff += 30;');
    assertHasResult(SearchResultKind.READ, 'fff); // in main()');
    assertHasResult(SearchResultKind.INVOCATION, 'fff(); // in main()');
  }

  test_field_implicit() async {
    addTestFile('''
class A {
  var  get fff => null;
  void set fff(x) {}
  m() {
    print(fff); // in m()
    fff = 1;
  }
}
main(A a) {
  print(a.fff); // in main()
  a.fff = 10;
}
''');
    {
      await findElementReferences('fff =>', false);
      expect(searchElement.kind, ElementKind.FIELD);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in main()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
    {
      await findElementReferences('fff(x) {}', false);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in main()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
  }

  test_field_inFormalParameter() async {
    addTestFile('''
class A {
  var fff; // declaration
  A(this.fff); // in constructor
  m() {
    fff = 2;
    print(fff); // in m()
  }
}
''');
    await findElementReferences('fff); // in constructor', false);
    expect(searchElement.kind, ElementKind.FIELD);
    expect(results, hasLength(3));
    assertHasResult(SearchResultKind.WRITE, 'fff); // in constructor');
    assertHasResult(SearchResultKind.WRITE, 'fff = 2;');
    assertHasResult(SearchResultKind.READ, 'fff); // in m()');
  }

  test_function() async {
    addTestFile('''
fff(p) {}
main() {
  fff(1);
  print(fff);
}
''');
    await findElementReferences('fff(p) {}', false);
    expect(searchElement.kind, ElementKind.FUNCTION);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.INVOCATION, 'fff(1)');
    assertHasResult(SearchResultKind.REFERENCE, 'fff);');
  }

  test_hierarchy_field_explicit() async {
    addTestFile('''
  class A {
    int fff; // in A
  }
  class B extends A {
    int fff; // in B
  }
  class C extends B {
    int fff; // in C
  }
  main(A a, B b, C c) {
    a.fff = 10;
    b.fff = 20;
    c.fff = 30;
  }
  ''');
    await findElementReferences('fff; // in B', false);
    expect(searchElement.kind, ElementKind.FIELD);
    assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    assertHasResult(SearchResultKind.WRITE, 'fff = 20;');
    assertHasResult(SearchResultKind.WRITE, 'fff = 30;');
  }

  test_hierarchy_method() async {
    addTestFile('''
class A {
  mmm(_) {} // in A
}
class B extends A {
  mmm(_) {} // in B
}
class C extends B {
  mmm(_) {} // in C
}
main(A a, B b, C c) {
  a.mmm(10);
  b.mmm(20);
  c.mmm(30);
}
''');
    await findElementReferences('mmm(_) {} // in B', false);
    expect(searchElement.kind, ElementKind.METHOD);
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(10)');
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(20)');
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(30)');
  }

  test_hierarchy_method_static() async {
    addTestFile('''
class A {
  static void mmm(_) {} // in A
}
class B extends A {
  static void mmm(_) {} // in B
}
class C extends B {
  static void mmm(_) {} // in C
}
main() {
  A.mmm(10);
  B.mmm(20);
  C.mmm(30);
}
''');
    await findElementReferences('mmm(_) {} // in B', false);
    expect(searchElement.kind, ElementKind.METHOD);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(20)');
  }

  test_label() async {
    addTestFile('''
main() {
myLabel:
  for (int i = 0; i < 10; i++) {
    if (i == 2) {
      continue myLabel; // continue
    }
    break myLabel; // break
  }
}
''');
    await findElementReferences('myLabel; // break', false);
    expect(searchElement.kind, ElementKind.LABEL);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'myLabel; // continue');
    assertHasResult(SearchResultKind.REFERENCE, 'myLabel; // break');
  }

  test_localVariable() async {
    addTestFile('''
main() {
  var vvv = 1;
  print(vvv);
  vvv += 3;
  vvv = 2;
  vvv();
}
''');
    await findElementReferences('vvv = 1', false);
    expect(searchElement.kind, ElementKind.LOCAL_VARIABLE);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.READ, 'vvv);');
    assertHasResult(SearchResultKind.READ_WRITE, 'vvv += 3');
    assertHasResult(SearchResultKind.WRITE, 'vvv = 2');
    assertHasResult(SearchResultKind.INVOCATION, 'vvv();');
  }

  test_method() async {
    addTestFile('''
class A {
  mmm(p) {}
  m() {
    mmm(1);
    print(mmm); // in m()
  }
}
main(A a) {
  a.mmm(10);
  print(a.mmm); // in main()
}
''');
    await findElementReferences('mmm(p) {}', false);
    expect(searchElement.kind, ElementKind.METHOD);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(1);');
    assertHasResult(SearchResultKind.REFERENCE, 'mmm); // in m()');
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(10);');
    assertHasResult(SearchResultKind.REFERENCE, 'mmm); // in main()');
  }

  test_method_propagatedType() async {
    addTestFile('''
class A {
  mmm(p) {}
}
main() {
  var a = new A();
  a.mmm(10);
  print(a.mmm);
}
''');
    await findElementReferences('mmm(p) {}', false);
    expect(searchElement.kind, ElementKind.METHOD);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(10);');
    assertHasResult(SearchResultKind.REFERENCE, 'mmm);');
  }

  test_noElement() async {
    addTestFile('''
main() {
  print(noElement);
}
''');
    await findElementReferences('noElement', false);
    expect(searchId, isNull);
  }

  test_oneUnit_zeroLibraries() async {
    addTestFile('''
part of lib;
fff(p) {}
main() {
  fff(10);
}
''');
    await findElementReferences('fff(p) {}', false);
    expect(results, isEmpty);
  }

  test_parameter() async {
    addTestFile('''
main(ppp) {
  print(ppp);
  ppp += 3;
  ppp = 2;
  ppp();
}
''');
    await findElementReferences('ppp) {', false);
    expect(searchElement.kind, ElementKind.PARAMETER);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.READ, 'ppp);');
    assertHasResult(SearchResultKind.READ_WRITE, 'ppp += 3');
    assertHasResult(SearchResultKind.WRITE, 'ppp = 2');
    assertHasResult(SearchResultKind.INVOCATION, 'ppp();');
  }

  test_path_inConstructor_named() async {
    addTestFile('''
library my_lib;
class A {}
class B {
  B.named() {
    A a = null;
  }
}
''');
    await findElementReferences('A {}', false);
    assertHasResult(SearchResultKind.REFERENCE, 'A a = null;');
    expect(
        getPathString(result.path),
        '''
LOCAL_VARIABLE a
CONSTRUCTOR named
CLASS B
COMPILATION_UNIT test.dart
LIBRARY my_lib''');
  }

  test_path_inConstructor_unnamed() async {
    addTestFile('''
library my_lib;
class A {}
class B {
  B() {
    A a = null;
  }
}
''');
    await findElementReferences('A {}', false);
    assertHasResult(SearchResultKind.REFERENCE, 'A a = null;');
    expect(
        getPathString(result.path),
        '''
LOCAL_VARIABLE a
CONSTRUCTOR
CLASS B
COMPILATION_UNIT test.dart
LIBRARY my_lib''');
  }

  test_path_inFunction() async {
    addTestFile('''
library my_lib;
class A {}
main() {
  A a = null;
}
''');
    await findElementReferences('A {}', false);
    assertHasResult(SearchResultKind.REFERENCE, 'A a = null;');
    expect(
        getPathString(result.path),
        '''
LOCAL_VARIABLE a
FUNCTION main
COMPILATION_UNIT test.dart
LIBRARY my_lib''');
  }

  test_potential_disabled() async {
    addTestFile('''
class A {
  test(p) {}
}
main(A a, p) {
  a.test(1);
  p.test(2);
}
''');
    await findElementReferences('test(p) {}', false);
    assertHasResult(SearchResultKind.INVOCATION, 'test(1);');
    assertNoResult(SearchResultKind.INVOCATION, 'test(2);');
  }

  test_potential_field() async {
    addTestFile('''
class A {
  var test; // declaration
}
main(A a, p) {
  a.test = 1;
  p.test = 2;
  print(p.test); // p
}
''');
    await findElementReferences('test; // declaration', true);
    {
      assertHasResult(SearchResultKind.WRITE, 'test = 1;');
      expect(result.isPotential, isFalse);
    }
    {
      assertHasResult(SearchResultKind.WRITE, 'test = 2;');
      expect(result.isPotential, isTrue);
    }
    {
      assertHasResult(SearchResultKind.READ, 'test); // p');
      expect(result.isPotential, isTrue);
    }
  }

  test_potential_method() async {
    addTestFile('''
class A {
  test(p) {}
}
main(A a, p) {
  a.test(1);
  p.test(2);
}
''');
    await findElementReferences('test(p) {}', true);
    {
      assertHasResult(SearchResultKind.INVOCATION, 'test(1);');
      expect(result.isPotential, isFalse);
    }
    {
      assertHasResult(SearchResultKind.INVOCATION, 'test(2);');
      expect(result.isPotential, isTrue);
    }
  }

  test_potential_method_definedInSubclass() async {
    addTestFile('''
class Base {
  methodInBase() {
    test(1);
  }
}
class Derived extends Base {
  test(_) {} // of Derived
  methodInDerived() {
    test(2);
  }
}
globalFunction(Base b) {
  b.test(3);
}
''');
    await findElementReferences('test(_) {} // of Derived', true);
    assertHasRef(SearchResultKind.INVOCATION, 'test(1);', true);
    assertHasRef(SearchResultKind.INVOCATION, 'test(2);', false);
    assertHasRef(SearchResultKind.INVOCATION, 'test(3);', true);
  }

  test_prefix() async {
    addTestFile('''
import 'dart:async' as ppp;
main() {
  ppp.Future a;
  ppp.Stream b;
}
''');
    await findElementReferences("ppp;", false);
    expect(searchElement.kind, ElementKind.PREFIX);
    expect(searchElement.name, 'ppp');
    expect(searchElement.location.startLine, 1);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'ppp.Future');
    assertHasResult(SearchResultKind.REFERENCE, 'ppp.Stream');
  }

  test_topLevelVariable_explicit() async {
    addTestFile('''
var vvv = 1;
main() {
  print(vvv);
  vvv += 3;
  vvv = 2;
  vvv();
}
''');
    await findElementReferences('vvv = 1', false);
    expect(searchElement.kind, ElementKind.TOP_LEVEL_VARIABLE);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.READ, 'vvv);');
    assertHasResult(SearchResultKind.WRITE, 'vvv += 3');
    assertHasResult(SearchResultKind.WRITE, 'vvv = 2');
    assertHasResult(SearchResultKind.INVOCATION, 'vvv();');
  }

  test_topLevelVariable_implicit() async {
    addTestFile('''
get vvv => null;
set vvv(x) {}
main() {
  print(vvv);
  vvv = 1;
}
''');
    {
      await findElementReferences('vvv =>', false);
      expect(searchElement.kind, ElementKind.TOP_LEVEL_VARIABLE);
      expect(results, hasLength(2));
      assertHasResult(SearchResultKind.READ, 'vvv);');
      assertHasResult(SearchResultKind.WRITE, 'vvv = 1;');
    }
    {
      await findElementReferences('vvv(x) {}', false);
      expect(results, hasLength(2));
      assertHasResult(SearchResultKind.READ, 'vvv);');
      assertHasResult(SearchResultKind.WRITE, 'vvv = 1;');
    }
  }

  test_typeReference_class() async {
    addTestFile('''
main() {
  int a = 1;
  int b = 2;
}
''');
    await findElementReferences('int a', false);
    expect(searchElement.kind, ElementKind.CLASS);
    assertHasResult(SearchResultKind.REFERENCE, 'int a');
    assertHasResult(SearchResultKind.REFERENCE, 'int b');
  }

  test_typeReference_functionType() async {
    addTestFile('''
typedef F();
main(F f) {
}
''');
    await findElementReferences('F()', false);
    expect(searchElement.kind, ElementKind.FUNCTION_TYPE_ALIAS);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, 'F f');
  }

  test_typeReference_typeVariable() async {
    addTestFile('''
class A<T> {
  T f;
  T m() => null;
}
''');
    await findElementReferences('T> {', false);
    expect(searchElement.kind, ElementKind.TYPE_PARAMETER);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'T f;');
    assertHasResult(SearchResultKind.REFERENCE, 'T m()');
  }
}

@reflectiveTest
class _NoSearchEngine extends AbstractSearchDomainTest {
  @override
  Index createIndex() {
    return null;
  }

  test_requestError_noSearchEngine() async {
    addTestFile('''
main() {
  var vvv = 1;
  print(vvv);
}
''');
    Request request = new SearchFindElementReferencesParams(testFile, 0, false)
        .toRequest('0');
    Response response = await waitResponse(request);
    expect(response.error, isNotNull);
    expect(response.error.code, RequestErrorCode.NO_INDEX_GENERATED);
  }
}
