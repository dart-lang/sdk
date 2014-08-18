// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.search.member_references;

import 'dart:async';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/search/search_result.dart';
import 'package:analysis_server/src/services/constants.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'abstract_search_domain.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(MemberReferencesTest);
}


@ReflectiveTestCase()
class MemberReferencesTest extends AbstractSearchDomainTest {
  void assertHasRef(SearchResultKind kind, String search, bool isPotential) {
    assertHasResult(kind, search);
    expect(result.isPotential, isPotential);
  }

  Future findMemberReferences(String name) {
    return waitForTasksFinished().then((_) {
      Request request = new Request('0', SEARCH_FIND_MEMBER_REFERENCES);
      request.setParameter(NAME, name);
      Response response = handleSuccessfulRequest(request);
      searchId = response.getResult(ID);
      results.clear();
      return waitForSearchResults();
    });
  }

  test_fields_explicit() {
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
    return findMemberReferences('foo').then((_) {
      assertHasRef(SearchResultKind.WRITE, 'foo = 1;', false);
      assertHasRef(SearchResultKind.WRITE, 'foo = 2;', false);
      assertHasRef(SearchResultKind.READ, 'foo); // resolved A', false);
      assertHasRef(SearchResultKind.READ, 'foo); // resolved B', false);
      assertHasRef(SearchResultKind.WRITE, 'foo = 10;', true);
      assertHasRef(SearchResultKind.WRITE, 'foo = 20;', true);
      assertHasRef(SearchResultKind.READ, 'foo); // unresolved A', true);
      assertHasRef(SearchResultKind.READ, 'foo); // unresolved B', true);
    });
  }

  test_fields_implicit() {
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
    return findMemberReferences('foo').then((_) {
      assertHasRef(SearchResultKind.READ, 'foo); // resolved A', false);
      assertHasRef(SearchResultKind.READ, 'foo); // resolved B', false);
      assertHasRef(SearchResultKind.READ, 'foo); // unresolved A', true);
      assertHasRef(SearchResultKind.READ, 'foo); // unresolved B', true);
    });
  }

  test_methods() {
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
    return findMemberReferences('foo').then((_) {
      assertHasRef(SearchResultKind.INVOCATION, 'foo(1)', false);
      assertHasRef(SearchResultKind.INVOCATION, 'foo(2)', false);
      assertHasRef(SearchResultKind.INVOCATION, 'foo(10)', true);
      assertHasRef(SearchResultKind.INVOCATION, 'foo(20)', true);
    });
  }
}
