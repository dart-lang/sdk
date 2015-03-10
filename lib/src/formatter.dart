// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.formatter;

import 'dart:io';

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
      {int fileCount, String fileRoot})
      : super(errors, filter, out, fileCount: fileCount, fileRoot: fileRoot);

  @override
  writeLint(AnalysisError error, LineInfo lineInfo) {
    super.writeLint(error, lineInfo);

    var location = lineInfo.getLocation(error.offset);
    var contents = getLineContents(location.lineNumber, error);
    out.writeln(contents);

    var arrows = '^' * error.length;
    var spaces = location.columnNumber - 1;
    var result = '${" " * spaces}$arrows';
    out.writeln(result);
  }
}

abstract class ReportFormatter {
  factory ReportFormatter(
      Iterable<AnalysisErrorInfo> errors, LintFilter filter, IOSink out,
      {int fileCount, String fileRoot}) => new DetailedReporter(
      errors, filter, out, fileCount: fileCount, fileRoot: fileRoot);

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

  SimpleFormatter(this.errors, this.filter, this.out,
      {this.fileCount, this.fileRoot});

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
  }

  void writeLint(AnalysisError error, LineInfo lineInfo) {
    LineInfo_Location location = lineInfo.getLocation(error.offset);

    // test/linter_test.dart 452:9 [lint] DO name types using UpperCamelCase.
    out
      ..write('${shorten(fileRoot, error.source.fullName)} ')
      ..write('${location.lineNumber}:${location.columnNumber} ')
      ..writeln('[${error.errorCode.type.displayName}] ${error.message}');
  }

  void writeLints() {
    errors.forEach((info) => (info.errors.toList()..sort(compare)).forEach((e) {
      if (filter != null && filter.filter(e)) {
        filteredLintCount++;
      } else {
        ++errorCount;
        writeLint(e, info.lineInfo);
      }
    }));
    out.writeln();
  }

  void writeSummary() {
    out
      ..write('${pluralize("file", fileCount)} analyzed, ')
      ..write('${pluralize("issue", errorCount)} found')
      ..writeln(
          "${filteredLintCount == 0 ? '' : ' ($filteredLintCount filtered)'}.");
  }
}
