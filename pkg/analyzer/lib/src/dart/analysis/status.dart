// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/fine/requirement_failure.dart';

/// The status of analysis.
sealed class AnalysisStatus {
  const AnalysisStatus._();

  bool get isIdle => !isWorking;

  bool get isWorking;
}

final class AnalysisStatusIdle extends AnalysisStatus {
  /// Statistics accumulated during the finished period of working.
  final AnalysisStatusWorkingStatistics? workingStatistics;

  AnalysisStatusIdle._({required this.workingStatistics}) : super._();

  @override
  bool get isWorking => false;

  @override
  String toString() => 'idle';
}

final class AnalysisStatusWorking extends AnalysisStatus {
  /// Will complete when we switch to [AnalysisStatusIdle].
  final Completer<void> _idleCompleter = Completer<void>();

  /// Accumulator for statistics during this working period.
  final AnalysisStatusWorkingStatistics workingStatistics;

  AnalysisStatusWorking._({required this.workingStatistics}) : super._();

  @override
  bool get isWorking => true;

  @override
  String toString() => 'working';
}

/// Accumulator for statistics during a single period of working.
class AnalysisStatusWorkingStatistics {
  final bool withFineDependencies;

  /// Files changed before the described working period.
  /// Usually probably just one, as the user types in the editor.
  final Set<String> changedFiles;

  /// Files removed before the described working period.
  /// Usually hopefully zero, as this is expensive operation.
  final Set<String> removedFiles;

  /// The semi-accurate statistics about files.
  final FileCountsStatistics fileCounts;

  /// The timer for producing errors (background file analysis).
  final Stopwatch produceErrorsTimer = Stopwatch();

  /// The timer for loading elements while producing errors.
  ///
  /// While doing this, we read transitive files, so it might be interesting
  /// to separate CPU intensive resolution and diagnostics from loading
  /// elements, that can have large IO portion (and also sometimes significant
  /// CPU, but much less than resolution).
  final Stopwatch produceErrorsElementsTimer = Stopwatch();

  /// The count of files that we initially decided to produce errors.
  int produceErrorsPotentialFileCount = 0;

  /// The sum of line counts for [produceErrorsActualFileCount].
  int produceErrorsPotentialFileLineCount = 0;

  /// The count of files that were actually analyzed, as opposite to
  /// producing errors from the cache, or not producing because no changes.
  int produceErrorsActualFileCount = 0;

  /// The sum of line counts for [produceErrorsActualFileCount].
  int produceErrorsActualFileLineCount = 0;

  /// The counts of requirement failures for library diagnostics bundles.
  final Map<RequirementFailureKindId, int>
  libraryDiagnosticsBundleRequirementsFailures = {};

  AnalysisStatusWorkingStatistics({
    required this.withFineDependencies,
    required this.changedFiles,
    required this.removedFiles,
    required this.fileCounts,
  });
}

/// The statistics about all files in the workspace.
class FileCountsStatistics {
  final Stopwatch age = Stopwatch()..start();

  /// The number of immediate files that were analyzed.
  int immediateFileCount = 0;

  /// The number of lines in the immediate files.
  int immediateFileLineCount = 0;

  /// The number of transitive files. If a single file is referenced from
  /// multiple analysis drivers, it will be counted multiple times.
  int transitiveFileCount = 0;

  /// The number of lines in the same files that are included in the
  /// [transitiveFileCount].
  int transitiveFileLineCount = 0;
}

/// File updates since last transition to working status.
class FileUpdatesStatistics {
  final Set<String> changedFiles = {};
  final Set<String> removedFiles = {};
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

  /// The last status sent to [_eventsController].
  AnalysisStatus _currentStatus = AnalysisStatusIdle._(workingStatistics: null);

  StatusSupport({required StreamController<Object> eventsController})
    : _eventsController = eventsController;

  /// The last status sent to [_eventsController].
  AnalysisStatus get currentStatus => _currentStatus;

  /// If the current status is not [AnalysisStatusIdle] yet, set the
  /// current status to it, and send it to the stream.
  void transitionToIdle() {
    if (_currentStatus case AnalysisStatusWorking status) {
      var newStatus = AnalysisStatusIdle._(
        workingStatistics: status.workingStatistics,
      );
      _currentStatus = newStatus;
      _eventsController.add(newStatus);
      status._idleCompleter.complete();
    }
  }

  /// If the current status is not [AnalysisStatusWorking] yet, set the
  /// current status to it, and send it to the stream.
  void transitionToWorking({
    required AnalysisStatusWorkingStatistics Function() buildStatistics,
  }) {
    if (_currentStatus is AnalysisStatusIdle) {
      var newStatus = AnalysisStatusWorking._(
        workingStatistics: buildStatistics(),
      );
      _currentStatus = newStatus;
      _eventsController.add(newStatus);
    }
  }

  /// If the current status is [AnalysisStatusIdle], returns the future that
  /// will complete immediately.
  ///
  /// If the current status is [AnalysisStatusWorking], returns the future
  /// that will complete when the status changes to [AnalysisStatusIdle].
  Future<void> waitForIdle() {
    switch (_currentStatus) {
      case AnalysisStatusIdle():
        return Future<void>.value();
      case AnalysisStatusWorking status:
        return status._idleCompleter.future;
    }
  }
}
