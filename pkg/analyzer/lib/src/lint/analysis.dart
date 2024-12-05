// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/apply_options.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';

AnalysisOptionsProvider _optionsProvider = AnalysisOptionsProvider();

Source createSource(Uri uri) {
  var filePath = uri.toFilePath();
  var file = PhysicalResourceProvider.INSTANCE.getFile(filePath);
  return FileSource(file, uri);
}

/// Print the given message and exit with the given [exitCode]
void printAndFail(String message, {int exitCode = 15}) {
  print(message);
  io.exit(exitCode);
}

void _updateAnalyzerOptions(
  AnalysisOptionsImpl analysisOptions,
  LinterOptions options,
) {
  if (options.analysisOptions != null) {
    var map = _optionsProvider.getOptionsFromString(options.analysisOptions);
    analysisOptions.applyOptions(map);
  }

  analysisOptions.lint = options.enableLints;
  analysisOptions.warning = false;
  analysisOptions.enableTiming = options.enableTiming;
  analysisOptions.lintRules = options.enabledRules.toList(growable: false);
}

class DriverOptions {
  /// The maximum number of sources for which AST structures should be kept
  /// in the cache.  The default is 512.
  int cacheSize = 512;

  /// The path to the dart SDK.
  String? dartSdkPath;

  /// Whether to show lint warnings.
  bool enableLints = true;

  /// Whether to gather timing data during analysis.
  bool enableTiming = false;

  /// The path to a `.packages` configuration file
  String? packageConfigPath;

  /// Whether to use Dart's Strong Mode analyzer.
  bool strongMode = true;
}

/// A driver _only used_ by [DartLinter], which is only used by package:linter
/// tests and tools.
class LintDriver {
  /// The files which have been analyzed so far.  This is used to compute the
  /// total number of files analyzed for statistics.
  final Set<String> _filesAnalyzed = {};

  final LinterOptions options;

  final ResourceProvider _resourceProvider;

  LintDriver(this.options, this._resourceProvider);

  /// Return the number of sources that have been analyzed so far.
  int get numSourcesAnalyzed => _filesAnalyzed.length;

  Future<List<AnalysisErrorInfo>> analyze(Iterable<io.File> files) async {
    AnalysisEngine.instance.instrumentationService = StdInstrumentation();

    // TODO(scheglov): Enforce normalized absolute paths in the config.
    var packageConfigPath = options.packageConfigPath;
    packageConfigPath = _absoluteNormalizedPath.ifNotNull(packageConfigPath);

    var contextCollection = AnalysisContextCollectionImpl(
      resourceProvider: _resourceProvider,
      packagesFile: packageConfigPath,
      sdkPath: options.dartSdkPath,
      includedPaths:
          files.map((file) => _absoluteNormalizedPath(file.path)).toList(),
      updateAnalysisOptions2: ({
        required analysisOptions,
        required contextRoot,
        required sdk,
      }) {
        _updateAnalyzerOptions(analysisOptions, options);
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
    path = pathContext.absolute(path);
    path = pathContext.normalize(path);
    return path;
  }
}

/// Prints logging information comments to the [outSink] and error messages to
/// [errorSink].
class StdInstrumentation extends NoopInstrumentationService {
  @override
  void logError(String message, [Object? exception]) {
    errorSink.writeln(message);
    if (exception != null) {
      errorSink.writeln(exception);
    }
  }

  @override
  void logException(dynamic exception,
      [StackTrace? stackTrace,
      List<InstrumentationServiceAttachment>? attachments]) {
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

extension _UnaryFunctionExtension<T, R> on R Function(T) {
  /// Invoke this function if [t] is not `null`, otherwise return `null`.
  R? ifNotNull(T? t) {
    if (t != null) {
      return this(t);
    } else {
      return null;
    }
  }
}
