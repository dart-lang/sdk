// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.toplevel;

import 'dart:async';

import 'package:analysis_services/completion/completion_computer.dart';
import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A computer for calculating imported class and top level variable
 * `completion.getSuggestions` request results.
 */
class ImportedTypeComputer extends CompletionComputer {

  @override
  bool computeFast(CompilationUnit unit,
      List<CompletionSuggestion> suggestions) {
    // TODO: implement computeFast
    // - compute results based upon current search, then replace those results
    // during the full compute phase
    // - filter results based upon completion offset
    return false;
  }

  @override
  Future<bool> computeFull(CompilationUnit unit,
      List<CompletionSuggestion> suggestions) {
    var future = searchEngine.searchTopLevelDeclarations('');
    return future.then((List<SearchMatch> matches) {

      // Exclude elements from the local library
      // which will be included by the LocalComputer

      // Compute the set of visible libraries to determine relevance
      var visibleLibraries = new Set<LibraryElement>();
      var excludedLibraries = new Set<LibraryElement>();
      var unitLibrary = unit.element.library;
      excludedLibraries.add(unitLibrary);
      unitLibrary.importedLibraries.forEach((LibraryElement library) {
        if (library.isDartCore) {
          visibleLibraries.add(library);
        }
      });
      unit.directives.forEach((Directive directive) {
        if (directive is ImportDirective) {
          LibraryElement library = directive.element.importedLibrary;
          if (directive.prefix == null) {
            visibleLibraries.add(library);
          } else {
            excludedLibraries.add(library);
          }
        }
      });

      // Compute the set of possible classes, functions, and top level variables
      matches.forEach((SearchMatch match) {
        if (match.kind == MatchKind.DECLARATION) {
          Element element = match.element;
          if (element.isPublic &&
              !excludedLibraries.contains(element.library)) {
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
      return true;
    });
  }
}
