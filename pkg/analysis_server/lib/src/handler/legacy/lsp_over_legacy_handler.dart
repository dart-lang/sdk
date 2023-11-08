// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart' as lsp;
import 'package:analysis_server/src/lsp/json_parsing.dart';

/// The handler for the `lsp.handle` request.
class LspOverLegacyHandler extends LegacyHandler {
  /// To match behaviour of the LSP server where only one
  /// InitializedStateMessageHandler exists for a server (and handlers can be
  /// stateful), we hand the handler off the server.
  ///
  /// Using a static causes issues for in-process tests, so this ensures a new
  /// server always gets a new handler.
  final _handlers = Expando<InitializedStateMessageHandler>();

  LspOverLegacyHandler(
      super.server, super.request, super.cancellationToken, super.performance) {
    _handlers[server] ??= InitializedStateMessageHandler(server);
  }

  InitializedStateMessageHandler get handler => _handlers[server]!;

  @override
  bool get recordsOwnAnalytics => true;

  @override
  Future<void> handle() async {
    final params = LspHandleParams.fromRequest(request);
    final lspMessageJson = params.lspMessage;
    final reporter = LspJsonReporter();
    final lspMessage = lspMessageJson is Map<String, Object?> &&
            RequestMessage.canParse(lspMessageJson, reporter)
        ? RequestMessage.fromJson({
            // Pass across any clientRequestTime from the envelope so that we
            // can record latency for LSP-over-Legacy requests.
            'clientRequestTime': request.clientRequestTime,
            ...lspMessageJson,
          })
        : null;

    if (lspMessage != null) {
      server.analyticsManager.startedRequestMessage(
          request: lspMessage, startTime: DateTime.now());
      await handleRequest(lspMessage);
    } else {
      final message =
          "The 'lspMessage' parameter was not a valid LSP request:\n"
          "${reporter.errors.join('\n')}";
      final error = RequestError(RequestErrorCode.INVALID_PARAMETER, message);
      sendResponse(Response(request.id, error: error));
    }
  }

  Future<void> handleRequest(RequestMessage message) async {
    final messageInfo = lsp.MessageInfo(
      performance: performance,
      timeSinceRequest: request.timeSinceRequest,
    );

    ErrorOr<Object?> result;
    try {
      result = await handler.handleMessage(message, messageInfo);
    } catch (e) {
      final errorMessage =
          'An error occurred while handling ${message.method} request: $e';
      result = error(ServerErrorCodes.UnhandledError, errorMessage);
    }

    final lspResponse = ResponseMessage(
      id: message.id,
      error: result.isError ? result.error : null,
      result: !result.isError ? result.result : null,
      jsonrpc: jsonRpcVersion,
    );

    server.analyticsManager.sentResponseMessage(response: lspResponse);
    sendResult(LspHandleResult(lspResponse.toJson()));
  }
}
