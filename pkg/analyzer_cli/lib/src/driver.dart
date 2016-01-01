// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.driver;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/file_system/file_system.dart' as fileSystem;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/interner.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_general.dart'
    show PerformanceTag;
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer_cli/src/analyzer_impl.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:analyzer_cli/src/perf_report.dart';
import 'package:linter/src/plugin/linter_plugin.dart';
import 'package:package_config/discovery.dart' as pkgDiscovery;
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
StringSink errorSink = stderr;

/// Shared IO sink for standard out reporting.
///
/// *Visible for testing.*
StringSink outSink = stdout;

/// Test this option map to see if it specifies lint rules.
bool containsLintRuleEntry(Map<String, YamlNode> options) {
  var linterNode = options['linter'];
  return linterNode is YamlMap && linterNode.containsKey('rules');
}

typedef ErrorSeverity _BatchRunnerHandler(List<String> args);

class Driver {
  static final PerformanceTag _analyzeAllTag =
      new PerformanceTag("Driver._analyzeAll");

  /// The plugins that are defined outside the `analyzer_cli` package.
  List<Plugin> _userDefinedPlugins = <Plugin>[];

  /// Indicates whether the analyzer is running in batch mode.
  bool _isBatch;

  /// The context that was most recently created by a call to [_analyzeAll], or
  /// `null` if [_analyzeAll] hasn't been called yet.
  AnalysisContext _context;

  /// If [_context] is not `null`, the [CommandLineOptions] that guided its
  /// creation.
  CommandLineOptions _previousOptions;

  /// This Driver's current analysis context.
  ///
  /// *Visible for testing.*
  AnalysisContext get context => _context;

  /// Set the [plugins] that are defined outside the `analyzer_cli` package.
  void set userDefinedPlugins(List<Plugin> plugins) {
    _userDefinedPlugins = plugins == null ? <Plugin>[] : plugins;
  }

  /// Use the given command-line [args] to start this analysis driver.
  void start(List<String> args) {
    int startTime = new DateTime.now().millisecondsSinceEpoch;

    StringUtilities.INTERNER = new MappedInterner();

    _processPlugins();

    // Parse commandline options.
    CommandLineOptions options = CommandLineOptions.parse(args);

    // Cache options of interest to inform analysis.
    _setupEnv(options);

    // Do analysis.
    if (_isBatch) {
      _BatchRunner.runAsBatch(args, (List<String> args) {
        CommandLineOptions options = CommandLineOptions.parse(args);
        return _analyzeAll(options);
      });
    } else {
      ErrorSeverity severity = _analyzeAll(options);
      // In case of error propagate exit code.
      if (severity == ErrorSeverity.ERROR) {
        exitCode = severity.ordinal;
      }
    }

    if (options.perfReport != null) {
      String json = makePerfReport(startTime, currentTimeMillis(), options);
      new File(options.perfReport).writeAsStringSync(json);
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
    Set<Source> knownSources = _context.sources.toSet();
    List<Source> sourcesToAnalyze = <Source>[];
    ChangeSet changeSet = new ChangeSet();
    for (String sourcePath in options.sourceFiles) {
      sourcePath = sourcePath.trim();
      // Check that file exists.
      if (!new File(sourcePath).existsSync()) {
        errorSink.writeln('File not found: $sourcePath');
        exitCode = ErrorSeverity.ERROR.ordinal;
        //Fail fast; don't analyze more files
        return ErrorSeverity.ERROR;
      }
      // Check that file is Dart file.
      if (!AnalysisEngine.isDartFileName(sourcePath)) {
        errorSink.writeln('$sourcePath is not a Dart file');
        exitCode = ErrorSeverity.ERROR.ordinal;
        // Fail fast; don't analyze more files.
        return ErrorSeverity.ERROR;
      }
      Source source = _computeLibrarySource(sourcePath);
      if (!knownSources.contains(source)) {
        changeSet.addedSource(source);
      }
      sourcesToAnalyze.add(source);
    }
    _context.applyChanges(changeSet);

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
        exitCode = ErrorSeverity.ERROR.ordinal;
        allResult = allResult.max(ErrorSeverity.ERROR);
      }
    }

    return allResult;
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
    if (options.enableStrictCallChecks !=
        _previousOptions.enableStrictCallChecks) {
      return false;
    }
    if (options.showPackageWarnings != _previousOptions.showPackageWarnings) {
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
    return true;
  }

