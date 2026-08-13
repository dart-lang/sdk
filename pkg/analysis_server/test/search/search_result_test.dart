// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SearchResultKindTest);
  });
}

@reflectiveTest
class SearchResultKindTest {
  void test_fromEngine() {
    expect(
      newSearchResultKind_fromEngine(MatchKind.DECLARATION),
      SearchResultKind.DECLARATION,
    );
    expect(
      newSearchResultKind_fromEngine(MatchKind.READ),
      SearchResultKind.READ,
    );
    expect(
      newSearchResultKind_fromEngine(MatchKind.READ_WRITE),
      SearchResultKind.READ_WRITE,
    );
    expect(
      newSearchResultKind_fromEngine(MatchKind.WRITE),
      SearchResultKind.WRITE,
    );
    expect(
      newSearchResultKind_fromEngine(MatchKind.REFERENCE),
      SearchResultKind.REFERENCE,
    );
    expect(
      newSearchResultKind_fromEngine(MatchKind.REFERENCE_IN_EXTENDS_CLAUSE),
      SearchResultKind.REFERENCE,
    );
    expect(
      newSearchResultKind_fromEngine(MatchKind.REFERENCE_IN_IMPLEMENTS_CLAUSE),
      SearchResultKind.REFERENCE,
    );
    expect(
      newSearchResultKind_fromEngine(MatchKind.REFERENCE_IN_WITH_CLAUSE),
      SearchResultKind.REFERENCE,
    );
    expect(
      newSearchResultKind_fromEngine(MatchKind.REFERENCE_IN_ON_CLAUSE),
      SearchResultKind.REFERENCE,
    );
    expect(
      newSearchResultKind_fromEngine(
        MatchKind.REFERENCE_BY_CONSTRUCTOR_TEAR_OFF,
      ),
      SearchResultKind.REFERENCE,
    );
    expect(
      newSearchResultKind_fromEngine(MatchKind.INVOCATION),
      SearchResultKind.INVOCATION,
    );
  }

  void test_toString() {
    expect(
      SearchResultKind.DECLARATION.toString(),
      'SearchResultKind.DECLARATION',
    );
  }
}
