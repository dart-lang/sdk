// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter_impl;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:dart_lint/src/analysis.dart';
import 'package:dart_lint/src/rules.dart';

void _registerLinters(Iterable<Linter> linters) {
  LintGenerator.LINTERS.clear();
  linters.forEach((l) => LintGenerator.LINTERS.add(l));
}

typedef AnalysisDriver _DriverFactory();

/// Dart source linter.
abstract class DartLinter {

  /// Creates a new linter.
  factory DartLinter([LinterOptions options]) =>
      new SourceLinter(options: options);

  disableRule(String ruleName);

  enableRule(String ruleName);

  Iterable<AnalysisErrorInfo> lintFile(File sourceFile);

  Iterable<AnalysisErrorInfo> lintLibrarySource(
      {String libraryName, String libraryContents});

  Iterable<AnalysisErrorInfo> lintPath(String sourcePath);

  registerRule(String ruleName, Linter lintRule);
}

/// Thrown when an error occurs in linting.
class LinterException implements Exception {

  /// A message describing the error.
  final String message;

  /// Creates a new LinterException with an optional error [message].
  const LinterException([this.message = 'LinterException']);

  LinterException.forError(List<AnalysisError> errors)
      : message = _createMessage(errors);

  String toString() => '$message';

  //TODO: revisit
  static String _createMessage(errors) {
    var errorCode = errors[0].errorCode;
    var phase = errorCode is ParserErrorCode ? 'parsing' : 'scanning';
    return 'An error occured while $phase (${errorCode.name}).';
  }
}

/// Linter options.
class LinterOptions extends DriverOptions {
  final bool enableLints = true;
  final ErrorFilter errorFilter =
      (AnalysisError error) => error.errorCode.type == ErrorType.LINT;
}

abstract class Reporter {
  void exception(LinterException exception);
  void warn(String message);
}

/// Linter implementation
class SourceLinter implements DartLinter, AnalysisErrorListener {
  final errors = <AnalysisError>[];
  LinterOptions options;
  final Reporter reporter;
  RuleRegistry registry;

  SourceLinter(
      {this.options, this.reporter: const StdIoReporter(), this.registry}) {
    if (options == null) {
      options = new LinterOptions();
    }
    if (registry == null) {
      registry = new RuleRegistry(reporter);
    }
  }

  @override
  disableRule(String ruleName) => registry.disable(ruleName);

  @override
  enableRule(String ruleName) => registry.enable(ruleName);

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

  @override
  registerRule(String ruleName, Linter lintRule) =>
      registry.registerLinter(ruleName, lintRule);

  Iterable<AnalysisErrorInfo> _registerAndRun(_DriverFactory createDriver) {
    _registerLinters(registry.enabledLints);
    return createDriver().getErrors();
  }
}

class StdIoReporter implements Reporter, Logger {
  const StdIoReporter();

  @override
  void exception(LinterException exception) {
    print('EXCEPTION: $exception');
  }

  @override
  void logError(String message, [CaughtException exception]) {
    print('ERROR: $message');
  }

  @override
  void logError2(String message, Object exception) {
    print('ERROR: $message');
  }

  @override
  void logInformation(String message, [CaughtException exception]) {
    print('INFO: $message');
  }

  @override
  void logInformation2(String message, Object exception) {
    print('INFO: $message');
  }

  @override
  void warn(String message) {
    print('WARN: $message');
  }
}

class _StringSource extends StringSource {
  _StringSource(String contents, String fullName) : super(contents, fullName);

  UriKind get uriKind => UriKind.FILE_URI;
}
