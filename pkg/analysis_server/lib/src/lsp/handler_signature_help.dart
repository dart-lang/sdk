// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/computer/computer_signature.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';

class SignatureHelpHandler extends MessageHandler {
  final LspAnalysisServer server;
  SignatureHelpHandler(this.server);
  List<String> get handlesMessages => const ['textDocument/signatureHelp'];

  @override
  FutureOr<Object> handleMessage(IncomingMessage message) {
    if (message is RequestMessage &&
        message.method == 'textDocument/signatureHelp') {
      final params =
          convertParams(message, TextDocumentPositionParams.fromJson);
      return handleSignatureHelp(params);
    } else {
      throw 'Unexpected message';
    }
  }

  Future<SignatureHelp> handleSignatureHelp(
      TextDocumentPositionParams params) async {
    final path = pathOf(params.textDocument);
    ResolvedUnitResult result = await server.getResolvedUnit(path);
    // TODO(dantup): Handle bad paths/offsets.
    CompilationUnit unit = result?.unit;

    if (unit == null) {
      return null;
    }

    final pos = params.position;
    final offset = result.lineInfo.getOffsetOfLine(pos.line) + pos.character;

    final computer = new DartUnitSignatureComputer(unit, offset);
    if (computer.offsetIsValid) {
      final signature = computer.compute();
      if (signature != null) {
        return toSignatureHelp(signature);
      }
    }

    return null;
  }
}
