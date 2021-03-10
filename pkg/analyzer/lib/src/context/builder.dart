// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:core';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart'
    show AnalysisDriver, AnalysisDriverScheduler;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/package_build.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:yaml/yaml.dart';

/// A utility class used to build an analysis context for a given directory.
///
/// The construction of analysis contexts is as follows:
///
/// 1. Determine how package: URI's are to be resolved. This follows the lookup
///    algorithm defined by the [package specification][1].
///
/// 2. Using the results of step 1, look in each package for an embedder file
///    (_embedder.yaml). If one exists then it defines the SDK. If multiple such
///    files exist then use the first one found. Otherwise, use the default SDK.
///
/// 3. Look for an analysis options file (`analysis_options.yaml` or
///    `.analysis_options`) and process the options in the file.
///
/// 4. Create a new context. Initialize its source factory based on steps 1, 2
///    and 3. Initialize its analysis options from step 4.
///
/// [1]: https://github.com/dart-lang/dart_enhancement_proposals/blob/master/Accepted/0005%20-%20Package%20Specification/DEP-pkgspec.md.
class ContextBuilder {
  /// The [ResourceProvider] by which paths are converted into [Resource]s.
  final ResourceProvider resourceProvider;

  /// The manager used to manage the DartSdk's that have been created so that
  /// they can be shared across contexts.
  final DartSdkManager sdkManager;

  /// The cache containing the contents of overlaid files. If this builder will
  /// be used to build analysis drivers, set the [fileContentOverlay] instead.
  final ContentCache? contentCache;

  /// The options used by the context builder.
  final ContextBuilderOptions builderOptions;

  /// The scheduler used by any analysis drivers created through this interface.
  late final AnalysisDriverScheduler analysisDriverScheduler;

  /// The performance log used by any analysis drivers created through this
  /// interface.
  late final PerformanceLog performanceLog;

  /// If `true`, additional analysis data useful for testing is stored.
  bool retainDataForTesting = false;

  /// The byte store used by any analysis drivers created through this interface.
  late final ByteStore byteStore;

  /// The file content overlay used by analysis drivers. If this builder will be
  /// used to build analysis contexts, set the [contentCache] instead.
  FileContentOverlay? fileContentOverlay;

  /// Whether any analysis driver created through this interface should support
  /// indexing and search.
  bool enableIndex = false;

  /// Sometimes `BUILD` files are not preserved, and other files are created
  /// instead. But looking for them is expensive, so we want to avoid this
  /// in cases when `BUILD` files are always available.
  bool lookForBazelBuildFileSubstitutes = true;

  /// Initialize a newly created builder to be ready to build a context rooted in
  /// the directory with the given [rootDirectoryPath].
  ContextBuilder(this.resourceProvider, this.sdkManager, this.contentCache,
      {ContextBuilderOptions? options})
      : builderOptions = options ?? ContextBuilderOptions();

  /// Return an analysis driver that is configured correctly to analyze code in
  /// the directory with the given [path].
  AnalysisDriver buildDriver(ContextRoot contextRoot, Workspace workspace,
      {void Function(AnalysisOptionsImpl)? updateAnalysisOptions}) {
    String path = contextRoot.root;

    var options = getAnalysisOptions(path, workspace, contextRoot: contextRoot);

    if (updateAnalysisOptions != null) {
      updateAnalysisOptions(options);
    }
    //_processAnalysisOptions(context, optionMap);

    SummaryDataStore? summaryData;
    var librarySummaryPaths = builderOptions.librarySummaryPaths;
    if (librarySummaryPaths != null) {
      summaryData = SummaryDataStore(librarySummaryPaths);
    }

    final sf =
        createSourceFactoryFromWorkspace(workspace, summaryData: summaryData);

    AnalysisDriver driver = AnalysisDriver(
      analysisDriverScheduler,
      performanceLog,
      resourceProvider,
      byteStore,
      fileContentOverlay,
      contextRoot,
      sf,
      options,
      packages: createPackageMap(
        resourceProvider: resourceProvider,
        options: builderOptions,
        rootPath: path,
      ),
      enableIndex: enableIndex,
      externalSummaries: summaryData,
      retainDataForTesting: retainDataForTesting,
    );

    declareVariablesInDriver(driver);
    return driver;
  }

//  void _processAnalysisOptions(
//      AnalysisContext context, Map<String, YamlNode> optionMap) {
//    List<OptionsProcessor> optionsProcessors =
//        AnalysisEngine.instance.optionsPlugin.optionsProcessors;
//    try {
//      optionsProcessors.forEach(
//          (OptionsProcessor p) => p.optionsProcessed(context, optionMap));
//
//      // Fill in lint rule defaults in case lints are enabled and rules are
//      // not specified in an options file.
//      if (context.analysisOptions.lint && !containsLintRuleEntry(optionMap)) {
//        setLints(context, linterPlugin.contributedRules);
//      }
//
//      // Ask engine to further process options.
//      if (optionMap != null) {
//        configureContextOptions(context, optionMap);
//      }
//    } on Exception catch (e) {
//      optionsProcessors.forEach((OptionsProcessor p) => p.onError(e));
//    }
//  }

