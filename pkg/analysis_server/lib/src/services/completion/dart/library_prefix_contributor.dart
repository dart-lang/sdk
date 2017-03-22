// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.library_prefix;

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/element/element.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/**
 * A contributor for calculating prefixed import library member suggestions
 * `completion.getSuggestions` request results.
 */
class LibraryPrefixContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    if (!request.includeIdentifiers) {
      return EMPTY_LIST;
    }

    List<ImportElement> imports = await request.resolveImports();
    if (imports == null) {
      return EMPTY_LIST;
    }

    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    for (ImportElement element in imports) {
      String completion = element.prefix?.name;
      if (completion != null && completion.length > 0) {
        LibraryElement libElem = element.importedLibrary;
        if (libElem != null) {
          CompletionSuggestion suggestion = createSuggestion(
              libElem, request.ideOptions,
              completion: completion,
              kind: CompletionSuggestionKind.IDENTIFIER);
          if (suggestion != null) {
            suggestions.add(suggestion);
          }
        }
      }
    }
    return suggestions;
  }
}
