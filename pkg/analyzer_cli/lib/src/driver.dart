// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:isolate';

import 'package:analyzer/dart/analysis/context_locator.dart' as api;
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    as api;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/interner.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/manifest/manifest_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/source/path_filter.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer_cli/src/analyzer_impl.dart';
import 'package:analyzer_cli/src/batch_mode.dart';
import 'package:analyzer_cli/src/build_mode.dart';
import 'package:analyzer_cli/src/context_cache.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/error_severity.dart';
import 'package:analyzer_cli/src/has_context_mixin.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:analyzer_cli/src/perf_report.dart';
import 'package:analyzer_cli/starter.dart' show CommandLineStarter;
import 'package:linter/src/rules.dart' as linter;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Shared IO sink for standard error reporting.
StringSink errorSink = io.stderr;

/// Shared IO sink for standard out reporting.
StringSink outSink = io.stdout;

/// Test this option map to see if it specifies lint rules.
bool containsLintRuleEntry(YamlMap options) {
  var linterNode = getValue(options, 'linter');
  return linterNode is YamlMap && getValue(linterNode, 'rules') != null;
}

class Driver with HasContextMixin implements CommandLineStarter {
  static final ByteStore analysisDriverMemoryByteStore = MemoryByteStore();

  @override
  ContextCache contextCache;

  /// The driver that was most recently created by a call to [_analyzeAll], or
  /// `null` if [_analyzeAll] hasn't been called yet.
  @visibleForTesting
  AnalysisDriver analysisDriver;

  /// The total number of source files loaded by an AnalysisContext.
  int _analyzedFileCount = 0;

  /// If [analysisDriver] is not `null`, the [CommandLineOptions] that guided
  /// its creation.
  CommandLineOptions _previousOptions;

  /// SDK instance.
  DartSdk sdk;

  /// The resource provider used to access the file system.
  @override
  final ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  /// Collected analysis statistics.
  final AnalysisStats stats = AnalysisStats();

  /// The [PathFilter] for excluded files with wildcards, etc.
  PathFilter pathFilter;

  /// Create a new Driver instance.
  Driver({@Deprecated('This parameter has no effect') bool isTesting = false});

  /// Converts the given [filePath] into absolute and normalized.
  String normalizePath(String filePath) {
    filePath = filePath.trim();
    filePath = resourceProvider.pathContext.absolute(filePath);
    filePath = resourceProvider.pathContext.normalize(filePath);
    return filePath;
  }

  @override
  Future<void> start(List<String> args, {SendPort sendPort}) async {
    if (analysisDriver != null) {
      throw StateError('start() can only be called once');
    }
    var startTime = DateTime.now().millisecondsSinceEpoch;

    StringUtilities.INTERNER = MappedInterner();

    linter.registerLintRules();

    // Parse commandline options.
    var options = CommandLineOptions.parse(resourceProvider, args);

    // Do analysis.
    if (options.buildMode) {
      var severity = await _buildModeAnalyze(options, sendPort);
      // Propagate issues to the exit code.
      if (_shouldBeFatal(severity, options)) {
        io.exitCode = severity.ordinal;
      }
    } else if (options.batchMode) {
      var batchRunner = BatchRunner(outSink, errorSink);
      batchRunner.runAsBatch(args, (List<String> args) async {
        // TODO(brianwilkerson) Determine whether this await is necessary.
        await null;
        var options = CommandLineOptions.parse(resourceProvider, args);
        return await _analyzeAll(options);
      });
    } else {
      var severity = await _analyzeAll(options);
      // Propagate issues to the exit code.
      if (_shouldBeFatal(severity, options)) {
        io.exitCode = severity.ordinal;
      }
    }

    // When training a snapshot, in addition to training regular analysis
    // (above), we train build mode as well.
    if (options.trainSnapshot) {
      // TODO(devoncarew): Iterate on this training to make it more
      // representative of what we see internally; call into _buildModeAnalyze()
      // with some appropriate options.
      print('\nGenerating strong mode summary...');
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 3; i++) {
        buildSdkSummary(
          resourceProvider: PhysicalResourceProvider.INSTANCE,
          sdkPath: options.dartSdkPath,
        );
      }

      print('Done in ${stopwatch.elapsedMilliseconds} ms.');
    }