  SourceFactory createSourceFactory(String rootPath, Workspace workspace,
      {SummaryDataStore? summaryData}) {
    DartSdk sdk = findSdk(workspace);
    if (summaryData != null && sdk is SummaryBasedDartSdk) {
      summaryData.addBundle(null, sdk.bundle);
    }
    return workspace.createSourceFactory(sdk, summaryData);
  }

  SourceFactory createSourceFactoryFromWorkspace(Workspace workspace,
      {SummaryDataStore? summaryData}) {
    DartSdk sdk = findSdk(workspace);
    if (summaryData != null && sdk is SummaryBasedDartSdk) {
      summaryData.addBundle(null, sdk.bundle);
    }
    return workspace.createSourceFactory(sdk, summaryData);
  }

  /// Add any [declaredVariables] to the list of declared variables used by the
  /// given analysis [driver].
  void declareVariablesInDriver(AnalysisDriver driver) {
    var variables = builderOptions.declaredVariables;
    if (variables.isNotEmpty) {
      driver.declaredVariables = DeclaredVariables.fromMap(variables);
      driver.configure();
    }
  }

  /// Return the SDK that should be used to analyze code. Use the given
  /// [workspace] to locate the SDK.
  DartSdk findSdk(Workspace? workspace) {
    String? summaryPath = builderOptions.dartSdkSummaryPath;
    if (summaryPath != null) {
      return SummaryBasedDartSdk(summaryPath, true,
          resourceProvider: resourceProvider);
    }

    DartSdk folderSdk;
    {
      String sdkPath = sdkManager.defaultSdkDirectory;
      SdkDescription description = SdkDescription(sdkPath);
      folderSdk = sdkManager.getSdk(description, () {
        return FolderBasedDartSdk(
          resourceProvider,
          resourceProvider.getFolder(sdkPath),
        );
      });
    }

    if (workspace != null) {
      var partialSourceFactory = workspace.createSourceFactory(null, null);
      var embedderYamlSource = partialSourceFactory.forUri(
        'package:sky_engine/_embedder.yaml',
      );
      if (embedderYamlSource != null) {
        var embedderYamlPath = embedderYamlSource.fullName;
        var libFolder = resourceProvider.getFile(embedderYamlPath).parent2;
        EmbedderYamlLocator locator =
            EmbedderYamlLocator.forLibFolder(libFolder);
        Map<Folder, YamlMap> embedderMap = locator.embedderYamls;
        if (embedderMap.isNotEmpty) {
          EmbedderSdk embedderSdk = EmbedderSdk(
            resourceProvider,
            embedderMap,
            languageVersion: folderSdk.languageVersion,
          );
          return embedderSdk;
        }
      }
    }

    return folderSdk;
  }

