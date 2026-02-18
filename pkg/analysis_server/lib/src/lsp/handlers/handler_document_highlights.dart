// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/computer/computer_document_highlights.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';

typedef StaticOptions = Either2<bool, DocumentHighlightOptions>;

class DocumentHighlightsHandler
    extends
        SharedMessageHandler<
          TextDocumentPositionParams,
          List<DocumentHighlight>
        > {
  DocumentHighlightsHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_documentHighlight;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<List<DocumentHighlight>>> handle(
    TextDocumentPositionParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }

    var pos = params.position;
    var path = pathOfDoc(params.textDocument);
    var unit = await path.mapResult(requireResolvedUnit);
    var offset = unit.mapResultSync((unit) => toOffset(unit.lineInfo, pos));

    return (unit, offset).mapResults((unit, requestedOffset) async {
      var computer = DartDocumentHighlightsComputer(unit.unit);
      var matchingTokens = computer.compute(requestedOffset);

      // No matches will return an empty list (not null) because that prevents
      // the editor falling back to a text search.
      var highlights = matchingTokens
          .map(
            (token) => DocumentHighlight(
              range: toRange(unit.lineInfo, token.offset, token.length),
            ),
          )
          .toList();

      return success(highlights);
    });
  }
}

class DocumentHighlightsRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  DocumentHighlightsRegistrations(super.info);

  @override
  ToJsonable? get options =>
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes);

  @override
  Method get registrationMethod => Method.textDocument_documentHighlight;

  @override
  StaticOptions get staticOptions => Either2.t1(true);

  @override
  bool get supportsDynamic => clientDynamic.documentHighlights;
}
