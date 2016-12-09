// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/**
 * The status of analysis.
 */
class AnalysisStatus {
  static const IDLE = const AnalysisStatus._(false);
  static const ANALYZING = const AnalysisStatus._(true);

  final bool _analyzing;

  const AnalysisStatus._(this._analyzing);

  /**
   * Return `true` is the driver is analyzing.
   */
  bool get isAnalyzing => _analyzing;

  /**
   * Return `true` is the driver is idle.
   */
  bool get isIdle => !_analyzing;

  @override
  String toString() => _analyzing ? 'analyzing' : 'idle';
}

/**
 * [Monitor] can be used to wait for a signal.
 *
 * Signals are not queued, the client will receive exactly one signal
 * regardless of the number of [notify] invocations. The [signal] is reset
 * after completion and will not complete until [notify] is called next time.
 */
class Monitor {
  Completer<Null> _completer = new Completer<Null>();

  /**
   * Return a [Future] that completes when [notify] is called at least once.
   */
  Future<Null> get signal async {
    await _completer.future;
    _completer = new Completer<Null>();
  }

  /**
   * Complete the [signal] future if it is not completed yet. It is safe to
   * call this method multiple times, but the [signal] will complete only once.
   */
  void notify() {
    if (!_completer.isCompleted) {
      _completer.complete(null);
    }
  }
}

/**
 * Helper for managing transitioning [AnalysisStatus].
 */
class StatusSupport {
  /**
   * The controller for the [stream].
   */
  final _statusController = new StreamController<AnalysisStatus>();

  /**
   * The last status sent to the [stream].
   */
  AnalysisStatus _currentStatus = AnalysisStatus.IDLE;

  /**
   * Return the last status sent to the [stream].
   */
  AnalysisStatus get currentStatus => _currentStatus;

  /**
   * Return the stream that produces [AnalysisStatus] events.
   */
  Stream<AnalysisStatus> get stream => _statusController.stream;

  /**
   * Send a notifications to the [stream] that the driver started analyzing.
   */
  void transitionToAnalyzing() {
    if (_currentStatus != AnalysisStatus.ANALYZING) {
      _currentStatus = AnalysisStatus.ANALYZING;
      _statusController.add(AnalysisStatus.ANALYZING);
    }
  }

  /**
   * Send a notifications to the [stream] stream that the driver is idle.
   */
  void transitionToIdle() {
    if (_currentStatus != AnalysisStatus.IDLE) {
      _currentStatus = AnalysisStatus.IDLE;
      _statusController.add(AnalysisStatus.IDLE);
    }
  }
}