  /// Return the analysis options that should be used to analyze code in the
  /// directory with the given [path]. Use [verbosePrint] to echo verbose
  /// information about the analysis options selection process.
  AnalysisOptionsImpl getAnalysisOptions(String path, Workspace workspace,
      {void Function(String text)? verbosePrint, ContextRoot? contextRoot}) {
    void verbose(String text) {
      if (verbosePrint != null) {
        verbosePrint(text);
      }
    }

    SourceFactory sourceFactory = workspace.createSourceFactory(null, null);
    AnalysisOptionsProvider optionsProvider =
        AnalysisOptionsProvider(sourceFactory);

    AnalysisOptionsImpl options = AnalysisOptionsImpl();

    var optionsPath = builderOptions.defaultAnalysisOptionsFilePath;
    if (optionsPath != null) {
      var optionsFile = resourceProvider.getFile(optionsPath);
      try {
        contextRoot?.optionsFilePath = optionsFile.path;
        var optionsMap = optionsProvider.getOptionsFromFile(optionsFile);
        applyToAnalysisOptions(options, optionsMap);
        verbose('Loaded analysis options from ${optionsFile.path}');
      } catch (e) {
        // Ignore exceptions thrown while trying to load the options file.
        verbose('Exception: $e\n  when loading ${optionsFile.path}');
      }
    } else {
      verbose('Using default analysis options');
    }

    var pubspecFile = _findPubspecFile(path);
    if (pubspecFile != null) {
      var extractor = SdkConstraintExtractor(pubspecFile);
      var sdkVersionConstraint = extractor.constraint();
      if (sdkVersionConstraint != null) {
        options.sdkVersionConstraint = sdkVersionConstraint;
      }
    }

    return options;
  }

  /// Return the `pubspec.yaml` file that should be used when analyzing code in
  /// the directory with the given [path], possibly `null`.
  File? _findPubspecFile(String path) {
    var folder = resourceProvider.getFolder(path);
    for (var current in folder.withAncestors) {
      var file = current.getChildAssumingFile('pubspec.yaml');
      if (file.exists) {
        return file;
      }
    }
  }

  /// Return [Packages] to analyze a resource with the [rootPath].
  static Packages createPackageMap({
    required ResourceProvider resourceProvider,
    required ContextBuilderOptions options,
    required String rootPath,
  }) {
    var configPath = options.defaultPackageFilePath;
    if (configPath != null) {
      var configFile = resourceProvider.getFile(configPath);
      return parsePackagesFile(resourceProvider, configFile);
    } else {
      var resource = resourceProvider.getResource(rootPath);
      return findPackagesFrom(resourceProvider, resource);
    }
  }

  /// If [packages] is provided, it will be used for the [Workspace],
  /// otherwise the packages file from [options] will be used, or discovered
  /// from [rootPath].
  ///
  /// TODO(scheglov) Make [packages] required, remove [options] and discovery.
  static Workspace createWorkspace({
    required ResourceProvider resourceProvider,
    required ContextBuilderOptions options,
    Packages? packages,
    required String rootPath,
    bool lookForBazelBuildFileSubstitutes = true,
  }) {
    packages ??= ContextBuilder.createPackageMap(
      resourceProvider: resourceProvider,
      options: options,
      rootPath: rootPath,
    );
    var packageMap = <String, List<Folder>>{};
    for (var package in packages.packages) {
      packageMap[package.name] = [package.libFolder];
    }

    if (_hasPackageFileInPath(resourceProvider, rootPath)) {
      // A Bazel or Gn workspace that includes a '.packages' file is treated
      // like a normal (non-Bazel/Gn) directory. But may still use
      // package:build or Pub.
      return PackageBuildWorkspace.find(
              resourceProvider, packageMap, rootPath) ??
          PubWorkspace.find(resourceProvider, packageMap, rootPath) ??
          BasicWorkspace.find(resourceProvider, packageMap, rootPath);
    }
    Workspace? workspace = BazelWorkspace.find(resourceProvider, rootPath,
        lookForBuildFileSubstitutes: lookForBazelBuildFileSubstitutes);
    workspace ??= GnWorkspace.find(resourceProvider, rootPath);
    workspace ??=
        PackageBuildWorkspace.find(resourceProvider, packageMap, rootPath);
    workspace ??= PubWorkspace.find(resourceProvider, packageMap, rootPath);
    workspace ??= BasicWorkspace.find(resourceProvider, packageMap, rootPath);
    return workspace;
  }

