// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/context_locator.dart' as api;
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/cache.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    as api;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer_cli/src/context_cache.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/error_severity.dart';
import 'package:analyzer_cli/src/has_context_mixin.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';

/// Persistent Bazel worker.
class AnalyzerWorkerLoop extends AsyncWorkerLoop {
  final ResourceProvider resourceProvider;
  final PerformanceLog logger = PerformanceLog(null);
  final String dartSdkPath;
  WorkerPackageBundleCache packageBundleCache;

  final StringBuffer errorBuffer = StringBuffer();
  final StringBuffer outBuffer = StringBuffer();

  AnalyzerWorkerLoop(this.resourceProvider, AsyncWorkerConnection connection,
      {this.dartSdkPath})
      : super(connection: connection) {
    packageBundleCache =
        WorkerPackageBundleCache(resourceProvider, logger, 256 * 1024 * 1024);
  }

  factory AnalyzerWorkerLoop.sendPort(
      ResourceProvider resourceProvider, SendPort sendPort,
      {String dartSdkPath}) {
    AsyncWorkerConnection connection = SendPortAsyncWorkerConnection(sendPort);
    return AnalyzerWorkerLoop(resourceProvider, connection,
        dartSdkPath: dartSdkPath);
  }

  factory AnalyzerWorkerLoop.std(ResourceProvider resourceProvider,
      {io.Stdin stdinStream, io.Stdout stdoutStream, String dartSdkPath}) {
    AsyncWorkerConnection connection = StdAsyncWorkerConnection(
        inputStream: stdinStream, outputStream: stdoutStream);
    return AnalyzerWorkerLoop(resourceProvider, connection,
        dartSdkPath: dartSdkPath);
  }

  /// Performs analysis with given [options].
  Future<void> analyze(
      CommandLineOptions options, Map<String, WorkerInput> inputs) async {
    var packageBundleProvider =
        WorkerPackageBundleProvider(packageBundleCache, inputs);
    var buildMode = BuildMode(resourceProvider, options, AnalysisStats(),
        ContextCache(resourceProvider, options, Driver.verbosePrint),
        logger: logger, packageBundleProvider: packageBundleProvider);
    await buildMode.analyze();
    AnalysisEngine.instance.clearCaches();
  }

  /// Perform a single loop step.
  @override
  Future<WorkResponse> performRequest(WorkRequest request) async {
    return logger.runAsync('Perform request', () async {
      errorBuffer.clear();
      outBuffer.clear();
      try {
        // Prepare inputs with their digests.
        var inputs = <String, WorkerInput>{};
        for (var input in request.inputs) {
          inputs[input.path] = WorkerInput(input.path, input.digest);
        }

        // Add in the dart-sdk argument if `dartSdkPath` is not null,
        // otherwise it will try to find the currently installed sdk.
        var arguments = request.arguments.toList();
        if (dartSdkPath != null &&
            !arguments.any((arg) => arg.startsWith('--dart-sdk'))) {
          arguments.add('--dart-sdk=$dartSdkPath');
        }

        // Prepare options.
        var options = CommandLineOptions.parse(resourceProvider, arguments,
            printAndFail: (String msg) {
          throw ArgumentError(msg);
        });

        // Analyze and respond.
        await analyze(options, inputs);
        var msg = _getErrorOutputBuffersText();
        return WorkResponse()
          ..exitCode = EXIT_CODE_OK
          ..output = msg;
      } catch (e, st) {
        var msg = _getErrorOutputBuffersText();
        msg += '$e\n$st';
        return WorkResponse()
          ..exitCode = EXIT_CODE_ERROR
          ..output = msg;
      }
    });
  }

  /// Run the worker loop.
  @override
  Future<void> run() async {
    errorSink = errorBuffer;
    outSink = outBuffer;
    exitHandler = (int exitCode) {
      throw StateError('Exit called: $exitCode');
    };
    await super.run();
  }

  String _getErrorOutputBuffersText() {
    var msg = '';
    if (errorBuffer.isNotEmpty) {
      msg += errorBuffer.toString() + '\n';
    }
    if (outBuffer.isNotEmpty) {
      msg += outBuffer.toString() + '\n';
    }
    return msg;
  }
}

/// Analyzer used when the "--build-mode" option is supplied.
class BuildMode with HasContextMixin {
  @override
  final ResourceProvider resourceProvider;
  final CommandLineOptions options;
  final AnalysisStats stats;
  final PerformanceLog logger;
  final PackageBundleProvider packageBundleProvider;

