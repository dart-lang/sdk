// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.toplevel;

import 'dart:async';

import 'package:analysis_services/completion/completion_computer.dart';
import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A computer for `completion.getSuggestions` request results.
 */
class TopLevelComputer extends CompletionComputer {
  final SearchEngine searchEngine;

  TopLevelComputer(this.searchEngine);

  /**
   * Computes [CompletionSuggestion]s for the specified position in the source.
   */
  Future<List<CompletionSuggestion>> compute() {
    var future = searchEngine.searchTopLevelDeclarations('');
    return future.then((List<SearchMatch> matches) {
      return matches.map((SearchMatch match) {
        Element element = match.element;
        String completion = element.displayName;
        return new CompletionSuggestion(
            CompletionSuggestionKind.fromElementKind(element.kind),
            CompletionRelevance.DEFAULT,
            completion,
            completion.length,
            0,
            element.isDeprecated,
            false // isPotential
            );
      }).toList();
    });
  }
}
