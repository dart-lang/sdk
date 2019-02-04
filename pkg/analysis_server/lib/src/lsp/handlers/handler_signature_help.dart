// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/computer/computer_signature.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';

class SignatureHelpHandler
    extends MessageHandler<TextDocumentPositionParams, SignatureHelp> {
  SignatureHelpHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_signatureHelp;

  @override
  TextDocumentPositionParams convertParams(Map<String, dynamic> json) =>
      TextDocumentPositionParams.fromJson(json);

  Future<ErrorOr<SignatureHelp>> handle(
      TextDocumentPositionParams params) async {
    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((offset) {
      final computer = new DartUnitSignatureComputer(unit.result.unit, offset);
      if (!computer.offsetIsValid) {
        return success(); // No error, just no valid hover.
      }
      final signature = computer.compute();
      if (signature == null) {
        return success(); // No error, just no valid hover.
      }
      final formats = server?.clientCapabilities?.textDocument?.signatureHelp
          ?.signatureInformation?.documentationFormat;
      return success(toSignatureHelp(formats, signature));
    });
  }
}
