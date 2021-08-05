// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analyzer/dart/analysis/results.dart';

class FormatRangeHandler
    extends MessageHandler<DocumentRangeFormattingParams, List<TextEdit>?> {
  FormatRangeHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_rangeFormatting;

  @override
  LspJsonHandler<DocumentRangeFormattingParams> get jsonHandler =>
      DocumentRangeFormattingParams.jsonHandler;

  ErrorOr<List<TextEdit>?> formatRange(String path, Range range) {
    final file = server.resourceProvider.getFile(path);
    if (!file.exists) {
      return error(ServerErrorCodes.InvalidFilePath, 'Invalid file path', path);
    }

    final result = server.getParsedUnit(path);
    if (result?.state != ResultState.VALID || result!.errors.isNotEmpty) {
      return success(null);
    }

    final lineLength = server.clientConfiguration.forResource(path).lineLength;
    return generateEditsForFormatting(result, lineLength, range: range);
  }

  @override
  Future<ErrorOr<List<TextEdit>?>> handle(
      DocumentRangeFormattingParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) {
      if (!server.clientConfiguration.forResource(path).enableSdkFormatter) {
        // Because we now support formatting for just some WorkspaceFolders
        // we should silently do nothing for those that are disabled.
        return success(null);
      }
      return formatRange(path, params.range);
    });
  }
}