  /// Return `true` if either the directory at [rootPath] or a parent of that
  /// directory contains a `.packages` file.
  static bool _hasPackageFileInPath(
      ResourceProvider resourceProvider, String rootPath) {
    var folder = resourceProvider.getFolder(rootPath);
    return folder.withAncestors.any((current) {
      return current.getChildAssumingFile('.packages').exists;
    });
  }
}

/// Options used by a [ContextBuilder].
class ContextBuilderOptions {
  /// The file path of the file containing the summary of the SDK that should be
  /// used to "analyze" the SDK. This option should only be specified by
  /// command-line tools such as 'dartanalyzer' or 'ddc'.
  String? dartSdkSummaryPath;

  /// The file path of the analysis options file that should be used in place of
  /// any file in the root directory or a parent of the root directory, or `null`
  /// if the normal lookup mechanism should be used.
  String? defaultAnalysisOptionsFilePath;

  /// A table mapping variable names to values for the declared variables.
  Map<String, String> declaredVariables = {};

  /// The file path of the .packages file that should be used in place of any
  /// file found using the normal (Package Specification DEP) lookup mechanism,
  /// or `null` if the normal lookup mechanism should be used.
  String? defaultPackageFilePath;

  /// A list of the paths of summary files that are to be used, or `null` if no
  /// summary information is available.
  List<String>? librarySummaryPaths;

  /// Initialize a newly created set of options
  ContextBuilderOptions();
}

/// Given a package map, check in each package's lib directory for the existence
/// of an `_embedder.yaml` file. If the file contains a top level YamlMap, it
/// will be added to the [embedderYamls] map.
class EmbedderYamlLocator {
  /// The name of the embedder files being searched for.
  static const String EMBEDDER_FILE_NAME = '_embedder.yaml';

  /// A mapping from a package's library directory to the parsed YamlMap.
  final Map<Folder, YamlMap> embedderYamls = HashMap<Folder, YamlMap>();

  /// Initialize a newly created locator by processing the packages in the given
  /// [packageMap].
  EmbedderYamlLocator(Map<String, List<Folder>>? packageMap) {
    if (packageMap != null) {
      _processPackageMap(packageMap);
    }
  }

  /// Initialize with the given [libFolder] of `sky_engine` package.
  EmbedderYamlLocator.forLibFolder(Folder libFolder) {
    _processPackage([libFolder]);
  }

  /// Programmatically add an `_embedder.yaml` mapping.
  void addEmbedderYaml(Folder libDir, String embedderYaml) {
    _processEmbedderYaml(libDir, embedderYaml);
  }

  /// Refresh the map of located files to those found by processing the given
  /// [packageMap].
  void refresh(Map<String, List<Folder>>? packageMap) {
    // Clear existing.
    embedderYamls.clear();
    if (packageMap != null) {
      _processPackageMap(packageMap);
    }
  }

  /// Given the yaml for an embedder ([embedderYaml]) and a folder ([libDir]),
  /// setup the uri mapping.
  void _processEmbedderYaml(Folder libDir, String embedderYaml) {
    try {
      YamlNode yaml = loadYaml(embedderYaml);
      if (yaml is YamlMap) {
        embedderYamls[libDir] = yaml;
      }
    } catch (_) {
      // Ignored
    }
  }

  /// Given a package list of folders ([libDirs]), process any
  /// `_embedder.yaml` files that are found in any of the folders.
  void _processPackage(List<Folder> libDirs) {
    for (Folder libDir in libDirs) {
      String? embedderYaml = _readEmbedderYaml(libDir);
      if (embedderYaml != null) {
        _processEmbedderYaml(libDir, embedderYaml);
      }
    }
  }

  /// Process each of the entries in the [packageMap].
  void _processPackageMap(Map<String, List<Folder>> packageMap) {
    packageMap.values.forEach(_processPackage);
  }

  /// Read and return the contents of [libDir]/[EMBEDDER_FILE_NAME], or `null`
  /// if the file doesn't exist.
  String? _readEmbedderYaml(Folder libDir) {
    var file = libDir.getChildAssumingFile(EMBEDDER_FILE_NAME);
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      // File can't be read.
      return null;
    }
  }
}
