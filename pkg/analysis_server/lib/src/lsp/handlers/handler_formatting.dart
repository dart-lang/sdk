// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';

class FormattingHandler
    extends MessageHandler<DocumentFormattingParams, List<TextEdit>> {
  FormattingHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_formatting;

  @override
  LspJsonHandler<DocumentFormattingParams> get jsonHandler =>
      DocumentFormattingParams.jsonHandler;

  ErrorOr<List<TextEdit>> formatFile(String path) {
    final file = server.resourceProvider.getFile(path);
    if (!file.exists) {
      return error(ServerErrorCodes.InvalidFilePath, 'Invalid file path', path);
    }

    final unformattedSource = file.readAsStringSync();
    return success(generateEditsForFormatting(
        unformattedSource, server.clientConfiguration.lineLength));
  }

  @override
  Future<ErrorOr<List<TextEdit>>> handle(
      DocumentFormattingParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    if (!server.clientConfiguration.enableSdkFormatter) {
      return error(ServerErrorCodes.FeatureDisabled,
          'Formatter was disabled by client settings');
    }

    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) => formatFile(path));
  }
}
