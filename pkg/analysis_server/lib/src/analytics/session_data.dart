// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analytics/percentile_calculator.dart';
import 'package:analyzer/src/dart/analysis/status.dart';

/// Accumulated statistics over multiple analysis working periods.
class AnalyticsAnalysisWorkingStatistics {
  final bool withFineDependencies;

  /// Files changed before the described set of working period.
  /// Usually probably small, as the user works in a few files.
  final Set<String> uniqueChangedFiles = {};

  /// The total number of change file events.
  int changeFileEventCount = 0;

  /// Files removed before the described working period.
  /// Usually hopefully zero, as this is expensive operation.
  final Set<String> uniqueRemovedFiles = {};

  /// The total number of change file events.
  int removeFileEventCount = 0;

  /// The number of immediate files that were analyzed.
  ///
  /// Allows us to understand if the number of files was changing significantly
  /// over the period.
  final PercentileCalculator immediateFileCountPercentiles =
      PercentileCalculator();

  /// The number of lines in the immediate files.
  final PercentileCalculator immediateFileLineCountPercentiles =
      PercentileCalculator();

  /// The number of transitive files. If a single file is referenced from
  /// multiple analysis drivers, it will be counted multiple times.
  ///
  /// Allows us to understand the kind of the workspace: many dependencies,
  /// small application; or few dependencies and relatively large application.
  final PercentileCalculator transitiveFileCountPercentiles =
      PercentileCalculator();

  /// The number of lines in the same files that are included in the
  /// [transitiveFileCountPercentiles].
  final PercentileCalculator transitiveFileLineCountPercentiles =
      PercentileCalculator();

  /// The time for producing errors (background file analysis).
  int produceErrorsMs = 0;

  /// The time for loading elements while producing errors.
  int produceErrorsElementsMs = 0;

  /// The count of files that we initially decided to produce errors.
  int produceErrorsPotentialFileCount = 0;

  /// The sum of line counts for [produceErrorsActualFileCount].
  int produceErrorsPotentialFileLineCount = 0;

  /// The count of files that were actually analyzed, as opposite to
  /// producing errors from the cache, or not producing because no changes.
  int produceErrorsActualFileCount = 0;

  /// The sum of line counts for [produceErrorsActualFileCount].
  int produceErrorsActualFileLineCount = 0;

  AnalyticsAnalysisWorkingStatistics({required this.withFineDependencies});

  void append(AnalysisStatusWorkingStatistics statistics) {
    uniqueChangedFiles.addAll(statistics.changedFiles);
    uniqueRemovedFiles.addAll(statistics.removedFiles);

    changeFileEventCount += statistics.changedFiles.length;
    removeFileEventCount += statistics.removedFiles.length;

    immediateFileCountPercentiles.addValue(
      statistics.fileCounts.immediateFileCount,
    );
    immediateFileLineCountPercentiles.addValue(
      statistics.fileCounts.immediateFileLineCount,
    );
    transitiveFileCountPercentiles.addValue(
      statistics.fileCounts.transitiveFileCount,
    );
    transitiveFileLineCountPercentiles.addValue(
      statistics.fileCounts.transitiveFileLineCount,
    );

    produceErrorsMs += statistics.produceErrorsTimer.elapsedMilliseconds;
    produceErrorsElementsMs +=
        statistics.produceErrorsElementsTimer.elapsedMilliseconds;
    produceErrorsPotentialFileCount +=
        statistics.produceErrorsPotentialFileCount;
    produceErrorsPotentialFileLineCount +=
        statistics.produceErrorsPotentialFileLineCount;
    produceErrorsActualFileCount += statistics.produceErrorsActualFileCount;
    produceErrorsActualFileLineCount +=
        statistics.produceErrorsActualFileLineCount;
  }
}

/// Data about the current session.
class SessionData {
  /// The time at which the current session started.
  final DateTime startTime;

  /// The command-line arguments passed to the server on startup.
  final String commandLineArguments;

  /// The parameters passed on initialize.
  String initializeParams = '';

  /// The name of the client that started the server.
  final String clientId;

  /// The version of the client that started the server, or an empty string if
  /// no version information was provided.
  final String clientVersion;

  /// Initialize a newly created data holder.
  SessionData({
    required this.startTime,
    required this.commandLineArguments,
    required this.clientId,
    required this.clientVersion,
  });
}
