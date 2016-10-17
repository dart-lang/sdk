// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.search.member_declarations;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_search_domain.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MemberDeclarationsTest);
  });
}

@reflectiveTest
class MemberDeclarationsTest extends AbstractSearchDomainTest {
  void assertHasDeclaration(ElementKind kind, String className) {
    result = findTopLevelResult(kind, className);
    if (result == null) {
      fail('Not found: kind=$kind in="$className"\nin\n' + results.join('\n'));
    }
  }

  Future findMemberDeclarations(String name) async {
    await waitForTasksFinished();
    Request request =
        new SearchFindMemberDeclarationsParams(name).toRequest('0');
    Response response = await waitResponse(request);
    var result = new SearchFindMemberDeclarationsResult.fromResponse(response);
    searchId = result.id;
    return waitForSearchResults();
  }

  SearchResult findTopLevelResult(ElementKind kind, String enclosingClass) {
    for (SearchResult result in results) {
      Element element = result.path[0];
      Element clazz = result.path[1];
      if (element.kind == kind && clazz.name == enclosingClass) {
        return result;
      }
    }
    return null;
  }

  test_localVariable() async {
    addTestFile('''
class A {
  main() {
    var foo = 42;
  }
}
''');
    await findMemberDeclarations('foo');
    expect(results, isEmpty);
  }

  test_localVariable_forIn() async {
    addTestFile('''
class A {
  main() {
    for (int foo in []) {
    }
  }
}
''');
    await findMemberDeclarations('foo');
    expect(results, isEmpty);
  }

  test_methodField() async {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  int foo;
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.FIELD, 'B');
  }

  test_methodGetter() async {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  get foo => null;
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.GETTER, 'B');
  }

  test_methodGetterSetter() async {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  get foo => null;
  set foo(x) {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(3));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.GETTER, 'B');
    assertHasDeclaration(ElementKind.SETTER, 'B');
  }

  test_methodMethod() async {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  foo() {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.METHOD, 'B');
  }

  test_methodSetter() async {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  set foo(x) {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.SETTER, 'B');
  }
}
