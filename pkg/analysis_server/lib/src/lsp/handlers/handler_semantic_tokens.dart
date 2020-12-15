// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/computer/computer_highlights.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/encoder.dart';
import 'package:analysis_server/src/plugin/result_merger.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

class SemanticTokensHandler
    extends MessageHandler<SemanticTokensParams, SemanticTokens>
    with LspPluginRequestHandlerMixin {
  SemanticTokensHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.textDocument_semanticTokens_full;

  @override
  LspJsonHandler<SemanticTokensParams> get jsonHandler =>
      SemanticTokensParams.jsonHandler;

  List<List<HighlightRegion>> getPluginResults(String path) {
    final notificationManager = server.notificationManager;
    return notificationManager.highlights.getResults(path);
  }

  Future<List<HighlightRegion>> getServerResult(String path) async {
    final result = await server.getResolvedUnit(path);
    if (result?.state == ResultState.VALID) {
      final computer = DartUnitHighlightsComputer(result.unit);
      return computer.compute();
    }
    return [];
  }

  @override
  Future<ErrorOr<SemanticTokens>> handle(
      SemanticTokensParams params, CancellationToken token) async {
    final path = pathOfDoc(params.textDocument);

    return path.mapResult((path) async {
      final lineInfo = server.getLineInfo(path);
      // If there is no lineInfo, the request cannot be translated from LSP
      // line/col to server offset/length.
      if (lineInfo == null) {
        return success(null);
      }

      // We need to be able to split multiline tokens up if a client does not
      // support them. Doing this correctly requires access to the line endings
      // and indenting so we must get a copy of the file contents. Although this
      // is on the Dart unit result, we may also need this for files being
      // handled by plugins.
      final file = server.resourceProvider.getFile(path);
      if (!file.exists) {
        return success(null);
      }
      final fileContents = file.readAsStringSync();

      final allResults = [
        await getServerResult(path),
        ...getPluginResults(path),
      ];

      final merger = ResultMerger();
      final mergedResults = merger.mergeHighlightRegions(allResults);

      final encoder = SemanticTokenEncoder();
      final tokens =
          encoder.convertHighlights(mergedResults, lineInfo, fileContents);
      final semanticTokens = encoder.encodeTokens(tokens);

      return success(semanticTokens);
    });
  }
}
