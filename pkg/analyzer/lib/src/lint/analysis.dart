// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io' as io;

import 'package:analyzer/dart/analysis/context_locator.dart' as api;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart'
    show File, Folder, ResourceProvider, ResourceUriResolver;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    as api;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/project.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/sdk.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

AnalysisOptionsProvider _optionsProvider = AnalysisOptionsProvider();

Source createSource(Uri sourceUri) {
  return PhysicalResourceProvider.INSTANCE
      .getFile(sourceUri.toFilePath())
      .createSource(sourceUri);
}

/// Print the given message and exit with the given [exitCode]
void printAndFail(String message, {int exitCode = 15}) {
  print(message);
  io.exit(exitCode);
}

AnalysisOptions _buildAnalyzerOptions(LinterOptions options) {
  AnalysisOptionsImpl analysisOptions = AnalysisOptionsImpl();
  if (options.analysisOptions != null) {
    YamlMap map =
        _optionsProvider.getOptionsFromString(options.analysisOptions);
    applyToAnalysisOptions(analysisOptions, map);
  }

  analysisOptions.hint = false;
  analysisOptions.lint = options.enableLints;
  analysisOptions.enableTiming = options.enableTiming;
  analysisOptions.lintRules = options.enabledLints?.toList(growable: false);
  return analysisOptions;
}

class DriverOptions {
  /// The maximum number of sources for which AST structures should be kept
  /// in the cache.  The default is 512.
  int cacheSize = 512;

  /// The path to the dart SDK.
  String dartSdkPath;

  /// Whether to show lint warnings.
  bool enableLints = true;

  /// Whether to gather timing data during analysis.
  bool enableTiming = false;

  /// The path to a `.packages` configuration file
  String packageConfigPath;

  /// The path to the package root.
  @Deprecated('https://github.com/dart-lang/sdk/issues/41197')
  String packageRootPath;

  /// Whether to use Dart's Strong Mode analyzer.
  bool strongMode = true;

  /// The mock SDK (to speed up testing) or `null` to use the actual SDK.
  DartSdk mockSdk;

  /// Return `true` is the parser is able to parse asserts in the initializer
  /// list of a constructor.
  @deprecated
  bool get enableAssertInitializer => true;

  /// Set whether the parser is able to parse asserts in the initializer list of
  /// a constructor to match [enable].
  @deprecated
  set enableAssertInitializer(bool enable) {
    // Ignored because the option is now always enabled.
  }

  /// Whether to use Dart 2.0 features.
  @deprecated
  bool get previewDart2 => true;

  @deprecated
  set previewDart2(bool value) {}
}

class LintDriver {
  /// The sources which have been analyzed so far.  This is used to avoid
  /// analyzing a source more than once, and to compute the total number of
  /// sources analyzed for statistics.
  final Set<Source> _sourcesAnalyzed = HashSet<Source>();

  final LinterOptions options;

  LintDriver(this.options);

  /// Return the number of sources that have been analyzed so far.
  int get numSourcesAnalyzed => _sourcesAnalyzed.length;

  List<UriResolver> get resolvers {
    // TODO(brianwilkerson) Use the context builder to compute all of the resolvers.
    ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

    DartSdk sdk = options.mockSdk ??
        FolderBasedDartSdk(
            resourceProvider, resourceProvider.getFolder(sdkDir));

    List<UriResolver> resolvers = [DartUriResolver(sdk)];

    var packageUriResolver = _getPackageUriResolver();
    if (packageUriResolver != null) {
      resolvers.add(packageUriResolver);
    }

    // File URI resolver must come last so that files inside "/lib" are
    // are analyzed via "package:" URI's.
    resolvers.add(ResourceUriResolver(resourceProvider));
    return resolvers;
  }

  ResourceProvider get resourceProvider => options.resourceProvider;

  String get sdkDir {
    // In case no SDK has been specified, fall back to inferring it.
    return options.dartSdkPath ?? getSdkPath();
  }

