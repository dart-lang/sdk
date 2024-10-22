// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
// ignore: implementation_imports
import 'package:analyzer/src/generated/engine.dart';
// ignore: implementation_imports
import 'package:analyzer/src/lint/io.dart';
// ignore: implementation_imports
import 'package:analyzer/src/lint/linter.dart';

class LintDriver {
  /// The files which have been analyzed so far.  This is used to compute the
  /// total number of files analyzed for statistics.
  final Set<String> _filesAnalyzed = {};

  final LinterOptions options;

  final ResourceProvider _resourceProvider;

  LintDriver(this.options, this._resourceProvider);

  Future<List<AnalysisErrorInfo>> analyze(Iterable<io.File> files) async {
    AnalysisEngine.instance.instrumentationService = _StdInstrumentation();

    var contextCollection = AnalysisContextCollectionImpl(
      resourceProvider: _resourceProvider,
      sdkPath: options.dartSdkPath,
      includedPaths:
          files.map((file) => _absoluteNormalizedPath(file.path)).toList(),
      updateAnalysisOptions2: ({
        required analysisOptions,
        required contextRoot,
        required sdk,
      }) {
        analysisOptions.lint = true;
        analysisOptions.warning = false;
        analysisOptions.enableTiming = options.enableTiming;
        analysisOptions.lintRules =
            options.enabledRules.toList(growable: false);
      },
    );

    for (io.File file in files) {
      var path = _absoluteNormalizedPath(file.path);
      _filesAnalyzed.add(path);
    }

    var result = <AnalysisErrorInfo>[];
    for (var path in _filesAnalyzed) {
      var analysisContext = contextCollection.contextFor(path);
      var analysisSession = analysisContext.currentSession;
      var errorsResult = await analysisSession.getErrors(path);
      if (errorsResult is ErrorsResult) {
        result.add(
          AnalysisErrorInfoImpl(
            errorsResult.errors,
            errorsResult.lineInfo,
          ),
        );
      }
    }
    return result;
  }

  String _absoluteNormalizedPath(String path) {
    var pathContext = _resourceProvider.pathContext;
    return pathContext.normalize(pathContext.absolute(path));
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
