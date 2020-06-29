// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/performance/operation_performance.dart';

/// Compute a string representing a code completion operation at the
/// given source and location.
///
/// This string is useful for displaying to users in a diagnostic context.
String computeCompletionSnippet(String contents, int offset) {
  if (contents == null ||
      offset == null ||
      offset < 0 ||
      contents.length < offset) {
    return '???';
  }
  var start = offset;
  while (start > 0) {
    var ch = contents[start - 1];
    if (ch == '\r' || ch == '\n') {
      break;
    }
    --start;
  }
  var end = offset;
  while (end < contents.length) {
    var ch = contents[end];
    if (ch == '\r' || ch == '\n') {
      break;
    }
    ++end;
  }
  var prefix = contents.substring(start, offset);
  var suffix = contents.substring(offset, end);
  return '$prefix^$suffix';
}

/// Overall performance of a code completion operation.
class CompletionPerformance {
  final DateTime start = DateTime.now();
  final Map<String, Duration> _startTimes = <String, Duration>{};
  final Stopwatch _stopwatch = Stopwatch();
  final List<OperationPerformance> operations = <OperationPerformance>[];

  String path;
  String snippet = '';
  int notificationCount = -1;
  int suggestionCountFirst = -1;
  int suggestionCountLast = -1;
  Duration _firstNotification;

  CompletionPerformance() {
    _stopwatch.start();
  }

  int get elapsedInMilliseconds =>
      operations.isNotEmpty ? operations.last.elapsed.inMilliseconds : 0;

  String get suggestionCount {
    if (notificationCount < 1) return '';
    if (notificationCount == 1) return '$suggestionCountFirst';
    return '$suggestionCountFirst,  $suggestionCountLast';
  }

  void complete([String tag]) {
    _stopwatch.stop();
    _logDuration(tag ?? 'total time', _stopwatch.elapsed);
  }

  void logElapseTime(String tag) {
    var end = _stopwatch.elapsed;
    var start = _startTimes[tag];
    if (start == null) {
      _logDuration(tag, null);
      return null;
    }
    _logDuration(tag, end - start);
  }

  void logFirstNotificationComplete(String tag) {
    _firstNotification = _stopwatch.elapsed;
    _logDuration(tag, _firstNotification);
  }

  void logStartTime(String tag) {
    _startTimes[tag] = _stopwatch.elapsed;
  }

  void setContentsAndOffset(String contents, int offset) {
    snippet = computeCompletionSnippet(contents, offset);
  }

  void _logDuration(String tag, Duration elapsed) {
    operations.add(OperationPerformanceFixed(tag, elapsed));
  }
}
