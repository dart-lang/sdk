// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
// ignore: implementation_imports
import 'package:analyzer/src/lint/analysis_rule_timers.dart';

import 'analysis_error_info.dart';

String getLineContents(int lineNumber, AnalysisError error) {
  var path = error.source.fullName;
  var file = File(path);
  String failureDetails;
  if (!file.existsSync()) {
    failureDetails = 'file at $path does not exist';
  } else {
    var lines = file.readAsLinesSync();
    var lineIndex = lineNumber - 1;
    if (lines.length > lineIndex) {
      return lines[lineIndex];
    }
    failureDetails =
        'line index ($lineIndex), outside of file line range (${lines.length})';
  }
  throw StateError('Unable to get contents for line: $failureDetails');
}

String pluralize(String word, int count) =>
    "$count ${count == 1 ? word : '${word}s'}";

class ReportFormatter {
  final StringSink out;
  final Iterable<AnalysisErrorInfo> errors;

  int errorCount = 0;

  final int? elapsedMs;
  final bool showStatistics;

  /// Cached for the purposes of statistics report formatting.
  int _summaryLength = 0;

  Map<String, int> stats = <String, int>{};

  ReportFormatter(
    this.errors,
    this.out, {
    this.elapsedMs,
    this.showStatistics = false,
  });

  /// Override to influence error sorting.
  int compare(AnalysisError error1, AnalysisError error2) {
    // Severity.
    var compare = error2.errorCode.errorSeverity
        .compareTo(error1.errorCode.errorSeverity);
    if (compare != 0) {
      return compare;
    }
    // Path.
    compare = Comparable.compare(error1.source.fullName.toLowerCase(),
        error2.source.fullName.toLowerCase());
    if (compare != 0) {
      return compare;
    }
    // Offset.
    return error1.offset - error2.offset;
  }

  void write() {
    writeLints();
    writeSummary();
    if (showStatistics) {
      out.writeln();
      writeStatistics();
    }
    out.writeln();
  }

  void writeCounts() {
    var codes = stats.keys.toList()..sort();
    var largestCountGuess = 8;
    var longest =
        codes.fold(0, (int prev, element) => max(prev, element.length));
    var tableWidth = max(_summaryLength, longest + largestCountGuess);
    var pad = tableWidth - longest;
    var line = ''.padLeft(tableWidth, '-');
    out
      ..writeln(line)
      ..writeln('Counts')
      ..writeln(line);
    for (var code in codes) {
      out
        ..write(code.padRight(longest))
        ..writeln(stats[code].toString().padLeft(pad));
    }
    out.writeln(line);
  }

  void writeLint(
    AnalysisError error, {
    required int offset,
    required int line,
    required int column,
  }) {
    // test/engine_test.dart 452:9 [lint] DO name types using UpperCamelCase.
    out
      ..write('${error.source.fullName} ')
      ..write('$line:$column ')
      ..writeln('[${error.errorCode.type.displayName}] ${error.message}');
    var contents = getLineContents(line, error);
    out.writeln(contents);

    var spaces = column - 1;
    var arrows = max(1, min(error.length, contents.length - spaces));

    var result = '${" " * spaces}${"^" * arrows}';
    out.writeln(result);
  }

  void writeLints() {
    for (var info in errors) {
      for (var e in (info.errors.toList()..sort(compare))) {
        ++errorCount;
        _writeLint(e, info.lineInfo);

        _recordStats(e);
      }
    }
    out.writeln();
  }

  void writeStatistics() {
    writeCounts();
    writeTimings();
  }

  void writeSummary() {
    var summary = 'files analyzed, '
        '${pluralize("issue", errorCount)} found, in $elapsedMs ms.';
    out.writeln(summary);
    // Cache for output table sizing
    _summaryLength = summary.length;
  }

  void writeTimings() {
    var timers = analysisRuleTimers.timers;
    var timings = timers.keys
        .map((t) => Stat(t, timers[t]?.elapsedMilliseconds ?? 0))
        .toList();
    out.writeTimings(timings, _summaryLength);
  }

  void _recordStats(AnalysisError error) {
    var codeName = error.errorCode.name;
    stats.putIfAbsent(codeName, () => 0);
    stats[codeName] = stats[codeName]! + 1;
  }

  void _writeLint(AnalysisError error, LineInfo lineInfo) {
    var offset = error.offset;
    var location = lineInfo.getLocation(offset);
    var line = location.lineNumber;
    var column = location.columnNumber;

    writeLint(error, offset: offset, column: column, line: line);
  }
}

class Stat implements Comparable<Stat> {
  final String name;
  final int elapsed;

  Stat(this.name, this.elapsed);

  @override
  int compareTo(Stat other) => other.elapsed - elapsed;
}

extension StringSinkExtension on StringSink {
  void writeTimings(List<Stat> timings, int summaryLength) {
    var names = timings.map((s) => s.name).toList();

    var longestName =
        names.fold<int>(0, (prev, element) => max(prev, element.length));
    var longestTime = 8;
    var tableWidth = max(summaryLength, longestName + longestTime);
    var pad = tableWidth - longestName;
    var line = ''.padLeft(tableWidth, '-');

    writeln();
    writeln(line);
    writeln('${'Timings'.padRight(longestName)}${'ms'.padLeft(pad)}');
    writeln(line);
    var totalTime = 0;

    timings.sort();
    for (var stat in timings) {
      totalTime += stat.elapsed;
      writeln(
          '${stat.name.padRight(longestName)}${stat.elapsed.toString().padLeft(pad)}');
    }

    writeln(line);
    writeln(
        '${'Total'.padRight(longestName)}${totalTime.toString().padLeft(pad)}');
    writeln(line);
  }
}
