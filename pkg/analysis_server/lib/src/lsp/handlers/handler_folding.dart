// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/computer/computer_folding.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';

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
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }

    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireUnresolvedUnit);

    return unit.mapResult((unit) {
      final lineInfo = unit.lineInfo;
      final regions = DartUnitFoldingComputer(lineInfo, unit.unit).compute();

      return success(
        regions.map((region) => toFoldingRange(lineInfo, region)).toList(),
      );
    });
  }
}
