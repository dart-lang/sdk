// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.formatter;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:linter/src/linter.dart';
import 'package:source_span/source_span.dart';

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

int getLineNumber(AnalysisError error, LineInfo lineInfo) {
  var path = error.source.fullName;
  var file = new File(path);
  if (file.existsSync()) {
    // Addresses raw mutiline string offset issues
    // https://github.com/dart-lang/linter/issues/47
    // Remove when fixed in analyzer
    var contents = file.readAsStringSync();
    var sourceFile = new SourceFile(contents);
    return sourceFile.getLine(error.offset) + 1;
  }
  // Fallback
  return lineInfo.getLocation(error.offset).lineNumber;
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
  writeLint(AnalysisError error, {int offset, int line, int column}) {
    super.writeLint(error, offset: offset, column: column, line: line);

    var contents = getLineContents(line, error);
    out.writeln(contents);

    var arrows = '^' * error.length;
    var spaces = column - 1;
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
        _writeLint(e, info.lineInfo);
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

  void _writeLint(AnalysisError error, LineInfo lineInfo) {
    var offset = error.offset;
    // Gnarly work-around for offsets confused by multi-line raw strings
    var line = getLineNumber(error, lineInfo);
    var column = lineInfo.getLocation(offset).columnNumber;

    writeLint(error, offset: offset, column: column, line: line);
  }
}
