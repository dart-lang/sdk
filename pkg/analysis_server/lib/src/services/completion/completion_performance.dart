// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';

/**
 * Overall performance of a code completion operation.
 */
class CompletionPerformance {
  final DateTime start = new DateTime.now();
  final Map<String, Duration> _startTimes = new Map<String, Duration>();
  final Stopwatch _stopwatch = new Stopwatch();
  final List<OperationPerformance> operations = <OperationPerformance>[];

  Source source;
  String snippet = '';
  int notificationCount = -1;
  int suggestionCountFirst = -1;
  int suggestionCountLast = -1;
  Duration _firstNotification;

  CompletionPerformance() {
    _stopwatch.start();
  }

  int get elapsedInMilliseconds =>
      operations.length > 0 ? operations.last.elapsed.inMilliseconds : 0;

  int get firstNotificationInMilliseconds =>
      _firstNotification != null ? _firstNotification.inMilliseconds : 0;

  String get startTimeAndMs => '${start.millisecondsSinceEpoch} - $start';

  String get suggestionCount {
    if (notificationCount < 1) return '';
    if (notificationCount == 1) return '$suggestionCountFirst';
    return '$suggestionCountFirst,  $suggestionCountLast';
  }

  void complete([String tag = null]) {
    _stopwatch.stop();
    _logDuration(tag ?? 'total time', _stopwatch.elapsed);
  }

  void logElapseTime(String tag) {
    Duration end = _stopwatch.elapsed;
    Duration start = _startTimes[tag];
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
    snippet = _computeSnippet(contents, offset);
  }

  void _logDuration(String tag, Duration elapsed) {
    operations.add(new OperationPerformance(tag, elapsed));
  }

  static String _computeSnippet(String contents, int offset) {
    if (contents == null ||
        offset == null ||
        offset < 0 ||
        contents.length < offset) {
      return '???';
    }
    int start = offset;
    while (start > 0) {
      String ch = contents[start - 1];
      if (ch == '\r' || ch == '\n') {
        break;
      }
      --start;
    }
    int end = offset;
    while (end < contents.length) {
      String ch = contents[end];
      if (ch == '\r' || ch == '\n') {
        break;
      }
      ++end;
    }
    String prefix = contents.substring(start, offset);
    String suffix = contents.substring(offset, end);
    return '$prefix^$suffix';
  }
}

/**
 * The performance of an operation when computing code completion.
 */
class OperationPerformance {
  /**
   * The name of the operation
   */
  final String name;

  /**
   * The elapse time or `null` if undefined.
   */
  final Duration elapsed;

  OperationPerformance(this.name, this.elapsed);
}
