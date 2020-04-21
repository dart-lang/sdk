// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart'
    show SuggestionBuilder;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;

import '../../../protocol_server.dart' show CompletionSuggestion;

/// A contributor for calculating suggestions for imported top level members.
class ImportedReferenceContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    if (!request.includeIdentifiers) {
      return const <CompletionSuggestion>[];
    }

    var imports = request.libraryElement.imports;
    if (imports == null) {
      return const <CompletionSuggestion>[];
    }

    var suggestions = <CompletionSuggestion>[];

    var seenElements = <protocol.Element>{};

    // Traverse imports including dart:core
    for (var importElement in imports) {
      var libraryElement = importElement.importedLibrary;
      if (libraryElement != null) {
        final newSuggestions = _buildSuggestions(
            request, importElement.namespace,
            prefix: importElement.prefix?.name);
        for (var suggestion in newSuggestions) {
          // Filter out multiply-exported elements (like Future and Stream).
          if (seenElements.add(suggestion.element)) {
            suggestions.add(suggestion);
          }
        }
      }
    }
    return suggestions;
  }

  List<CompletionSuggestion> _buildSuggestions(
      DartCompletionRequest request, Namespace namespace,
      {String prefix}) {
    var visitor = LibraryElementSuggestionBuilder(request, prefix);
    for (var elem in namespace.definedNames.values) {
      elem.accept(visitor);
    }
    return visitor.suggestions;
  }
}
