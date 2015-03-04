// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.formatter;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

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

String pluralize(String word, int count) => count == 1 ? '$word' : '${word}s';

String shorten(String fileRoot, String fullName) {
  if (fileRoot == null || !fullName.startsWith(fileRoot)) {
    return fullName;
  }
  return fullName.substring(fileRoot.length);
}

class DetailedReporter extends SimpleFormatter {
  DetailedReporter(Iterable<AnalysisErrorInfo> errors, IOSink out,
      {int fileCount, String fileRoot})
      : super(errors, out, fileCount: fileCount, fileRoot: fileRoot);

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
  factory ReportFormatter(List<AnalysisErrorInfo> errors, IOSink out,
      {int fileCount, String fileRoot}) => new DetailedReporter(errors, out,
      fileCount: fileCount, fileRoot: fileRoot);

  write();
}

/// Simple formatter suitable for subclassing.
class SimpleFormatter implements ReportFormatter {
  final IOSink out;
  final Iterable<AnalysisErrorInfo> errors;

  int errorCount = 0;
  final int fileCount;
  final String fileRoot;

  SimpleFormatter(this.errors, this.out, {this.fileCount, this.fileRoot});

  @override
  write() {
    writeLints();
    writeSummary();
  }

  writeLint(AnalysisError error, LineInfo lineInfo) {
    LineInfo_Location location = lineInfo.getLocation(error.offset);

    // test/linter_test.dart 452:9 [lint] DO name types using UpperCamelCase.
    out
      ..write('${shorten(fileRoot, error.source.fullName)} ')
      ..write('${location.lineNumber}:${location.columnNumber} ')
      ..write('[${error.errorCode.type.displayName}] ${error.message} ')
      ..writeln();
  }

  writeLints() {
    errors.forEach((info) => info.errors.forEach((e) {
      ++errorCount;
      writeLint(e, info.lineInfo);
    }));
    out.writeln();
  }

  writeSummary() {
    out
      ..write('$fileCount ${pluralize("file", fileCount)} analyzed, ')
      ..writeln('$errorCount ${pluralize("issue", errorCount)} found.');
  }
}
