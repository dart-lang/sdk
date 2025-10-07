// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/domains/analysis/occurrences_dart.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analyzer/dart/ast/token.dart';

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
      var occurrences = getAllOccurrences(unit.unit);

      /// Checks whether an Occurrence token spans the requested
      /// offset.
      ///
      /// It's possible multiple occurrences might match because some nodes
      /// such as object destructuring might match multiple elements (for
      /// example the object getter and a declared variable).
      bool spansRequestedPosition(Token token) {
        return token.offset <= requestedOffset && token.end >= requestedOffset;
      }

      // Find the groups of tokens that contains an
      // offset/length that spans the requested range. There may be multiple
      // matches here if the source element is in multiple groups.
      var matchingSet = <Token>{};

      for (var occurrence in occurrences) {
        var tokens = occurrence.tokens;
        if (tokens.any(spansRequestedPosition)) {
          matchingSet.addAll(tokens);
        }
      }

      // No matches will return an empty list (not null) because that prevents
      // the editor falling back to a text search.
      var highlights = matchingSet
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
