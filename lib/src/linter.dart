// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter_impl;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:dart_lint/src/analysis.dart';

void _registerLinters(Iterable<Linter> linters) {
  if (linters != null) {
    LintGenerator.LINTERS.clear();
    linters.forEach((l) => LintGenerator.LINTERS.add(l));
  }
}

typedef Printer(String msg);

/// Describes a set of enabled rules.
typedef Iterable<Linter> RuleSet();

typedef AnalysisDriver _DriverFactory();

/// Dart source linter.
abstract class DartLinter {

  /// Creates a new linter.
  factory DartLinter([LinterOptions options]) => new SourceLinter(options);

  factory DartLinter.forRules(RuleSet ruleSet) =>
      new DartLinter(new LinterOptions(ruleSet));

  Iterable<AnalysisErrorInfo> lintFile(File sourceFile);

  Iterable<AnalysisErrorInfo> lintLibrarySource(
      {String libraryName, String libraryContents});

  Iterable<AnalysisErrorInfo> lintPath(String sourcePath);
}

/// Thrown when an error occurs in linting.
class LinterException implements Exception {

  /// A message describing the error.
  final String message;

  /// Creates a new LinterException with an optional error [message].
  const LinterException([this.message]);

  String toString() =>
      message == null ? "LinterException" : "LinterException: $message";
}

/// Linter options.
class LinterOptions extends DriverOptions {
  final RuleSet _enabledLints;
  final bool enableLints = true;
  final ErrorFilter errorFilter =
      (AnalysisError error) => error.errorCode.type == ErrorType.LINT;
  LinterOptions(this._enabledLints);
  Iterable<Linter> get enabledLints => _enabledLints();
}

class PrintingReporter implements Reporter, Logger {
  final Printer _print;

  const PrintingReporter([this._print = print]);

  @override
  void exception(LinterException exception) {
    _print('EXCEPTION: $exception');
  }

  @override
  void logError(String message, [CaughtException exception]) {
    _print('ERROR: $message');
  }

  @override
  void logError2(String message, Object exception) {
    _print('ERROR: $message');
  }

  @override
  void logInformation(String message, [CaughtException exception]) {
    _print('INFO: $message');
  }

  @override
  void logInformation2(String message, Object exception) {
    _print('INFO: $message');
  }

  @override
  void warn(String message) {
    _print('WARN: $message');
  }
}

abstract class Reporter {
  void exception(LinterException exception);
  void warn(String message);
}

/// Linter implementation
class SourceLinter implements DartLinter, AnalysisErrorListener {
  final errors = <AnalysisError>[];
  final LinterOptions options;
  final Reporter reporter;
  SourceLinter(this.options, {this.reporter: const PrintingReporter()});

  @override
  Iterable<AnalysisErrorInfo> lintFile(File sourceFile) =>
      _registerAndRun(() => new AnalysisDriver.forFile(sourceFile, options));

  @override
  Iterable<AnalysisErrorInfo> lintLibrarySource(
      {String libraryName, String libraryContents}) => _registerAndRun(
          () => new AnalysisDriver.forSource(
              new _StringSource(libraryContents, libraryName), options));

  @override
  Iterable<AnalysisErrorInfo> lintPath(String sourcePath) =>
      _registerAndRun(() => new AnalysisDriver.forPath(sourcePath, options));

  @override
  onError(AnalysisError error) => errors.add(error);

  Iterable<AnalysisErrorInfo> _registerAndRun(_DriverFactory createDriver) {
    _registerLinters(options.enabledLints);
    return createDriver().getErrors();
  }
}

class _StringSource extends StringSource {
  _StringSource(String contents, String fullName) : super(contents, fullName);

  UriKind get uriKind => UriKind.FILE_URI;
}
