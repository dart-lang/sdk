// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/utilities/extensions/source.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

String _getLineContents(int lineNumber, Diagnostic diagnostic) {
  var path = diagnostic.source.fullName;
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
  final Iterable<Diagnostic> diagnostics;

  int diagnosticCount = 0;

  ReportFormatter(this.diagnostics, this.out);

  /// Override to influence diagnostic sorting.
  int compare(Diagnostic diagnostic1, Diagnostic diagnostic2) {
    // Severity.
    var compare = diagnostic2.diagnosticCode.severity.compareTo(
      diagnostic1.diagnosticCode.severity,
    );
    if (compare != 0) {
      return compare;
    }
    // Path.
    compare = Comparable.compare(
      diagnostic1.source.fullName.toLowerCase(),
      diagnostic2.source.fullName.toLowerCase(),
    );
    if (compare != 0) {
      return compare;
    }
    // Offset.
    return diagnostic1.offset - diagnostic2.offset;
  }

  void write() {
    _writeLints();
    _writeSummary();
    out.writeln();
  }

  void writeLint(
    Diagnostic diagnostic, {
    required int offset,
    required int line,
    required int column,
  }) {
    // test/engine_test.dart 452:9 [lint] DO name types using UpperCamelCase.
    out
      ..write('${diagnostic.source.fullName} ')
      ..write('$line:$column ')
      ..writeln(
        '[${diagnostic.diagnosticCode.type.displayName}] ${diagnostic.message}',
      );
    var contents = _getLineContents(line, diagnostic);
    out.writeln(contents);

    var spaces = column - 1;
    var arrows = max(1, min(diagnostic.length, contents.length - spaces));

    var result = '${" " * spaces}${"^" * arrows}';
    out.writeln(result);
  }

  void _writeLint(Diagnostic diagnostic) {
    var offset = diagnostic.offset;
    var lineInfo = LineInfo.fromContent(diagnostic.source.stringContents);
    var location = lineInfo.getLocation(offset);
    var line = location.lineNumber;
    var column = location.columnNumber;

    writeLint(diagnostic, offset: offset, column: column, line: line);
  }

  void _writeLints() {
    for (var e in (diagnostics.toList()..sort(compare))) {
      ++diagnosticCount;
      _writeLint(e);
    }

    out.writeln();
  }

  void _writeSummary() {
    var summary =
        'files analyzed, '
        '$diagnosticCount ${"issue".pluralized(diagnosticCount)} found.';
    out.writeln(summary);
  }
}
