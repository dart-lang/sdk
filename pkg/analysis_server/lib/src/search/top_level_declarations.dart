// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library search.top_level_declarations;

import 'dart:async';

import 'package:analysis_server/src/search/search_result.dart';
import 'package:analysis_services/search/search_engine.dart';


/**
 * A computer for `search.findTopLevelDeclarations` request results.
 */
class TopLevelDeclarationsComputer {
  final SearchEngine searchEngine;

  TopLevelDeclarationsComputer(this.searchEngine);

  /**
   * Computes [SearchResult]s for top-level [element] declarations.
   */
  Future<List<SearchResult>> compute(String pattern) {
    var matchesFuture = searchEngine.searchTopLevelDeclarations(pattern);
    return matchesFuture.then((List<SearchMatch> matches) {
      return matches.map(toResult).toList();
    });
  }

  static SearchResult toResult(SearchMatch match) {
    return new SearchResult.fromMatch(match);
  }
}
