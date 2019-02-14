// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analyzer/dart/analysis/results.dart';

class FormattingHandler
    extends MessageHandler<DocumentFormattingParams, List<TextEdit>> {
  FormattingHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_formatting;

  @override
  DocumentFormattingParams convertParams(Map<String, dynamic> json) =>
      DocumentFormattingParams.fromJson(json);

  ErrorOr<List<TextEdit>> formatFile(String path, ResolvedUnitResult unit) {
    final unformattedSource =
        server.resourceProvider.getFile(path).readAsStringSync();

    return success(generateEditsForFormatting(unformattedSource));
  }

  Future<ErrorOr<List<TextEdit>>> handle(
      DocumentFormattingParams params) async {
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireUnit);
    return unit.mapResult((unit) => formatFile(path.result, unit));
  }
}
