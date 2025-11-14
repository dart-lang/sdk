// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart' as file_system;
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:path/path.dart' as path;

import 'util/io.dart';

class TestLinter implements DiagnosticListener {
  final errors = <Diagnostic>[];

  final List<AbstractAnalysisRule> _rules;

  final String? _dartSdkPath;

  TestLinter(this._rules, this._dartSdkPath);

  ResourceProvider get _resourceProvider =>
      file_system.PhysicalResourceProvider.INSTANCE;

  Future<List<Diagnostic>> lintFiles(List<io.File> files) async {
    var errors = await _analyze(files.where((f) => f.path.endsWith('.dart')));
    for (var file in files.where(_isPubspecFile)) {
      _lintPubspecSource(
        contents: file.readAsStringSync(),
        sourcePath: _resourceProvider.pathContext.normalize(file.absolute.path),
      );
    }
    return errors;
  }

  @override
  void onDiagnostic(Diagnostic error) => errors.add(error);

  String _absoluteNormalizedPath(String path) => _resourceProvider.pathContext
      .normalize(_resourceProvider.pathContext.absolute(path));

  Future<List<Diagnostic>> _analyze(Iterable<io.File> files) async {
    AnalysisEngine.instance.instrumentationService = _StdInstrumentation();

    var filePaths = files
        .map((file) => _absoluteNormalizedPath(file.path))
        .toList();

    var contextCollection = AnalysisContextCollectionImpl(
      resourceProvider: _resourceProvider,
      sdkPath: _dartSdkPath,
      includedPaths: filePaths,
      updateAnalysisOptions4: ({required analysisOptions}) {
        analysisOptions.lint = true;
        analysisOptions.warning = false;
        analysisOptions.lintRules = _rules;
      },
      enableLintRuleTiming: true,
      withFineDependencies: true,
    );

    var result = <Diagnostic>[];
    for (var path in filePaths) {
      var analysisSession = contextCollection.contextFor(path).currentSession;
      var errorsResult = await analysisSession.getErrors(path);
      if (errorsResult is ErrorsResult) {
        result.addAll(errorsResult.diagnostics);
      }
    }
    return result;
  }

  /// Whether this [entry] is a pubspec file.
  bool _isPubspecFile(io.FileSystemEntity entry) =>
      path.basename(entry.path) == file_paths.pubspecYaml;

  void _lintPubspecSource({required String contents, String? sourcePath}) {
    var sourceUrl = sourcePath == null ? null : path.toUri(sourcePath);
    var spec = Pubspec.parse(contents, sourceUrl: sourceUrl);

    for (var rule in _rules) {
      var visitor = rule.pubspecVisitor;
      if (visitor != null) {
        // Analyzer sets reporters; if this file is not being analyzed,
        // we need to set one ourselves.  (Needless to say, when pubspec
        // processing gets pushed down, this hack can go away.)
        if (sourceUrl != null) {
          var source = FileSource(
            _resourceProvider.getFile(sourceUrl.toFilePath()),
            sourceUrl,
          );
          rule.reporter = DiagnosticReporter(this, source);
        }
        try {
          spec.accept(visitor);
        } on Exception catch (_) {
          // TODO(srawlins): Report the exception somewhere?
        }
      }
    }
  }
}

/// Prints logging information comments to the [outSink] and error messages to
/// [errorSink].
class _StdInstrumentation extends NoopInstrumentationService {
  @override
  void logError(String message, [Object? exception]) {
    errorSink.writeln(message);
    if (exception != null) {
      errorSink.writeln(exception);
    }
  }

  @override
  void logException(
    exception, [
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  ]) {
    errorSink.writeln(exception);
    errorSink.writeln(stackTrace);
  }

  @override
  void logInfo(String message, [Object? exception]) {
    outSink.writeln(message);
    if (exception != null) {
      outSink.writeln(exception);
    }
  }
}