    if (analysisDriver != null) {
      _analyzedFileCount += analysisDriver.knownFiles.length;
    }

    if (options.perfReport != null) {
      var json = makePerfReport(
          startTime, currentTimeMillis, options, _analyzedFileCount, stats);
      io.File(options.perfReport).writeAsStringSync(json);
    }
  }

  Future<ErrorSeverity> _analyzeAll(CommandLineOptions options) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;

    return await _analyzeAllImpl(options);
  }

  /// Perform analysis according to the given [options].
  Future<ErrorSeverity> _analyzeAllImpl(CommandLineOptions options) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (!options.machineFormat) {
      var fileNames = options.sourceFiles.map((String file) {
        file = path.normalize(file);
        if (file == '.') {
          file = path.basename(path.current);
        } else if (file == '..') {
          file = path.basename(path.normalize(path.absolute(file)));
        }
        return file;
      }).toList();

      outSink.writeln("Analyzing ${fileNames.join(', ')}...");
    }

    // These are used to do part file analysis across sources.
    var dartFiles = <String>{};
    var libraryFiles = <FileState>{};
    var danglingParts = <FileState>{};

    // Note: This references analysisDriver via closure, so it will change over
    // time during the following analysis.
    var defaultSeverityProcessor = (AnalysisError error) {
      return determineProcessedSeverity(
          error, options, analysisDriver.analysisOptions);
    };

    // We currently print out to stderr to ensure that when in batch mode we
    // print to stderr, this is because the prints from batch are made to
    // stderr. The reason that options.shouldBatch isn't used is because when
    // the argument flags are constructed in BatchRunner and passed in from
    // batch mode which removes the batch flag to prevent the "cannot have the
    // batch flag and source file" error message.
    ErrorFormatter formatter;
    if (options.machineFormat) {
      formatter = MachineErrorFormatter(errorSink, options, stats,
          severityProcessor: defaultSeverityProcessor);
    } else {
      formatter = HumanErrorFormatter(outSink, options, stats,
          severityProcessor: defaultSeverityProcessor);
    }

    var allResult = ErrorSeverity.NONE;

    void reportPartError(String partPath) {
      errorSink.writeln('$partPath is a part and cannot be analyzed.');
      errorSink.writeln('Please pass in a library that contains this part.');
      io.exitCode = ErrorSeverity.ERROR.ordinal;
      allResult = allResult.max(ErrorSeverity.ERROR);
    }

    for (var sourcePath in options.sourceFiles) {
      sourcePath = normalizePath(sourcePath);

      // Create a context, or re-use the previous one.
      try {
        _createContextAndAnalyze(options, sourcePath);
      } on _DriverError catch (error) {
        outSink.writeln(error.msg);
        return ErrorSeverity.ERROR;
      }

      // Add all the files to be analyzed en masse to the context. Skip any
      // files that were added earlier (whether explicitly or implicitly) to
      // avoid causing those files to be unnecessarily re-read.
      var filesToAnalyze = <String>{};

      // Collect files for analysis.
      // Note that these files will all be analyzed in the same context.
      // This should be updated when the ContextManager re-work is complete
      // (See: https://github.com/dart-lang/sdk/issues/24133)
      var files = _collectFiles(sourcePath, analysisDriver.analysisOptions);
      if (files.isEmpty) {
        errorSink.writeln('No dart files found at: $sourcePath');
        io.exitCode = ErrorSeverity.ERROR.ordinal;
        return ErrorSeverity.ERROR;
      }

      for (var file in files) {
        filesToAnalyze.add(file.absolute.path);
      }

      // Analyze the libraries.
      for (var path in filesToAnalyze) {
        var shortName = resourceProvider.pathContext.basename(path);
        if (shortName == AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE) {
          var file = resourceProvider.getFile(path);
          var content = file.readAsStringSync();
          var lineInfo = LineInfo.fromContent(content);
          var errors = analyzeAnalysisOptions(
              file.createSource(), content, analysisDriver.sourceFactory);
          formatter.formatErrors([
            ErrorsResultImpl(analysisDriver.currentSession, path, null,
                lineInfo, false, errors)
          ]);
          for (var error in errors) {
            var severity = determineProcessedSeverity(
                error, options, analysisDriver.analysisOptions);
            if (severity != null) {
              allResult = allResult.max(severity);
            }
          }
        } else if (shortName == AnalysisEngine.PUBSPEC_YAML_FILE) {
          var errors = <AnalysisError>[];
          try {
            var file = resourceProvider.getFile(path);
            var content = file.readAsStringSync();
            var node = loadYamlNode(content);
            if (node is YamlMap) {
              var validator =
                  PubspecValidator(resourceProvider, file.createSource());
              errors.addAll(validator.validate(node.nodes));
            }

            if (analysisDriver != null && analysisDriver.analysisOptions.lint) {
              var visitors = <LintRule, PubspecVisitor>{};
              for (var linter in analysisDriver.analysisOptions.lintRules) {
                if (linter is LintRule) {
                  var visitor = linter.getPubspecVisitor();
                  if (visitor != null) {
                    visitors[linter] = visitor;
                  }
                }
              }
              if (visitors.isNotEmpty) {
                var sourceUri = resourceProvider.pathContext.toUri(path);
                var pubspecAst = Pubspec.parse(content,
                    sourceUrl: sourceUri, resourceProvider: resourceProvider);
                var listener = RecordingErrorListener();
                var reporter = ErrorReporter(listener,
                    resourceProvider.getFile(path).createSource(sourceUri),
                    isNonNullableByDefault: false);
                for (var entry in visitors.entries) {
                  entry.key.reporter = reporter;
                  pubspecAst.accept(entry.value);
                }
                errors.addAll(listener.errors);
              }
            }

            if (errors.isNotEmpty) {
              for (var error in errors) {
                var severity = determineProcessedSeverity(
                    error, options, analysisDriver.analysisOptions);
                allResult = allResult.max(severity);
              }
              var lineInfo = LineInfo.fromContent(content);
              formatter.formatErrors([
                ErrorsResultImpl(analysisDriver.currentSession, path, null,
                    lineInfo, false, errors)
              ]);
            }
          } catch (exception) {
            // If the file cannot be analyzed, ignore it.
          }
        } else if (shortName == AnalysisEngine.ANDROID_MANIFEST_FILE) {
          try {
            var file = resourceProvider.getFile(path);
            var content = file.readAsStringSync();
            var validator = ManifestValidator(file.createSource());
            var lineInfo = LineInfo.fromContent(content);
            var errors = validator.validate(
                content, analysisDriver.analysisOptions.chromeOsManifestChecks);
            formatter.formatErrors([
              ErrorsResultImpl(analysisDriver.currentSession, path, null,
                  lineInfo, false, errors)
            ]);
            for (var error in errors) {
              var severity = determineProcessedSeverity(
                  error, options, analysisDriver.analysisOptions);
              allResult = allResult.max(severity);
            }
          } catch (exception) {
            // If the file cannot be analyzed, ignore it.
          }
        } else {
          dartFiles.add(path);
          var file = analysisDriver.fsState.getFileForPath(path);

          if (file.isPart) {
            if (!libraryFiles.contains(file.library)) {
              danglingParts.add(file);
            }
            continue;
          }
          libraryFiles.add(file);

          var status = await _runAnalyzer(file, options, formatter);
          allResult = allResult.max(status);

          // Mark previously dangling parts as no longer dangling.
          for (var part in file.partedFiles) {
            danglingParts.remove(part);
          }
        }
      }
    }

    // We are done analyzing this batch of files.
    // The next batch should not be affected by a previous batch.
    // E.g. the same parts in both batches, but with different libraries.
    for (var path in dartFiles) {
      analysisDriver.removeFile(path);
    }

    // Any dangling parts still in this list were definitely dangling.
    for (var partFile in danglingParts) {
      reportPartError(partFile.path);
    }

    formatter.flush();

    if (!options.machineFormat) {
      stats.print(outSink);
    }

    return allResult;
  }

  /// Perform analysis in build mode according to the given [options].
  ///
  /// If [sendPort] is provided it is used for bazel worker communication
  /// instead of stdin/stdout.
  Future<ErrorSeverity> _buildModeAnalyze(
      CommandLineOptions options, SendPort sendPort) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;

    if (options.buildModePersistentWorker) {
      var workerLoop = sendPort == null
          ? AnalyzerWorkerLoop.std(resourceProvider,
              dartSdkPath: options.dartSdkPath)
          : AnalyzerWorkerLoop.sendPort(resourceProvider, sendPort,
              dartSdkPath: options.dartSdkPath);
      await workerLoop.run();
      return ErrorSeverity.NONE;
    } else {
      return await BuildMode(resourceProvider, options, stats,
              ContextCache(resourceProvider, options, verbosePrint))
          .analyze();
    }
  }

  /// Decide on the appropriate method for resolving URIs based on the given
  /// [options] and [customUrlMappings] settings, and return a
  /// [SourceFactory] that has been configured accordingly.
  /// When [includeSdkResolver] is `false`, return a temporary [SourceFactory]
  /// for the purpose of resolved analysis options file `include:` directives.
  /// In this situation, [analysisOptions] is ignored and can be `null`.
  SourceFactory _chooseUriResolutionPolicy(
      CommandLineOptions options,
      Map<Folder, YamlMap> embedderMap,
      _PackageInfo packageInfo,
      SummaryDataStore summaryDataStore,
      bool includeSdkResolver,
      AnalysisOptions analysisOptions) {
    UriResolver packageUriResolver;

    if (packageInfo.packageMap != null) {
      packageUriResolver = PackageMapUriResolver(
        resourceProvider,
        packageInfo.packageMap,
      );
    }

    // Now, build our resolver list.
    var resolvers = <UriResolver>[];

    // 'dart:' URIs come first.

    // Setup embedding.
    if (includeSdkResolver) {
      var embedderSdk = EmbedderSdk(
        resourceProvider,
        embedderMap,
        languageVersion: sdk.languageVersion,
      );
      if (embedderSdk.libraryMap.size() == 0) {
        // The embedder uri resolver has no mappings. Use the default Dart SDK
        // uri resolver.
        resolvers.add(DartUriResolver(sdk));
      } else {
        // The embedder uri resolver has mappings, use it instead of the default
        // Dart SDK uri resolver.
        resolvers.add(DartUriResolver(embedderSdk));
      }
    }

    // Then package URIs from summaries.
    resolvers.add(InSummaryUriResolver(resourceProvider, summaryDataStore));

    // Then package URIs.
    if (packageUriResolver != null) {
      resolvers.add(packageUriResolver);
    }

    // Finally files.
    resolvers.add(ResourceUriResolver(resourceProvider));

    return SourceFactory(resolvers);
  }

  /// Collect all analyzable files at [filePath], recursively if it's a
  /// directory, ignoring links.
  Iterable<io.File> _collectFiles(String filePath, AnalysisOptions options) {
    var files = <io.File>[];
    var file = io.File(filePath);
    if (file.existsSync() && !pathFilter.ignored(filePath)) {
      files.add(file);
    } else {
      var directory = io.Directory(filePath);
      if (directory.existsSync()) {
        for (var entry
            in directory.listSync(recursive: true, followLinks: false)) {
          var relative = path.relative(entry.path, from: directory.path);
          if ((AnalysisEngine.isDartFileName(entry.path) ||
                  AnalysisEngine.isManifestFileName(entry.path)) &&
              entry is io.File &&
              !pathFilter.ignored(entry.path) &&
              !_isInHiddenDir(relative)) {
            files.add(entry);
          }
        }
      }
    }
    return files;
  }

  /// Create an analysis driver that is prepared to analyze sources according
  /// to the given [options], and store it in [analysisDriver].
  void _createContextAndAnalyze(CommandLineOptions options, String source) {
    // If not the same command-line options, clear cached information.
    if (!_equalCommandLineOptions(_previousOptions, options)) {
      _previousOptions = options;
      contextCache = ContextCache(resourceProvider, options, verbosePrint);
      analysisDriver = null;
    }

    var analysisOptions =
        createAnalysisOptionsForCommandLineOptions(options, source);

    // Store the [PathFilter] for this context to properly exclude files
    pathFilter = PathFilter(getContextInfo(options, source).analysisRoot,
        analysisOptions.excludePatterns);

    // If we have the analysis driver, and the new analysis options are the
    // same, we can reuse this analysis driver.
    if (analysisDriver != null &&
        AnalysisOptions.signaturesEqual(
            analysisDriver.analysisOptions.signature,
            analysisOptions.signature)) {
      return;
    }

    // Set up logging.
    if (options.log) {
      AnalysisEngine.instance.instrumentationService = StdInstrumentation();
    }

    // Save stats from previous context before clobbering it.
    if (analysisDriver != null) {
      _analyzedFileCount += analysisDriver.knownFiles.length;
    }

    // Find package info.
    var packageInfo = _findPackages(options);

    // Process embedders.
    var embedderMap = <Folder, YamlMap>{};
    if (packageInfo.packageMap != null) {
      var libFolder = packageInfo.packageMap['sky_engine']?.first;
      if (libFolder != null) {
        var locator = EmbedderYamlLocator.forLibFolder(libFolder);
        embedderMap = locator.embedderYamls;
      }
    }

    // No summaries in the presence of embedders.
    var useSummaries = embedderMap.isEmpty;

    if (!useSummaries && options.buildSummaryInputs.isNotEmpty) {
      throw _DriverError('Summaries are not yet supported when using Flutter.');
    }

    // Read any input summaries.
    var summaryDataStore = SummaryDataStore(
        useSummaries ? options.buildSummaryInputs : <String>[]);

    // Once options and embedders are processed, setup the SDK.
    _setupSdk(options, analysisOptions);

    // Choose a package resolution policy and a diet parsing policy based on
    // the command-line options.
    var sourceFactory = _chooseUriResolutionPolicy(options, embedderMap,
        packageInfo, summaryDataStore, true, analysisOptions);

    var log = PerformanceLog(null);
    var scheduler = AnalysisDriverScheduler(log);

    analysisDriver = AnalysisDriver(
        scheduler,
        log,
        resourceProvider,
        analysisDriverMemoryByteStore,
        FileContentOverlay(),
        ContextRoot(source, [], pathContext: resourceProvider.pathContext),
        sourceFactory,
        analysisOptions,
        packages: packageInfo.packages);
    analysisDriver.results.listen((_) {});
    analysisDriver.exceptions.listen((_) {});
    _setAnalysisDriverAnalysisContext(source);
    scheduler.start();
  }

  _PackageInfo _findPackages(CommandLineOptions options) {
    Packages packages;
    Map<String, List<Folder>> packageMap;

    if (options.packageConfigPath != null) {
      var path = normalizePath(options.packageConfigPath);
      try {
        packages = parsePackagesFile(
          resourceProvider,
          resourceProvider.getFile(path),
        );
        packageMap = _getPackageMap(packages);
      } catch (e) {
        printAndFail('Unable to read package config data from $path: $e');
      }
    } else {
      var cwd = resourceProvider.getResource(path.current);
      // Look for .packages.
      packages = findPackagesFrom(resourceProvider, cwd);
      packageMap = _getPackageMap(packages);
    }

    return _PackageInfo(packages, packageMap);
  }

  Map<String, List<Folder>> _getPackageMap(Packages packages) {
    if (packages == null) {
      return null;
    }

    var packageMap = <String, List<Folder>>{};
    for (var package in packages.packages) {
      packageMap[package.name] = [package.libFolder];
    }
    return packageMap;
  }

  /// Returns `true` if this relative path is a hidden directory.
  bool _isInHiddenDir(String relative) =>
      path.split(relative).any((part) => part.startsWith('.'));

  /// Analyze a single source.
  Future<ErrorSeverity> _runAnalyzer(
      FileState file, CommandLineOptions options, ErrorFormatter formatter) {
    var startTime = currentTimeMillis;
    var analyzer = AnalyzerImpl(analysisDriver.analysisOptions, analysisDriver,
        file, options, stats, startTime);
    return analyzer.analyze(formatter);
  }

  void _setAnalysisDriverAnalysisContext(String rootPath) {
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

  void _setupSdk(CommandLineOptions options, AnalysisOptions analysisOptions) {
    if (sdk == null) {
      if (options.dartSdkSummaryPath != null) {
        sdk = SummaryBasedDartSdk(options.dartSdkSummaryPath, true);
      } else {
        var dartSdkPath = options.dartSdkPath;
        sdk = FolderBasedDartSdk(
          resourceProvider,
          resourceProvider.getFolder(dartSdkPath),
        );
      }
    }
  }

  bool _shouldBeFatal(ErrorSeverity severity, CommandLineOptions options) {
    if (severity == ErrorSeverity.ERROR) {
      return true;
    } else if (severity == ErrorSeverity.WARNING &&
        (options.warningsAreFatal || options.infosAreFatal)) {
      return true;
    } else if (severity == ErrorSeverity.INFO && options.infosAreFatal) {
      return true;
    } else {
      return false;
    }
  }

  static void verbosePrint(String text) {
    outSink.writeln(text);
  }

  /// Return whether the [newOptions] are equal to the [previous].
  static bool _equalCommandLineOptions(
      CommandLineOptions previous, CommandLineOptions newOptions) {
    return previous != null &&
        newOptions != null &&
        newOptions.packageConfigPath == previous.packageConfigPath &&
        _equalMaps(newOptions.definedVariables, previous.definedVariables) &&
        newOptions.log == previous.log &&
        newOptions.disableHints == previous.disableHints &&
        newOptions.showPackageWarnings == previous.showPackageWarnings &&
        newOptions.showPackageWarningsPrefix ==
            previous.showPackageWarningsPrefix &&
        newOptions.showSdkWarnings == previous.showSdkWarnings &&
        newOptions.lints == previous.lints &&
        _equalLists(
            newOptions.buildSummaryInputs, previous.buildSummaryInputs) &&
        newOptions.disableCacheFlushing == previous.disableCacheFlushing &&
        _equalLists(newOptions.enabledExperiments, previous.enabledExperiments);
  }

  /// Perform a deep comparison of two string lists.
  static bool _equalLists(List<String> l1, List<String> l2) {
    if (l1.length != l2.length) {
      return false;
    }
    for (var i = 0; i < l1.length; i++) {
      if (l1[i] != l2[i]) {
        return false;
      }
    }
    return true;
  }

  /// Perform a deep comparison of two string maps.
  static bool _equalMaps(Map<String, String> m1, Map<String, String> m2) {
    if (m1.length != m2.length) {
      return false;
    }
    for (var key in m1.keys) {
      if (!m2.containsKey(key) || m1[key] != m2[key]) {
        return false;
      }
    }
    return true;
  }
}

class _DriverError implements Exception {
  final String msg;

  _DriverError(this.msg);
}

class _PackageInfo {
  final Packages packages;
  final Map<String, List<Folder>> packageMap;

  _PackageInfo(this.packages, this.packageMap);
}
