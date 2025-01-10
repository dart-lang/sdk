// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/computer/computer_highlights.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/encoder.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/legend.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:collection/collection.dart';

typedef StaticOptions =
    Either2<SemanticTokensOptions, SemanticTokensRegistrationOptions>;

abstract class AbstractSemanticTokensHandler<T>
    extends LspMessageHandler<T, SemanticTokens?>
    with LspPluginRequestHandlerMixin {
  AbstractSemanticTokensHandler(super.server);

  List<List<HighlightRegion>> getPluginResults(String path) {
    var notificationManager = server.notificationManager;
    return notificationManager.highlights.getResults(path);
  }

  Future<List<SemanticTokenInfo>> getServerResult(
    CompilationUnit unit,
    SourceRange? range,
  ) async {
    var computer = DartUnitHighlightsComputer(unit, range: range);
    return computer.computeSemanticTokens();
  }

  Iterable<SemanticTokenInfo> _filter(
    Iterable<SemanticTokenInfo> tokens,
    SourceRange? range,
  ) {
    if (range == null) {
      return tokens;
    }

    return tokens.where(
      (token) =>
          !(token.offset + token.length < range.offset ||
              token.offset > range.end),
    );
  }

  Future<ErrorOr<SemanticTokens?>> _handleImpl(
    TextDocumentIdentifier textDocument,
    CancellationToken token, {
    Range? range,
  }) {
    var path = pathOfDoc(textDocument);

    return path.mapResult((path) async {
      // Always prefer a LineInfo from a resolved unit than server.getLineInfo.
      var resolvedUnit = (await requireResolvedUnit(path)).resultOrNull;
      var lineInfo = resolvedUnit?.lineInfo ?? server.getLineInfo(path);

      // If there is no lineInfo, the request cannot be translated from LSP
      // line/col to server offset/length.
      if (lineInfo == null) {
        return success(null);
      }

      return toSourceRangeNullable(lineInfo, range).mapResult((range) async {
        var serverTokens =
            resolvedUnit != null
                ? await getServerResult(resolvedUnit.unit, range)
                : <SemanticTokenInfo>[];
        var pluginHighlightRegions = getPluginResults(path).flattenedToList;

        if (token.isCancellationRequested) {
          return cancelled(token);
        }

        var encoder = SemanticTokenEncoder();
        Iterable<SemanticTokenInfo> pluginTokens = encoder
            .convertHighlightToTokens(pluginHighlightRegions);

        // Plugin tokens are not filtered at source, so need to be filtered here.
        pluginTokens = _filter(pluginTokens, range);

        Iterable<SemanticTokenInfo> tokens = [...serverTokens, ...pluginTokens];

        // Capabilities exist for supporting multiline/overlapping tokens. These
        // could be used if any clients take it up (VS Code does not).
        // - clientCapabilities?.multilineTokenSupport
        // - clientCapabilities?.overlappingTokenSupport
        var allowMultilineTokens = false;
        var allowOverlappingTokens = false;

        // Some of the translation operations and the final encoding require
        // the tokens to be sorted. Do it once here to avoid each method needing
        // to do it itself (resulting in multiple sorts).
        tokens =
            tokens.toList()..sort(SemanticTokenInfo.offsetLengthPrioritySort);

        if (!allowOverlappingTokens) {
          tokens = encoder.splitOverlappingTokens(tokens);
        }

        if (!allowMultilineTokens) {
          tokens = tokens.expand(
            (token) => encoder.splitMultilineTokens(token, lineInfo),
          );

          // Tokens may need re-filtering after being split up as there may
          // now be tokens outside of the range.
          tokens = _filter(tokens, range);
        }

        var semanticTokens = encoder.encodeTokens(tokens.toList(), lineInfo);

        return success(semanticTokens);
      });
    });
  }
}

class SemanticTokensFullHandler
    extends AbstractSemanticTokensHandler<SemanticTokensParams> {
  SemanticTokensFullHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_semanticTokens_full;

  @override
  LspJsonHandler<SemanticTokensParams> get jsonHandler =>
      SemanticTokensParams.jsonHandler;

  @override
  Future<ErrorOr<SemanticTokens?>> handle(
    SemanticTokensParams params,
    MessageInfo message,
    CancellationToken token,
  ) => _handleImpl(params.textDocument, token);
}

class SemanticTokensRangeHandler
    extends AbstractSemanticTokensHandler<SemanticTokensRangeParams> {
  SemanticTokensRangeHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_semanticTokens_range;

  @override
  LspJsonHandler<SemanticTokensRangeParams> get jsonHandler =>
      SemanticTokensRangeParams.jsonHandler;

  @override
  Future<ErrorOr<SemanticTokens?>> handle(
    SemanticTokensRangeParams params,
    MessageInfo message,
    CancellationToken token,
  ) => _handleImpl(params.textDocument, token, range: params.range);
}

class SemanticTokensRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  SemanticTokensRegistrations(super.info);

  @override
  ToJsonable? get options => SemanticTokensRegistrationOptions(
    documentSelector: fullySupportedTypes,
    legend: semanticTokenLegend.lspLegend,
    full: Either2<bool, SemanticTokensFullDelta>.t2(
      SemanticTokensFullDelta(delta: false),
    ),
    range: Either2<bool, SemanticTokensOptionsRange>.t1(true),
  );

  @override
  Method get registrationMethod =>
      CustomMethods.semanticTokenDynamicRegistration;

  @override
  StaticOptions get staticOptions => Either2.t1(
    SemanticTokensOptions(
      legend: semanticTokenLegend.lspLegend,
      full: Either2.t2(SemanticTokensFullDelta(delta: false)),
      range: Either2.t1(true),
    ),
  );

  @override
  bool get supportsDynamic => clientDynamic.semanticTokens;
}
