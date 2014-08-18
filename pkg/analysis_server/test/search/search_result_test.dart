// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.search.search_result;

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/search/search_result.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(SearchResultTest);
  runReflectiveTests(SearchResultKindTest);
}


@ReflectiveTestCase()
class SearchResultKindTest {
  void test_fromEngine() {
    expect(
        new SearchResultKind.fromEngine(MatchKind.DECLARATION),
        SearchResultKind.DECLARATION);
    expect(
        new SearchResultKind.fromEngine(MatchKind.READ),
        SearchResultKind.READ);
    expect(
        new SearchResultKind.fromEngine(MatchKind.READ_WRITE),
        SearchResultKind.READ_WRITE);
    expect(
        new SearchResultKind.fromEngine(MatchKind.WRITE),
        SearchResultKind.WRITE);
    expect(
        new SearchResultKind.fromEngine(MatchKind.REFERENCE),
        SearchResultKind.REFERENCE);
    expect(
        new SearchResultKind.fromEngine(MatchKind.INVOCATION),
        SearchResultKind.INVOCATION);
    expect(new SearchResultKind.fromEngine(null), SearchResultKind.UNKNOWN);
  }

  void test_fromName() {
    expect(
        new SearchResultKind.fromName(SearchResultKind.DECLARATION.name),
        SearchResultKind.DECLARATION);
    expect(
        new SearchResultKind.fromName(SearchResultKind.READ.name),
        SearchResultKind.READ);
    expect(
        new SearchResultKind.fromName(SearchResultKind.READ_WRITE.name),
        SearchResultKind.READ_WRITE);
    expect(
        new SearchResultKind.fromName(SearchResultKind.WRITE.name),
        SearchResultKind.WRITE);
    expect(
        new SearchResultKind.fromName(SearchResultKind.REFERENCE.name),
        SearchResultKind.REFERENCE);
    expect(
        new SearchResultKind.fromName(SearchResultKind.INVOCATION.name),
        SearchResultKind.INVOCATION);
    expect(new SearchResultKind.fromName(null), SearchResultKind.UNKNOWN);
  }

  void test_toString() {
    expect(SearchResultKind.DECLARATION.toString(), 'DECLARATION');
  }
}


@ReflectiveTestCase()
class SearchResultTest {
  void test_fromJson() {
    Map<String, Object> map = {
      KIND: 'READ',
      IS_POTENTIAL: true,
      LOCATION: {
        FILE: '/test.dart',
        OFFSET: 1,
        LENGTH: 2,
        START_LINE: 3,
        START_COLUMN: 4
      },
      PATH: [
          new Element(
              ElementKind.FIELD,
              'myField',
              new Location('/lib.dart', 10, 20, 30, 40),
              false,
              false).toJson()]
    };
    SearchResult result = new SearchResult.fromJson(map);
    expect(result.kind, SearchResultKind.READ);
    expect(result.location.file, '/test.dart');
    expect(result.location.offset, 1);
    expect(result.location.length, 2);
    expect(result.location.startLine, 3);
    expect(result.location.startColumn, 4);
    expect(result.path, hasLength(1));
    expect(result.path[0].kind, ElementKind.FIELD);
    expect(result.path[0].name, 'myField');
    expect(result.path[0].location.file, '/lib.dart');
    expect(result.path[0].location.offset, 10);
    // touch toJson();
    expect(result.toJson(), hasLength(4));
    // touch asJson();
    expect(SearchResult.asJson(result), hasLength(4));
    // touch toString();
    expect(result.toString(), hasLength(greaterThan(10)));
  }
}
