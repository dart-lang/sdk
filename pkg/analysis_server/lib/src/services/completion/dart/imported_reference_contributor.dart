// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.imported_ref;

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/resolver.dart';

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

    List<ImportElement> imports = await request.resolveImports();
    if (imports == null) {
      return EMPTY_LIST;
    }

    // If the target is in an expression
    // then resolve the outermost/entire expression
    AstNode node = request.target.containingNode;
    if (node is Expression) {
      await request.resolveContainingExpression(node);

      // Discard any cached target information
      // because it may have changed as a result of the resolution
      node = request.target.containingNode;
    }

    this.request = request;
    this.optype = (request as DartCompletionRequestImpl).opType;
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

    // Traverse imports including dart:core
    for (ImportElement importElem in imports) {
      LibraryElement libElem = importElem?.importedLibrary;
      if (libElem != null) {
        suggestions.addAll(_buildSuggestions(libElem.exportNamespace,
            prefix: importElem.prefix?.name,
            showNames: showNamesIn(importElem),
            hiddenNames: hiddenNamesIn(importElem)));
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