  /// Decide on the appropriate policy for which files need to be fully parsed
  /// and which files need to be diet parsed, based on [options], and return an
  /// [AnalyzeFunctionBodiesPredicate] that implements this policy.
  AnalyzeFunctionBodiesPredicate _chooseDietParsingPolicy(
      CommandLineOptions options) {
    if (_isBatch) {
      // As analyzer is currently implemented, once a file has been diet
      // parsed, it can't easily be un-diet parsed without creating a brand new
      // context and losing caching.  In batch mode, we can't predict which
      // files we'll need to generate errors and warnings for in the future, so
      // we can't safely diet parse anything.
      return (Source source) => true;
    }

    // Determine the set of packages requiring a full parse.  Use null to
    // represent the case where all packages require a full parse.
    Set<String> packagesRequiringFullParse;
    if (options.showPackageWarnings) {
      // We are showing warnings from all packages so all packages require a
      // full parse.
      packagesRequiringFullParse = null;
    } else {
      // We aren't showing warnings for dependent packages, but we may still
      // need to show warnings for "self" packages, so we need to do a full
      // parse in any package containing files mentioned on the command line.
      // TODO(paulberry): implement this.  As a temporary workaround, we're
      // fully parsing all packages.
      packagesRequiringFullParse = null;
    }
    return (Source source) {
      if (source.uri.scheme == 'dart') {
        return options.showSdkWarnings;
      } else if (source.uri.scheme == 'package') {
        if (packagesRequiringFullParse == null) {
          return true;
        } else if (source.uri.pathSegments.length == 0) {
          // We should never see a URI like this, but fully parse it to be
          // safe.
          return true;
        } else {
          return packagesRequiringFullParse
              .contains(source.uri.pathSegments[0]);
        }
      } else {
        return true;
      }
    };
  }

