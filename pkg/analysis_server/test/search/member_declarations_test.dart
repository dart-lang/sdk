// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.search.member_declarations;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import '../reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'abstract_search_domain.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(MemberDeclarationsTest);
}


@ReflectiveTestCase()
class MemberDeclarationsTest extends AbstractSearchDomainTest {
  void assertHasDeclaration(ElementKind kind, String className) {
    result = findTopLevelResult(kind, className);
    if (result == null) {
      fail('Not found: kind=$kind in="$className"\nin\n' + results.join('\n'));
    }
  }

  void assertNoDeclaration(ElementKind kind, String className) {
    result = findTopLevelResult(kind, className);
    if (result != null) {
      fail('Unexpected: kind=$kind in="$className"\nin\n' + results.join('\n'));
    }
  }

  Future findMemberDeclarations(String name) {
    return waitForTasksFinished().then((_) {
      Request request =
          new SearchFindMemberDeclarationsParams(name).toRequest('0');
      Response response = handleSuccessfulRequest(request);
      var result = new SearchFindMemberDeclarationsResult.fromResponse(response);
      searchId = result.id;
      results.clear();
      return waitForSearchResults();
    });
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

  test_localVariable() {
    addTestFile('''
class A {
  main() {
    var foo = 42;
  }
}
''');
    return findMemberDeclarations('foo').then((_) {
      expect(results, isEmpty);
    });
  }

  test_localVariable_forIn() {
    addTestFile('''
class A {
  main() {
    for (int foo in []) {
    }
  }
}
''');
    return findMemberDeclarations('foo').then((_) {
      expect(results, isEmpty);
    });
  }

  test_methodField() {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  int foo;
}
''');
    return findMemberDeclarations('foo').then((_) {
      expect(results, hasLength(2));
      assertHasDeclaration(ElementKind.METHOD, 'A');
      assertHasDeclaration(ElementKind.FIELD, 'B');
    });
  }

  test_methodGetter() {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  get foo => null;
}
''');
    return findMemberDeclarations('foo').then((_) {
      expect(results, hasLength(2));
      assertHasDeclaration(ElementKind.METHOD, 'A');
      assertHasDeclaration(ElementKind.GETTER, 'B');
    });
  }

  test_methodGetterSetter() {
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
    return findMemberDeclarations('foo').then((_) {
      expect(results, hasLength(3));
      assertHasDeclaration(ElementKind.METHOD, 'A');
      assertHasDeclaration(ElementKind.GETTER, 'B');
      assertHasDeclaration(ElementKind.SETTER, 'B');
    });
  }

  test_methodMethod() {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  foo() {}
}
''');
    return findMemberDeclarations('foo').then((_) {
      expect(results, hasLength(2));
      assertHasDeclaration(ElementKind.METHOD, 'A');
      assertHasDeclaration(ElementKind.METHOD, 'B');
    });
  }

  test_methodSetter() {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  set foo(x) {}
}
''');
    return findMemberDeclarations('foo').then((_) {
      expect(results, hasLength(2));
      assertHasDeclaration(ElementKind.METHOD, 'A');
      assertHasDeclaration(ElementKind.SETTER, 'B');
    });
  }
}
