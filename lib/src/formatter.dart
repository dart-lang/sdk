// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.formatter;

import 'dart:io';
import 'dart:math';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:linter/src/linter.dart';

String getLineContents(int lineNumber, AnalysisError error) {
  var path = error.source.fullName;
  var file = new File(path);
  if (file.existsSync()) {
    var lines = file.readAsLinesSync();
    var lineIndex = lineNumber - 1;
    if (lines.length > lineIndex) {
      return lines[lineIndex];
    }
  }
  return null;
}

String pluralize(String word, int count) =>
    "$count ${count == 1 ? '$word' : '${word}s'}";

String shorten(String fileRoot, String fullName) {
  if (fileRoot == null || !fullName.startsWith(fileRoot)) {
    return fullName;
  }
  return fullName.substring(fileRoot.length);
}

class DetailedReporter extends SimpleFormatter {
  DetailedReporter(
      Iterable<AnalysisErrorInfo> errors, LintFilter filter, IOSink out,
      {int fileCount, String fileRoot, bool showStatistics: false,
      quiet: false})
      : super(errors, filter, out,
          fileCount: fileCount,
          fileRoot: fileRoot,
          showStatistics: showStatistics,
          quiet: quiet);

  @override
  writeLint(AnalysisError error, {int offset, int line, int column}) {
    super.writeLint(error, offset: offset, column: column, line: line);

    var contents = getLineContents(line, error);
    out.writeln(contents);

    var spaces = column - 1;
    var arrows = max(1, min(error.length, contents.length - spaces));

    var result = '${" " * spaces}${"^" * arrows}';
    out.writeln(result);
  }
}

abstract class ReportFormatter {
  factory ReportFormatter(
      Iterable<AnalysisErrorInfo> errors, LintFilter filter, IOSink out,
      {int fileCount, String fileRoot, bool showStatistics: false,
      bool quiet: false}) => new DetailedReporter(errors, filter, out,
      fileCount: fileCount,
      fileRoot: fileRoot,
      showStatistics: showStatistics,
      quiet: quiet);

  write();
}

/// Simple formatter suitable for subclassing.
class SimpleFormatter implements ReportFormatter {
  final IOSink out;
  final Iterable<AnalysisErrorInfo> errors;
  final LintFilter filter;

  int errorCount = 0;
  int filteredLintCount = 0;

  final int fileCount;
  final String fileRoot;
  final bool showStatistics;
  final bool quiet;

  /// Cached for the purposes of statistics report formatting.
  int _summaryLength = 0;

  Map<String, int> stats = <String, int>{};

  SimpleFormatter(this.errors, this.filter, this.out, {this.fileCount,
      this.fileRoot, this.showStatistics: false, this.quiet: false});

  /// Override to influence error sorting
  int compare(AnalysisError error1, AnalysisError error2) {
    // Severity
    int compare = error2.errorCode.errorSeverity
        .compareTo(error1.errorCode.errorSeverity);
    if (compare != 0) {
      return compare;
    }
    // Path
    compare = Comparable.compare(error1.source.fullName.toLowerCase(),
        error2.source.fullName.toLowerCase());
    if (compare != 0) {
      return compare;
    }
    // Offset
    return error1.offset - error2.offset;
  }

  @override
  write() {
    writeLints();
    writeSummary();
    if (showStatistics) {
      writeStatistics();
    }
  }

  void writeLint(AnalysisError error, {int offset, int line, int column}) {
    // test/linter_test.dart 452:9 [lint] DO name types using UpperCamelCase.
    out
      ..write('${shorten(fileRoot, error.source.fullName)} ')
      ..write('$line:$column ')
      ..writeln('[${error.errorCode.type.displayName}] ${error.message}');
  }

  void writeLints() {
    errors.forEach((info) => (info.errors.toList()..sort(compare)).forEach((e) {
      if (filter != null && filter.filter(e)) {
        filteredLintCount++;
      } else {
        ++errorCount;
        if (!quiet) {
          _writeLint(e, info.lineInfo);
        }
        _recordStats(e);
      }
    }));
    if (!quiet) {
      out.writeln();
    }
  }

  void writeStatistics() {
    var codes = stats.keys.toList()..sort();
    var longest = 0;
    var largestCountGuess = 8;
    codes.forEach((c) => longest = max(longest, c.length));
    var tableWidth = max(_summaryLength, longest + largestCountGuess);
    var pad = tableWidth - longest;
    var line = ''.padLeft(tableWidth, '-');
    out.writeln(line);
    codes.forEach((c) {
      out
        ..write('${c.padRight(longest)}')
        ..writeln('${stats[c].toString().padLeft(pad)}');
    });
    out.writeln(line);
  }

  void writeSummary() {
    var summary = '${pluralize("file", fileCount)} analyzed, '
        '${pluralize("issue", errorCount)} found'
        "${filteredLintCount == 0 ? '' : ' ($filteredLintCount filtered)'}.";
    out.writeln(summary);
    // Cache for output table sizing
    _summaryLength = summary.length;
  }

  void _recordStats(AnalysisError error) {
    var codeName = error.errorCode.name;
    stats.putIfAbsent(codeName, () => 0);
    stats[codeName]++;
  }

  void _writeLint(AnalysisError error, LineInfo lineInfo) {
    var offset = error.offset;
    var location = lineInfo.getLocation(offset);
    var line = location.lineNumber;
    var column = location.columnNumber;

    writeLint(error, offset: offset, column: column, line: line);
  }
}
