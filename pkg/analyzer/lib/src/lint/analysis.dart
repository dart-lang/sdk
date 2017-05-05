// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io' as io;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart'
    show File, Folder, ResourceProvider, ResourceUriResolver;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/project.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/util/sdk.dart';
import 'package:package_config/packages.dart' show Packages;
import 'package:package_config/packages_file.dart' as pkgfile show parse;
import 'package:package_config/src/packages_impl.dart' show MapPackages;
import 'package:path/path.dart' as p;
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';

Source createSource(Uri sourceUri) {
  return PhysicalResourceProvider.INSTANCE
      .getFile(sourceUri.toFilePath())
      .createSource(sourceUri);
}

/// Print the given message and exit with the given [exitCode]
void printAndFail(String message, {int exitCode: 15}) {
  print(message);
  io.exit(exitCode);
}

AnalysisOptions _buildAnalyzerOptions(DriverOptions options) {
  AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
  analysisOptions.strongMode = options.strongMode;
  analysisOptions.hint = false;
  analysisOptions.lint = options.enableLints;
  analysisOptions.generateSdkErrors = options.showSdkWarnings;
  analysisOptions.enableAssertInitializer = options.enableAssertInitializer;
  analysisOptions.enableTiming = options.enableTiming;
  return analysisOptions;
}

class DriverOptions {
  /// The maximum number of sources for which AST structures should be kept
  /// in the cache.  The default is 512.
  int cacheSize = 512;

  /// The path to the dart SDK.
  String dartSdkPath;

  /// Whether the parser is able to parse asserts in the initializer list of a
  /// constructor
  bool enableAssertInitializer = false;

  /// Whether to show lint warnings.
  bool enableLints = true;

  /// Whether to gather timing data during analysis.
  bool enableTiming = false;

  /// The path to a `.packages` configuration file
  String packageConfigPath;

  /// The path to the package root.
  String packageRootPath;

  /// Whether to show SDK warnings.
  bool showSdkWarnings = false;

  /// Whether to use Dart's Strong Mode analyzer.
  bool strongMode = true;

  /// The mock SDK (to speed up testing) or `null` to use the actual SDK.
  DartSdk mockSdk;

  /// Whether to show lints for the transitive closure of imported and exported
  /// libraries.
  bool visitTransitiveClosure = false;
}

class LintDriver {
  /// The sources which have been analyzed so far.  This is used to avoid
  /// analyzing a source more than once, and to compute the total number of
  /// sources analyzed for statistics.
  Set<Source> _sourcesAnalyzed = new HashSet<Source>();

  final LinterOptions options;

  LintDriver(this.options) {
    _processPlugins();
  }

  /// Return the number of sources that have been analyzed so far.
  int get numSourcesAnalyzed => _sourcesAnalyzed.length;

  List<UriResolver> get resolvers {
    // TODO(brianwilkerson) Use the context builder to compute all of the resolvers.
    ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
    ContextBuilder builder = new ContextBuilder(resourceProvider, null, null);

    DartSdk sdk = options.mockSdk ??
        new FolderBasedDartSdk(
            resourceProvider, resourceProvider.getFolder(sdkDir));

    List<UriResolver> resolvers = [new DartUriResolver(sdk)];

    if (options.packageRootPath != null) {
      // TODO(brianwilkerson) After 0.30.0 is published, clean up the following.
      try {
        // Try to use the post 0.30.0 API.
        (builder as dynamic).builderOptions.defaultPackagesDirectoryPath =
            options.packageRootPath;
      } catch (_) {
        // If that fails, fall back to the pre 0.30.0 API.
        (builder as dynamic).defaultPackagesDirectoryPath =
            options.packageRootPath;
      }
      Map<String, List<Folder>> packageMap =
          builder.convertPackagesToMap(builder.createPackageMap(null));
      resolvers.add(new PackageMapUriResolver(resourceProvider, packageMap));
    }

    // File URI resolver must come last so that files inside "/lib" are
    // are analyzed via "package:" URI's.
    resolvers.add(new ResourceUriResolver(resourceProvider));
    return resolvers;
  }

