// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.build_mode;

import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;
import 'package:analyzer_cli/src/context_cache.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/error_severity.dart';
import 'package:analyzer_cli/src/has_context_mixin.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:front_end/src/api_prototype/byte_store.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:front_end/src/byte_store/cache.dart';

/**
 * Persistent Bazel worker.
 */
class AnalyzerWorkerLoop extends AsyncWorkerLoop {
  final ResourceProvider resourceProvider;
  final PerformanceLog logger = new PerformanceLog(null);
  final String dartSdkPath;
  WorkerPackageBundleCache packageBundleCache;

  final StringBuffer errorBuffer = new StringBuffer();
  final StringBuffer outBuffer = new StringBuffer();

  AnalyzerWorkerLoop(this.resourceProvider, AsyncWorkerConnection connection,
      {this.dartSdkPath})
      : super(connection: connection) {
    packageBundleCache = new WorkerPackageBundleCache(
        resourceProvider, logger, 256 * 1024 * 1024);
  }

  factory AnalyzerWorkerLoop.std(ResourceProvider resourceProvider,
      {io.Stdin stdinStream, io.Stdout stdoutStream, String dartSdkPath}) {
    AsyncWorkerConnection connection = new StdAsyncWorkerConnection(
        inputStream: stdinStream, outputStream: stdoutStream);
    return new AnalyzerWorkerLoop(resourceProvider, connection,
        dartSdkPath: dartSdkPath);
  }

  /**
   * Performs analysis with given [options].
   */
  Future<Null> analyze(
      CommandLineOptions options, Map<String, WorkerInput> inputs) async {
    var packageBundleProvider =
        new WorkerPackageBundleProvider(packageBundleCache, inputs);
    var buildMode = new BuildMode(
        resourceProvider,
        options,
        new AnalysisStats(),
        new ContextCache(resourceProvider, options, Driver.verbosePrint),
        logger: logger,
        packageBundleProvider: packageBundleProvider);
    await buildMode.analyze();
    AnalysisEngine.instance.clearCaches();
  }

  /**
   * Perform a single loop step.
   */
  @override
  Future<WorkResponse> performRequest(WorkRequest request) async {
    return logger.runAsync('Perform request', () async {
      errorBuffer.clear();
      outBuffer.clear();
      try {
        // Prepare inputs with their digests.
        Map<String, WorkerInput> inputs = {};
        for (var input in request.inputs) {
          inputs[input.path] = new WorkerInput(input.path, input.digest);
        }

        // Add in the dart-sdk argument if `dartSdkPath` is not null,
        // otherwise it will try to find the currently installed sdk.
        var arguments = request.arguments.toList();
        if (dartSdkPath != null &&
            !arguments.any((arg) => arg.startsWith('--dart-sdk'))) {
          arguments.add('--dart-sdk=$dartSdkPath');
        }

        // Prepare options.
        CommandLineOptions options =
            CommandLineOptions.parse(arguments, printAndFail: (String msg) {
          throw new ArgumentError(msg);
        });

        // Analyze and respond.
        await analyze(options, inputs);
        String msg = _getErrorOutputBuffersText();
        return new WorkResponse()
          ..exitCode = EXIT_CODE_OK
          ..output = msg;
      } catch (e, st) {
        String msg = _getErrorOutputBuffersText();
        msg += '$e\n$st';
        return new WorkResponse()
          ..exitCode = EXIT_CODE_ERROR
          ..output = msg;
      }
    });
  }

  /**
   * Run the worker loop.
   */
  @override
  Future<Null> run() async {
    errorSink = errorBuffer;
    outSink = outBuffer;
    exitHandler = (int exitCode) {
      return throw new StateError('Exit called: $exitCode');
    };
    await super.run();
  }

  String _getErrorOutputBuffersText() {
    String msg = '';
    if (errorBuffer.isNotEmpty) {
      msg += errorBuffer.toString() + '\n';
    }
    if (outBuffer.isNotEmpty) {
      msg += outBuffer.toString() + '\n';
    }
    return msg;
  }
}

