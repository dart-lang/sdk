// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'adapters/dart.dart';
import 'protocol_generated.dart';

/// A reporter that can send progress notifications to the client.
abstract class DapProgressReporter {
  final DartDebugAdapter adapter;

  /// The ID for the this progress, used by the client to distinguish between
  /// any overlapping progress.
  final String id;

  /// A suffix to use for the next token to ensure all IDs are unique.
  static int nextIdSuffix = 1;

  DapProgressReporter(this.adapter, String idPrefix)
      : id = '${idPrefix}_${nextIdSuffix++}';

  void _start(String title, String? message) {
    sendStart(ProgressStartEventBody(
      progressId: id,
      title: title,
      message: message,
    ));
  }

  void update({required String message}) {
    sendUpdate(ProgressUpdateEventBody(progressId: id, message: message));
  }

  void end([String? message]) {
    sendEnd(ProgressEndEventBody(progressId: id, message: message));
  }

  /// Creates a progress reporter and sends the start event.
  factory DapProgressReporter.start(
    DartDebugAdapter adapter,
    String idPrefix,
    String title, {
    String? message,
  }) {
    final supportsStandardProgress =
        adapter.initializeArgs?.supportsProgressReporting ?? false;
    final useCustomProgress = adapter.args.sendCustomProgressEvents ?? false;

    final reporter = useCustomProgress
        ? _CustomDapProgressReporter(adapter, idPrefix)
        : supportsStandardProgress
            ? _StandardDapProgressReporter(adapter, idPrefix)
            : _NoopDapProgressReporter(adapter, idPrefix);

    return reporter.._start(title, message);
  }

  void sendStart(ProgressStartEventBody body);
  void sendUpdate(ProgressUpdateEventBody body);
  void sendEnd(ProgressEndEventBody body);
}

/// Sends progress notifications using custom events.
///
/// Custom events are used by VS Code to allow the Dart extension to control the
/// notifications instead of VS Code, which allows them to be shown immediately
/// instead of after a 500ms debounce which can cause fast Hot Reload
/// notifications to never be shown and provide no user feedback.
///
/// https://github.com/microsoft/vscode/issues/101405
class _CustomDapProgressReporter extends DapProgressReporter {
  _CustomDapProgressReporter(DartDebugAdapter adapter, String idPrefix)
      : super(adapter, idPrefix);

  @override
  void sendStart(ProgressStartEventBody body) {
    adapter.sendEvent(body, eventType: 'dart.progressStart');
  }

  @override
  void sendUpdate(ProgressUpdateEventBody body) {
    adapter.sendEvent(body, eventType: 'dart.progressUpdate');
  }

  @override
  void sendEnd(ProgressEndEventBody body) {
    adapter.sendEvent(body, eventType: 'dart.progressEnd');
  }
}

/// Sends progress notifications using standard events.
class _StandardDapProgressReporter extends DapProgressReporter {
  _StandardDapProgressReporter(DartDebugAdapter adapter, String idPrefix)
      : super(adapter, idPrefix);

  @override
  void sendStart(ProgressStartEventBody body) {
    adapter.sendEvent(body);
  }

  @override
  void sendUpdate(ProgressUpdateEventBody body) {
    adapter.sendEvent(body);
  }

  @override
  void sendEnd(ProgressEndEventBody body) {
    adapter.sendEvent(body);
  }
}

/// A [DapProgressReporter] that does not send any events.
class _NoopDapProgressReporter extends DapProgressReporter {
  _NoopDapProgressReporter(DartDebugAdapter adapter, String idPrefix)
      : super(adapter, idPrefix);

  @override
  void sendStart(ProgressStartEventBody body) {}

  @override
  void sendUpdate(ProgressUpdateEventBody body) {}

  @override
  void sendEnd(ProgressEndEventBody body) {}
}
