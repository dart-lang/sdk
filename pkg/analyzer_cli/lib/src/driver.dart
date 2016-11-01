// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.driver;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/context/builder.dart';
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
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer_cli/src/analyzer_impl.dart';
import 'package:analyzer_cli/src/build_mode.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:analyzer_cli/src/perf_report.dart';
import 'package:analyzer_cli/starter.dart';
import 'package:linter/src/plugin/linter_plugin.dart';
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

typedef ErrorSeverity _BatchRunnerHandler(List<String> args);

class Driver implements CommandLineStarter {
  static final PerformanceTag _analyzeAllTag =
      new PerformanceTag("Driver._analyzeAll");

  /// The plugins that are defined outside the `analyzer_cli` package.
  List<Plugin> _userDefinedPlugins = <Plugin>[];

  /// The context that was most recently created by a call to [_analyzeAll], or
  /// `null` if [_analyzeAll] hasn't been called yet.
  InternalAnalysisContext _context;

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
  void start(List<String> args) {
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
      // In case of error propagate exit code.
      if (severity == ErrorSeverity.ERROR) {
        io.exitCode = severity.ordinal;
      }
    } else if (options.shouldBatch) {
      _BatchRunner.runAsBatch(args, (List<String> args) {
        CommandLineOptions options = CommandLineOptions.parse(args);
        return _analyzeAll(options);
      });
    } else {
      ErrorSeverity severity = _analyzeAll(options);
      // In case of error propagate exit code.
      if (severity == ErrorSeverity.ERROR) {
        io.exitCode = severity.ordinal;
      }
    }

    if (_context != null) {
      _analyzedFileCount += _context.sources.length;
    }

