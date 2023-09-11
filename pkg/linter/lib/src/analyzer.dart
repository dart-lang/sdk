// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisErrorInfo;
import 'package:analyzer/src/lint/io.dart' show errorSink;
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/util.dart' as util;
import 'package:analyzer/src/services/lint.dart' as lint_service;

export 'package:analyzer/dart/element/type_system.dart';
export 'package:analyzer/src/dart/ast/token.dart';
export 'package:analyzer/src/dart/element/inheritance_manager3.dart'
    show InheritanceManager3, Name;
export 'package:analyzer/src/dart/error/lint_codes.dart';
export 'package:analyzer/src/dart/resolver/exit_detector.dart';
export 'package:analyzer/src/generated/engine.dart' show AnalysisErrorInfo;
export 'package:analyzer/src/generated/source.dart' show LineInfo, Source;
export 'package:analyzer/src/lint/linter.dart'
    show
        dart2_12,
        dart3,
        DartLinter,
        Group,
        LintFilter,
        LintRule,
        LinterContext,
        LinterOptions,
        NodeLintRegistry,
        NodeLintRule,
        State;
export 'package:analyzer/src/lint/pub.dart' show PSEntry, PubspecVisitor;
export 'package:analyzer/src/lint/util.dart' show FileSpelunker;
export 'package:analyzer/src/services/lint.dart' show lintRegistry;
export 'package:analyzer/src/workspace/pub.dart' show PubWorkspacePackage;

const loggedAnalyzerErrorExitCode = 63;

Future<Iterable<AnalysisErrorInfo>> lintFiles(
    DartLinter linter, List<File> filesToLint) async {
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

/// Facade for managing access to `analyzer` package APIs.
class Analyzer {
  /// Shared instance.
  static Analyzer facade = Analyzer();

  /// Returns currently registered lint rules.
  Iterable<LintRule> get registeredRules => Registry.ruleRegistry;

  /// Cache linter version; used in summary signatures.
  void cacheLinterVersion() {
    // todo(pq): remove (https://github.com/dart-lang/linter/issues/4418)
    lint_service.linterVersion = '1.35.0';
  }

  /// Create a library name prefix based on [libraryPath], [projectRoot] and
  /// current [packageName].
  String createLibraryNamePrefix(
          {required String libraryPath,
          String? projectRoot,
          String? packageName}) =>
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
