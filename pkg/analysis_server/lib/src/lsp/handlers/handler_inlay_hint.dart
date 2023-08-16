// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/computer/computer_inlay_hint.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';

class InlayHintHandler
    extends LspMessageHandler<InlayHintParams, List<InlayHint>> {
  InlayHintHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_inlayHint;

  @override
  LspJsonHandler<InlayHintParams> get jsonHandler =>
      InlayHintParams.jsonHandler;

  @override
  Future<ErrorOr<List<InlayHint>>> handle(InlayHintParams params,
      MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success([]);
    }

    final path = pathOfDoc(params.textDocument);

    // It's particularly important to provide results consistent with the
    // document in the client in this handler to avoid inlay hints "jumping
    // around" while the user types, so ensure no other requests (content
    // updates) are processed while we do async work to get the resolved unit.
    late ErrorOr<ResolvedUnitResult> result;
    await server.lockRequestsWhile(() async {
      result = await path.mapResult(requireResolvedUnit);
    });

    if (token.isCancellationRequested) {
      return cancelled();
    }

    return result.mapResult((result) async {
      if (!result.exists) {
        return success([]);
      }

      final computer = DartInlayHintComputer(pathContext, result);
      final hints = computer.compute();

      return success(hints);
    });
  }
}
