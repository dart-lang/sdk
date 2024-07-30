// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/io.dart' show errorSink;

import '../analyzer.dart';
import 'test_linter.dart';

Future<Iterable<AnalysisErrorInfo>> lintFiles(
    TestLinter linter, List<File> filesToLint) async {
  // Setup an error watcher to track whether an error was logged to stderr so
  // we can set the exit code accordingly.
  var errorWatcher = ErrorWatchingSink(errorSink);
  errorSink = errorWatcher;

  var errors = await linter.lintFiles(filesToLint);
  if (errorWatcher.encounteredError) {
    exitCode = loggedAnalyzerErrorExitCode;
  } else if (errors.isNotEmpty) {
    exitCode = _maxSeverity(errors.toList(), linter.options.filter);
  }

  return errors;
}

Iterable<AnalysisError> _filtered(
        List<AnalysisError> errors, LintFilter? filter) =>
    (filter == null)
        ? errors
        : errors.where((AnalysisError e) => !filter.filter(e));

int _maxSeverity(List<AnalysisErrorInfo> errors, LintFilter? filter) {
  var max = 0;
  for (var info in errors) {
    _filtered(info.errors, filter).forEach((AnalysisError e) {
      max = math.max(max, e.errorCode.errorSeverity.ordinal);
    });
  }
  return max;
}

class ErrorWatchingSink implements IOSink {
  bool encounteredError = false;

  IOSink delegate;

  ErrorWatchingSink(this.delegate);

  @override
  Future get done => delegate.done;

  @override
  Encoding get encoding => delegate.encoding;

  @override
  set encoding(Encoding encoding) {
    delegate.encoding = encoding;
  }

  @override
  void add(List<int> data) {
    delegate.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    encounteredError = true;
    delegate.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<List<int>> stream) => delegate.addStream(stream);

  @override
  Future close() => delegate.close();

  @override
  Future flush() => delegate.flush();

  @override
  void write(Object? obj) {
    delegate.write(obj);
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    delegate.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    delegate.writeCharCode(charCode);
  }

  @override
  void writeln([Object? obj = '']) {
    // 'Exception while using a Visitor to visit ...' (
    if (obj.toString().startsWith('Exception')) {
      encounteredError = true;
    }
    delegate.writeln(obj);
  }
}
