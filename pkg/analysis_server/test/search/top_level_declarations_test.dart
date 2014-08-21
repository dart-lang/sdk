// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.search.top_level_declarations;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/protocol2.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'abstract_search_domain.dart';
import 'dart:async';


main() {
  groupSep = ' | ';
  runReflectiveTests(TopLevelDeclarationsTest);
}


@ReflectiveTestCase()
class TopLevelDeclarationsTest extends AbstractSearchDomainTest {
  Future findTopLevelDeclarations(String pattern) {
    return waitForTasksFinished().then((_) {
      Request request = new SearchFindTopLevelDeclarationsParams(
          pattern).toRequest('0');
      Response response = handleSuccessfulRequest(request);
      searchId = new SearchFindTopLevelDeclarationsResult.fromResponse(
          response).id;
      results.clear();
      return waitForSearchResults();
    });
  }

  void assertHasDeclaration(ElementKind kind, String name) {
    result = findTopLevelResult(kind, name);
    if (result == null) {
      fail('Not found: kind=$kind name="$name"\nin\n' + results.join('\n'));
    }
  }

  void assertNoDeclaration(ElementKind kind, String name) {
    result = findTopLevelResult(kind, name);
    if (result != null) {
      fail('Unexpected: kind=$kind name="$name"\nin\n' + results.join('\n'));
    }
  }

  SearchResult findTopLevelResult(ElementKind kind, String name) {
    for (SearchResult result in results) {
      Element element = result.path[0];
      if (element.kind == kind && element.name == name) {
        return result;
      }
    }
    return null;
  }

  test_startEndPattern() {
    addTestFile('''
class A {} // A
class B = Object with A;
typedef C();
D() {}
var E = null;
class ABC {}
''');
    return findTopLevelDeclarations('^[A-E]\$').then((_) {
      assertHasDeclaration(ElementKind.CLASS, 'A');
      assertHasDeclaration(ElementKind.CLASS, 'B');
      assertHasDeclaration(ElementKind.FUNCTION_TYPE_ALIAS, 'C');
      assertHasDeclaration(ElementKind.FUNCTION, 'D');
      assertHasDeclaration(ElementKind.TOP_LEVEL_VARIABLE, 'E');
      assertNoDeclaration(ElementKind.CLASS, 'ABC');
    });
  }
}
