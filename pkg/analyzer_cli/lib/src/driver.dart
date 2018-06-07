// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/interner.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart'
    show PerformanceTag;
import 'package:analyzer/src/plugin/resolver_provider.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/source/package_map_provider.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/source/path_filter.dart';
import 'package:analyzer/src/source/pub_package_map_provider.dart';
import 'package:analyzer/src/source/sdk_ext.dart';
import 'package:analyzer/src/summary/idl.dart';
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
import 'package:front_end/src/api_prototype/byte_store.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:linter/src/rules.dart' as linter;
import 'package:meta/meta.dart';
import 'package:package_config/discovery.dart' as pkg_discovery;
import 'package:package_config/packages.dart' show Packages;
import 'package:package_config/packages_file.dart' as pkgfile show parse;
import 'package:package_config/src/packages_impl.dart' show MapPackages;
import 'package:path/path.dart' as path;
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:telemetry/crash_reporting.dart';
import 'package:telemetry/telemetry.dart' as telemetry;
import 'package:yaml/yaml.dart';

const _analyticsID = 'UA-26406144-28';

/// Shared IO sink for standard error reporting.
@visibleForTesting
StringSink errorSink = io.stderr;

/// Shared IO sink for standard out reporting.
@visibleForTesting
StringSink outSink = io.stdout;

telemetry.Analytics _analytics;

/// The analytics instance for analyzer-cli.
telemetry.Analytics get analytics => (_analytics ??=
    telemetry.createAnalyticsInstance(_analyticsID, 'analyzer-cli'));

/// Test this option map to see if it specifies lint rules.
bool containsLintRuleEntry(YamlMap options) {
  YamlNode linterNode = getValue(options, 'linter');
  return linterNode is YamlMap && getValue(linterNode, 'rules') != null;
}

/// Make sure that we create an analytics instance that doesn't send for this
/// session.
void disableAnalyticsForSession() {
  _analytics = telemetry.createAnalyticsInstance(_analyticsID, 'analyzer-cli',
      disableForSession: true);
}

@visibleForTesting
void setAnalytics(telemetry.Analytics replacementAnalytics) {
  _analytics = replacementAnalytics;
}

class Driver extends Object with HasContextMixin implements CommandLineStarter {
  static final PerformanceTag _analyzeAllTag =
      new PerformanceTag("Driver._analyzeAll");

  static ByteStore analysisDriverMemoryByteStore = new MemoryByteStore();

  ContextCache contextCache;

  /// The plugins that are defined outside the `analyzer_cli` package.
  List<Plugin> _userDefinedPlugins = <Plugin>[];

  /// The driver that was most recently created by a call to [_analyzeAll], or
  /// `null` if [_analyzeAll] hasn't been called yet.
  @visibleForTesting
  AnalysisDriver analysisDriver;

  /// The total number of source files loaded by an AnalysisContext.
  int _analyzedFileCount = 0;

  /// If [analysisDriver] is not `null`, the [CommandLineOptions] that guided
  /// its creation.
  CommandLineOptions _previousOptions;

  @override
  ResolverProvider packageResolverProvider;

  /// SDK instance.
  DartSdk sdk;

  /**
   * The resource provider used to access the file system.
   */
  file_system.ResourceProvider resourceProvider =
      PhysicalResourceProvider.INSTANCE;

  /// Collected analysis statistics.
  final AnalysisStats stats = new AnalysisStats();

  CrashReportSender _crashReportSender;

  /// The [PathFilter] for excluded files with wildcards, etc.
  PathFilter pathFilter;

  /// Create a new Driver instance.
  ///
  /// [isTesting] is true if we're running in a test environment.
  Driver({bool isTesting: false}) {
    if (isTesting) {
      disableAnalyticsForSession();
    }
  }

  /// The crash reporting instance for analyzer-cli.
  /// TODO(devoncarew): Replace with the real crash product ID.
  CrashReportSender get crashReportSender => (_crashReportSender ??=
      new CrashReportSender('Dart_analyzer_cli', analytics));

