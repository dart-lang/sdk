// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/process_id.dart';
import 'package:analysis_server/src/session_logger/session_listener.dart';
import 'package:analyzer/instrumentation/service.dart';

/// A session listener that will forward events to two or more other session
/// listeners.
class ForwardingSessionListener(
  /// The listeners to which events will be forwarded.
  final List<SessionListener> _listeners,
) implements SessionListener {
  @override
  void addPackageRoots({
    required int index,
    required Map<String, Uri> packageRoots,
  }) {
    for (var listener in _listeners) {
      listener.addPackageRoots(index: index, packageRoots: packageRoots);
    }
  }

  @override
  void logCommandLine({required List<String> arguments}) {
    for (var listener in _listeners) {
      listener.logCommandLine(arguments: arguments);
    }
  }

  @override
  void logException({
    required Object exception,
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  }) {
    for (var listener in _listeners) {
      listener.logException(
        exception: exception,
        stackTrace: stackTrace,
        attachments: attachments,
      );
    }
  }

  @override
  void logInfo(String message) {
    for (var listener in _listeners) {
      listener.logInfo(message);
    }
  }

  @override
  void logMessage({
    required ProcessId from,
    required ProcessId to,
    required JsonMap message,
  }) {
    for (var listener in _listeners) {
      listener.logMessage(from: from, to: to, message: message);
    }
  }

  @override
  Future<void> shutdown() {
    return Future.wait(_listeners.map((s) => s.shutdown()));
  }
}
