// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_signature.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';

class SignatureHelpHandler
    extends MessageHandler<TextDocumentPositionParams, SignatureHelp> {
  SignatureHelpHandler(LspAnalysisServer server) : super(server);
  String get handlesMessage => 'textDocument/signatureHelp';

  @override
  TextDocumentPositionParams convertParams(Map<String, dynamic> json) =>
      TextDocumentPositionParams.fromJson(json);

  Future<SignatureHelp> handle(TextDocumentPositionParams params) async {
    final path = pathOf(params.textDocument);
    final result = await requireUnit(path);
    final offset = toOffset(result.lineInfo, params.position);

    final computer = new DartUnitSignatureComputer(result.unit, offset);
    if (computer.offsetIsValid) {
      final signature = computer.compute();
      if (signature != null) {
        final formats = server?.clientCapabilities?.textDocument?.signatureHelp
            ?.signatureInformation?.documentationFormat;
        return toSignatureHelp(formats, signature);
      }
    }

    return null;
  }
}