  Future<List<AnalysisErrorInfo>> analyze(Iterable<io.File> files) async {
    AnalysisEngine.instance.instrumentationService = StdInstrumentation();

    SourceFactory sourceFactory = SourceFactory(resolvers);

    PerformanceLog log = PerformanceLog(null);
    AnalysisDriverScheduler scheduler = AnalysisDriverScheduler(log);
    AnalysisDriver analysisDriver = AnalysisDriver(
      scheduler,
      log,
      resourceProvider,
      MemoryByteStore(),
      FileContentOverlay(),
      null,
      sourceFactory,
      _buildAnalyzerOptions(options),
      packages: Packages.empty,
    );

    _setAnalysisDriverAnalysisContext(analysisDriver, files);

    analysisDriver.results.listen((_) {});
    analysisDriver.exceptions.listen((_) {});
    scheduler.start();

    List<Source> sources = [];
    for (io.File file in files) {
      File sourceFile =
          resourceProvider.getFile(p.normalize(file.absolute.path));
      Source source = sourceFile.createSource();
      Uri uri = sourceFactory.restoreUri(source);
      if (uri != null) {
        // Ensure that we analyze the file using its canonical URI (e.g. if
        // it's in "/lib", analyze it using a "package:" URI).
        source = sourceFile.createSource(uri);
      }

      sources.add(source);
      analysisDriver.addFile(source.fullName);
    }

    DartProject project = await DartProject.create(analysisDriver, sources);
    Registry.ruleRegistry.forEach((lint) {
      if (lint is ProjectVisitor) {
        (lint as ProjectVisitor).visit(project);
      }
    });

    List<AnalysisErrorInfo> errors = [];
    for (Source source in sources) {
      ErrorsResult errorsResult =
          await analysisDriver.getErrors(source.fullName);
      errors.add(
          AnalysisErrorInfoImpl(errorsResult.errors, errorsResult.lineInfo));
      _sourcesAnalyzed.add(source);
    }

    return errors;
  }

  void registerLinters(AnalysisContext context) {
    if (options.enableLints) {
      setLints(context, options.enabledLints?.toList(growable: false));
    }
  }

  PackageMapUriResolver _getPackageUriResolver() {
    var packageConfigPath = options.packageConfigPath;
    if (packageConfigPath != null) {
      var resourceProvider = PhysicalResourceProvider.INSTANCE;
      var pathContext = resourceProvider.pathContext;
      packageConfigPath = pathContext.absolute(packageConfigPath);
      packageConfigPath = pathContext.normalize(packageConfigPath);

      try {
        var packages = parsePackagesFile(
          resourceProvider,
          resourceProvider.getFile(packageConfigPath),
        );

        var packageMap = <String, List<Folder>>{};
        for (var package in packages.packages) {
          packageMap[package.name] = [package.libFolder];
        }

        return PackageMapUriResolver(resourceProvider, packageMap);
      } catch (e) {
        printAndFail(
          'Unable to read package config data from $packageConfigPath: $e',
        );
      }
    }
    return null;
  }

  void _setAnalysisDriverAnalysisContext(
    AnalysisDriver analysisDriver,
    Iterable<io.File> files,
  ) {
    if (files.isEmpty) {
      return;
    }

    var rootPath = p.normalize(files.first.absolute.path);
    if (rootPath == null) {
      return;
    }

    var apiContextRoots = api.ContextLocator(
      resourceProvider: resourceProvider,
    ).locateRoots(
      includedPaths: [rootPath],
      excludedPaths: [],
    );

    if (apiContextRoots.isEmpty) {
      return;
    }

    analysisDriver.configure(
      analysisContext: api.DriverBasedAnalysisContext(
        resourceProvider,
        apiContextRoots.first,
        analysisDriver,
      ),
    );
  }
}

/// Prints logging information comments to the [outSink] and error messages to
/// [errorSink].
class StdInstrumentation extends NoopInstrumentationService {
  @override
  void logError(String message, [Object exception]) {
    errorSink.writeln(message);
    if (exception != null) {
      errorSink.writeln(exception);
    }
  }

  @override
  void logException(dynamic exception,
      [StackTrace stackTrace,
      List<InstrumentationServiceAttachment> attachments]) {
    errorSink.writeln(exception);
    errorSink.writeln(stackTrace);
  }

  @override
  void logInfo(String message, [Object exception]) {
    outSink.writeln(message);
    if (exception != null) {
      outSink.writeln(exception);
    }
  }
}
