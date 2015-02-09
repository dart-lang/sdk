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
import 'package:dart_lint/src/rules.dart';

final _camelCaseMatcher = new RegExp('[A-Z][a-z]*');

final _camelCaseTester = new RegExp('([A-Z]+[a-z0-9]+)+');

String _humanize(String camelCase) =>
    _camelCaseMatcher.allMatches(camelCase).map((m) => m.group(0)).join(' ');

bool _isCamelCase(String name) => _camelCaseTester.hasMatch(name);

void _registerLinters(Iterable<Linter> linters) {
  if (linters != null) {
    LintGenerator.LINTERS.clear();
    linters.forEach((l) => LintGenerator.LINTERS.add(l));
  }
}

typedef Printer(String msg);

/// Describes a set of enabled rules.
typedef Iterable<LintRule> RuleSet();

typedef AnalysisDriver _DriverFactory();

/// Describes a String in valid camel case format.
class CamelCaseString {
  final String value;
  CamelCaseString(this.value) {
    if (!_isCamelCase(value)) {
      throw new ArgumentError('$value is not CamelCase');
    }
  }

  String get humanized => _humanize(value);
}

/// Dart source linter.
abstract class DartLinter {

  /// Creates a new linter.
  factory DartLinter([LinterOptions options]) => new SourceLinter(options);

  factory DartLinter.forRules(RuleSet ruleSet) =>
      new DartLinter(new LinterOptions(ruleSet));

  Iterable<AnalysisErrorInfo> lintFile(File sourceFile);

  Iterable<AnalysisErrorInfo> lintLibrarySource({String libraryName,
      String libraryContents});

  Iterable<AnalysisErrorInfo> lintPath(String sourcePath);
}

class Group {

  /// Defined rule groups.
  static final Group STYLE_GUIDE = new Group._('Style Guide');

  final String name;
  final bool custom;
  factory Group(String name) {
    switch (name) {
      case 'Styleguide':
      case 'Style Guide':
        return STYLE_GUIDE;
      default:
        return new Group._(name, custom: true);
    }
  }

  Group._(this.name, {this.custom: false});
}
class Kind {

  /// Defined rule kinds.
  static final Kind DO = new Kind._('Do');
  static final Kind DONT = new Kind._("Don't");
  static final Kind PREFER = new Kind._('Prefer');
  static final Kind AVOID = new Kind._('Avoid');
  static final Kind CONSIDER = new Kind._('Consider');

  final String name;
  final bool custom;
  factory Kind(String name) {
    var label = name.toUpperCase();
    switch (label) {
      case 'DO':
        return DO;
      case 'DONT':
      case "DON'T":
        return DONT;
      case 'PREFER':
        return PREFER;
      case 'AVOID':
        return AVOID;
      case 'CONSIDER':
        return CONSIDER;
      default:
        return new Kind._(label, custom: true);
    }
  }

  Kind._(this.name, {this.custom: false});
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

/// Describes a lint rule.
abstract class LintRule extends Linter {

  /// Longer description (in markdown format).
  final String details;
  /// Short description
  final String description;
  /// Lint group (for example, 'Style Guide')
  final Group group;
  /// Lint kind (DO|DON'T|PREFER|AVOID|CONSIDER)
  final Kind kind;
  /// Lint name.
  final CamelCaseString name;

  LintRule({String name, this.group, this.kind, this.description, this.details})
      : name = new CamelCaseString(name);
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
  SourceLinter(LinterOptions options, {this.reporter: const PrintingReporter()})
      : this.options = options != null ? options : _defaultOptions();

  @override
  Iterable<AnalysisErrorInfo> lintFile(File sourceFile) =>
      _registerAndRun(() => new AnalysisDriver.forFile(sourceFile, options));

  @override
  Iterable<AnalysisErrorInfo> lintLibrarySource({String libraryName,
      String libraryContents}) =>
      _registerAndRun(
          () =>
              new AnalysisDriver.forSource(
                  new _StringSource(libraryContents, libraryName),
                  options));

  @override
  Iterable<AnalysisErrorInfo> lintPath(String sourcePath) =>
      _registerAndRun(() => new AnalysisDriver.forPath(sourcePath, options));

  @override
  onError(AnalysisError error) => errors.add(error);

  Iterable<AnalysisErrorInfo> _registerAndRun(_DriverFactory createDriver) {
    _registerLinters(options.enabledLints);
    return createDriver().getErrors();
  }

  static LinterOptions _defaultOptions() =>
      new LinterOptions(() => ruleMap.values);
}

class _StringSource extends StringSource {
  _StringSource(String contents, String fullName) : super(contents, fullName);

  UriKind get uriKind => UriKind.FILE_URI;
}