  @override
  final ContextCache contextCache;

  SummaryDataStore summaryDataStore;
  AnalysisOptionsImpl analysisOptions;
  Map<Uri, File> uriToFileMap;
  final List<Source> explicitSources = <Source>[];

  SourceFactory sourceFactory;
  DeclaredVariables declaredVariables;
  AnalysisDriver analysisDriver;

  LinkedElementFactory elementFactory;

  // May be null.
  final DependencyTracker dependencyTracker;

  BuildMode(this.resourceProvider, this.options, this.stats, this.contextCache,
      {PerformanceLog logger, PackageBundleProvider packageBundleProvider})
      : logger = logger ?? PerformanceLog(null),
        packageBundleProvider = packageBundleProvider ??
            DirectPackageBundleProvider(resourceProvider),
        dependencyTracker = options.summaryDepsOutput != null
            ? DependencyTracker(options.summaryDepsOutput)
            : null;

  bool get _shouldOutputSummary =>
      options.buildSummaryOutput != null ||
      options.buildSummaryOutputSemantic != null;

  /// Perform package analysis according to the given [options].
  Future<ErrorSeverity> analyze() async {
    return await logger.runAsync('Analyze', () async {
      // Write initial progress message.
      if (!options.machineFormat) {
        outSink.writeln("Analyzing ${options.sourceFiles.join(', ')}...");
      }

      // Create the URI to file map.
      uriToFileMap = _createUriToFileMap(options.sourceFiles);
      if (uriToFileMap == null) {
        io.exitCode = ErrorSeverity.ERROR.ordinal;
        return ErrorSeverity.ERROR;
      }

      // BuildMode expects sourceFiles in the format "<uri>|<filepath>",
      // but the rest of the code base does not understand this format.
      // Rewrite sourceFiles, stripping the "<uri>|" prefix, so that it
      // does not cause problems with code that does not expect this format.
      options.rewriteSourceFiles(options.sourceFiles
          .map((String uriPipePath) =>
              uriPipePath.substring(uriPipePath.indexOf('|') + 1))
          .toList());

      // Prepare the analysis driver.
      try {
        logger.run('Prepare analysis driver', () {
          _createAnalysisDriver();
        });
      } on ConflictingSummaryException catch (e) {
        errorSink.writeln('$e');
        io.exitCode = ErrorSeverity.ERROR.ordinal;
        return ErrorSeverity.ERROR;
      }

      // Add sources.
      for (var uri in uriToFileMap.keys) {
        var file = uriToFileMap[uri];
        if (!file.exists) {
          errorSink.writeln('File not found: ${file.path}');
          io.exitCode = ErrorSeverity.ERROR.ordinal;
          return ErrorSeverity.ERROR;
        }
        Source source = FileSource(file, uri);
        explicitSources.add(source);
      }

      // Write summary.
      if (_shouldOutputSummary) {
        await logger.runAsync('Build and write output summary', () async {
          // Build and assemble linked libraries.
          var bytes = _computeLinkedLibraries2();

          // Write the whole package bundle.
          // TODO(scheglov) Remove support for `buildSummaryOutput`.
          if (options.buildSummaryOutput != null) {
            var file = io.File(options.buildSummaryOutput);
            file.writeAsBytesSync(bytes, mode: io.FileMode.writeOnly);
          }
          if (options.buildSummaryOutputSemantic != null) {
            var file = io.File(options.buildSummaryOutputSemantic);
            file.writeAsBytesSync(bytes, mode: io.FileMode.writeOnly);
          }
        });
      } else {
        // Build the graph, e.g. associate parts with libraries.
        for (var file in uriToFileMap.values) {
          analysisDriver.fsState.getFileForPath(file.path);
        }
      }

      ErrorSeverity severity;
      if (options.buildSummaryOnly) {
        severity = ErrorSeverity.NONE;
      } else {
        // Process errors.
        await _printErrors(outputPath: options.buildAnalysisOutput);
        severity = await _computeMaxSeverity();
      }

      if (dependencyTracker != null) {
        var file = io.File(dependencyTracker.outputPath);
        file.writeAsStringSync(dependencyTracker.dependencies.join('\n'));
      }

      return severity;
    });
  }