/**
 * Analyzer used when the "--build-mode" option is supplied.
 */
class BuildMode extends Object with HasContextMixin {
  final ResourceProvider resourceProvider;
  final CommandLineOptions options;
  final AnalysisStats stats;
  final PerformanceLog logger;
  final PackageBundleProvider packageBundleProvider;

  final ContextCache contextCache;

  SummaryDataStore summaryDataStore;
  AnalysisOptions analysisOptions;
  Map<Uri, File> uriToFileMap;
  final List<Source> explicitSources = <Source>[];
  final List<PackageBundle> unlinkedBundles = <PackageBundle>[];

  AnalysisDriver analysisDriver;

  PackageBundleAssembler assembler;
  final Set<Source> processedSources = new Set<Source>();
  final Map<String, UnlinkedUnit> uriToUnit = <String, UnlinkedUnit>{};

  BuildMode(this.resourceProvider, this.options, this.stats, this.contextCache,
      {PerformanceLog logger, PackageBundleProvider packageBundleProvider})
      : logger = logger ?? new PerformanceLog(null),
        packageBundleProvider = packageBundleProvider ??
            new DirectPackageBundleProvider(resourceProvider);

  bool get _shouldOutputSummary =>
      options.buildSummaryOutput != null ||
      options.buildSummaryOutputSemantic != null;

  /**
   * Perform package analysis according to the given [options].
   */
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
      for (Uri uri in uriToFileMap.keys) {
        File file = uriToFileMap[uri];
        if (!file.exists) {
          errorSink.writeln('File not found: ${file.path}');
          io.exitCode = ErrorSeverity.ERROR.ordinal;
          return ErrorSeverity.ERROR;
        }
        Source source = new FileSource(file, uri);
        explicitSources.add(source);
      }

      // Write summary.
      assembler = new PackageBundleAssembler();
      if (_shouldOutputSummary) {
        await logger.runAsync('Build and write output summary', () async {
          // Prepare all unlinked units.
          await logger.runAsync('Prepare unlinked units', () async {
            for (var src in explicitSources) {
              await _prepareUnlinkedUnit('${src.uri}');
            }
          });

          // Build and assemble linked libraries.
          if (!options.buildSummaryOnlyUnlinked) {
            // Prepare URIs of unlinked units that should be linked.
            var unlinkedUris = new Set<String>();
            for (var bundle in unlinkedBundles) {
              unlinkedUris.addAll(bundle.unlinkedUnitUris);
            }
            for (var src in explicitSources) {
              unlinkedUris.add('${src.uri}');
            }
            // Perform linking.
            _computeLinkedLibraries(unlinkedUris);
          }

          // Write the whole package bundle.
          PackageBundleBuilder bundle = assembler.assemble();
          if (options.buildSummaryOutput != null) {
            io.File file = new io.File(options.buildSummaryOutput);
            file.writeAsBytesSync(bundle.toBuffer(),
                mode: io.FileMode.WRITE_ONLY);
          }
          if (options.buildSummaryOutputSemantic != null) {
            bundle.flushInformative();
            io.File file = new io.File(options.buildSummaryOutputSemantic);
            file.writeAsBytesSync(bundle.toBuffer(),
                mode: io.FileMode.WRITE_ONLY);
          }
        });
      } else {
        // Build the graph, e.g. associate parts with libraries.
        for (var file in uriToFileMap.values) {
          analysisDriver.fsState.getFileForPath(file.path);
        }
      }