  String get sdkDir {
    // In case no SDK has been specified, fall back to inferring it.
    return options.dartSdkPath ?? getSdkPath();
  }

  List<AnalysisErrorInfo> analyze(Iterable<io.File> files) {
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    context.analysisOptions = _buildAnalyzerOptions(options);
    registerLinters(context);

    Packages packages = _getPackageConfig();

    context.sourceFactory = new SourceFactory(resolvers, packages);
    AnalysisEngine.instance.logger = new StdLogger();

    List<Source> sources = [];
    ChangeSet changeSet = new ChangeSet();
    for (io.File file in files) {
      File sourceFile = PhysicalResourceProvider.INSTANCE
          .getFile(p.normalize(file.absolute.path));
      Source source = sourceFile.createSource();
      Uri uri = context.sourceFactory.restoreUri(source);
      if (uri != null) {
        // Ensure that we analyze the file using its canonical URI (e.g. if
        // it's in "/lib", analyze it using a "package:" URI).
        source = sourceFile.createSource(uri);
      }
      sources.add(source);
      changeSet.addedSource(source);
    }
    context.applyChanges(changeSet);

    // Temporary location
    var project = new DartProject(context, sources);
    // This will get pushed into the generator (or somewhere comparable) when
    // we have a proper plugin.
    Registry.ruleRegistry.forEach((lint) {
      if (lint is ProjectVisitor) {
        (lint as ProjectVisitor).visit(project);
      }
    });

    List<AnalysisErrorInfo> errors = [];

    for (Source source in sources) {
      context.computeErrors(source);
      errors.add(context.getErrors(source));
      _sourcesAnalyzed.add(source);
    }

    if (options.visitTransitiveClosure) {
      // In the process of computing errors for all the sources in [sources],
      // the analyzer has visited the transitive closure of all libraries
      // referenced by those sources.  So now we simply need to visit all
      // library sources known to the analysis context, and all parts they
      // refer to.
      for (Source librarySource in context.librarySources) {
        for (Source source in _getAllUnitSources(context, librarySource)) {
          if (!_sourcesAnalyzed.contains(source)) {
            context.computeErrors(source);
            errors.add(context.getErrors(source));
            _sourcesAnalyzed.add(source);
          }
        }
      }
    }

    return errors;
  }

  void registerLinters(AnalysisContext context) {
    if (options.enableLints) {
      setLints(context, options.enabledLints?.toList(growable: false));
    }
  }

  /// Yield the sources for all the compilation units constituting
  /// [librarySource] (including the defining compilation unit).
  Iterable<Source> _getAllUnitSources(
      AnalysisContext context, Source librarySource) {
    List<Source> result = <Source>[librarySource];
    result.addAll(context
        .getLibraryElement(librarySource)
        .parts
        .map((CompilationUnitElement e) => e.source));
    return result;
  }

  Packages _getPackageConfig() {
    if (options.packageConfigPath != null) {
      String packageConfigPath = options.packageConfigPath;
      Uri fileUri = new Uri.file(packageConfigPath);
      try {
        io.File configFile = new io.File.fromUri(fileUri).absolute;
        List<int> bytes = configFile.readAsBytesSync();
        Map<String, Uri> map = pkgfile.parse(bytes, configFile.uri);
        return new MapPackages(map);
      } catch (e) {
        printAndFail(
            'Unable to read package config data from $packageConfigPath: $e');
      }
    }
    return null;
  }

  void _processPlugins() {
    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);
  }
}

/// Prints logging information comments to the [outSink] and error messages to
/// [errorSink].
class StdLogger extends Logger {
  @override
  void logError(String message, [exception]) => errorSink.writeln(message);
  @override
  void logInformation(String message, [exception]) => outSink.writeln(message);
}
