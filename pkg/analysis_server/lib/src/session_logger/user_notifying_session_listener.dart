// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/server/error_notifier.dart';
import 'package:analysis_server/src/session_logger/process_id.dart';
import 'package:analysis_server/src/session_logger/session_listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/service.dart';

/// A session listener that notifies users when an exception is reported.
///
/// This class can only notify users if the client supports showing messages.
class UserNotifyingSessionListener implements SessionListener {
  AnalysisServer? server;

  bool sendSilentExceptionsToClient = false;

  @override
  void addPackageRoots({
    required int index,
    required Map<String, Uri> packageRoots,
  }) {
    // Not sent to the user.
  }

  @override
  void logCommandLine({required List<String> arguments}) {
    // Not sent to the user.
  }

  @override
  void logException({
    required Object exception,
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  }) {
    var server = this.server;
    if (server == null) {
      return;
    }

    // Silent exceptions should not be reported to the user unless this
    // flag is set (this is used by 'dart analyze').
    if (exception is SilentException && !sendSilentExceptionsToClient) {
      return;
    }

    var message = 'Internal error';
    if (exception is CaughtException) {
      var message = exception.message;
      if (message != null) {
        // TODO(mfairhurst): Use the outermost exception once crash reporting is
        //  fixed and this becomes purely user-facing.
        exception = exception.rootCaughtException;
        // TODO(mfairhurst): Use the outermost message rather than the innermost
        //  exception as its own message.
        message = message;
      }
    }

    server.sendServerErrorNotification(
      message,
      exception,
      stackTrace,
      fatal: exception is FatalException,
    );
  }

  @override
  void logInfo(String message) {
    // Not sent to the user.
  }

  @override
  void logMessage({
    required ProcessId from,
    required ProcessId to,
    required JsonMap message,
  }) {
    // Not sent to the user.
  }

  @override
  Future<void> shutdown() {
    // There is nothing to do before shutting down.
    return Future.value();
  }
}
