// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/io.dart' show errorSink;
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/util.dart' as util;
import 'package:analyzer/src/services/lint.dart' as lint_service;

import 'analyzer.dart';
import 'version.dart';

export 'package:analyzer/dart/element/type_system.dart';
export 'package:analyzer/src/dart/ast/token.dart';
export 'package:analyzer/src/dart/constant/evaluation.dart'
    show ConstantEvaluationEngine, ConstantVisitor;
export 'package:analyzer/src/dart/constant/value.dart' show DartObjectImpl;
export 'package:analyzer/src/dart/element/inheritance_manager3.dart'
    show InheritanceManager3, Name;
export 'package:analyzer/src/dart/element/type_provider.dart'
    show TypeProviderImpl;
export 'package:analyzer/src/dart/error/lint_codes.dart';
export 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisErrorInfo;
export 'package:analyzer/src/generated/resolver.dart'
    show ExitDetector, TypeProvider;
export 'package:analyzer/src/generated/source.dart' show LineInfo, Source;
export 'package:analyzer/src/lint/linter.dart'
    show
        DartLinter,
        LintRule,
        Group,
        Maturity,
        LinterContext,
        LinterOptions,
        LintFilter,
        NodeLintRegistry,
        NodeLintRule;
export 'package:analyzer/src/lint/project.dart'
    show DartProject, ProjectVisitor;
export 'package:analyzer/src/lint/pub.dart' show PubspecVisitor, PSEntry;
export 'package:analyzer/src/lint/util.dart' show Spelunker;
export 'package:analyzer/src/services/lint.dart' show lintRegistry;

const loggedAnalyzerErrorExitCode = 63;

Future<Iterable<AnalysisErrorInfo>> lintFiles(
    DartLinter linter, List<File> filesToLint) async {
  // Setup an error watcher to track whether an error was logged to stderr so
  // we can set the exit code accordingly.
  final errorWatcher = ErrorWatchingSink(errorSink);
  errorSink = errorWatcher;

  final errors = await linter.lintFiles(filesToLint);
  if (errorWatcher.encounteredError) {
    exitCode = loggedAnalyzerErrorExitCode;
  } else if (errors.isNotEmpty) {
    exitCode = _maxSeverity(errors.toList(), linter.options.filter);
  }

  return errors;
}

Iterable<AnalysisError> _filtered(
        List<AnalysisError> errors, LintFilter filter) =>
    (filter == null)
        ? errors
        : errors.where((AnalysisError e) => !filter.filter(e));

int _maxSeverity(List<AnalysisErrorInfo> errors, LintFilter filter) {
  var max = 0;
  for (final info in errors) {
    _filtered(info.errors, filter).forEach((AnalysisError e) {
      max = math.max(max, e.errorCode.errorSeverity.ordinal);
    });
  }
  return max;
}

/// Facade for managing access to `analyzer` package APIs.
class Analyzer {
  /// Shared instance.
  static Analyzer facade = Analyzer();

  /// Returns currently registered lint rules.
  Iterable<LintRule> get registeredRules => Registry.ruleRegistry;

  /// Cache linter version; used in summary signatures.
  void cacheLinterVersion() {
    lint_service.linterVersion = version;
  }

  /// Create a library name prefix based on [libraryPath], [projectRoot] and
  /// current [packageName].
  String createLibraryNamePrefix(
          {String libraryPath, String projectRoot, String packageName}) =>
      util.createLibraryNamePrefix(
          libraryPath: libraryPath,
          projectRoot: projectRoot,
          packageName: packageName);

  /// Register this [lint] with the analyzer's rule registry.
  void register(LintRule lint) {
    Registry.ruleRegistry.register(lint);
  }
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
  void addError(Object error, [StackTrace stackTrace]) {
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
  void write(Object obj) {
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
  void writeln([Object obj = '']) {
    // 'Exception while using a Visitor to visit ...' (
    if (obj.toString().startsWith('Exception')) {
      encounteredError = true;
    }
    delegate.writeln(obj);
  }
}