  /// Use [elementFactory] filled with input summaries, and link libraries
  /// in [explicitSources] to produce linked summary bytes.
  Uint8List _computeLinkedLibraries2() {
    return logger.run('Link output summary2', () {
      var inputLibraries = <LinkInputLibrary>[];

      for (var librarySource in explicitSources) {
        var path = librarySource.fullName;

        var parseResult = analysisDriver.parseFileSync(path);
        if (parseResult == null) {
          throw ArgumentError('No parsed unit for $path');
        }

        var unit = parseResult.unit;
        var isPart = unit.directives.any((d) => d is PartOfDirective);
        if (isPart) {
          continue;
        }

        var inputUnits = <LinkInputUnit>[];
        inputUnits.add(
          LinkInputUnit(null, librarySource, false, unit),
        );

        for (var directive in unit.directives) {
          if (directive is PartDirective) {
            var partUri = directive.uri.stringValue;
            var partSource = sourceFactory.resolveUri(librarySource, partUri);

            // Add empty synthetic units for unresolved `part` URIs.
            if (partSource == null) {
              var unit = analysisDriver.fsState.unresolvedFile.parse();
              inputUnits.add(
                LinkInputUnit(partUri, null, true, unit),
              );
              continue;
            }

            var partPath = partSource.fullName;
            var partParseResult = analysisDriver.parseFileSync(partPath);
            if (partParseResult == null) {
              throw ArgumentError('No parsed unit for part $partPath in $path');
            }
            inputUnits.add(
              LinkInputUnit(
                partUri,
                partSource,
                false,
                partParseResult.unit,
              ),
            );
          }
        }

        inputLibraries.add(
          LinkInputLibrary(librarySource, inputUnits),
        );
      }

      var linkResult = link(elementFactory, inputLibraries, false);

      var bundleBuilder = PackageBundleBuilder();
      for (var library in inputLibraries) {
        bundleBuilder.addLibrary(
          library.uriStr,
          library.units.map((e) => e.uriStr).toList(),
        );
      }
      return bundleBuilder.finish(
        astBytes: linkResult.astBytes,
        resolutionBytes: linkResult.resolutionBytes,
      );
    });
  }

  Future<ErrorSeverity> _computeMaxSeverity() async {
    var maxSeverity = ErrorSeverity.NONE;
    if (!options.buildSuppressExitCode) {
      for (var source in explicitSources) {
        var result = await analysisDriver.getErrors(source.fullName);
        for (var error in result.errors) {
          var processedSeverity = determineProcessedSeverity(
              error, options, analysisDriver.analysisOptions);
          if (processedSeverity != null) {
            maxSeverity = maxSeverity.max(processedSeverity);
          }
        }
      }
    }
    return maxSeverity;
  }

  void _createAnalysisDriver() {
    // Read the summaries.
    summaryDataStore = SummaryDataStore(<String>[]);

    // Adds a bundle at `path` to `summaryDataStore`.
    PackageBundleReader addBundle(String path) {
      var bundle = packageBundleProvider.get(path);
      summaryDataStore.addBundle(path, bundle);
      return bundle;
    }

    SummaryBasedDartSdk sdk;
    logger.run('Add SDK bundle', () {
      sdk = SummaryBasedDartSdk(options.dartSdkSummaryPath, true);
      summaryDataStore.addBundle(null, sdk.bundle);
    });

    var numInputs = options.buildSummaryInputs.length;
    logger.run('Add $numInputs input summaries', () {
      for (var path in options.buildSummaryInputs) {
        addBundle(path);
      }
    });

    var rootPath =
        options.sourceFiles.isEmpty ? null : options.sourceFiles.first;

    var packages = _findPackages(rootPath);

    sourceFactory = SourceFactory(<UriResolver>[
      DartUriResolver(sdk),
      TrackingInSummaryUriResolver(
          InSummaryUriResolver(resourceProvider, summaryDataStore),
          dependencyTracker),
      ExplicitSourceResolver(uriToFileMap)
    ]);

    analysisOptions =
        createAnalysisOptionsForCommandLineOptions(options, rootPath);

    var scheduler = AnalysisDriverScheduler(logger);
    analysisDriver = AnalysisDriver(
      scheduler,
      logger,
      resourceProvider,
      MemoryByteStore(),
      FileContentOverlay(),
      null,
      sourceFactory,
      analysisOptions,
      externalSummaries: summaryDataStore,
      packages: packages,
    );

    _setAnalysisDriverAnalysisContext(rootPath);

    declaredVariables = DeclaredVariables.fromMap(options.definedVariables);
    analysisDriver.declaredVariables = declaredVariables;

    _createLinkedElementFactory();

    scheduler.start();
  }

