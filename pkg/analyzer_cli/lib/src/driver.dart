// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/interner.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_general.dart'
    show PerformanceTag;
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;
import 'package:analyzer_cli/src/analyzer_impl.dart';
import 'package:analyzer_cli/src/batch_mode.dart';
import 'package:analyzer_cli/src/build_mode.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/error_severity.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:analyzer_cli/src/perf_report.dart';
import 'package:analyzer_cli/starter.dart' show CommandLineStarter;
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:linter/src/rules.dart' as linter;
import 'package:package_config/discovery.dart' as pkg_discovery;
import 'package:package_config/packages.dart' show Packages;
import 'package:package_config/packages_file.dart' as pkgfile show parse;
import 'package:package_config/src/packages_impl.dart' show MapPackages;
import 'package:path/path.dart' as path;
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:yaml/yaml.dart';

/// Shared IO sink for standard error reporting.
///
/// *Visible for testing.*
StringSink errorSink = io.stderr;

/// Shared IO sink for standard out reporting.
///
/// *Visible for testing.*
StringSink outSink = io.stdout;

/// Test this option map to see if it specifies lint rules.
bool containsLintRuleEntry(Map<String, YamlNode> options) {
  var linterNode = options['linter'];
  return linterNode is YamlMap && linterNode.containsKey('rules');
}

class Driver implements CommandLineStarter {
  static final PerformanceTag _analyzeAllTag =
      new PerformanceTag("Driver._analyzeAll");

  /// Cache of [AnalysisOptionsImpl] objects that correspond to directories
  /// with analyzed files, used to reduce searching for `analysis_options.yaml`
  /// files.
  static Map<String, AnalysisOptionsImpl> _directoryToAnalysisOptions = {};

  static ByteStore analysisDriverMemoryByteStore = new MemoryByteStore();

  /// The plugins that are defined outside the `analyzer_cli` package.
  List<Plugin> _userDefinedPlugins = <Plugin>[];

  /// The context that was most recently created by a call to [_analyzeAll], or
  /// `null` if [_analyzeAll] hasn't been called yet.
  InternalAnalysisContext _context;

  AnalysisDriver analysisDriver;

  /// The total number of source files loaded by an AnalysisContext.
  int _analyzedFileCount = 0;

  /// If [_context] is not `null`, the [CommandLineOptions] that guided its
  /// creation.
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

  /// This Driver's current analysis context.
  ///
  /// *Visible for testing.*
  AnalysisContext get context => _context;

  @override
  void set userDefinedPlugins(List<Plugin> plugins) {
    _userDefinedPlugins = plugins ?? <Plugin>[];
  }

