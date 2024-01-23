// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// The status of analysis.
sealed class AnalysisStatus {
  const AnalysisStatus._();

  bool get isAnalyzing;

  bool get isIdle => !isAnalyzing;
}

final class AnalysisStatusAnalyzing extends AnalysisStatus {
  /// Will complete when we switch to [AnalysisStatusIdle].
  final Completer<void> _idleCompleter = Completer<void>();

  AnalysisStatusAnalyzing._() : super._();

  @override
  bool get isAnalyzing => true;

  @override
  String toString() => 'analyzing';
}

final class AnalysisStatusIdle extends AnalysisStatus {
  const AnalysisStatusIdle._() : super._();

  @override
  bool get isAnalyzing => false;

  @override
  String toString() => 'idle';
}

/// [Monitor] can be used to wait for a signal.
///
/// Signals are not queued, the client will receive exactly one signal
/// regardless of the number of [notify] invocations. The [signal] is reset
/// after completion and will not complete until [notify] is called next time.
class Monitor {
  Completer<void> _completer = Completer<void>();

  /// Return a [Future] that completes when [notify] is called at least once.
  Future<void> get signal async {
    await _completer.future;
    _completer = Completer<void>();
  }

  /// Complete the [signal] future if it is not completed yet. It is safe to
  /// call this method multiple times, but the [signal] will complete only once.
  void notify() {
    if (!_completer.isCompleted) {
      _completer.complete(null);
    }
  }
}

/// Helper for managing transitioning [AnalysisStatus].
class StatusSupport {
  final StreamController<Object> _eventsController;

  /// The controller for the [stream].
  final _statusController = StreamController<AnalysisStatus>();

  /// The last status sent to the [stream].
  AnalysisStatus _currentStatus = const AnalysisStatusIdle._();

  StatusSupport({
    required StreamController<Object> eventsController,
  }) : _eventsController = eventsController;

  /// Return the last status sent to the [stream].
  AnalysisStatus get currentStatus => _currentStatus;

  /// Return the stream that produces [AnalysisStatus] events.
  Stream<AnalysisStatus> get stream => _statusController.stream;

  /// If the current status is not [AnalysisStatusAnalyzing] yet, set the
  /// current status to it, and send it to the stream.
  void transitionToAnalyzing() {
    if (_currentStatus is AnalysisStatusIdle) {
      var newStatus = AnalysisStatusAnalyzing._();
      _currentStatus = newStatus;
      _eventsController.add(newStatus);
      _statusController.add(newStatus);
    }
  }

  /// If the current status is not [AnalysisStatusIdle] yet, set the
  /// current status to it, and send it to the stream.
  void transitionToIdle() {
    if (_currentStatus case AnalysisStatusAnalyzing status) {
      var newStatus = const AnalysisStatusIdle._();
      _currentStatus = newStatus;
      _eventsController.add(newStatus);
      _statusController.add(newStatus);
      status._idleCompleter.complete();
    }
  }

  /// If the current status is [AnalysisStatusIdle], returns the future that
  /// will complete immediately.
  ///
  /// If the current status is [AnalysisStatusAnalyzing], returns the future
  /// that will complete when the status changes to [AnalysisStatusIdle].
  Future<void> waitForIdle() {
    switch (_currentStatus) {
      case AnalysisStatusIdle():
        return Future<void>.value();
      case AnalysisStatusAnalyzing status:
        return status._idleCompleter.future;
    }
  }
}