      if (options.buildSummaryOnly) {
        return ErrorSeverity.NONE;
      } else {
        // Process errors.
        await _printErrors(outputPath: options.buildAnalysisOutput);
        return await _computeMaxSeverity();
      }
    });
  }

  /**
   * Compute linked libraries for the given [libraryUris] using the linked
   * libraries of the [summaryDataStore] and unlinked units in [uriToUnit], and
   * add them to  the [assembler].
   */
  void _computeLinkedLibraries(Set<String> libraryUris) {
    logger.run('Link output summary', () {
      LinkedLibrary getDependency(String absoluteUri) =>
          summaryDataStore.linkedMap[absoluteUri];

      UnlinkedUnit getUnit(String absoluteUri) =>
          summaryDataStore.unlinkedMap[absoluteUri] ?? uriToUnit[absoluteUri];

      Map<String, LinkedLibraryBuilder> linkResult = link(
          libraryUris,
          getDependency,
          getUnit,
          analysisDriver.declaredVariables.get,
          options.strongMode);
      linkResult.forEach(assembler.addLinkedLibrary);
    });
  }

  Future<ErrorSeverity> _computeMaxSeverity() async {
    ErrorSeverity maxSeverity = ErrorSeverity.NONE;
    if (!options.buildSuppressExitCode) {
      for (Source source in explicitSources) {
        ErrorsResult result = await analysisDriver.getErrors(source.fullName);
        for (AnalysisError error in result.errors) {
          ErrorSeverity processedSeverity = determineProcessedSeverity(
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
    summaryDataStore = new SummaryDataStore(<String>[]);

    // Adds a bundle at `path` to `summaryDataStore`.
    PackageBundle addBundle(String path) {
      PackageBundle bundle = packageBundleProvider.get(path);
      summaryDataStore.addBundle(path, bundle);
      return bundle;
    }

    int numInputs = options.buildSummaryInputs.length +
        options.buildSummaryUnlinkedInputs.length;
    logger.run('Add $numInputs input summaries', () {
      for (var path in options.buildSummaryInputs) {
        var bundle = addBundle(path);
        if (bundle.linkedLibraryUris.isEmpty &&
            bundle.unlinkedUnitUris.isNotEmpty) {
          throw new ArgumentError(
              'Got an unlinked summary for --build-summary-input at `$path`. '
              'Unlinked summaries should be provided with the '
              '--build-summary-unlinked-input argument.');
        }
      }

      for (var path in options.buildSummaryUnlinkedInputs) {
        var bundle = addBundle(path);
        unlinkedBundles.add(bundle);
        if (bundle.linkedLibraryUris.isNotEmpty) {
          throw new ArgumentError(
              'Got a linked summary for --build-summary-input-unlinked at `$path`'
              '. Linked bundles should be provided with the '
              '--build-summary-input argument.');
        }
      }
    });

    String rootPath =
        options.sourceFiles.isEmpty ? null : options.sourceFiles.first;
    DartSdk sdk;
    logger.run('Add SDK bundle', () {
      PackageBundle sdkBundle;
      if (options.dartSdkSummaryPath != null) {
        SummaryBasedDartSdk summarySdk = new SummaryBasedDartSdk(
            options.dartSdkSummaryPath, options.strongMode);
        sdk = summarySdk;
        sdkBundle = summarySdk.bundle;
      } else {
        FolderBasedDartSdk dartSdk = new FolderBasedDartSdk(
            resourceProvider,
            resourceProvider.getFolder(options.dartSdkPath),
            options.strongMode);
        dartSdk.analysisOptions =
            createAnalysisOptionsForCommandLineOptions(options, rootPath);
        dartSdk.useSummary = !options.buildSummaryOnly;
        sdk = dartSdk;
        sdkBundle = dartSdk.getSummarySdkBundle(options.strongMode);
      }

      // Include SDK bundle to avoid parsing SDK sources.
      summaryDataStore.addBundle(null, sdkBundle);
    });

    var sourceFactory = new SourceFactory(<UriResolver>[
      new DartUriResolver(sdk),
      new InSummaryUriResolver(resourceProvider, summaryDataStore),
      new ExplicitSourceResolver(uriToFileMap)
    ]);

    analysisOptions =
        createAnalysisOptionsForCommandLineOptions(options, rootPath);

    AnalysisDriverScheduler scheduler = new AnalysisDriverScheduler(logger);
    analysisDriver = new AnalysisDriver(
        scheduler,
        logger,
        resourceProvider,
        new MemoryByteStore(),
        new FileContentOverlay(),
        null,
        sourceFactory,
        analysisOptions,
        externalSummaries: summaryDataStore);
    Driver.declareVariables(analysisDriver.declaredVariables, options);

    scheduler.start();
  }

  /**
   * Convert [sourceEntities] (a list of file specifications of the form
   * "$uri|$path") to a map from URI to path.  If an error occurs, report the
   * error and return null.
   */
  Map<Uri, File> _createUriToFileMap(List<String> sourceEntities) {
    Map<Uri, File> uriToFileMap = <Uri, File>{};
    for (String sourceFile in sourceEntities) {
      int pipeIndex = sourceFile.indexOf('|');
      if (pipeIndex == -1) {
        // TODO(paulberry): add the ability to guess the URI from the path.
        errorSink.writeln(
            'Illegal input file (must be "\$uri|\$path"): $sourceFile');
        return null;
      }
      Uri uri = Uri.parse(sourceFile.substring(0, pipeIndex));
      String path = sourceFile.substring(pipeIndex + 1);
      uriToFileMap[uri] = resourceProvider.getFile(path);
    }
    return uriToFileMap;
  }

  /**
   * Ensure that the [UnlinkedUnit] for [absoluteUri] is available.
   *
   * If the unit is in the input [summaryDataStore], do nothing.
   *
   * Otherwise compute it and store into the [uriToUnit] and [assembler].
   */
  Future<Null> _prepareUnlinkedUnit(String absoluteUri) async {
    // Maybe an input package contains the source.
    if (summaryDataStore.unlinkedMap[absoluteUri] != null) {
      return;
    }
    // Parse the source and serialize its AST.
    Uri uri = Uri.parse(absoluteUri);
    Source source = analysisDriver.sourceFactory.forUri2(uri);
    if (!source.exists()) {
      // TODO(paulberry): we should report a warning/error because DDC
      // compilations are unlikely to work.
      return;
    }
    var result = await analysisDriver.parseFile(source.fullName);
    UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(result.unit);
    uriToUnit[absoluteUri] = unlinkedUnit;
    assembler.addUnlinkedUnit(source, unlinkedUnit);
  }

  /**
   * Print errors for all explicit sources.  If [outputPath] is supplied, output
   * is sent to a new file at that path.
   */
  Future<Null> _printErrors({String outputPath}) async {
    await logger.runAsync('Compute and print analysis errors', () async {
      StringBuffer buffer = new StringBuffer();
      var severityProcessor = (AnalysisError error) =>
          determineProcessedSeverity(error, options, analysisOptions);
      ErrorFormatter formatter = options.machineFormat
          ? new MachineErrorFormatter(buffer, options, stats,
              severityProcessor: severityProcessor)
          : new HumanErrorFormatter(buffer, options, stats,
              severityProcessor: severityProcessor);
      for (Source source in explicitSources) {
        var result = await analysisDriver.getErrors(source.fullName);
        var errorInfo =
            new AnalysisErrorInfoImpl(result.errors, result.lineInfo);
        formatter.formatErrors([errorInfo]);
      }
      formatter.flush();
      if (!options.machineFormat) {
        stats.print(buffer);
      }
      if (outputPath == null) {
        StringSink sink = options.machineFormat ? errorSink : outSink;
        sink.write(buffer);
      } else {
        new io.File(outputPath).writeAsStringSync(buffer.toString());
      }
    });
  }
}

/**
 * [PackageBundleProvider] that always reads from the [ResourceProvider].
 */
class DirectPackageBundleProvider implements PackageBundleProvider {
  final ResourceProvider resourceProvider;

  DirectPackageBundleProvider(this.resourceProvider);

  @override
  PackageBundle get(String path) {
    var bytes = new io.File(path).readAsBytesSync();
    return new PackageBundle.fromBuffer(bytes);
  }
}

/**
 * Instances of the class [ExplicitSourceResolver] map URIs to files on disk
 * using a fixed mapping provided at construction time.
 */
class ExplicitSourceResolver extends UriResolver {
  final Map<Uri, File> uriToFileMap;
  final Map<String, Uri> pathToUriMap;

  /**
   * Construct an [ExplicitSourceResolver] based on the given [uriToFileMap].
   */
  ExplicitSourceResolver(Map<Uri, File> uriToFileMap)
      : uriToFileMap = uriToFileMap,
        pathToUriMap = _computePathToUriMap(uriToFileMap);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    File file = uriToFileMap[uri];
    actualUri ??= uri;
    if (file == null) {
      return new NonExistingSource(
          uri.toString(), actualUri, UriKind.fromScheme(actualUri.scheme));
    } else {
      return new FileSource(file, actualUri);
    }
  }

  @override
  Uri restoreAbsolute(Source source) {
    return pathToUriMap[source.fullName];
  }

  /**
   * Build the inverse mapping of [uriToSourceMap].
   */
  static Map<String, Uri> _computePathToUriMap(Map<Uri, File> uriToSourceMap) {
    Map<String, Uri> pathToUriMap = <String, Uri>{};
    uriToSourceMap.forEach((Uri uri, File file) {
      pathToUriMap[file.path] = uri;
    });
    return pathToUriMap;
  }
}

/**
 * Provider for [PackageBundle]s by file paths.
 */
abstract class PackageBundleProvider {
  /**
   * Return the [PackageBundle] for the file with the given [path].
   */
  PackageBundle get(String path);
}

/**
 * Worker input.
 *
 * Bazel does not specify the format of the digest, so we cannot assume that
 * the digest itself is enough to uniquely identify inputs. So, we use a pair
 * of path + digest.
 */
class WorkerInput {
  static const _digestEquality = const ListEquality<int>();

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

/**
 * Value object for [WorkerPackageBundleCache].
 */
class WorkerPackageBundle {
  final List<int> bytes;
  final PackageBundle bundle;

  WorkerPackageBundle(this.bytes, this.bundle);

  /**
   * Approximation of a bundle size in memory.
   */
  int get size => bytes.length * 3;
}

/**
 * Cache of [PackageBundle]s.
 */
class WorkerPackageBundleCache {
  final ResourceProvider resourceProvider;
  final PerformanceLog logger;
  final Cache<WorkerInput, WorkerPackageBundle> _cache;

  WorkerPackageBundleCache(this.resourceProvider, this.logger, int maxSizeBytes)
      : _cache = new Cache<WorkerInput, WorkerPackageBundle>(
            maxSizeBytes, (value) => value.size);

  /**
   * Get the [PackageBundle] from the file with the given [path] in the context
   * of the given worker [inputs].
   */
  PackageBundle get(Map<String, WorkerInput> inputs, String path) {
    WorkerInput input = inputs[path];

    // The input must be not null, otherwise we're not expected to read
    // this file, but we check anyway to be safe.
    if (input == null) {
      logger.writeln('Read $path outside of the inputs.');
      var bytes = resourceProvider.getFile(path).readAsBytesSync();
      return new PackageBundle.fromBuffer(bytes);
    }

    return _cache.get(input, () {
      logger.writeln('Read $input.');
      var bytes = resourceProvider.getFile(path).readAsBytesSync();
      var bundle = new PackageBundle.fromBuffer(bytes);
      return new WorkerPackageBundle(bytes, bundle);
    }).bundle;
  }
}

/**
 * [PackageBundleProvider] that reads from [WorkerPackageBundleCache] using
 * the request specific [inputs].
 */
class WorkerPackageBundleProvider implements PackageBundleProvider {
  final WorkerPackageBundleCache cache;
  final Map<String, WorkerInput> inputs;

  WorkerPackageBundleProvider(this.cache, this.inputs);

  @override
  PackageBundle get(String path) {
    return cache.get(inputs, path);
  }
}
