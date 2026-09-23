// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server/src/handler/legacy/lsp_over_legacy_handler.dart';
library;

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart' as lsp;
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';

/// The handler for the `lsp.notification` notification.
///
/// Unlike [LspOverLegacyHandler] there is no response to send, so a failure to
/// handle the wrapped LSP notification is logged instead of being reported back
/// to the client.
class LspNotificationOverLegacyHandler {
  /// The analysis server that is using this handler to process a notification.
  final LegacyAnalysisServer server;

  /// The notification being handled.
  final Notification notification;

  new(this.server, this.notification);

  Future<void> handle() async {
    server.initializeLspOverLegacy();
    server.ensureLspInitializedForClientWithoutCapabilities();

    LspNotificationParams params;
    try {
      params = LspNotificationParams.fromNotification(
        notification,
        clientUriConverter: server.uriConverter,
      );
    } catch (exception) {
      // The client sent something that is not a valid `lsp.notification`. That
      // is a client error rather than a server failure, and there is no
      // response to report it in, so it is only logged.
      server.instrumentationService.logError(
        "The 'lsp.notification' notification was not valid: $exception",
      );
      return;
    }

    var reporter = LspJsonReporter();
    var lspNotificationJson = params.lspNotification;
    if (lspNotificationJson is! Map<String, Object?> ||
        !NotificationMessage.canParse(lspNotificationJson, reporter)) {
      server.instrumentationService.logError(
        "The 'lspNotification' parameter was not a valid LSP notification:\n"
        "${reporter.errors.join('\n')}",
      );
      return;
    }

    await _handle(NotificationMessage.fromJson(lspNotificationJson));
  }

  Future<void> _handle(NotificationMessage message) async {
    var messageInfo = lsp.MessageInfo(
      performance: OperationPerformanceImpl('<lsp.notification>'),
      clientCapabilities: server.editorClientCapabilities,
      isTrustedCaller: true,
    );

    var startTime = DateTime.now();
    try {
      // Since this notification was already scheduled, we immediately execute
      // the wrapped LSP notification without additional scheduling.
      //
      // Waiting for the handler is safe even if it sends a request to the
      // client (such as `workspace/configuration`) because there is no response
      // for the client to be waiting on here and responses from the client are
      // not scheduled.
      var result = await server.immediatelyHandleLspMessage(
        message,
        messageInfo,
      );
      var lspError = result.errorOrNull;
      if (lspError != null) {
        _logError(message, lspError.message);
      }
    } on InconsistentAnalysisException {
      _logError(message, 'Document was modified before operation completed');
    } catch (exception, stackTrace) {
      // Unlike the expected failure above, this is unexpected, so it is
      // recorded as an exception like `LspAnalysisServer.logException` does.
      server.instrumentationService.logException(
        CaughtException.withMessage(
          'An error occurred while handling ${message.method} notification',
          exception,
          stackTrace,
        ),
      );
    } finally {
      server.analyticsManager.handledNotificationMessage(
        notification: message,
        startTime: startTime,
        endTime: DateTime.now(),
      );
    }
  }

  /// Logs that handling the notification [message] failed with [error].
  ///
  /// Unlike requests, LSP notifications have no response, so the failure can't
  /// be delivered back as part of an LSP ResponseMessage. The LSP server shows
  /// such failures to the user with 'window/showMessage' (see
  /// `LspAnalysisServer.showErrorMessageToUser`) but that is LSP-only, so
  /// logging is the closest the legacy protocol has to offer.
  void _logError(NotificationMessage message, String error) {
    server.instrumentationService.logError(
      'An error occurred while handling ${message.method} notification: $error',
    );
  }
}
