// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.search.member_references;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_search_domain.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MemberReferencesTest);
    defineReflectiveTests(MemberReferencesTest_Driver);
  });
}

@reflectiveTest
class MemberReferencesTest extends AbstractSearchDomainTest {
  void assertHasRef(SearchResultKind kind, String search, bool isPotential) {
    assertHasResult(kind, search);
    expect(result.isPotential, isPotential);
  }

  Future findMemberReferences(String name) async {
    await waitForTasksFinished();
    Request request = new SearchFindMemberReferencesParams(name).toRequest('0');
    Response response = await waitResponse(request);
    searchId = new SearchFindMemberReferencesResult.fromResponse(response).id;
    return waitForSearchResults();
  }

  test_fields_explicit() async {
    addTestFile('''
class A {
  var foo;
}
class B {
  var foo;
}
mainResolved(A a, B b) {
  a.foo = 1;
  b.foo = 2;
  print(a.foo); // resolved A
  print(b.foo); // resolved B
}
mainUnresolved(a, b) {
  a.foo = 10;
  b.foo = 20;
  print(a.foo); // unresolved A
  print(b.foo); // unresolved B
}
''');
    await findMemberReferences('foo');
    assertNoResult(SearchResultKind.WRITE, 'foo = 1;');
    assertNoResult(SearchResultKind.WRITE, 'foo = 2;');
    assertNoResult(SearchResultKind.READ, 'foo); // resolved A');
    assertNoResult(SearchResultKind.READ, 'foo); // resolved B');
    assertHasRef(SearchResultKind.WRITE, 'foo = 10;', true);
    assertHasRef(SearchResultKind.WRITE, 'foo = 20;', true);
    assertHasRef(SearchResultKind.READ, 'foo); // unresolved A', true);
    assertHasRef(SearchResultKind.READ, 'foo); // unresolved B', true);
  }

  test_fields_implicit() async {
    addTestFile('''
class A {
  get foo => null;
}
class B {
  get foo => null;
}
mainResolved(A a, B b) {
  print(a.foo); // resolved A
  print(b.foo); // resolved B
}
mainUnresolved(a, b) {
  print(a.foo); // unresolved A
  print(b.foo); // unresolved B
}
''');
    await findMemberReferences('foo');
    assertNoResult(SearchResultKind.READ, 'foo); // resolved A');
    assertNoResult(SearchResultKind.READ, 'foo); // resolved B');
    assertHasRef(SearchResultKind.READ, 'foo); // unresolved A', true);
    assertHasRef(SearchResultKind.READ, 'foo); // unresolved B', true);
  }

  test_methods() async {
    addTestFile('''
class A {
  foo() {}
}
class B {
  foo() {}
}
mainResolved(A a, B b) {
  a.foo(1);
  b.foo(2);
}
mainUnresolved(a, b) {
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

@reflectiveTest
class MemberReferencesTest_Driver extends MemberReferencesTest {
  @override
  void setUp() {
    enableNewAnalysisDriver = true;
    super.setUp();
  }
}
