// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.toplevel;

import 'dart:async';

import 'package:analysis_services/completion/completion_computer.dart';
import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A computer for calculating class and top level variable
 * `completion.getSuggestions` request results
 */
class TopLevelComputer extends CompletionComputer {
  final SearchEngine searchEngine;
  final CompilationUnit unit;

  TopLevelComputer(this.searchEngine, this.unit);

  /**
   * Computes [CompletionSuggestion]s for the specified position in the source.
   */
  Future<List<CompletionSuggestion>> compute() {
    var future = searchEngine.searchTopLevelDeclarations('');
    return future.then((List<SearchMatch> matches) {

      // Compute the set of visible libraries to determine relevance
      var visibleLibraries = new Set<LibraryElement>();
      var unitLibrary = unit.element.library;
      visibleLibraries.add(unitLibrary);
      visibleLibraries.addAll(unitLibrary.importedLibraries);

      // Compute the set of possible classes and top level variables
      var suggestions = new List<CompletionSuggestion>();
      matches.forEach((SearchMatch match) {
        if (match.kind == MatchKind.DECLARATION) {
          Element element = match.element;
          if (element.isPublic || element.library == unitLibrary) {
            String completion = element.displayName;
            var relevance = visibleLibraries.contains(element.library) ?
                CompletionRelevance.DEFAULT :
                CompletionRelevance.LOW;
            suggestions.add(
                new CompletionSuggestion(
                    CompletionSuggestionKind.fromElementKind(element.kind),
                    relevance,
                    completion,
                    completion.length,
                    0,
                    element.isDeprecated,
                    false // isPotential
            ));
          }
        }
      });
      return suggestions;
    });
  }

}
