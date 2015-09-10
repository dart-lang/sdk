// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.analysis;

import 'dart:collection';
import 'dart:io';

import 'package:analyzer/file_system/file_system.dart' show Folder;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:linter/src/io.dart';
import 'package:linter/src/project.dart';
import 'package:linter/src/rules.dart';
import 'package:package_config/packages.dart' show Packages;
import 'package:package_config/packages_file.dart' as pkgfile show parse;
import 'package:package_config/src/packages_impl.dart' show MapPackages;
import 'package:path/path.dart' as p;

Source createSource(Uri sourceUri) =>
    new FileBasedSource(new JavaFile(sourceUri.toFilePath()));

/// Print the given message and exit with the given [exitCode]
void printAndFail(String message, {int exitCode: 15}) {
  print(message);
  exit(exitCode);
}

AnalysisOptions _buildAnalyzerOptions(DriverOptions options) {
  AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
  analysisOptions.cacheSize = options.cacheSize;
  analysisOptions.hint = false;
  analysisOptions.lint = options.enableLints;
  analysisOptions.generateSdkErrors = options.showSdkWarnings;
  return analysisOptions;
}

class AnalysisDriver {
  /// The sources which have been analyzed so far.  This is used to avoid
  /// analyzing a source more than once, and to compute the total number of
  /// sources analyzed for statistics.
  Set<Source> _sourcesAnalyzed = new HashSet<Source>();

  final DriverOptions options;

  AnalysisDriver(this.options);

  /// Return the number of sources that have been analyzed so far.
  int get numSourcesAnalyzed => _sourcesAnalyzed.length;

  List<UriResolver> get resolvers {
    DartSdk sdk = new DirectoryBasedDartSdk(new JavaFile(sdkDir));
    List<UriResolver> resolvers = [new DartUriResolver(sdk)];
    if (options.packageRootPath != null) {
      JavaFile packageDirectory = new JavaFile(options.packageRootPath);
      resolvers.add(new PackageUriResolver([packageDirectory]));
    } else {
      PubPackageMapProvider pubPackageMapProvider = new PubPackageMapProvider(
          PhysicalResourceProvider.INSTANCE, sdk, options.runPubList);
      PackageMapInfo packageMapInfo = pubPackageMapProvider.computePackageMap(
          PhysicalResourceProvider.INSTANCE.getResource('.'));
      Map<String, List<Folder>> packageMap = packageMapInfo.packageMap;
      if (packageMap != null) {
        resolvers.add(new PackageMapUriResolver(
            PhysicalResourceProvider.INSTANCE, packageMap));
      }
    }
    // File URI resolver must come last so that files inside "/lib" are
    // are analyzed via "package:" URI's.
    resolvers.add(new FileUriResolver());
    return resolvers;
  }

  String get sdkDir {
    if (options.dartSdkPath != null) {
      return options.dartSdkPath;
    }
    // In case no SDK has been specified, fall back to inferring it
    // TODO: pass args to cli_util
    return cli_util.getSdkDir().path;
  }

  List<AnalysisErrorInfo> analyze(Iterable<File> files) {
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    context.analysisOptions = _buildAnalyzerOptions(options);

    Packages packages = _getPackageConfig();

    context.sourceFactory = new SourceFactory(resolvers, packages);
    AnalysisEngine.instance.logger = new StdLogger();

    List<Source> sources = [];
    ChangeSet changeSet = new ChangeSet();
    for (File file in files) {
      JavaFile sourceFile = new JavaFile(p.normalize(file.absolute.path));
      Source source = new FileBasedSource(sourceFile, sourceFile.toURI());
      Uri uri = context.sourceFactory.restoreUri(source);
      if (uri != null) {
        // Ensure that we analyze the file using its canonical URI (e.g. if
        // it's in "/lib", analyze it using a "package:" URI).
        source = new FileBasedSource(sourceFile, uri);
      }
      sources.add(source);
      changeSet.addedSource(source);
    }
    context.applyChanges(changeSet);

    // Temporary location
    var project = new DartProject(context, sources);
    // This will get pushed into the generator (or somewhere comparable) when
    // we have a proper plugin.
    ruleRegistry.forEach((lint) {
      if (lint is ProjectVisitor) {
        lint.visit(project);
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
        File configFile = new File.fromUri(fileUri).absolute;
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
}

class DriverOptions {
  /// The maximum number of sources for which AST structures should be kept
  /// in the cache.  The default is 512.
  int cacheSize = 512;

  /// The path to the dart SDK.
  String dartSdkPath;

  /// Whether to show lint warnings.
  bool enableLints = true;

  /// The path to a `.packages` configuration file
  String packageConfigPath;

  /// The path to the package root.
  String packageRootPath;

  /// Whether to show SDK warnings.
  bool showSdkWarnings = false;

  /// Whether to show lints for the transitive closure of imported and exported
  /// libraries.
  bool visitTransitiveClosure = false;

  /// If non-null, the function to use to run pub list.  This is used to mock
  /// out executions of pub list when testing the linter.
  RunPubList runPubList = null;
}

/// Prints logging information comments to the [outSink] and error messages to
/// [errorSink].
class StdLogger extends Logger {
  @override
  void logError(String message, [exception]) => errorSink.writeln(message);
  @override
  void logError2(String message, dynamic exception) =>
      errorSink.writeln(message);
  @override
  void logInformation(String message, [exception]) => outSink.writeln(message);
  @override
  void logInformation2(String message, dynamic exception) =>
      outSink.writeln(message);
}