  void _createLinkedElementFactory() {
    var analysisContext = AnalysisContextImpl(
      SynchronousSession(analysisOptions, declaredVariables),
      sourceFactory,
    );

    elementFactory = LinkedElementFactory(
      analysisContext,
      AnalysisSessionImpl(null),
      Reference.root(),
    );

    for (var bundle in summaryDataStore.bundles) {
      elementFactory.addBundle(
        BundleReader(
          elementFactory: elementFactory,
          astBytes: bundle.astBytes,
          resolutionBytes: bundle.resolutionBytes,
        ),
      );
    }
  }

  /// Convert [sourceEntities] (a list of file specifications of the form
  /// "$uri|$path") to a map from URI to path. If an error occurs, report the
  /// error and return null.
  Map<Uri, File> _createUriToFileMap(List<String> sourceEntities) {
    var uriToFileMap = <Uri, File>{};
    for (var sourceFile in sourceEntities) {
      var pipeIndex = sourceFile.indexOf('|');
      if (pipeIndex == -1) {
        // TODO(paulberry): add the ability to guess the URI from the path.
        errorSink.writeln(
            'Illegal input file (must be "\$uri|\$path"): $sourceFile');
        return null;
      }
      var uri = Uri.parse(sourceFile.substring(0, pipeIndex));
      var path = sourceFile.substring(pipeIndex + 1);
      path = resourceProvider.pathContext.absolute(path);
      path = resourceProvider.pathContext.normalize(path);
      uriToFileMap[uri] = resourceProvider.getFile(path);
    }
    return uriToFileMap;
  }

  Packages _findPackages(String path) {
    var configPath = options.packageConfigPath;
    if (configPath != null) {
      var configFile = resourceProvider.getFile(configPath);
      return parsePackagesFile(resourceProvider, configFile);
    }

    if (path != null) {
      var file = resourceProvider.getFile(path);
      return findPackagesFrom(resourceProvider, file);
    }

    return Packages.empty;
  }

  /// Print errors for all explicit sources. If [outputPath] is supplied, output
  /// is sent to a new file at that path.
  Future<void> _printErrors({String outputPath}) async {
    await logger.runAsync('Compute and print analysis errors', () async {
      var buffer = StringBuffer();
      var severityProcessor = (AnalysisError error) =>
          determineProcessedSeverity(error, options, analysisOptions);
      var formatter = options.machineFormat
          ? MachineErrorFormatter(buffer, options, stats,
              severityProcessor: severityProcessor)
          : HumanErrorFormatter(buffer, options, stats,
              severityProcessor: severityProcessor);
      for (var source in explicitSources) {
        var result = await analysisDriver.getErrors(source.fullName);
        formatter.formatErrors([result]);
      }
      formatter.flush();
      if (!options.machineFormat) {
        stats.print(buffer);
      }
      if (outputPath == null) {
        var sink = options.machineFormat ? errorSink : outSink;
        sink.write(buffer);
      } else {
        io.File(outputPath).writeAsStringSync(buffer.toString());
      }
    });
  }