  @override
  void set userDefinedPlugins(List<Plugin> plugins) {
    _userDefinedPlugins = plugins ?? <Plugin>[];
  }

  /**
   * Converts the given [filePath] into absolute and normalized.
   */
  String normalizePath(String filePath) {
    filePath = filePath.trim();
    filePath = resourceProvider.pathContext.absolute(filePath);
    filePath = resourceProvider.pathContext.normalize(filePath);
    return filePath;
  }

  @override
  Future<Null> start(List<String> args) async {
    if (analysisDriver != null) {
      throw new StateError("start() can only be called once");
    }
    int startTime = new DateTime.now().millisecondsSinceEpoch;

    StringUtilities.INTERNER = new MappedInterner();

    _processPlugins();

    // Parse commandline options.
    CommandLineOptions options = CommandLineOptions.parse(args);

    if (options.batchMode || options.buildMode) {
      disableAnalyticsForSession();
    }

    // Ping analytics with our initial call.
    analytics.sendScreenView('home');

    var timer = analytics.startTimer('analyze');

    // Do analysis.
    if (options.buildMode) {
      ErrorSeverity severity = await _buildModeAnalyze(options);
      // Propagate issues to the exit code.
      if (_shouldBeFatal(severity, options)) {
        io.exitCode = severity.ordinal;
      }
    } else if (options.batchMode) {
      BatchRunner batchRunner = new BatchRunner(outSink, errorSink);
      batchRunner.runAsBatch(args, (List<String> args) async {
        CommandLineOptions options = CommandLineOptions.parse(args);
        return await _analyzeAll(options);
      });
    } else {
      ErrorSeverity severity = await _analyzeAll(options);
      // Propagate issues to the exit code.
      if (_shouldBeFatal(severity, options)) {
        io.exitCode = severity.ordinal;
      }
    }

    if (analysisDriver != null) {
      _analyzedFileCount += analysisDriver.knownFiles.length;
    }

    // Send how long analysis took.
    timer.finish();

    // Send how many files were analyzed.
    analytics.sendEvent('analyze', 'fileCount', value: _analyzedFileCount);

    if (options.perfReport != null) {
      String json = makePerfReport(
          startTime, currentTimeMillis, options, _analyzedFileCount, stats);
      new io.File(options.perfReport).writeAsStringSync(json);
    }

    // Wait a brief time for any analytics calls to finish.
    await analytics.waitForLastPing(timeout: new Duration(milliseconds: 200));
    analytics.close();
  }

  Future<ErrorSeverity> _analyzeAll(CommandLineOptions options) async {
    PerformanceTag previous = _analyzeAllTag.makeCurrent();
    try {
      return await _analyzeAllImpl(options);
    } catch (e, st) {
      // Catch and ignore any exceptions when reporting exceptions (network
      // errors or other).
      crashReportSender.sendReport(e, stackTrace: st).catchError((_) {});
      rethrow;
    } finally {
      previous.makeCurrent();
    }
  }

