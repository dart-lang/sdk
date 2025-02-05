// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:linter/src/test_utilities/analysis_error_info.dart';

String pluralize(String word, int count) =>
    "$count ${count == 1 ? word : '${word}s'}";

String _getLineContents(int lineNumber, AnalysisError error) {
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

class ReportFormatter {
  final StringSink out;
  final Iterable<AnalysisErrorInfo> errors;

  int errorCount = 0;

  ReportFormatter(this.errors, this.out);

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
    _writeLints();
    _writeSummary();
    out.writeln();
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
    var contents = _getLineContents(line, error);
    out.writeln(contents);

    var spaces = column - 1;
    var arrows = max(1, min(error.length, contents.length - spaces));

    var result = '${" " * spaces}${"^" * arrows}';
    out.writeln(result);
  }

  void _writeLint(AnalysisError error, LineInfo lineInfo) {
    var offset = error.offset;
    var location = lineInfo.getLocation(offset);
    var line = location.lineNumber;
    var column = location.columnNumber;

    writeLint(error, offset: offset, column: column, line: line);
  }

  void _writeLints() {
    for (var info in errors) {
      for (var e in (info.errors.toList()..sort(compare))) {
        ++errorCount;
        _writeLint(e, info.lineInfo);
      }
    }
    out.writeln();
  }

  void _writeSummary() {
    var summary = 'files analyzed, ${pluralize("issue", errorCount)} found.';
    out.writeln(summary);
  }
}