  void _setAnalysisDriverAnalysisContext(String rootPath) {
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

/// Tracks paths to dependencies, really just a thin api around a Set<String>.
class DependencyTracker {
  final _dependencies = <String>{};

  /// The path to the file to create once tracking is done.
  final String outputPath;

  DependencyTracker(this.outputPath);

  Iterable<String> get dependencies => _dependencies;

  void record(String path) => _dependencies.add(path);
}

/// [PackageBundleProvider] that always reads from the [ResourceProvider].
class DirectPackageBundleProvider implements PackageBundleProvider {
  final ResourceProvider resourceProvider;

  DirectPackageBundleProvider(this.resourceProvider);

  @override
  PackageBundleReader get(String path) {
    var bytes = io.File(path).readAsBytesSync();
    return PackageBundleReader(bytes);
  }
}

/// Instances of the class [ExplicitSourceResolver] map URIs to files on disk
/// using a fixed mapping provided at construction time.
class ExplicitSourceResolver extends UriResolver {
  final Map<Uri, File> uriToFileMap;
  final Map<String, Uri> pathToUriMap;

  /// Construct an [ExplicitSourceResolver] based on the given [uriToFileMap].
  ExplicitSourceResolver(Map<Uri, File> uriToFileMap)
      : uriToFileMap = uriToFileMap,
        pathToUriMap = _computePathToUriMap(uriToFileMap);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    var file = uriToFileMap[uri];
    actualUri ??= uri;
    if (file == null) {
      return null;
    } else {
      return FileSource(file, actualUri);
    }
  }

  @override
  Uri restoreAbsolute(Source source) {
    return pathToUriMap[source.fullName];
  }

  /// Build the inverse mapping of [uriToSourceMap].
  static Map<String, Uri> _computePathToUriMap(Map<Uri, File> uriToSourceMap) {
    var pathToUriMap = <String, Uri>{};
    uriToSourceMap.forEach((Uri uri, File file) {
      pathToUriMap[file.path] = uri;
    });
    return pathToUriMap;
  }
}

/// Provider for [PackageBundleReader]s by file paths.
abstract class PackageBundleProvider {
  /// Return the [PackageBundleReader] for the file with the given [path].
  PackageBundleReader get(String path);
}

/// Wrapper for [InSummaryUriResolver] that tracks accesses to summaries.
class TrackingInSummaryUriResolver extends UriResolver {
  // May be null.
  final DependencyTracker dependencyTracker;
  final InSummaryUriResolver inSummaryUriResolver;

  TrackingInSummaryUriResolver(
      this.inSummaryUriResolver, this.dependencyTracker);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    var source = inSummaryUriResolver.resolveAbsolute(uri, actualUri);
    if (dependencyTracker != null &&
        source != null &&
        source is InSummarySource) {
      dependencyTracker.record(source.summaryPath);
    }
    return source;
  }
}

/// Worker input.
///
/// Bazel does not specify the format of the digest, so we cannot assume that
/// the digest itself is enough to uniquely identify inputs. So, we use a pair
/// of path + digest.
class WorkerInput {
  static const _digestEquality = ListEquality<int>();

  final String path;
  final List<int> digest;

  WorkerInput(this.path, this.digest);

  @override
  int get hashCode => _digestEquality.hash(digest);

  @override
  bool operator ==(Object other) {
    return other is WorkerInput &&
        other.path == path &&
        _digestEquality.equals(other.digest, digest);
  }

  @override
  String toString() => '$path @ ${hex.encode(digest)}';
}

/// Value object for [WorkerPackageBundleCache].
class WorkerPackageBundle {
  final List<int> bytes;
  final PackageBundleReader bundle;

  WorkerPackageBundle(this.bytes, this.bundle);

  /// Approximation of a bundle size in memory.
  int get size => bytes.length * 3;
}

/// Cache of [PackageBundleReader]s.
class WorkerPackageBundleCache {
  final ResourceProvider resourceProvider;
  final PerformanceLog logger;
  final Cache<WorkerInput, WorkerPackageBundle> _cache;

  WorkerPackageBundleCache(this.resourceProvider, this.logger, int maxSizeBytes)
      : _cache = Cache<WorkerInput, WorkerPackageBundle>(
            maxSizeBytes, (value) => value.size);

  /// Get the [PackageBundleReader] from the file with the given [path] in the context
  /// of the given worker [inputs].
  PackageBundleReader get(Map<String, WorkerInput> inputs, String path) {
    var input = inputs[path];

    // The input must be not null, otherwise we're not expected to read
    // this file, but we check anyway to be safe.
    if (input == null) {
      logger.writeln('Read $path outside of the inputs.');
      var file = resourceProvider.getFile(path);
      var bytes = file.readAsBytesSync() as Uint8List;
      return PackageBundleReader(bytes);
    }

    return _cache.get(input, () {
      logger.writeln('Read $input.');
      var file = resourceProvider.getFile(path);
      var bytes = file.readAsBytesSync() as Uint8List;
      var bundle = PackageBundleReader(bytes);
      return WorkerPackageBundle(bytes, bundle);
    }).bundle;
  }
}

/// [PackageBundleProvider] that reads from [WorkerPackageBundleCache] using
/// the request specific [inputs].
class WorkerPackageBundleProvider implements PackageBundleProvider {
  final WorkerPackageBundleCache cache;
  final Map<String, WorkerInput> inputs;

  WorkerPackageBundleProvider(this.cache, this.inputs);

  @override
  PackageBundleReader get(String path) {
    return cache.get(inputs, path);
  }
}
