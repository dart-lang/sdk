// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analyzer/dart/analysis/results.dart';

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
  CompletionHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_completion;

  @override
  CompletionParams convertParams(Map<String, dynamic> json) =>
      CompletionParams.fromJson(json);

  Future<ErrorOr<List<CompletionItem>>> handle(CompletionParams params) async {
    final completionCapabilities =
        server?.clientCapabilities?.textDocument?.completion;

    final clientSupportedCompletionKinds =
        completionCapabilities?.completionItemKind?.valueSet != null
            ? new HashSet<CompletionItemKind>.of(
                completionCapabilities.completionItemKind.valueSet)
            : defaultSupportedCompletionKinds;

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));
    return offset.mapResult((offset) => _getItems(
          completionCapabilities,
          clientSupportedCompletionKinds,
          unit.result,
          offset,
        ));
  }

  Future<ErrorOr<List<CompletionItem>>> _getItems(
    TextDocumentClientCapabilitiesCompletion completionCapabilities,
    HashSet<CompletionItemKind> clientSupportedCompletionKinds,
    ResolvedUnitResult unit,
    int offset,
  ) async {
    final performance = new CompletionPerformance();
    performance.path = unit.path;
    performance.setContentsAndOffset(unit.content, offset);
    server.performanceStats.completion.add(performance);

    final completionRequest =
        new CompletionRequestImpl(unit, offset, performance);

    try {
      CompletionContributor contributor = new DartCompletionManager();
      final items = await contributor.computeSuggestions(completionRequest);

      performance.notificationCount = 1;
      performance.suggestionCountFirst = items.length;
      performance.suggestionCountLast = items.length;
      performance.complete();

      return success(items
          .map((item) => toCompletionItem(
                completionCapabilities,
                clientSupportedCompletionKinds,
                unit.lineInfo,
                item,
                completionRequest.replacementOffset,
                completionRequest.replacementLength,
              ))
          .toList());
    } on AbortCompletion {
      return success([]);
    }
  }
}
