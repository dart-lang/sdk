// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/// A contributor that produces suggestions based on the prefixes defined on
/// import directives.
class LibraryPrefixContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    if (!request.includeIdentifiers) {
      return const <CompletionSuggestion>[];
    }

    var imports = request.libraryElement.imports;
    if (imports == null) {
      return const <CompletionSuggestion>[];
    }

    // TODO(brianwilkerson) The code below will result in duplication if two or
    //  more imports use the same prefix. Might not be worth fixing. The one
    //  potential complication is if the library is displayed with the prefix,
    //  in which case not having one per library could be confusing.
    var useNewRelevance = request.useNewRelevance;
    var suggestions = <CompletionSuggestion>[];
    for (var element in imports) {
      var completion = element.prefix?.name;
      if (completion != null && completion.isNotEmpty) {
        var libraryElement = element.importedLibrary;
        if (libraryElement != null) {
          var relevance =
              useNewRelevance ? Relevance.prefix : DART_RELEVANCE_DEFAULT;
          var suggestion = createSuggestion(request, libraryElement,
              completion: completion,
              kind: CompletionSuggestionKind.IDENTIFIER,
              relevance: relevance,
              useNewRelevance: useNewRelevance);
          if (suggestion != null) {
            suggestions.add(suggestion);
          }
        }
      }
    }
    return suggestions;
  }
}