    if (options.perfReport != null) {
      String json = makePerfReport(
          startTime, currentTimeMillis(), options, _analyzedFileCount, stats);
      new io.File(options.perfReport).writeAsStringSync(json);
    }
  }

  ErrorSeverity _analyzeAll(CommandLineOptions options) {
    return _analyzeAllTag.makeCurrentWhile(() {
      return _analyzeAllImpl(options);
    });
  }

  /// Perform analysis according to the given [options].
  ErrorSeverity _analyzeAllImpl(CommandLineOptions options) {
    if (!options.machineFormat) {
      outSink.writeln("Analyzing ${options.sourceFiles}...");
    }

    // Create a context, or re-use the previous one.
    try {
      _createAnalysisContext(options);
    } on _DriverError catch (error) {
      outSink.writeln(error.msg);
      return ErrorSeverity.ERROR;
    }

    // Add all the files to be analyzed en masse to the context.  Skip any
    // files that were added earlier (whether explicitly or implicitly) to
    // avoid causing those files to be unnecessarily re-read.
    Set<Source> knownSources = context.sources.toSet();
    List<Source> sourcesToAnalyze = <Source>[];
    ChangeSet changeSet = new ChangeSet();
    for (String sourcePath in options.sourceFiles) {
      sourcePath = sourcePath.trim();

      // Collect files for analysis.
      // Note that these files will all be analyzed in the same context.
      // This should be updated when the ContextManager re-work is complete
      // (See: https://github.com/dart-lang/sdk/issues/24133)
      Iterable<io.File> files = _collectFiles(sourcePath);
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
    }
    context.applyChanges(changeSet);

    // Analyze the libraries.
    ErrorSeverity allResult = ErrorSeverity.NONE;
    var libUris = <Uri>[];
    var parts = <Source>[];
    for (Source source in sourcesToAnalyze) {
      if (context.computeKindOf(source) == SourceKind.PART) {
        parts.add(source);
        continue;
      }
      ErrorSeverity status = _runAnalyzer(source, options);
      allResult = allResult.max(status);
      libUris.add(source.uri);
    }

    // Check that each part has a corresponding source in the input list.
    for (Source part in parts) {
      bool found = false;
      for (var lib in context.getLibrariesContaining(part)) {
        if (libUris.contains(lib.uri)) {
          found = true;
        }
      }
      if (!found) {
        errorSink.writeln("${part.fullName} is a part and cannot be analyzed.");
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

  /// Determine whether the context created during a previous call to
  /// [_analyzeAll] can be re-used in order to analyze using [options].
  bool _canContextBeReused(CommandLineOptions options) {
    // TODO(paulberry): add a command-line option that disables context re-use.
    if (_context == null) {
      return false;
    }
    if (options.packageRootPath != _previousOptions.packageRootPath) {
      return false;
    }
    if (options.packageConfigPath != _previousOptions.packageConfigPath) {
      return false;
    }
    if (!_equalMaps(
        options.definedVariables, _previousOptions.definedVariables)) {
      return false;
    }
    if (options.log != _previousOptions.log) {
      return false;
    }
    if (options.disableHints != _previousOptions.disableHints) {
      return false;
    }
    if (options.enableInitializingFormalAccess !=
        _previousOptions.enableInitializingFormalAccess) {
      return false;
    }
    if (options.enableStrictCallChecks !=
        _previousOptions.enableStrictCallChecks) {
      return false;
    }
    if (options.showPackageWarnings != _previousOptions.showPackageWarnings) {
      return false;
    }
    if (options.showPackageWarningsPrefix !=
        _previousOptions.showPackageWarningsPrefix) {
      return false;
    }
    if (options.showSdkWarnings != _previousOptions.showSdkWarnings) {
      return false;
    }
    if (options.lints != _previousOptions.lints) {
      return false;
    }
    if (options.strongMode != _previousOptions.strongMode) {
      return false;
    }
    if (options.enableSuperMixins != _previousOptions.enableSuperMixins) {
      return false;
    }
    if (!_equalLists(
        options.buildSummaryInputs, _previousOptions.buildSummaryInputs)) {
      return false;
    }
    if (options.disableCacheFlushing != _previousOptions.disableCacheFlushing) {
      return false;
    }
    return true;
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
  SourceFactory _chooseUriResolutionPolicy(
      CommandLineOptions options,
      Map<file_system.Folder, YamlMap> embedderMap,
      _PackageInfo packageInfo,
      SummaryDataStore summaryDataStore) {
    // Create a custom package resolver if one has been specified.
    if (packageResolverProvider != null) {
      file_system.Folder folder = resourceProvider.getResource('.');
      UriResolver resolver = packageResolverProvider(folder);
      if (resolver != null) {
        UriResolver sdkResolver = new DartUriResolver(sdk);

        // TODO(brianwilkerson) This doesn't handle sdk extensions.
        List<UriResolver> resolvers = <UriResolver>[
          sdkResolver,
          new InSummaryUriResolver(resourceProvider, summaryDataStore),
          resolver,
          new file_system.ResourceUriResolver(resourceProvider)
        ];
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
    EmbedderSdk embedderSdk = new EmbedderSdk(resourceProvider, embedderMap);
    if (embedderSdk.libraryMap.size() == 0) {
      // The embedder uri resolver has no mappings. Use the default Dart SDK
      // uri resolver.
      resolvers.add(new DartUriResolver(sdk));
    } else {
      // The embedder uri resolver has mappings, use it instead of the default
      // Dart SDK uri resolver.
      resolvers.add(new DartUriResolver(embedderSdk));
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
  Iterable<io.File> _collectFiles(String filePath) {
    List<io.File> files = <io.File>[];
    io.File file = new io.File(filePath);
    if (file.existsSync()) {
      files.add(file);
    } else {
      io.Directory directory = new io.Directory(filePath);
      if (directory.existsSync()) {
        for (io.FileSystemEntity entry
            in directory.listSync(recursive: true, followLinks: false)) {
          String relative = path.relative(entry.path, from: directory.path);
          if (AnalysisEngine.isDartFileName(entry.path) &&
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
    if (_canContextBeReused(options)) {
      return;
    }
    _previousOptions = options;

    // Save stats from previous context before clobbering it.
    if (_context != null) {
      _analyzedFileCount += _context.sources.length;
    }

    // Create a context.
    _context = AnalysisEngine.instance.createAnalysisContext();

    AnalyzeFunctionBodiesPredicate dietParsingPolicy =
        _chooseDietParsingPolicy(options);
    setAnalysisContextOptions(resourceProvider, _context, options,
        (AnalysisOptionsImpl contextOptions) {
      contextOptions.analyzeFunctionBodiesPredicate = dietParsingPolicy;
    });

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
    _setupSdk(options, useSummaries);

    // Choose a package resolution policy and a diet parsing policy based on
    // the command-line options.
    SourceFactory sourceFactory = _chooseUriResolutionPolicy(
        options, embedderMap, packageInfo, summaryDataStore);

    _context.sourceFactory = sourceFactory;
    _context.resultProvider =
        new InputPackagesResultProvider(_context, summaryDataStore);
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
    plugins.add(AnalysisEngine.instance.commandLinePlugin);
    plugins.add(AnalysisEngine.instance.optionsPlugin);
    plugins.add(linterPlugin);
    plugins.addAll(_userDefinedPlugins);

    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);
  }

  /// Analyze a single source.
  ErrorSeverity _runAnalyzer(Source source, CommandLineOptions options) {
    int startTime = currentTimeMillis();
    AnalyzerImpl analyzer =
        new AnalyzerImpl(_context, source, options, stats, startTime);
    var errorSeverity = analyzer.analyzeSync();
    if (errorSeverity == ErrorSeverity.ERROR) {
      io.exitCode = errorSeverity.ordinal;
    }
    if (options.warningsAreFatal && errorSeverity == ErrorSeverity.WARNING) {
      io.exitCode = errorSeverity.ordinal;
    }
    return errorSeverity;
  }

  void _setupSdk(CommandLineOptions options, bool useSummaries) {
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

        dartSdk.analysisOptions = context.analysisOptions;
        sdk = dartSdk;
      }
    }
  }

  static AnalysisOptionsImpl createAnalysisOptionsForCommandLineOptions(
      CommandLineOptions options) {
    AnalysisOptionsImpl contextOptions = new AnalysisOptionsImpl();
    contextOptions.trackCacheDependencies = false;
    contextOptions.disableCacheFlushing = options.disableCacheFlushing;
    contextOptions.hint = !options.disableHints;
    contextOptions.enableInitializingFormalAccess =
        options.enableInitializingFormalAccess;
    contextOptions.enableStrictCallChecks = options.enableStrictCallChecks;
    contextOptions.enableSuperMixins = options.enableSuperMixins;
    contextOptions.generateImplicitErrors = options.showPackageWarnings;
    contextOptions.generateSdkErrors = options.showSdkWarnings;
    contextOptions.lint = options.lints;
    contextOptions.strongMode = options.strongMode;
    contextOptions.implicitCasts = options.implicitCasts;
    contextOptions.implicitDynamic = options.implicitDynamic;
    return contextOptions;
  }

  static void setAnalysisContextOptions(
      file_system.ResourceProvider resourceProvider,
      AnalysisContext context,
      CommandLineOptions options,
      void configureContextOptions(AnalysisOptionsImpl contextOptions)) {
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

    // Prepare context options.
    AnalysisOptionsImpl contextOptions =
        createAnalysisOptionsForCommandLineOptions(options);
    configureContextOptions(contextOptions);

    // Set context options.
    context.analysisOptions = contextOptions;

    // Process analysis options file (and notify all interested parties).
    _processAnalysisOptions(resourceProvider, context, options);
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

  static file_system.File _getOptionsFile(
      file_system.ResourceProvider resourceProvider,
      CommandLineOptions options) {
    file_system.File file;
    String filePath = options.analysisOptionsFile;
    if (filePath != null) {
      file = resourceProvider.getFile(filePath);
      if (!file.exists) {
        printAndFail('Options file not found: $filePath',
            exitCode: ErrorSeverity.ERROR.ordinal);
      }
    } else {
      filePath = AnalysisEngine.ANALYSIS_OPTIONS_FILE;
      file = resourceProvider.getFile(filePath);
      if (!file.exists) {
        filePath = AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;
        file = resourceProvider.getFile(filePath);
      }
    }
    return file;
  }

  /// Convert [sourcePath] into an absolute path.
  static String _normalizeSourcePath(String sourcePath) =>
      path.normalize(new io.File(sourcePath).absolute.path);

  static void _processAnalysisOptions(
      file_system.ResourceProvider resourceProvider,
      AnalysisContext context,
      CommandLineOptions options) {
    file_system.File file = _getOptionsFile(resourceProvider, options);
    List<OptionsProcessor> optionsProcessors =
        AnalysisEngine.instance.optionsPlugin.optionsProcessors;
    try {
      AnalysisOptionsProvider analysisOptionsProvider =
          new AnalysisOptionsProvider();
      Map<String, YamlNode> optionMap =
          analysisOptionsProvider.getOptionsFromFile(file);
      optionsProcessors.forEach(
          (OptionsProcessor p) => p.optionsProcessed(context, optionMap));

      // Fill in lint rule defaults in case lints are enabled and rules are
      // not specified in an options file.
      if (options.lints && !containsLintRuleEntry(optionMap)) {
        setLints(context, linterPlugin.contributedRules);
      }

      // Ask engine to further process options.
      if (optionMap != null) {
        configureContextOptions(context, optionMap);
      }
    } on Exception catch (e) {
      optionsProcessors.forEach((OptionsProcessor p) => p.onError(e));
    }
  }
}

/// Provides a framework to read command line options from stdin and feed them
/// to a callback.
class _BatchRunner {
  /// Run the tool in 'batch' mode, receiving command lines through stdin and
  /// returning pass/fail status through stdout. This feature is intended for
  /// use in unit testing.
  static void runAsBatch(List<String> sharedArgs, _BatchRunnerHandler handler) {
    outSink.writeln('>>> BATCH START');
    Stopwatch stopwatch = new Stopwatch();
    stopwatch.start();
    int testsFailed = 0;
    int totalTests = 0;
    ErrorSeverity batchResult = ErrorSeverity.NONE;
    // Read line from stdin.
    Stream cmdLine =
        io.stdin.transform(UTF8.decoder).transform(new LineSplitter());
    cmdLine.listen((String line) {
      // Maybe finish.
      if (line.isEmpty) {
        var time = stopwatch.elapsedMilliseconds;
        outSink.writeln(
            '>>> BATCH END (${totalTests - testsFailed}/$totalTests) ${time}ms');
        io.exitCode = batchResult.ordinal;
      }
      // Prepare arguments.
      var lineArgs = line.split(new RegExp('\\s+'));
      var args = new List<String>();
      args.addAll(sharedArgs);
      args.addAll(lineArgs);
      args.remove('-b');
      args.remove('--batch');
      // Analyze single set of arguments.
      try {
        totalTests++;
        ErrorSeverity result = handler(args);
        bool resultPass = result != ErrorSeverity.ERROR;
        if (!resultPass) {
          testsFailed++;
        }
        batchResult = batchResult.max(result);
        // Write stderr end token and flush.
        errorSink.writeln('>>> EOF STDERR');
        String resultPassString = resultPass ? 'PASS' : 'FAIL';
        outSink.writeln(
            '>>> TEST $resultPassString ${stopwatch.elapsedMilliseconds}ms');
      } catch (e, stackTrace) {
        errorSink.writeln(e);
        errorSink.writeln(stackTrace);
        errorSink.writeln('>>> EOF STDERR');
        outSink.writeln('>>> TEST CRASH');
      }
    });
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