  @override
  Future<Null> start(List<String> args) async {
    if (_context != null) {
      throw new StateError("start() can only be called once");
    }
    int startTime = new DateTime.now().millisecondsSinceEpoch;

    StringUtilities.INTERNER = new MappedInterner();

    _processPlugins();

    // Parse commandline options.
    CommandLineOptions options = CommandLineOptions.parse(args);

    // Do analysis.
    if (options.buildMode) {
      ErrorSeverity severity = _buildModeAnalyze(options);
      // Propagate issues to the exit code.
      if (_shouldBeFatal(severity, options)) {
        io.exitCode = severity.ordinal;
      }
    } else if (options.shouldBatch) {
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

    if (_context != null) {
      _analyzedFileCount += _context.sources.length;
    }

    if (options.perfReport != null) {
      String json = makePerfReport(
          startTime, currentTimeMillis, options, _analyzedFileCount, stats);
      new io.File(options.perfReport).writeAsStringSync(json);
    }
  }

  Future<ErrorSeverity> _analyzeAll(CommandLineOptions options) async {
    PerformanceTag previous = _analyzeAllTag.makeCurrent();
    try {
      return await _analyzeAllImpl(options);
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

    // Create a context, or re-use the previous one.
    try {
      _createAnalysisContext(options);
    } on _DriverError catch (error) {
      outSink.writeln(error.msg);
      return ErrorSeverity.ERROR;
    }

    // Add all the files to be analyzed en masse to the context. Skip any
    // files that were added earlier (whether explicitly or implicitly) to
    // avoid causing those files to be unnecessarily re-read.
    Set<Source> knownSources = context.sources.toSet();
    Set<Source> sourcesToAnalyze = new Set<Source>();
    ChangeSet changeSet = new ChangeSet();
    for (String sourcePath in options.sourceFiles) {
      sourcePath = sourcePath.trim();

      // Collect files for analysis.
      // Note that these files will all be analyzed in the same context.
      // This should be updated when the ContextManager re-work is complete
      // (See: https://github.com/dart-lang/sdk/issues/24133)
      Iterable<io.File> files =
          _collectFiles(sourcePath, context.analysisOptions);
      if (files.isEmpty) {
        errorSink.writeln('No dart files found at: $sourcePath');
        io.exitCode = ErrorSeverity.ERROR.ordinal;
        return ErrorSeverity.ERROR;
      }

      for (io.File file in files) {
        Source source = _computeLibrarySource(file.absolute.path);
        if (!knownSources.contains(source)) {
          changeSet.addedSource(source);
        }
        sourcesToAnalyze.add(source);
      }

      if (analysisDriver == null) {
        context.applyChanges(changeSet);
      }
    }

    // Analyze the libraries.
    ErrorSeverity allResult = ErrorSeverity.NONE;
    List<Uri> libUris = <Uri>[];
    Set<Source> partSources = new Set<Source>();

    SeverityProcessor defaultSeverityProcessor = (AnalysisError error) {
      return determineProcessedSeverity(
          error, options, _context.analysisOptions);
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

    for (Source source in sourcesToAnalyze) {
      SourceKind sourceKind = analysisDriver != null
          ? await analysisDriver.getSourceKind(source.fullName)
          : context.computeKindOf(source);
      if (sourceKind == SourceKind.PART) {
        partSources.add(source);
        continue;
      }
      ErrorSeverity status = await _runAnalyzer(source, options, formatter);
      allResult = allResult.max(status);
      libUris.add(source.uri);
    }

    formatter.flush();

    // Check that each part has a corresponding source in the input list.
    for (Source partSource in partSources) {
      bool found = false;
      if (analysisDriver != null) {
        var partFile =
            analysisDriver.fsState.getFileForPath(partSource.fullName);
        if (libUris.contains(partFile.library?.uri)) {
          found = true;
        }
      } else {
        for (var lib in context.getLibrariesContaining(partSource)) {
          if (libUris.contains(lib.uri)) {
            found = true;
          }
        }
      }
      if (!found) {
        errorSink.writeln(
            "${partSource.fullName} is a part and cannot be analyzed.");
        errorSink.writeln("Please pass in a library that contains this part.");
        io.exitCode = ErrorSeverity.ERROR.ordinal;
        allResult = allResult.max(ErrorSeverity.ERROR);
      }
    }

    if (!options.machineFormat) {
      stats.print(outSink);
    }

    return allResult;
  }

  /// Perform analysis in build mode according to the given [options].
  ErrorSeverity _buildModeAnalyze(CommandLineOptions options) {
    return _analyzeAllTag.makeCurrentWhile(() {
      if (options.buildModePersistentWorker) {
        new AnalyzerWorkerLoop.std(resourceProvider,
                dartSdkPath: options.dartSdkPath)
            .run();
      } else {
        return new BuildMode(resourceProvider, options, stats).analyze();
      }
    });
  }

  /// Decide on the appropriate policy for which files need to be fully parsed
  /// and which files need to be diet parsed, based on [options], and return an
  /// [AnalyzeFunctionBodiesPredicate] that implements this policy.
  AnalyzeFunctionBodiesPredicate _chooseDietParsingPolicy(
      CommandLineOptions options) {
    if (options.shouldBatch) {
      // As analyzer is currently implemented, once a file has been diet
      // parsed, it can't easily be un-diet parsed without creating a brand new
      // context and losing caching.  In batch mode, we can't predict which
      // files we'll need to generate errors and warnings for in the future, so
      // we can't safely diet parse anything.
      return (Source source) => true;
    }

    return (Source source) {
      if (options.sourceFiles.contains(source.fullName)) {
        return true;
      } else if (source.uri.scheme == 'dart') {
        return options.showSdkWarnings;
      } else {
        // TODO(paulberry): diet parse 'package:' imports when we don't want
        // diagnostics. (Full parse is still needed for "self" packages.)
        return true;
      }
    };
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
        resolvers.add(new file_system.ResourceUriResolver(resourceProvider));
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
    resolvers.add(new file_system.ResourceUriResolver(resourceProvider));

    return new SourceFactory(resolvers, packageInfo.packages);
  }

  /// Collect all analyzable files at [filePath], recursively if it's a
  /// directory, ignoring links.
  Iterable<io.File> _collectFiles(String filePath, AnalysisOptions options) {
    List<String> excludedPaths = options.excludePatterns;

    /**
     * Returns `true` if the given [path] is excluded by [excludedPaths].
     */
    bool _isExcluded(String path) {
      return excludedPaths.any((excludedPath) {
        if (resourceProvider.absolutePathContext.isWithin(excludedPath, path)) {
          return true;
        }
        return path == excludedPath;
      });
    }

    List<io.File> files = <io.File>[];
    io.File file = new io.File(filePath);
    if (file.existsSync() && !_isExcluded(filePath)) {
      files.add(file);
    } else {
      io.Directory directory = new io.Directory(filePath);
      if (directory.existsSync()) {
        for (io.FileSystemEntity entry
            in directory.listSync(recursive: true, followLinks: false)) {
          String relative = path.relative(entry.path, from: directory.path);
          if (AnalysisEngine.isDartFileName(entry.path) &&
              !_isExcluded(relative) &&
              !_isInHiddenDir(relative)) {
            files.add(entry);
          }
        }
      }
    }
    return files;
  }

  /// Convert the given [sourcePath] (which may be relative to the current
  /// working directory) to a [Source] object that can be fed to the analysis
  /// context.
  Source _computeLibrarySource(String sourcePath) {
    sourcePath = _normalizeSourcePath(sourcePath);
    File sourceFile = resourceProvider.getFile(sourcePath);
    Source source = sdk.fromFileUri(sourceFile.toUri());
    if (source != null) {
      return source;
    }
    source = new FileSource(sourceFile, sourceFile.toUri());
    Uri uri = _context.sourceFactory.restoreUri(source);
    if (uri == null) {
      return source;
    }
    return new FileSource(sourceFile, uri);
  }

  /// Create an analysis context that is prepared to analyze sources according
  /// to the given [options], and store it in [_context].
  void _createAnalysisContext(CommandLineOptions options) {
    // If not the same command-line options, clear cached information.
    if (!_equalCommandLineOptions(_previousOptions, options)) {
      _previousOptions = options;
      _directoryToAnalysisOptions.clear();
      _context = null;
      analysisDriver = null;
    }

    AnalysisOptionsImpl analysisOptions =
        createAnalysisOptionsForCommandLineOptions(resourceProvider, options);
    analysisOptions.analyzeFunctionBodiesPredicate =
        _chooseDietParsingPolicy(options);

    // If we have the analysis driver, and the new analysis options are the
    // same, we can reuse this analysis driver.
    if (_context != null &&
        _equalAnalysisOptions(_context.analysisOptions, analysisOptions)) {
      return;
    }

    // Save stats from previous context before clobbering it.
    if (_context != null) {
      _analyzedFileCount += _context.sources.length;
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

    // Create a context.
    _context = AnalysisEngine.instance.createAnalysisContext();
    setupAnalysisContext(_context, options, analysisOptions);
    _context.sourceFactory = sourceFactory;

    if (options.enableNewAnalysisDriver) {
      PerformanceLog log = new PerformanceLog(null);
      AnalysisDriverScheduler scheduler = new AnalysisDriverScheduler(log);
      analysisDriver = new AnalysisDriver(
          scheduler,
          log,
          resourceProvider,
          analysisDriverMemoryByteStore,
          new FileContentOverlay(),
          null,
          context.sourceFactory,
          context.analysisOptions);
      analysisDriver.results.listen((_) {});
      analysisDriver.exceptions.listen((_) {});
      scheduler.start();
    } else {
      if (sdkBundle != null) {
        _context.resultProvider =
            new InputPackagesResultProvider(_context, summaryDataStore);
      }
    }
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
    return a.enableAssertInitializer == b.enableAssertInitializer &&
        a.enableStrictCallChecks == b.enableStrictCallChecks &&
        a.enableLazyAssignmentOperators == b.enableLazyAssignmentOperators &&
        a.enableSuperMixins == b.enableSuperMixins &&
        a.enableTiming == b.enableTiming &&
        a.generateImplicitErrors == b.generateImplicitErrors &&
        a.generateSdkErrors == b.generateSdkErrors &&
        a.hint == b.hint &&
        a.lint == b.lint &&
        AnalysisOptionsImpl.compareLints(a.lintRules, b.lintRules) &&
        a.preserveComments == b.preserveComments &&
        a.strongMode == b.strongMode;
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
      Source source, CommandLineOptions options, ErrorFormatter formatter) {
    int startTime = currentTimeMillis;
    AnalyzerImpl analyzer = new AnalyzerImpl(_context.analysisOptions, _context,
        analysisDriver, source, options, stats, startTime);
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

  static AnalysisOptionsImpl createAnalysisOptionsForCommandLineOptions(
      ResourceProvider resourceProvider, CommandLineOptions options) {
    if (options.analysisOptionsFile != null) {
      file_system.File file =
          resourceProvider.getFile(options.analysisOptionsFile);
      if (!file.exists) {
        printAndFail('Options file not found: ${options.analysisOptionsFile}',
            exitCode: ErrorSeverity.ERROR.ordinal);
      }
    }

    String contextRoot;
    if (options.sourceFiles.isEmpty) {
      contextRoot = path.current;
    } else {
      contextRoot = options.sourceFiles[0];
      if (!path.isAbsolute(contextRoot)) {
        contextRoot = path.absolute(contextRoot);
      }
    }

    void verbosePrint(String text) {
      outSink.writeln(text);
    }

    // Prepare the directory which is, or contains, the context root.
    String contextRootDirectory;
    if (resourceProvider.getFolder(contextRoot).exists) {
      contextRootDirectory = contextRoot;
    } else {
      contextRootDirectory = resourceProvider.pathContext.dirname(contextRoot);
    }

    // Check if there is the options object for the content directory.
    AnalysisOptionsImpl contextOptions =
        _directoryToAnalysisOptions[contextRootDirectory];
    if (contextOptions != null) {
      return contextOptions;
    }

    contextOptions = new ContextBuilder(resourceProvider, null, null,
            options: options.contextBuilderOptions)
        .getAnalysisOptions(contextRoot,
            verbosePrint: options.verbose ? verbosePrint : null);

    contextOptions.trackCacheDependencies = false;
    contextOptions.disableCacheFlushing = options.disableCacheFlushing;
    contextOptions.hint = !options.disableHints;
    contextOptions.generateImplicitErrors = options.showPackageWarnings;
    contextOptions.generateSdkErrors = options.showSdkWarnings;
    if (options.enableAssertInitializer != null) {
      contextOptions.enableAssertInitializer = options.enableAssertInitializer;
    }

    _directoryToAnalysisOptions[contextRootDirectory] = contextOptions;
    return contextOptions;
  }

  static void setAnalysisContextOptions(
      file_system.ResourceProvider resourceProvider,
      AnalysisContext context,
      CommandLineOptions options,
      void configureContextOptions(AnalysisOptionsImpl contextOptions)) {
    AnalysisOptionsImpl analysisOptions =
        createAnalysisOptionsForCommandLineOptions(resourceProvider, options);
    configureContextOptions(analysisOptions);
    setupAnalysisContext(context, options, analysisOptions);
  }

  static void setupAnalysisContext(AnalysisContext context,
      CommandLineOptions options, AnalysisOptionsImpl analysisOptions) {
    Map<String, String> definedVariables = options.definedVariables;
    if (definedVariables.isNotEmpty) {
      DeclaredVariables declaredVariables = context.declaredVariables;
      definedVariables.forEach((String variableName, String value) {
        declaredVariables.define(variableName, value);
      });
    }

    if (options.log) {
      AnalysisEngine.instance.logger = new StdLogger();
    }

    // Set context options.
    context.analysisOptions = analysisOptions;
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
    if (newOptions.enableStrictCallChecks != previous.enableStrictCallChecks) {
      return false;
    }
    if (newOptions.enableAssertInitializer !=
        previous.enableAssertInitializer) {
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

  /// Convert [sourcePath] into an absolute path.
  static String _normalizeSourcePath(String sourcePath) =>
      path.normalize(new io.File(sourcePath).absolute.path);
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