  /// Perform analysis according to the given [options].
  Future<ErrorSeverity> _analyzeAllImpl(CommandLineOptions options) async {
    if (!options.machineFormat) {
      List<String> fileNames = options.sourceFiles.map((String file) {
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
    Set<FileState> libraryFiles = new Set<FileState>();
    Set<FileState> danglingParts = new Set<FileState>();

    // Note: This references analysisDriver via closure, so it will change over
    // time during the following analysis.
    SeverityProcessor defaultSeverityProcessor = (AnalysisError error) {
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
      formatter = new MachineErrorFormatter(errorSink, options, stats,
          severityProcessor: defaultSeverityProcessor);
    } else {
      formatter = new HumanErrorFormatter(outSink, options, stats,
          severityProcessor: defaultSeverityProcessor);
    }

    ErrorSeverity allResult = ErrorSeverity.NONE;

    void reportPartError(String partPath) {
      errorSink.writeln("$partPath is a part and cannot be analyzed.");
      errorSink.writeln("Please pass in a library that contains this part.");
      io.exitCode = ErrorSeverity.ERROR.ordinal;
      allResult = allResult.max(ErrorSeverity.ERROR);
    }

    for (String sourcePath in options.sourceFiles) {
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
      Set<String> filesToAnalyze = new Set<String>();

      // Collect files for analysis.
      // Note that these files will all be analyzed in the same context.
      // This should be updated when the ContextManager re-work is complete
      // (See: https://github.com/dart-lang/sdk/issues/24133)
      Iterable<io.File> files =
          _collectFiles(sourcePath, analysisDriver.analysisOptions);
      if (files.isEmpty) {
        errorSink.writeln('No dart files found at: $sourcePath');
        io.exitCode = ErrorSeverity.ERROR.ordinal;
        return ErrorSeverity.ERROR;
      }

      for (io.File file in files) {
        filesToAnalyze.add(file.absolute.path);
      }

      // Analyze the libraries.
      for (String path in filesToAnalyze) {
        var shortName = resourceProvider.pathContext.basename(path);
        if (shortName == AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE ||
            shortName == AnalysisEngine.ANALYSIS_OPTIONS_FILE) {
          file_system.File file = resourceProvider.getFile(path);
          String content = file.readAsStringSync();
          LineInfo lineInfo = new LineInfo.fromContent(content);
          List<AnalysisError> errors =
              GenerateOptionsErrorsTask.analyzeAnalysisOptions(
                  file.createSource(), content, analysisDriver.sourceFactory);
          formatter.formatErrors([new AnalysisErrorInfoImpl(errors, lineInfo)]);
          for (AnalysisError error in errors) {
            allResult = allResult.max(determineProcessedSeverity(
                error, options, analysisDriver.analysisOptions));
          }
        } else if (shortName == AnalysisEngine.PUBSPEC_YAML_FILE) {
          try {
            file_system.File file = resourceProvider.getFile(path);
            String content = file.readAsStringSync();
            YamlNode node = loadYamlNode(content);
            if (node is YamlMap) {
              PubspecValidator validator =
                  new PubspecValidator(resourceProvider, file.createSource());
              LineInfo lineInfo = new LineInfo.fromContent(content);
              List<AnalysisError> errors = validator.validate(node.nodes);
              formatter
                  .formatErrors([new AnalysisErrorInfoImpl(errors, lineInfo)]);
              for (AnalysisError error in errors) {
                allResult = allResult.max(determineProcessedSeverity(
                    error, options, analysisDriver.analysisOptions));
              }
            }
          } catch (exception) {
            // If the file cannot be analyzed, ignore it.
          }
        } else {
          var file = analysisDriver.fsState.getFileForPath(path);

          if (file.isPart) {
            if (!libraryFiles.contains(file.library)) {
              danglingParts.add(file);
            }
            continue;
          }
          libraryFiles.add(file);

          ErrorSeverity status = await _runAnalyzer(file, options, formatter);
          allResult = allResult.max(status);

          // Mark previously dangling parts as no longer dangling.
          for (FileState part in file.partedFiles) {
            danglingParts.remove(part);
          }
        }
      }
    }

    // Any dangling parts still in this list were definitely dangling.
    for (FileState partFile in danglingParts) {
      reportPartError(partFile.path);
    }

    formatter.flush();

    if (!options.machineFormat) {
      stats.print(outSink);
    }

    return allResult;
  }

  /// Perform analysis in build mode according to the given [options].
  Future<ErrorSeverity> _buildModeAnalyze(CommandLineOptions options) async {
    PerformanceTag previous = _analyzeAllTag.makeCurrent();
    try {
      if (options.buildModePersistentWorker) {
        await new AnalyzerWorkerLoop.std(resourceProvider,
                dartSdkPath: options.dartSdkPath)
            .run();
        return ErrorSeverity.NONE;
      } else {
        return await new BuildMode(resourceProvider, options, stats,
                new ContextCache(resourceProvider, options, verbosePrint))
            .analyze();
      }
    } finally {
      previous.makeCurrent();
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
      Map<file_system.Folder, YamlMap> embedderMap,
      _PackageInfo packageInfo,
      SummaryDataStore summaryDataStore,
      bool includeSdkResolver,
      AnalysisOptions analysisOptions) {
    // Create a custom package resolver if one has been specified.
    if (packageResolverProvider != null) {
      file_system.Folder folder = resourceProvider.getResource('.');
      UriResolver resolver = packageResolverProvider(folder);
      if (resolver != null) {
        // TODO(brianwilkerson) This doesn't handle sdk extensions.
        List<UriResolver> resolvers = <UriResolver>[];
        if (includeSdkResolver) {
          resolvers.add(new DartUriResolver(sdk));
        }
        resolvers
            .add(new InSummaryUriResolver(resourceProvider, summaryDataStore));
        resolvers.add(resolver);
        resolvers.add(new ResourceUriResolver(resourceProvider));
        return new SourceFactory(resolvers);
      }
    }

    UriResolver packageUriResolver;

    if (options.packageRootPath != null) {
      ContextBuilderOptions builderOptions = new ContextBuilderOptions();
      builderOptions.defaultPackagesDirectoryPath = options.packageRootPath;
      ContextBuilder builder = new ContextBuilder(resourceProvider, null, null,
          options: builderOptions);
      packageUriResolver = new PackageMapUriResolver(resourceProvider,
          builder.convertPackagesToMap(builder.createPackageMap('')));
    } else if (options.packageConfigPath == null) {
      // TODO(pq): remove?
      if (packageInfo.packageMap == null) {
        // Fall back to pub list-package-dirs.
        PubPackageMapProvider pubPackageMapProvider =
            new PubPackageMapProvider(resourceProvider, sdk);
        file_system.Resource cwd = resourceProvider.getResource('.');
        PackageMapInfo packageMapInfo =
            pubPackageMapProvider.computePackageMap(cwd);
        Map<String, List<file_system.Folder>> packageMap =
            packageMapInfo.packageMap;

        // Only create a packageUriResolver if pub list-package-dirs succeeded.
        // If it failed, that's not a problem; it simply means we have no way
        // to resolve packages.
        if (packageMapInfo.packageMap != null) {
          packageUriResolver =
              new PackageMapUriResolver(resourceProvider, packageMap);
        }
      }
    }

    // Now, build our resolver list.
    List<UriResolver> resolvers = [];

    // 'dart:' URIs come first.

    // Setup embedding.
    if (includeSdkResolver) {
      EmbedderSdk embedderSdk = new EmbedderSdk(resourceProvider, embedderMap);
      if (embedderSdk.libraryMap.size() == 0) {
        // The embedder uri resolver has no mappings. Use the default Dart SDK
        // uri resolver.
        resolvers.add(new DartUriResolver(sdk));
      } else {
        // The embedder uri resolver has mappings, use it instead of the default
        // Dart SDK uri resolver.
        embedderSdk.analysisOptions = analysisOptions;
        resolvers.add(new DartUriResolver(embedderSdk));
      }
    }

    // Next SdkExts.
    if (packageInfo.packageMap != null) {
      resolvers.add(new SdkExtUriResolver(packageInfo.packageMap));
    }

    // Then package URIs from summaries.
    resolvers.add(new InSummaryUriResolver(resourceProvider, summaryDataStore));

    // Then package URIs.
    if (packageUriResolver != null) {
      resolvers.add(packageUriResolver);
    }

    // Finally files.
    resolvers.add(new ResourceUriResolver(resourceProvider));

    return new SourceFactory(resolvers, packageInfo.packages);
  }

  /// Collect all analyzable files at [filePath], recursively if it's a
  /// directory, ignoring links.
  Iterable<io.File> _collectFiles(String filePath, AnalysisOptions options) {
    List<io.File> files = <io.File>[];
    io.File file = new io.File(filePath);
    if (file.existsSync() && !pathFilter.ignored(filePath)) {
      files.add(file);
    } else {
      io.Directory directory = new io.Directory(filePath);
      if (directory.existsSync()) {
        for (io.FileSystemEntity entry
            in directory.listSync(recursive: true, followLinks: false)) {
          String relative = path.relative(entry.path, from: directory.path);
          if (AnalysisEngine.isDartFileName(entry.path) &&
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
      contextCache = new ContextCache(resourceProvider, options, verbosePrint);
      analysisDriver = null;
    }

    AnalysisOptionsImpl analysisOptions =
        createAnalysisOptionsForCommandLineOptions(options, source);

    // Store the [PathFilter] for this context to properly exclude files
    pathFilter = new PathFilter(getContextInfo(options, source).analysisRoot,
        analysisOptions.excludePatterns);

    // If we have the analysis driver, and the new analysis options are the
    // same, we can reuse this analysis driver.
    if (analysisDriver != null &&
        _equalAnalysisOptions(
            analysisDriver.analysisOptions, analysisOptions)) {
      return;
    }

    // Set up logging.
    if (options.log) {
      AnalysisEngine.instance.logger = new StdLogger();
    }

    // Save stats from previous context before clobbering it.
    if (analysisDriver != null) {
      _analyzedFileCount += analysisDriver.knownFiles.length;
    }

    // Find package info.
    _PackageInfo packageInfo = _findPackages(options);

    // Process embedders.
    Map<file_system.Folder, YamlMap> embedderMap =
        new EmbedderYamlLocator(packageInfo.packageMap).embedderYamls;

    // Scan for SDK extenders.
    bool hasSdkExt = _hasSdkExt(packageInfo.packageMap?.values);

    // No summaries in the presence of embedders or extenders.
    bool useSummaries = embedderMap.isEmpty && !hasSdkExt;

    if (!useSummaries && options.buildSummaryInputs.isNotEmpty) {
      throw new _DriverError(
          'Summaries are not yet supported when using Flutter.');
    }

    // Read any input summaries.
    SummaryDataStore summaryDataStore = new SummaryDataStore(
        useSummaries ? options.buildSummaryInputs : <String>[]);

    // Once options and embedders are processed, setup the SDK.
    _setupSdk(options, useSummaries, analysisOptions);

    PackageBundle sdkBundle = sdk.getLinkedBundle();
    if (sdkBundle != null) {
      summaryDataStore.addBundle(null, sdkBundle);
    }

    // Choose a package resolution policy and a diet parsing policy based on
    // the command-line options.
    SourceFactory sourceFactory = _chooseUriResolutionPolicy(options,
        embedderMap, packageInfo, summaryDataStore, true, analysisOptions);

    PerformanceLog log = new PerformanceLog(null);
    AnalysisDriverScheduler scheduler = new AnalysisDriverScheduler(log);

    bool enableKernelDriver = options.useCFE;
    file_system.Folder kernelPlatformBinariesFolder;
    if (enableKernelDriver && options.dartSdkPlatformBinariesPath != null) {
      kernelPlatformBinariesFolder =
          resourceProvider.getFolder(options.dartSdkPlatformBinariesPath);
    }

    analysisDriver = new AnalysisDriver(
        scheduler,
        log,
        resourceProvider,
        analysisDriverMemoryByteStore,
        new FileContentOverlay(),
        null,
        sourceFactory,
        analysisOptions,
        enableKernelDriver: enableKernelDriver,
        kernelPlatformFolder: kernelPlatformBinariesFolder);
    analysisDriver.results.listen((_) {});
    analysisDriver.exceptions.listen((_) {});
    scheduler.start();
  }

  /// Return discovered packagespec, or `null` if none is found.
  Packages _discoverPackagespec(Uri root) {
    try {
      Packages packages = pkg_discovery.findPackagesFromFile(root);
      if (packages != Packages.noPackages) {
        return packages;
      }
    } catch (_) {
      // Ignore and fall through to null.
    }

    return null;
  }

  /// Return whether [a] and [b] options are equal for the purpose of
  /// command line analysis.
  bool _equalAnalysisOptions(AnalysisOptionsImpl a, AnalysisOptions b) {
    return a.enableLazyAssignmentOperators == b.enableLazyAssignmentOperators &&
        a.enableSuperMixins == b.enableSuperMixins &&
        a.enableTiming == b.enableTiming &&
        a.generateImplicitErrors == b.generateImplicitErrors &&
        a.generateSdkErrors == b.generateSdkErrors &&
        a.hint == b.hint &&
        a.lint == b.lint &&
        AnalysisOptionsImpl.compareLints(a.lintRules, b.lintRules) &&
        a.preserveComments == b.preserveComments &&
        a.strongMode == b.strongMode &&
        a.useFastaParser == b.useFastaParser;
  }

  _PackageInfo _findPackages(CommandLineOptions options) {
    if (packageResolverProvider != null) {
      // The resolver provider will do all the work later.
      return new _PackageInfo(null, null);
    }

    Packages packages;
    Map<String, List<file_system.Folder>> packageMap;

    if (options.packageConfigPath != null) {
      String packageConfigPath = options.packageConfigPath;
      Uri fileUri = new Uri.file(packageConfigPath);
      try {
        io.File configFile = new io.File.fromUri(fileUri).absolute;
        List<int> bytes = configFile.readAsBytesSync();
        Map<String, Uri> map = pkgfile.parse(bytes, configFile.uri);
        packages = new MapPackages(map);
        packageMap = _getPackageMap(packages);
      } catch (e) {
        printAndFail(
            'Unable to read package config data from $packageConfigPath: $e');
      }
    } else if (options.packageRootPath != null) {
      packageMap = _PackageRootPackageMapBuilder
          .buildPackageMap(options.packageRootPath);
    } else {
      file_system.Resource cwd = resourceProvider.getResource('.');
      // Look for .packages.
      packages = _discoverPackagespec(new Uri.directory(cwd.path));
      packageMap = _getPackageMap(packages);
    }

    return new _PackageInfo(packages, packageMap);
  }

  Map<String, List<file_system.Folder>> _getPackageMap(Packages packages) {
    if (packages == null) {
      return null;
    }

    Map<String, List<file_system.Folder>> folderMap =
        new Map<String, List<file_system.Folder>>();
    packages.asMap().forEach((String packagePath, Uri uri) {
      folderMap[packagePath] = [resourceProvider.getFolder(path.fromUri(uri))];
    });
    return folderMap;
  }

  bool _hasSdkExt(Iterable<List<file_system.Folder>> folders) {
    if (folders != null) {
      //TODO: ideally share this traversal with SdkExtUriResolver
      for (Iterable<file_system.Folder> libDirs in folders) {
        if (libDirs.any((file_system.Folder libDir) =>
            libDir.getChild(SdkExtUriResolver.SDK_EXT_NAME).exists)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns `true` if this relative path is a hidden directory.
  bool _isInHiddenDir(String relative) =>
      path.split(relative).any((part) => part.startsWith("."));

  void _processPlugins() {
    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    plugins.addAll(_userDefinedPlugins);

    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);

    linter.registerLintRules();
  }

  /// Analyze a single source.
  Future<ErrorSeverity> _runAnalyzer(
      FileState file, CommandLineOptions options, ErrorFormatter formatter) {
    int startTime = currentTimeMillis;
    AnalyzerImpl analyzer = new AnalyzerImpl(analysisDriver.analysisOptions,
        analysisDriver, file, options, stats, startTime);
    return analyzer.analyze(formatter);
  }

  void _setupSdk(CommandLineOptions options, bool useSummaries,
      AnalysisOptions analysisOptions) {
    if (sdk == null) {
      if (options.dartSdkSummaryPath != null) {
        sdk = new SummaryBasedDartSdk(
            options.dartSdkSummaryPath, options.strongMode);
      } else {
        String dartSdkPath = options.dartSdkPath;
        FolderBasedDartSdk dartSdk = new FolderBasedDartSdk(resourceProvider,
            resourceProvider.getFolder(dartSdkPath), options.strongMode);
        dartSdk.useSummary = useSummaries &&
            options.sourceFiles.every((String sourcePath) {
              sourcePath = path.absolute(sourcePath);
              sourcePath = path.normalize(sourcePath);
              return !path.isWithin(dartSdkPath, sourcePath);
            });
        dartSdk.analysisOptions = analysisOptions;
        sdk = dartSdk;
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
    if (previous == null || newOptions == null) {
      return false;
    }
    if (newOptions.packageRootPath != previous.packageRootPath) {
      return false;
    }
    if (newOptions.packageConfigPath != previous.packageConfigPath) {
      return false;
    }
    if (!_equalMaps(newOptions.definedVariables, previous.definedVariables)) {
      return false;
    }
    if (newOptions.log != previous.log) {
      return false;
    }
    if (newOptions.disableHints != previous.disableHints) {
      return false;
    }
    if (newOptions.showPackageWarnings != previous.showPackageWarnings) {
      return false;
    }
    if (newOptions.showPackageWarningsPrefix !=
        previous.showPackageWarningsPrefix) {
      return false;
    }
    if (newOptions.showSdkWarnings != previous.showSdkWarnings) {
      return false;
    }
    if (newOptions.lints != previous.lints) {
      return false;
    }
    if (newOptions.strongMode != previous.strongMode) {
      return false;
    }
    if (newOptions.enableSuperMixins != previous.enableSuperMixins) {
      return false;
    }
    if (!_equalLists(
        newOptions.buildSummaryInputs, previous.buildSummaryInputs)) {
      return false;
    }
    if (newOptions.disableCacheFlushing != previous.disableCacheFlushing) {
      return false;
    }
    return true;
  }

  /// Perform a deep comparison of two string lists.
  static bool _equalLists(List<String> l1, List<String> l2) {
    if (l1.length != l2.length) {
      return false;
    }
    for (int i = 0; i < l1.length; i++) {
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
    for (String key in m1.keys) {
      if (!m2.containsKey(key) || m1[key] != m2[key]) {
        return false;
      }
    }
    return true;
  }
}

class _DriverError implements Exception {
  String msg;

  _DriverError(this.msg);
}

class _PackageInfo {
  Packages packages;
  Map<String, List<file_system.Folder>> packageMap;

  _PackageInfo(this.packages, this.packageMap);
}

/// [SdkExtUriResolver] needs a Map from package name to folder. In the case
/// that the analyzer is invoked with a --package-root option, we need to
/// manually create this mapping. Given [packageRootPath],
/// [_PackageRootPackageMapBuilder] creates a simple mapping from package name
/// to full path on disk (resolving any symbolic links).
class _PackageRootPackageMapBuilder {
  static Map<String, List<file_system.Folder>> buildPackageMap(
      String packageRootPath) {
    var packageRoot = new io.Directory(packageRootPath);
    if (!packageRoot.existsSync()) {
      throw new _DriverError(
          'Package root directory ($packageRootPath) does not exist.');
    }
    var packages = packageRoot.listSync(followLinks: false);
    var result = new Map<String, List<file_system.Folder>>();
    for (var package in packages) {
      var packageName = path.basename(package.path);
      var realPath = package.resolveSymbolicLinksSync();
      result[packageName] = [
        PhysicalResourceProvider.INSTANCE.getFolder(realPath)
      ];
    }
    return result;
  }
}
