// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/process_id.dart';
import 'package:analysis_server/src/session_logger/session_listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:telemetry/crash_reporting.dart';

/// A session listener that will send reported exceptions to the crash reporting
/// service.
class CrashReportingSessionListener(
  // The object used to report analysis server crashes.
  final CrashReportSender serverReporter,
) implements SessionListener {
  @override
  void addPackageRoots({
    required int index,
    required Map<String, Uri> packageRoots,
  }) {
    // Nothing to report.
  }

  @override
  void logCommandLine({required List<String> arguments}) {
    // Nothing to report.
  }

  @override
  void logException({
    required Object exception,
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  }) {
    var crashReportAttachments = (attachments ?? []).map((e) {
      return CrashReportAttachment.string(
        field: 'attachment_${e.id}',
        value: e.stringValue,
      );
    }).toList();

    if (exception is CaughtException) {
      // Get the root CaughtException, which matters most for debugging.
      var root = exception.rootCaughtException;
      var message = root.message;
      if (message == null) {
        _sendServerReport(
          root.exception,
          root.stackTrace,
          attachments: crashReportAttachments,
        );
      } else {
        _sendServerReport(
          root.exception,
          root.stackTrace,
          attachments: crashReportAttachments,
          comment: message,
        );
      }
    } else {
      _sendServerReport(
        exception,
        stackTrace ?? StackTrace.current,
        attachments: crashReportAttachments,
      );
    }
  }

  @override
  void logInfo(String message) {
    // Nothing to report.
  }

  @override
  void logMessage({
    required ProcessId from,
    required ProcessId to,
    required JsonMap message,
  }) {
    // Nothing to report.
  }

  @override
  Future<void> shutdown() {
    // There is nothing to do before shutting down.
    return Future.value();
  }

  /// Use the [serverReporter] to send a crash report.
  void _sendServerReport(
    Object exception,
    StackTrace stackTrace, {
    String? comment,
    List<CrashReportAttachment>? attachments,
  }) {
    serverReporter
        .sendReport(
          exception,
          stackTrace,
          attachments: attachments ?? const [],
          comment: comment,
        )
        .catchError((error) {
          // We silently ignore errors sending crash reports because there isn't
          // anything useful that we can do with the failure.
        });
  }
}
