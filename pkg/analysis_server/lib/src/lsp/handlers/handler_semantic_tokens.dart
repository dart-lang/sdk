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

  Future<List<SemanticTokenInfo>> getServerResult(String path) async {
    final result = await server.getResolvedUnit(path);
    if (result?.state == ResultState.VALID) {
      final computer = DartUnitHighlightsComputer(result.unit);
      return computer.computeSemanticTokens();
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

      final serverTokens = await getServerResult(path);
      final pluginHighlightRegions =
          getPluginResults(path).expand((results) => results).toList();

      if (token.isCancellationRequested) {
        return cancelled();
      }

      final encoder = SemanticTokenEncoder();
      final pluginTokens =
          encoder.convertHighlightToTokens(pluginHighlightRegions);

      Iterable<SemanticTokenInfo> tokens = [...serverTokens, ...pluginTokens];

      // Capabilities exist for supporting multiline/overlapping tokens. These
      // could be used if any clients take it up (VS Code does not).
      // - clientCapabilities?.multilineTokenSupport
      // - clientCapabilities?.overlappingTokenSupport
      final allowMultilineTokens = false;
      final allowOverlappingTokens = false;

      // Some of the translation operations and the final encoding require
      // the tokens to be sorted. Do it once here to avoid each method needing
      // to do it itself (resulting in multiple sorts).
      tokens = tokens.toList()
        ..sort(SemanticTokenInfo.offsetLengthPrioritySort);

      if (!allowOverlappingTokens) {
        tokens = encoder.splitOverlappingTokens(tokens);
      }

      if (!allowMultilineTokens) {
        tokens = tokens
            .expand((token) => encoder.splitMultilineTokens(token, lineInfo));
      }

      final semanticTokens = encoder.encodeTokens(tokens.toList(), lineInfo);

      return success(semanticTokens);
    });
  }
}
