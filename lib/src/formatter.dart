// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.formatter;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

String pluralize(String word, int count) => count == 1 ? '$word' : '${word}s';

String shorten(String fileRoot, String fullName) {
  if (fileRoot == null || !fullName.startsWith(fileRoot)) {
    return fullName;
  }
  return fullName.substring(fileRoot.length);
}

class ReportFormatter {
  final IOSink out;
  final Iterable<AnalysisErrorInfo> errors;

  int errorCount = 0;
  final int fileCount;
  final String fileRoot;

  ReportFormatter(this.errors, this.out, {this.fileCount, this.fileRoot});

  write() {
    writeLints();
    writeSummary();
  }

  writeError(AnalysisError error, LineInfo lineInfo) {
    LineInfo_Location location = lineInfo.getLocation(error.offset);

    // [lint] DO name types... (test/linter_test.dart, line 417, col 1)
    out.write('[${error.errorCode.type.displayName}] ${error.message} ');
    out.write('(${shorten(fileRoot, error.source.fullName)}');
    out.write(', line ${location.lineNumber}, col ${location.columnNumber})');
    out.writeln();
  }

  writeLints() {
    errors.forEach((info) => info.errors.forEach((e) {
      ++errorCount;
      writeError(e, info.lineInfo);
    }));
    out.writeln();
  }

  writeSummary() {
    out.write('$fileCount ${pluralize("file", fileCount)} analyzed, ');
    out.writeln('$errorCount ${pluralize("issue", errorCount)} found.');
  }
}
