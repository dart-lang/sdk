// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_search_domain.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MemberReferencesTest);
  });
}

@reflectiveTest
class MemberReferencesTest extends AbstractSearchDomainTest {
  void assertHasRef(SearchResultKind kind, String search, bool isPotential) {
    assertHasResult(kind, search);
    expect(result.isPotential, isPotential);
  }

  Future<void> findMemberReferences(String name) async {
    await waitForTasksFinished();
    var request = SearchFindMemberReferencesParams(name).toRequest('0');
    var response = await handleSuccessfulRequest(request);
    searchId = SearchFindMemberReferencesResult.fromResponse(response).id;
    return waitForSearchResults();
  }

  Future<void> test_class_fields_explicit() async {
    addTestFile('''
class A {
  var foo;
}

class B {
  var foo;
}

void whenResolved(A a, B b) {
  a.foo = 1;
  b.foo = 2;
  a.foo; // resolved A
  b.foo; // resolved B
}

void whenUnresolved(a, b) {
  a.foo = 10;
  b.foo = 20;
  a.foo; // unresolved A
  b.foo; // unresolved B
}
''');
    await findMemberReferences('foo');
    assertNoResult(SearchResultKind.WRITE, 'foo = 1;');
    assertNoResult(SearchResultKind.WRITE, 'foo = 2;');
    assertNoResult(SearchResultKind.READ, 'foo; // resolved A');
    assertNoResult(SearchResultKind.READ, 'foo; // resolved B');
    assertHasRef(SearchResultKind.WRITE, 'foo = 10;', true);
    assertHasRef(SearchResultKind.WRITE, 'foo = 20;', true);
    assertHasRef(SearchResultKind.READ, 'foo; // unresolved A', true);
    assertHasRef(SearchResultKind.READ, 'foo; // unresolved B', true);
  }

  Future<void> test_class_fields_implicit() async {
    addTestFile('''
class A {
  int get foo => 0;
}

class B {
  int get foo => 0;
}

void whenResolved(A a, B b) {
  a.foo; // resolved A
  b.foo; // resolved B
}

void whenUnresolved(a, b) {
  a.foo; // unresolved A
  b.foo; // unresolved B
}
''');
    await findMemberReferences('foo');
    assertNoResult(SearchResultKind.READ, 'foo; // resolved A');
    assertNoResult(SearchResultKind.READ, 'foo; // resolved B');
    assertHasRef(SearchResultKind.READ, 'foo; // unresolved A', true);
    assertHasRef(SearchResultKind.READ, 'foo; // unresolved B', true);
  }

  Future<void> test_class_methods() async {
    addTestFile('''
class A {
  void foo() {}
}

class B {
  void foo() {}
}

void whenResolved(A a, B b) {
  a.foo(1);
  b.foo(2);
}

void whenUnresolved(a, b) {
  a.foo(10);
  b.foo(20);
}
''');
    await findMemberReferences('foo');
    assertNoResult(SearchResultKind.INVOCATION, 'foo(1)');
    assertNoResult(SearchResultKind.INVOCATION, 'foo(2)');
    assertHasRef(SearchResultKind.INVOCATION, 'foo(10)', true);
    assertHasRef(SearchResultKind.INVOCATION, 'foo(20)', true);
  }

  Future<void> test_enum_fields_explicit() async {
    addTestFile('''
enum A {
  v;
  final foo = 0;
}

enum B {
  v;
  final foo = 0;
}

void whenResolved(A a, B b) {
  a.foo = 1;
  b.foo = 2;
  a.foo; // resolved A
  b.foo; // resolved B
}

whenUnresolved(a, b) {
  a.foo = 10;
  b.foo = 20;
  a.foo; // unresolved A
  b.foo; // unresolved B
}
''');
    await findMemberReferences('foo');
    assertNoResult(SearchResultKind.WRITE, 'foo = 1;');
    assertNoResult(SearchResultKind.WRITE, 'foo = 2;');
    assertNoResult(SearchResultKind.READ, 'foo; // resolved A');
    assertNoResult(SearchResultKind.READ, 'foo; // resolved B');
    assertHasRef(SearchResultKind.WRITE, 'foo = 10;', true);
    assertHasRef(SearchResultKind.WRITE, 'foo = 20;', true);
    assertHasRef(SearchResultKind.READ, 'foo; // unresolved A', true);
    assertHasRef(SearchResultKind.READ, 'foo; // unresolved B', true);
  }

  Future<void> test_enum_fields_implicit() async {
    addTestFile('''
enum A {
  v;
  int get foo => 0;
}

enum B {
  v;
  int get foo => 0;
}

void whenResolved(A a, B b) {
  a.foo; // resolved A
  b.foo; // resolved B
}

void whenUnresolved(a, b) {
  a.foo; // unresolved A
  b.foo; // unresolved B
}
''');
    await findMemberReferences('foo');
    assertNoResult(SearchResultKind.READ, 'foo; // resolved A');
    assertNoResult(SearchResultKind.READ, 'foo; // resolved B');
    assertHasRef(SearchResultKind.READ, 'foo; // unresolved A', true);
    assertHasRef(SearchResultKind.READ, 'foo; // unresolved B', true);
  }

  Future<void> test_enum_methods() async {
    addTestFile('''
enum A {
  v;
  void foo() {}
}

enum B {
  v;
  void foo() {}
}

void whenResolved(A a, B b) {
  a.foo(1);
  b.foo(2);
}

void whenUnresolved(a, b) {
  a.foo(10);
  b.foo(20);
}
''');
    await findMemberReferences('foo');
    assertNoResult(SearchResultKind.INVOCATION, 'foo(1)');
    assertNoResult(SearchResultKind.INVOCATION, 'foo(2)');
    assertHasRef(SearchResultKind.INVOCATION, 'foo(10)', true);
    assertHasRef(SearchResultKind.INVOCATION, 'foo(20)', true);
  }

  Future<void> test_extensionType_fields_implicit() async {
    addTestFile('''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) {
  int get foo => 0;
}

void whenResolved(A a, B b) {
  a.foo; // resolved A
  b.foo; // resolved B
}

void whenUnresolved(a, b) {
  a.foo; // unresolved A
  b.foo; // unresolved B
}
''');
    await findMemberReferences('foo');
    assertNoResult(SearchResultKind.READ, 'foo; // resolved A');
    assertNoResult(SearchResultKind.READ, 'foo; // resolved B');
    assertHasRef(SearchResultKind.READ, 'foo; // unresolved A', true);
    assertHasRef(SearchResultKind.READ, 'foo; // unresolved B', true);
  }

  Future<void> test_extensionType_methods() async {
    addTestFile('''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) {
  void foo() {}
}

void whenResolved(A a, B b) {
  a.foo(1);
  b.foo(2);
}

void whenUnresolved(a, b) {
  a.foo(10);
  b.foo(20);
}
''');
    await findMemberReferences('foo');
    assertNoResult(SearchResultKind.INVOCATION, 'foo(1)');
    assertNoResult(SearchResultKind.INVOCATION, 'foo(2)');
    assertHasRef(SearchResultKind.INVOCATION, 'foo(10)', true);
    assertHasRef(SearchResultKind.INVOCATION, 'foo(20)', true);
  }
}
