// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.imported_ref;

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analyzer/src/generated/resolver.dart';

/**
 * A contributor for calculating suggestions for imported top level members.
 */
class ImportedReferenceContributor extends DartCompletionContributor {
  DartCompletionRequest request;
  OpType optype;

  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    if (!request.includeIdentifiers) {
      return EMPTY_LIST;
    }

    List<Directive> directives = await request.resolveDirectives();
    if (directives == null) {
      return EMPTY_LIST;
    }

    this.request = request;
    this.optype = (request as DartCompletionRequestImpl).opType;

    // Traverse dart:core
    List<CompletionSuggestion> suggestions =
        _buildSuggestions(request.coreLib.exportNamespace);

    // Traverse imports
    for (Directive directive in directives) {
      if (directive is ImportDirective) {
        ImportElement importElem = directive.element;
        LibraryElement libElem = importElem?.importedLibrary;
        if (libElem != null) {
          suggestions.addAll(_buildSuggestions(libElem.exportNamespace,
              prefix: importElem.prefix?.name,
              showNames: showNamesIn(importElem),
              hiddenNames: hiddenNamesIn(importElem)));
        }
      }
    }

    return suggestions;
  }

  List<CompletionSuggestion> _buildSuggestions(Namespace namespace,
      {String prefix, List<String> showNames, List<String> hiddenNames}) {
    LibraryElementSuggestionBuilder visitor =
        new LibraryElementSuggestionBuilder(request, optype, prefix);
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

List<String> showNamesIn(ImportElement importElem) {
  for (NamespaceCombinator combinator in importElem.combinators) {
    if (combinator is ShowElementCombinator) {
      return combinator.shownNames;
    }
  }
  return null;
}

List<String> hiddenNamesIn(ImportElement importElem) {
  for (NamespaceCombinator combinator in importElem.combinators) {
    if (combinator is HideElementCombinator) {
      return combinator.hiddenNames;
    }
  }
  return null;
}