  /// Decide on the appropriate method for resolving URIs based on the given
  /// [options] and [customUrlMappings] settings, and return a
  /// [SourceFactory] that has been configured accordingly.
  SourceFactory _chooseUriResolutionPolicy(CommandLineOptions options) {
    Packages packages;
    Map<String, List<fileSystem.Folder>> packageMap;
    UriResolver packageUriResolver;

    // Process options, caching package resolution details.
    if (options.packageConfigPath != null) {
      String packageConfigPath = options.packageConfigPath;
      Uri fileUri = new Uri.file(packageConfigPath);
      try {
        File configFile = new File.fromUri(fileUri).absolute;
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

      JavaFile packageDirectory = new JavaFile(options.packageRootPath);
      packageUriResolver = new PackageUriResolver([packageDirectory]);
    } else {
      fileSystem.Resource cwd =
          PhysicalResourceProvider.INSTANCE.getResource('.');

      // Look for .packages.
      packages = _discoverPackagespec(new Uri.directory(cwd.path));

      if (packages != null) {
        packageMap = _getPackageMap(packages);
      } else {
        // Fall back to pub list-package-dirs.

        PubPackageMapProvider pubPackageMapProvider =
            new PubPackageMapProvider(PhysicalResourceProvider.INSTANCE, sdk);
        PackageMapInfo packageMapInfo =
            pubPackageMapProvider.computePackageMap(cwd);
        packageMap = packageMapInfo.packageMap;

        // Only create a packageUriResolver if pub list-package-dirs succeeded.
        // If it failed, that's not a problem; it simply means we have no way
        // to resolve packages.
        if (packageMapInfo.packageMap != null) {
          packageUriResolver = new PackageMapUriResolver(
              PhysicalResourceProvider.INSTANCE, packageMap);
        }
      }
    }

    // Now, build our resolver list.

    // 'dart:' URIs come first.
    List<UriResolver> resolvers = [new DartUriResolver(sdk)];

    // Next SdkExts.
    if (packageMap != null) {
      resolvers.add(new SdkExtUriResolver(packageMap));
    }

    // Then package URIs.
    if (packageUriResolver != null) {
      resolvers.add(packageUriResolver);
    }

    // Finally files.
    resolvers.add(new FileUriResolver());

    return new SourceFactory(resolvers, packages);
  }

  /// Convert the given [sourcePath] (which may be relative to the current
  /// working directory) to a [Source] object that can be fed to the analysis
  /// context.
  Source _computeLibrarySource(String sourcePath) {
    sourcePath = _normalizeSourcePath(sourcePath);
    JavaFile sourceFile = new JavaFile(sourcePath);
    Source source = sdk.fromFileUri(sourceFile.toURI());
    if (source != null) {
      return source;
    }
    source = new FileBasedSource(sourceFile, sourceFile.toURI());
    Uri uri = _context.sourceFactory.restoreUri(source);
    if (uri == null) {
      return source;
    }
    return new FileBasedSource(sourceFile, uri);
  }

  /// Create an analysis context that is prepared to analyze sources according
  /// to the given [options], and store it in [_context].
  void _createAnalysisContext(CommandLineOptions options) {
    if (_canContextBeReused(options)) {
      return;
    }
    _previousOptions = options;
    // Choose a package resolution policy and a diet parsing policy based on
    // the command-line options.
    SourceFactory sourceFactory = _chooseUriResolutionPolicy(options);
    AnalyzeFunctionBodiesPredicate dietParsingPolicy =
        _chooseDietParsingPolicy(options);
    // Create a context using these policies.
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();

    context.sourceFactory = sourceFactory;

    Map<String, String> definedVariables = options.definedVariables;
    if (!definedVariables.isEmpty) {
      DeclaredVariables declaredVariables = context.declaredVariables;
      definedVariables.forEach((String variableName, String value) {
        declaredVariables.define(variableName, value);
      });
    }

    if (options.log) {
      AnalysisEngine.instance.logger = new StdLogger();
    }

    // Set context options.
    AnalysisOptionsImpl contextOptions = new AnalysisOptionsImpl();
    contextOptions.hint = !options.disableHints;
    contextOptions.enableStrictCallChecks = options.enableStrictCallChecks;
    contextOptions.enableSuperMixins = options.enableSuperMixins;
    contextOptions.analyzeFunctionBodiesPredicate = dietParsingPolicy;
    contextOptions.generateImplicitErrors = options.showPackageWarnings;
    contextOptions.generateSdkErrors = options.showSdkWarnings;
    contextOptions.lint = options.lints;
    contextOptions.strongMode = options.strongMode;
    context.analysisOptions = contextOptions;
    _context = context;

    // Process analysis options file (and notify all interested parties).
    _processAnalysisOptions(options, context);
  }

  /// Return discovered packagespec, or `null` if none is found.
  Packages _discoverPackagespec(Uri root) {
    try {
      Packages packages = pkgDiscovery.findPackagesFromFile(root);
      if (packages != Packages.noPackages) {
        return packages;
      }
    } catch (_) {
      // Ignore and fall through to null.
    }

    return null;
  }

  fileSystem.File _getOptionsFile(CommandLineOptions options) {
    fileSystem.File file;
    String filePath = options.analysisOptionsFile;
    if (filePath != null) {
      file = PhysicalResourceProvider.INSTANCE.getFile(filePath);
      if (!file.exists) {
        printAndFail('Options file not found: $filePath',
            exitCode: ErrorSeverity.ERROR.ordinal);
      }
    } else {
      filePath = AnalysisEngine.ANALYSIS_OPTIONS_FILE;
      file = PhysicalResourceProvider.INSTANCE.getFile(filePath);
    }
    return file;
  }

  Map<String, List<fileSystem.Folder>> _getPackageMap(Packages packages) {
    if (packages == null) {
      return null;
    }

    Map<String, List<fileSystem.Folder>> folderMap =
        new Map<String, List<fileSystem.Folder>>();
    packages.asMap().forEach((String packagePath, Uri uri) {
      folderMap[packagePath] = [
        PhysicalResourceProvider.INSTANCE.getFolder(path.fromUri(uri))
      ];
    });
    return folderMap;
  }

  void _processAnalysisOptions(
      CommandLineOptions options, AnalysisContext context) {
    fileSystem.File file = _getOptionsFile(options);
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
        new AnalyzerImpl(_context, source, options, startTime);
    var errorSeverity = analyzer.analyzeSync();
    if (errorSeverity == ErrorSeverity.ERROR) {
      exitCode = errorSeverity.ordinal;
    }
    if (options.warningsAreFatal && errorSeverity == ErrorSeverity.WARNING) {
      exitCode = errorSeverity.ordinal;
    }
    return errorSeverity;
  }

  void _setupEnv(CommandLineOptions options) {
    // In batch mode, SDK is specified on the main command line rather than in
    // the command lines sent to stdin.  So process it before deciding whether
    // to activate batch mode.
    if (sdk == null) {
      sdk = new DirectoryBasedDartSdk(new JavaFile(options.dartSdkPath));
    }
    _isBatch = options.shouldBatch;
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
      path.normalize(new File(sourcePath).absolute.path);
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
        stdin.transform(UTF8.decoder).transform(new LineSplitter());
    cmdLine.listen((String line) {
      // Maybe finish.
      if (line.isEmpty) {
        var time = stopwatch.elapsedMilliseconds;
        outSink.writeln(
            '>>> BATCH END (${totalTests - testsFailed}/$totalTests) ${time}ms');
        exitCode = batchResult.ordinal;
      }
      // Prepare aruments.
      var args;
      {
        var lineArgs = line.split(new RegExp('\\s+'));
        args = new List<String>();
        args.addAll(sharedArgs);
        args.addAll(lineArgs);
        args.remove('-b');
        args.remove('--batch');
      }
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

/// [SdkExtUriResolver] needs a Map from package name to folder. In the case
/// that the analyzer is invoked with a --package-root option, we need to
/// manually create this mapping. Given [packageRootPath],
/// [_PackageRootPackageMapBuilder] creates a simple mapping from package name
/// to full path on disk (resolving any symbolic links).
class _PackageRootPackageMapBuilder {
  static Map<String, List<fileSystem.Folder>> buildPackageMap(
      String packageRootPath) {
    var packageRoot = new Directory(packageRootPath);
    if (!packageRoot.existsSync()) {
      throw new _DriverError(
          'Package root directory ($packageRootPath) does not exist.');
    }
    var packages = packageRoot.listSync(followLinks: false);
    var result = new Map<String, List<fileSystem.Folder>>();
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
