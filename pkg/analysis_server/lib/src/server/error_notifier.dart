// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';

/// An instrumentation service to show instrumentation errors as error
/// notifications to the user.
class ErrorNotifier extends NoopInstrumentationService {
  AnalysisServer? server;
  bool sendSilentExceptionsToClient = false;

  @override
  void logException(
    Object exception, [
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  ]) {
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
}

/// Server may throw a [FatalException] to send a fatal error response to the
/// IDEs.
class FatalException extends CaughtException {
  FatalException(String super.message, super.exception, super.stackTrace)
    : super.withMessage();
}
