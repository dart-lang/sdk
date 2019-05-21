// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domains/completion/available_suggestions.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

// If the client does not provide capabilities.completion.completionItemKind.valueSet
// then we must never send a kind that's not in this list.
final defaultSupportedCompletionKinds = new HashSet<CompletionItemKind>.of([
  CompletionItemKind.Text,
  CompletionItemKind.Method,
  CompletionItemKind.Function,
  CompletionItemKind.Constructor,
  CompletionItemKind.Field,
  CompletionItemKind.Variable,
  CompletionItemKind.Class,
  CompletionItemKind.Interface,
  CompletionItemKind.Module,
  CompletionItemKind.Property,
  CompletionItemKind.Unit,
  CompletionItemKind.Value,
  CompletionItemKind.Enum,
  CompletionItemKind.Keyword,
  CompletionItemKind.Snippet,
  CompletionItemKind.Color,
  CompletionItemKind.File,
  CompletionItemKind.Reference,
]);

class CompletionHandler
    extends MessageHandler<CompletionParams, List<CompletionItem>> {
  final bool suggestFromUnimportedLibraries;
  CompletionHandler(
      LspAnalysisServer server, this.suggestFromUnimportedLibraries)
      : super(server);

  Method get handlesMessage => Method.textDocument_completion;

  @override
  LspJsonHandler<CompletionParams> get jsonHandler =>
      CompletionParams.jsonHandler;

  Future<ErrorOr<List<CompletionItem>>> handle(CompletionParams params) async {
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }

    final completionCapabilities =
        server?.clientCapabilities?.textDocument?.completion;

    final clientSupportedCompletionKinds =
        completionCapabilities?.completionItemKind?.valueSet != null
            ? new HashSet<CompletionItemKind>.of(
                completionCapabilities.completionItemKind.valueSet)
            : defaultSupportedCompletionKinds;

    final includeSuggestionSets = suggestFromUnimportedLibraries &&
        server?.clientCapabilities?.workspace?.applyEdit == true;

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));
    return offset.mapResult((offset) => _getItems(
          completionCapabilities,
          clientSupportedCompletionKinds,
          includeSuggestionSets,
          unit.result,
          offset,
        ));
  }

  Future<ErrorOr<List<CompletionItem>>> _getItems(
    TextDocumentClientCapabilitiesCompletion completionCapabilities,
    HashSet<CompletionItemKind> clientSupportedCompletionKinds,
    bool includeSuggestionSets,
    ResolvedUnitResult unit,
    int offset,
  ) async {
    final performance = new CompletionPerformance();
    performance.path = unit.path;
    performance.setContentsAndOffset(unit.content, offset);
    server.performanceStats.completion.add(performance);

    final completionRequest =
        new CompletionRequestImpl(unit, offset, performance);

    Set<ElementKind> includedElementKinds;
    List<IncludedSuggestionRelevanceTag> includedSuggestionRelevanceTags;
    if (includeSuggestionSets) {
      includedElementKinds = Set<ElementKind>();
      includedSuggestionRelevanceTags = <IncludedSuggestionRelevanceTag>[];
    }

    try {
      CompletionContributor contributor = new DartCompletionManager(
        includedElementKinds: includedElementKinds,
        includedSuggestionRelevanceTags: includedSuggestionRelevanceTags,
      );
      final suggestions =
          await contributor.computeSuggestions(completionRequest);
      final results = suggestions
          .map((item) => toCompletionItem(
                completionCapabilities,
                clientSupportedCompletionKinds,
                unit.lineInfo,
                item,
                completionRequest.replacementOffset,
                completionRequest.replacementLength,
              ))
          .toList();

      // Now compute items in suggestion sets.
      List<IncludedSuggestionSet> includedSuggestionSets =
          includedElementKinds == null || unit == null
              ? const []
              : computeIncludedSetList(
                  server.declarationsTracker,
                  unit,
                );

      includedSuggestionSets.forEach((includedSet) {
        final library = server.declarationsTracker.getLibrary(includedSet.id);
        if (library == null) {
          return;
        }

        // Make a fast lookup for tag relevance.
        final tagBoosts = <String, int>{};
        includedSuggestionRelevanceTags
            .forEach((t) => tagBoosts[t.tag] = t.relevanceBoost);

        final setResults = library.declarations
            // Filter to only the kinds we should return.
            .where((item) =>
                includedElementKinds.contains(protocolElementKind(item.kind)))
            .map((item) => declarationToCompletionItem(
                  completionCapabilities,
                  clientSupportedCompletionKinds,
                  unit.path,
                  offset,
                  includedSet,
                  library,
                  tagBoosts,
                  unit.lineInfo,
                  item,
                  completionRequest.replacementOffset,
                  completionRequest.replacementLength,
                ));
        results.addAll(setResults);
      });

      performance.notificationCount = 1;
      performance.suggestionCountFirst = results.length;
      performance.suggestionCountLast = results.length;
      performance.complete();

      return success(results);
    } on AbortCompletion {
      return success([]);
    }
  }
}
