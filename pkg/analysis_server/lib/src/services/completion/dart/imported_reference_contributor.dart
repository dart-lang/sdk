// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';

import '../../../protocol_server.dart' show CompletionSuggestion;

List<String> hiddenNamesIn(ImportElement importElem) {
  for (NamespaceCombinator combinator in importElem.combinators) {
    if (combinator is HideElementCombinator) {
      return combinator.hiddenNames;
    }
  }
  return null;
}

List<String> showNamesIn(ImportElement importElem) {
  for (NamespaceCombinator combinator in importElem.combinators) {
    if (combinator is ShowElementCombinator) {
      return combinator.shownNames;
    }
  }
  return null;
}

/// A contributor for calculating suggestions for imported top level members.
class ImportedReferenceContributor extends DartCompletionContributor {
  DartCompletionRequest request;
  OpType optype;

  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (!request.includeIdentifiers) {
      return const <CompletionSuggestion>[];
    }

    List<ImportElement> imports = request.libraryElement.imports;
    if (imports == null) {
      return const <CompletionSuggestion>[];
    }

    this.request = request;
    optype = (request as DartCompletionRequestImpl).opType;
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

    final seenElements = <protocol.Element>{};

    // Traverse imports including dart:core
    for (ImportElement importElem in imports) {
      LibraryElement libElem = importElem?.importedLibrary;
      if (libElem != null) {
        final newSuggestions = _buildSuggestions(libElem.exportNamespace,
            prefix: importElem.prefix?.name,
            showNames: showNamesIn(importElem),
            hiddenNames: hiddenNamesIn(importElem));
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

  List<CompletionSuggestion> _buildSuggestions(Namespace namespace,
      {String prefix, List<String> showNames, List<String> hiddenNames}) {
    LibraryElementSuggestionBuilder visitor =
        LibraryElementSuggestionBuilder(request, optype, prefix);
    for (Element elem in namespace.definedNames.values) {
      if (showNames != null && !showNames.contains(elem.name)) {
        continue;
      }
      if (hiddenNames != null && hiddenNames.contains(elem.name)) {
        continue;
      }
      elem.accept(visitor);
    }
    return visitor.suggestions;
  }
}
