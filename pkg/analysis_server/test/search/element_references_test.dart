// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_search_domain.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementReferencesTest);
  });
}

@reflectiveTest
class ElementReferencesTest extends AbstractSearchDomainTest {
  Element? searchElement;

  void assertHasRef(SearchResultKind kind, String search, bool isPotential) {
    assertHasResult(kind, search);
    expect(result.isPotential, isPotential);
  }

  Future<void> findElementReferences(
      String search, bool includePotential) async {
    var offset = findOffset(search);
    await waitForTasksFinished();
    var request =
        SearchFindElementReferencesParams(testFile, offset, includePotential)
            .toRequest('0');
    var response = await waitResponse(request);
    var result = SearchFindElementReferencesResult.fromResponse(response);
    searchId = result.id;
    searchElement = result.element;
    if (searchId != null) {
      await waitForSearchResults();
    }
  }

  Future<void> test_constructor_named() async {
    addTestFile('''
class A {
  A.named(p);
}
void f() {
  new A.named(1);
  new A.named(2);
}
''');
    await findElementReferences('named(p)', false);
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, '.named(1)', 6);
    assertHasResult(SearchResultKind.REFERENCE, '.named(2)', 6);
  }

  Future<void> test_constructor_named_potential() async {
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
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, '.named(1)', 6);
  }

  Future<void> test_constructor_unnamed() async {
    addTestFile('''
class A {
  A(p);
}
void f() {
  new A(1);
  new A(2);
}
''');
    await findElementReferences('A(p)', false);
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, '(1)', 0);
    assertHasResult(SearchResultKind.REFERENCE, '(2)', 0);
  }

  Future<void> test_constructor_unnamed_potential() async {
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
void f() {
  new A(1);
  new B(2);
}
''');
    await findElementReferences('A(p)', true);
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, '(1)', 0);
  }

  Future<void> test_extension() async {
    addTestFile('''
extension E on int {
  static void foo() {}
  void bar() {}
}

void f() {
  E.foo();
  E(0).bar();
}
''');
    await findElementReferences('E on int', false);
    expect(searchElement!.kind, ElementKind.EXTENSION);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'E.foo();');
    assertHasResult(SearchResultKind.REFERENCE, 'E(0)');
  }

  Future<void> test_field_explicit() async {
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
void f(A a) {
  a.fff = 20;
  a.fff += 30;
  print(a.fff); // in f()
  a.fff(); // in f()
}
''');
    await findElementReferences('fff; // declaration', false);
    expect(searchElement!.kind, ElementKind.FIELD);
    expect(results, hasLength(10));
    assertHasResult(SearchResultKind.WRITE, 'fff); // in constructor');
    assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
    // m()
    assertHasResult(SearchResultKind.WRITE, 'fff = 2;');
    assertHasResult(SearchResultKind.WRITE, 'fff += 3;');
    assertHasResult(SearchResultKind.READ, 'fff); // in m()');
    assertHasResult(SearchResultKind.READ, 'fff(); // in m()');
    // f()
    assertHasResult(SearchResultKind.WRITE, 'fff = 20;');
    assertHasResult(SearchResultKind.WRITE, 'fff += 30;');
    assertHasResult(SearchResultKind.READ, 'fff); // in f()');
    assertHasResult(SearchResultKind.READ, 'fff(); // in f()');
  }

  Future<void> test_field_implicit() async {
    addTestFile('''
class A {
  var  get fff => null;
  void set fff(x) {}
  m() {
    print(fff); // in m()
    fff = 1;
  }
}
void f(A a) {
  print(a.fff); // in f()
  a.fff = 10;
}
''');
    {
      await findElementReferences('fff =>', false);
      expect(searchElement!.kind, ElementKind.FIELD);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
    {
      await findElementReferences('fff(x) {}', false);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
  }

  Future<void> test_field_inFormalParameter() async {
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
    expect(searchElement!.kind, ElementKind.FIELD);
    expect(results, hasLength(3));
    assertHasResult(SearchResultKind.WRITE, 'fff); // in constructor');
    assertHasResult(SearchResultKind.WRITE, 'fff = 2;');
    assertHasResult(SearchResultKind.READ, 'fff); // in m()');
  }

  Future<void> test_field_ofExtension_explicit_static() async {
    addTestFile('''
extension E on int {
  static var fff; // declaration

  void m() {
    fff = 2;
    fff += 3;
    print(fff); // in m()
    fff(); // in m()
  }
}

void f() {
  E.fff = 20;
  E.fff += 30;
  print(E.fff); // in f()
  E.fff(); // in f()
}
''');
    await findElementReferences('fff; // declaration', false);
    expect(searchElement!.kind, ElementKind.FIELD);
    expect(results, hasLength(8));
    // m()
    assertHasResult(SearchResultKind.WRITE, 'fff = 2;');
    assertHasResult(SearchResultKind.WRITE, 'fff += 3;');
    assertHasResult(SearchResultKind.READ, 'fff); // in m()');
    assertHasResult(SearchResultKind.READ, 'fff(); // in m()');
    // f()
    assertHasResult(SearchResultKind.WRITE, 'fff = 20;');
    assertHasResult(SearchResultKind.WRITE, 'fff += 30;');
    assertHasResult(SearchResultKind.READ, 'fff); // in f()');
    assertHasResult(SearchResultKind.READ, 'fff(); // in f()');
  }

  Future<void> test_field_ofExtension_implicit_instance() async {
    addTestFile('''
extension E on int {
  var get fff => null;
  set fff(x) {}
  m() {
    print(fff); // in m()
    fff = 1;
  }
}
void f() {
  print(0.fff); // in f()
  0.fff = 10;
}
''');
    {
      await findElementReferences('fff =>', false);
      expect(searchElement!.kind, ElementKind.FIELD);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
    {
      await findElementReferences('fff(x) {}', false);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
  }

  Future<void> test_field_ofExtension_implicit_static() async {
    addTestFile('''
extension E on int {
  static var get fff => null;
  static set fff(x) {}
  m() {
    print(fff); // in m()
    fff = 1;
  }
}
void f() {
  print(E.fff); // in f()
  E.fff = 10;
}
''');
    {
      await findElementReferences('fff =>', false);
      expect(searchElement!.kind, ElementKind.FIELD);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
    {
      await findElementReferences('fff(x) {}', false);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
  }

  Future<void> test_function() async {
    addTestFile('''
fff(p) {}
void f() {
  fff(1);
  print(fff);
}
''');
    await findElementReferences('fff(p) {}', false);
    expect(searchElement!.kind, ElementKind.FUNCTION);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.INVOCATION, 'fff(1)');
    assertHasResult(SearchResultKind.REFERENCE, 'fff);');
  }

  Future<void> test_hierarchy_field_explicit() async {
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
  void f(A a, B b, C c) {
    a.fff = 10;
    b.fff = 20;
    c.fff = 30;
  }
  ''');
    await findElementReferences('fff; // in B', false);
    expect(searchElement!.kind, ElementKind.FIELD);
    assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    assertHasResult(SearchResultKind.WRITE, 'fff = 20;');
    assertHasResult(SearchResultKind.WRITE, 'fff = 30;');
  }

  Future<void> test_hierarchy_method() async {
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
void f(A a, B b, C c) {
  a.mmm(10);
  b.mmm(20);
  c.mmm(30);
}
''');
    await findElementReferences('mmm(_) {} // in B', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(10)');
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(20)');
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(30)');
  }

  Future<void> test_hierarchy_method_static() async {
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
void f() {
  A.mmm(10);
  B.mmm(20);
  C.mmm(30);
}
''');
    await findElementReferences('mmm(_) {} // in B', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(20)');
  }

  Future<void> test_hierarchy_namedParameter() async {
    addTestFile('''
class A {
  m({p}) {} // in A
}
class B extends A {
  m({p}) {} // in B
}
class C extends B {
  m({p}) {} // in C
}
void f(A a, B b, C c) {
  a.m(p: 1);
  b.m(p: 2);
  c.m(p: 3);
}
''');
    await findElementReferences('p}) {} // in B', false);
    expect(searchElement!.kind, ElementKind.PARAMETER);
    assertHasResult(SearchResultKind.REFERENCE, 'p: 1');
    assertHasResult(SearchResultKind.REFERENCE, 'p: 2');
    assertHasResult(SearchResultKind.REFERENCE, 'p: 3');
  }

  Future<void> test_label() async {
    addTestFile('''
void f() {
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
    expect(searchElement!.kind, ElementKind.LABEL);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'myLabel; // continue');
    assertHasResult(SearchResultKind.REFERENCE, 'myLabel; // break');
  }

  Future<void> test_localVariable() async {
    addTestFile('''
void f() {
  var vvv = 1;
  print(vvv);
  vvv += 3;
  vvv = 2;
  vvv();
}
''');
    await findElementReferences('vvv = 1', false);
    expect(searchElement!.kind, ElementKind.LOCAL_VARIABLE);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.READ, 'vvv);');
    assertHasResult(SearchResultKind.READ_WRITE, 'vvv += 3');
    assertHasResult(SearchResultKind.WRITE, 'vvv = 2');
    assertHasResult(SearchResultKind.READ, 'vvv();');
  }

  Future<void> test_method() async {
    addTestFile('''
class A {
  mmm(p) {}
  m() {
    mmm(1);
    print(mmm); // in m()
  }
}
void f(A a) {
  a.mmm(10);
  print(a.mmm); // in f()
}
''');
    await findElementReferences('mmm(p) {}', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(1);');
    assertHasResult(SearchResultKind.REFERENCE, 'mmm); // in m()');
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(10);');
    assertHasResult(SearchResultKind.REFERENCE, 'mmm); // in f()');
  }

  Future<void> test_method_ofExtension() async {
    addTestFile('''
extension E on int {
  void foo() {}
}

void f() {
  E(0).foo(); // 1
  E(0).foo; // 2
  0.foo(); // 3
  0.foo; // 4
}
''');
    await findElementReferences('foo() {}', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.INVOCATION, 'foo(); // 1');
    assertHasResult(SearchResultKind.REFERENCE, 'foo; // 2');
    assertHasResult(SearchResultKind.INVOCATION, 'foo(); // 3');
    assertHasResult(SearchResultKind.REFERENCE, 'foo; // 4');
  }

  Future<void> test_method_propagatedType() async {
    addTestFile('''
class A {
  mmm(p) {}
}
void f() {
  var a = new A();
  a.mmm(10);
  print(a.mmm);
}
''');
    await findElementReferences('mmm(p) {}', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(10);');
    assertHasResult(SearchResultKind.REFERENCE, 'mmm);');
  }

  Future<void> test_mixin() async {
    addTestFile('''
mixin A {}
class B extends Object with A {} // B
''');
    await findElementReferences('A {}', false);
    expect(searchElement!.kind, ElementKind.MIXIN);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, 'A {} // B');
  }

  Future<void> test_noElement() async {
    addTestFile('''
void f() {
  print(noElement);
}
''');
    await findElementReferences('noElement', false);
    expect(searchId, isNull);
  }

  Future<void> test_oneUnit_zeroLibraries() async {
    addTestFile('''
part of lib;
fff(p) {}
void f() {
  fff(10);
}
''');
    await findElementReferences('fff(p) {}', false);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.INVOCATION, 'fff(10);');
  }

  Future<void> test_parameter() async {
    addTestFile('''
void f(ppp) {
  print(ppp);
  ppp += 3;
  ppp = 2;
  ppp();
}
''');
    await findElementReferences('ppp) {', false);
    expect(searchElement!.kind, ElementKind.PARAMETER);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.READ, 'ppp);');
    assertHasResult(SearchResultKind.READ_WRITE, 'ppp += 3');
    assertHasResult(SearchResultKind.WRITE, 'ppp = 2');
    assertHasResult(SearchResultKind.READ, 'ppp();');
  }

  @failingTest
  Future<void> test_path_inConstructor_named() async {
    // The path does not contain the first expected element.
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
    expect(getPathString(result.path), '''
LOCAL_VARIABLE a
CONSTRUCTOR named
CLASS B
COMPILATION_UNIT test.dart
LIBRARY my_lib''');
  }

  @failingTest
  Future<void> test_path_inConstructor_unnamed() async {
    // The path does not contain the first expected element.
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
    expect(getPathString(result.path), '''
LOCAL_VARIABLE a
CONSTRUCTOR
CLASS B
COMPILATION_UNIT test.dart
LIBRARY my_lib''');
  }

  Future<void> test_path_inExtension_named() async {
    addTestFile('''
class A {
  void foo() {}
}

extension E on A {
  void bar() {
    foo();
  }
}
''');
    await findElementReferences('foo() {}', false);
    assertHasResult(SearchResultKind.INVOCATION, 'foo();');
    expect(getPathString(result.path), '''
METHOD bar
EXTENSION E
COMPILATION_UNIT test.dart
LIBRARY''');
  }

  Future<void> test_path_inExtension_unnamed() async {
    addTestFile('''
class A {
  void foo() {}
}

extension on A {
  void bar() {
    foo();
  }
}
''');
    await findElementReferences('foo() {}', false);
    assertHasResult(SearchResultKind.INVOCATION, 'foo();');
    expect(getPathString(result.path), '''
METHOD bar
EXTENSION
COMPILATION_UNIT test.dart
LIBRARY''');
  }

  @failingTest
  Future<void> test_path_inFunction() async {
    // The path does not contain the first expected element.
    addTestFile('''
library my_lib;
class A {}
void f() {
  A a = null;
}
''');
    await findElementReferences('A {}', false);
    assertHasResult(SearchResultKind.REFERENCE, 'A a = null;');
    expect(getPathString(result.path), '''
LOCAL_VARIABLE a
FUNCTION f
COMPILATION_UNIT test.dart
LIBRARY my_lib''');
  }

  Future<void> test_potential_disabled() async {
    addTestFile('''
class A {
  test(p) {}
}
void f(A a, p) {
  a.test(1);
  p.test(2);
}
''');
    await findElementReferences('test(p) {}', false);
    assertHasResult(SearchResultKind.INVOCATION, 'test(1);');
    assertNoResult(SearchResultKind.INVOCATION, 'test(2);');
  }

  Future<void> test_potential_field() async {
    addTestFile('''
class A {
  var test; // declaration
}
void f(A a, p) {
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

  Future<void> test_potential_method() async {
    addTestFile('''
class A {
  test(p) {}
}
void f(A a, p) {
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

  Future<void> test_potential_method_definedInSubclass() async {
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

  Future<void> test_prefix() async {
    addTestFile('''
import 'dart:async' as ppp;
void f() {
  ppp.Future a;
  ppp.Stream b;
}
''');
    await findElementReferences('ppp;', false);
    final searchElement = this.searchElement!;
    expect(searchElement.kind, ElementKind.PREFIX);
    expect(searchElement.name, 'ppp');
    expect(searchElement.location!.startLine, 1);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'ppp.Future');
    assertHasResult(SearchResultKind.REFERENCE, 'ppp.Stream');
  }

  Future<void> test_topLevelVariable_explicit() async {
    addTestFile('''
var vvv = 1;
void f() {
  print(vvv);
  vvv += 3;
  vvv = 2;
  vvv();
}
''');
    await findElementReferences('vvv = 1', false);
    expect(searchElement!.kind, ElementKind.TOP_LEVEL_VARIABLE);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.READ, 'vvv);');
    assertHasResult(SearchResultKind.WRITE, 'vvv += 3');
    assertHasResult(SearchResultKind.WRITE, 'vvv = 2');
    assertHasResult(SearchResultKind.READ, 'vvv();');
  }

  Future<void> test_topLevelVariable_implicit() async {
    addTestFile('''
get vvv => null;
set vvv(x) {}
void f() {
  print(vvv);
  vvv = 1;
}
''');
    {
      await findElementReferences('vvv =>', false);
      expect(searchElement!.kind, ElementKind.TOP_LEVEL_VARIABLE);
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

  Future<void> test_typeReference_class() async {
    addTestFile('''
void f() {
  int a = 1;
  int b = 2;
}
''');
    await findElementReferences('int a', false);
    expect(searchElement!.kind, ElementKind.CLASS);
    assertHasResult(SearchResultKind.REFERENCE, 'int a');
    assertHasResult(SearchResultKind.REFERENCE, 'int b');
  }

  Future<void> test_typeReference_typeAlias_functionType() async {
    addTestFile('''
typedef F = Function();
void f(F f) {
}
''');
    await findElementReferences('F =', false);
    expect(searchElement!.kind, ElementKind.TYPE_ALIAS);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, 'F f');
  }

  Future<void> test_typeReference_typeAlias_interfaceType() async {
    addTestFile('''
typedef A<T> = Map<int, T>;

void(A<String> a) {}
''');
    // Can find `A`.
    await findElementReferences('A<T> =', false);
    expect(searchElement!.kind, ElementKind.TYPE_ALIAS);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, 'A<String>');

    // Can find in `A`.
    await findElementReferences('int,', false);
    expect(searchElement!.kind, ElementKind.CLASS);
    assertHasResult(SearchResultKind.REFERENCE, 'int,');
  }

  Future<void> test_typeReference_typeAlias_legacy() async {
    addTestFile('''
typedef F();
void f(F f) {
}
''');
    await findElementReferences('F()', false);
    expect(searchElement!.kind, ElementKind.TYPE_ALIAS);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, 'F f');
  }

  Future<void> test_typeReference_typeVariable() async {
    addTestFile('''
class A<T> {
  T f;
  T m() => null;
}
''');
    await findElementReferences('T> {', false);
    expect(searchElement!.kind, ElementKind.TYPE_PARAMETER);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'T f;');
    assertHasResult(SearchResultKind.REFERENCE, 'T m()');
  }
}
