// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// The status of analysis.
class AnalysisStatus {
  static const IDLE = AnalysisStatus._(false);
  static const ANALYZING = AnalysisStatus._(true);

  final bool _analyzing;

  const AnalysisStatus._(this._analyzing);

  /// Return `true` if the scheduler is analyzing.
  bool get isAnalyzing => _analyzing;

  /// Return `true` if the scheduler is idle.
  bool get isIdle => !_analyzing;

  @override
  String toString() => _analyzing ? 'analyzing' : 'idle';
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
  AnalysisStatus _currentStatus = AnalysisStatus.IDLE;

  /// If non-null, a completer which should be completed on the next transition
  /// to idle.
  Completer<void>? _idleCompleter;

  StatusSupport({
    required StreamController<Object> eventsController,
  }) : _eventsController = eventsController;

  /// Return the last status sent to the [stream].
  AnalysisStatus get currentStatus => _currentStatus;

  /// Return the stream that produces [AnalysisStatus] events.
  Stream<AnalysisStatus> get stream => _statusController.stream;

  /// If the current status is not [AnalysisStatus.ANALYZING] yet, set the
  /// current status to it, and send it to the stream.
  void transitionToAnalyzing() {
    if (_currentStatus != AnalysisStatus.ANALYZING) {
      _idleCompleter = Completer<void>();
      _currentStatus = AnalysisStatus.ANALYZING;
      _eventsController.add(AnalysisStatus.ANALYZING);
      _statusController.add(AnalysisStatus.ANALYZING);
    }
  }

  /// If the current status is not [AnalysisStatus.IDLE] yet, set the
  /// current status to it, and send it to the stream.
  void transitionToIdle() {
    if (_currentStatus != AnalysisStatus.IDLE) {
      _currentStatus = AnalysisStatus.IDLE;
      _eventsController.add(AnalysisStatus.IDLE);
      _statusController.add(AnalysisStatus.IDLE);
      // TODO(scheglov): Use separate status classes?
      _idleCompleter!.complete();
      _idleCompleter = null;
    }
  }

  /// Return a future that will be completed the next time the status is idle.
  ///
  /// If the status is currently idle, the returned future will be signaled
  /// immediately.
  Future<void> waitForIdle() {
    return _idleCompleter?.future ?? Future<void>.value();
  }
}
