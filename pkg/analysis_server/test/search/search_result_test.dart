// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.search.search_result;

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchResultKindTest);
  });
}

@reflectiveTest
class SearchResultKindTest {
  void test_fromEngine() {
    expect(newSearchResultKind_fromEngine(MatchKind.DECLARATION),
        SearchResultKind.DECLARATION);
    expect(
        newSearchResultKind_fromEngine(MatchKind.READ), SearchResultKind.READ);
    expect(newSearchResultKind_fromEngine(MatchKind.READ_WRITE),
        SearchResultKind.READ_WRITE);
    expect(newSearchResultKind_fromEngine(MatchKind.WRITE),
        SearchResultKind.WRITE);
    expect(newSearchResultKind_fromEngine(MatchKind.REFERENCE),
        SearchResultKind.REFERENCE);
    expect(newSearchResultKind_fromEngine(MatchKind.INVOCATION),
        SearchResultKind.INVOCATION);
    expect(newSearchResultKind_fromEngine(null), SearchResultKind.UNKNOWN);
  }

  void test_fromName() {
    expect(new SearchResultKind(SearchResultKind.DECLARATION.name),
        SearchResultKind.DECLARATION);
    expect(new SearchResultKind(SearchResultKind.READ.name),
        SearchResultKind.READ);
    expect(new SearchResultKind(SearchResultKind.READ_WRITE.name),
        SearchResultKind.READ_WRITE);
    expect(new SearchResultKind(SearchResultKind.WRITE.name),
        SearchResultKind.WRITE);
    expect(new SearchResultKind(SearchResultKind.REFERENCE.name),
        SearchResultKind.REFERENCE);
    expect(new SearchResultKind(SearchResultKind.INVOCATION.name),
        SearchResultKind.INVOCATION);
    expect(new SearchResultKind(SearchResultKind.UNKNOWN.name),
        SearchResultKind.UNKNOWN);
  }

  void test_toString() {
    expect(SearchResultKind.DECLARATION.toString(),
        'SearchResultKind.DECLARATION');
  }
}
