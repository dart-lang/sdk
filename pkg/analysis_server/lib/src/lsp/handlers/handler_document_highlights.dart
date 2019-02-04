// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/domains/analysis/occurrences.dart';
import 'package:analysis_server/src/domains/analysis/occurrences_dart.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';

class DocumentHighlightsHandler extends MessageHandler<
    TextDocumentPositionParams, List<DocumentHighlight>> {
  DocumentHighlightsHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_documentHighlight;

  @override
  TextDocumentPositionParams convertParams(Map<String, dynamic> json) =>
      TextDocumentPositionParams.fromJson(json);

  Future<ErrorOr<List<DocumentHighlight>>> handle(
      TextDocumentPositionParams params) async {
    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((requestedOffset) {
      final collector = new OccurrencesCollectorImpl();
      addDartOccurrences(collector, unit.result.unit);

      // Find an occurrence that has an instance that spans the position.
      for (final occurrence in collector.allOccurrences) {
        bool spansRequestedPosition(int offset) {
          return offset <= requestedOffset &&
              offset + occurrence.length >= requestedOffset;
        }

        if (occurrence.offsets.any(spansRequestedPosition)) {
          return success(toHighlights(unit.result.lineInfo, occurrence));
        }
      }

      // No matches.
      return success(null);
    });
  }
}
