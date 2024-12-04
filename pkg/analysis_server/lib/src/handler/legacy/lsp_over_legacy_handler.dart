// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart' as lsp;
import 'package:analyzer/dart/analysis/session.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:language_server_protocol/protocol_special.dart';

/// The handler for the `lsp.handle` request.
class LspOverLegacyHandler extends LegacyHandler {
  LspOverLegacyHandler(
    super.server,
    super.request,
    super.cancellationToken,
    super.performance,
  );

  @override
  bool get recordsOwnAnalytics => true;

  @override
  Future<void> handle() async {
    server.initializeLspOverLegacy();

    var params = LspHandleParams.fromRequest(
      request,
      clientUriConverter: server.uriConverter,
    );
    var lspMessageJson = params.lspMessage;
    var reporter = LspJsonReporter();
    var lspMessage =
        lspMessageJson is Map<String, Object?> &&
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
        request: lspMessage,
        startTime: DateTime.now(),
      );
      await handleRequest(lspMessage);
    } else {
      var message =
          "The 'lspMessage' parameter was not a valid LSP request:\n"
          "${reporter.errors.join('\n')}";
      var error = RequestError(RequestErrorCode.INVALID_PARAMETER, message);
      sendResponse(Response(request.id, error: error));
    }
  }

  Future<void> handleRequest(RequestMessage message) async {
    var messageInfo = lsp.MessageInfo(
      performance: performance,
      clientCapabilities: server.editorClientCapabilities,
      timeSinceRequest: request.timeSinceRequest,
    );

    ErrorOr<Object?> result;
    try {
      // Since this (legacy) request was already scheduled, we immediately
      // execute the wrapped LSP request without additional scheduling.
      result = await server.immediatelyHandleLspMessage(
        message,
        messageInfo,
        cancellationToken: cancellationToken,
      );
    } on InconsistentAnalysisException {
      result = error(
        ErrorCodes.ContentModified,
        'Document was modified before operation completed',
      );
    } catch (e) {
      var errorMessage =
          'An error occurred while handling ${message.method} request: $e';
      result = error(ServerErrorCodes.UnhandledError, errorMessage);
    }

    var lspResponse = ResponseMessage(
      id: message.id,
      error: result.errorOrNull,
      result: result.resultOrNull,
      jsonrpc: jsonRpcVersion,
    );

    server.analyticsManager.sentResponseMessage(response: lspResponse);
    sendResult(LspHandleResult(lspResponse.toJson()));
  }
}
