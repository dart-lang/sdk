// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/noop_service.dart';
import 'package:analyzer/instrumentation/plugin_data.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:telemetry/crash_reporting.dart';

class CrashReportingInstrumentation extends NoopInstrumentationService {
  final CrashReportSender reporter;

  CrashReportingInstrumentation(this.reporter);

  @override
  void logException(dynamic exception,
      [StackTrace stackTrace,
      List<InstrumentationServiceAttachment> attachments]) {
    var crashReportAttachments = (attachments ?? []).map((e) {
      return CrashReportAttachment.string(
        field: 'attachment_${e.id}',
        value: e.stringValue,
      );
    }).toList();

    if (exception is CaughtException) {
      // Get the root CaughtException, which matters most for debugging.
      var root = exception.rootCaughtException;

      reporter
          .sendReport(root.exception, root.stackTrace,
              attachments: crashReportAttachments, comment: root.message)
          .catchError((error) {
        // We silently ignore errors sending crash reports (network issues, ...).
      });
    } else {
      reporter
          .sendReport(exception, stackTrace ?? StackTrace.current,
              attachments: crashReportAttachments)
          .catchError((error) {
        // We silently ignore errors sending crash reports (network issues, ...).
      });
    }
  }

  @override
  void logPluginException(
    PluginData plugin,
    dynamic exception,
    StackTrace stackTrace,
  ) {
    // TODO(devoncarew): Temporarily disabled; re-enable after deciding on a
    // plan of action for the AngularDart analysis plugin.
    const angularPluginName = 'Angular Analysis Plugin';
    if (plugin.name == angularPluginName) {
      return;
    }

    reporter
        .sendReport(exception, stackTrace, comment: 'plugin: ${plugin.name}')
        .catchError((error) {
      // We silently ignore errors sending crash reports (network issues, ...).
    });
  }
}
