// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/computer/computer_folding.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';

class FoldingHandler
    extends MessageHandler<FoldingRangeParams, List<FoldingRange>> {
  FoldingHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_foldingRange;

  @override
  LspJsonHandler<FoldingRangeParams> get jsonHandler =>
      FoldingRangeParams.jsonHandler;

  @override
  Future<ErrorOr<List<FoldingRange>>> handle(
      FoldingRangeParams params, CancellationToken token) async {
    final path = pathOfDoc(params.textDocument);

    return path.mapResult((path) async {
      final partialResults = <List<FoldingRegion>>[];
      LineInfo lineInfo;

      final unit = server.getParsedUnit(path);
      if (unit?.state == ResultState.VALID) {
        lineInfo = unit.lineInfo;

        final regions = DartUnitFoldingComputer(lineInfo, unit.unit).compute();
        partialResults.insert(0, regions);
      }

      // Still try to obtain line info for invalid or non-Dart files, as plugins
      // could contribute to those.
      lineInfo ??= server.getLineInfo(path);

      if (lineInfo == null) {
        // Line information would be required to translate folding results to
        // LSP.
        return success(const []);
      }

      final notificationManager = server.notificationManager;
      final pluginResults = notificationManager.folding.getResults(path);
      partialResults.addAll(pluginResults);

      final regions =
          notificationManager.merger.mergeFoldingRegions(partialResults);

      return success(
        regions.map((region) => toFoldingRange(lineInfo, region)).toList(),
      );
    });
  }
}
