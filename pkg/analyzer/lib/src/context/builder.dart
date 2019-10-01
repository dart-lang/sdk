// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:core';

import 'package:analyzer/dart/analysis/analysis_context.dart' as api;
import 'package:analyzer/dart/analysis/context_locator.dart' as api;
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/command_line/arguments.dart'
    show
        applyAnalysisOptionFlags,
        bazelAnalysisOptionsPath,
        flutterAnalysisOptionsPath;
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart' as api;
import 'package:analyzer/src/dart/analysis/driver.dart'
    show AnalysisDriver, AnalysisDriverScheduler;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    as api;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer/src/plugin/resolver_provider.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/package_build.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:args/args.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/packages_file.dart';
import 'package:package_config/src/packages_impl.dart';
import 'package:path/src/context.dart';
import 'package:yaml/yaml.dart';

/**
 * A utility class used to build an analysis context for a given directory.
 *
 * The construction of analysis contexts is as follows:
 *
 * 1. Determine how package: URI's are to be resolved. This follows the lookup
 *    algorithm defined by the [package specification][1].
 *
 * 2. Using the results of step 1, look in each package for an embedder file
 *    (_embedder.yaml). If one exists then it defines the SDK. If multiple such
 *    files exist then use the first one found. Otherwise, use the default SDK.
 *
 * 3. Look in each package for an SDK extension file (_sdkext). For each such
 *    file, add the specified files to the SDK.
 *
 * 4. Look for an analysis options file (`analysis_options.yaml` or
 *    `.analysis_options`) and process the options in the file.
 *
 * 5. Create a new context. Initialize its source factory based on steps 1, 2
 *    and 3. Initialize its analysis options from step 4.
 *
 * [1]: https://github.com/dart-lang/dart_enhancement_proposals/blob/master/Accepted/0005%20-%20Package%20Specification/DEP-pkgspec.md.
 */
class ContextBuilder {
  /**
   * A callback for when analysis drivers are created, which takes all the same
   * arguments as the dart analysis driver constructor so that plugins may
   * create their own drivers with the same tools, in theory. Here as a stopgap
   * until the official plugin API is complete
   */
  static Function onCreateAnalysisDriver;

  /**
   * The [ResourceProvider] by which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  /**
   * The manager used to manage the DartSdk's that have been created so that
   * they can be shared across contexts.
   */
  final DartSdkManager sdkManager;

  /**
   * The cache containing the contents of overlaid files. If this builder will
   * be used to build analysis drivers, set the [fileContentOverlay] instead.
   */
  final ContentCache contentCache;

  /**
   * The options used by the context builder.
   */
  final ContextBuilderOptions builderOptions;

  /**
   * The resolver provider used to create a package: URI resolver, or `null` if
   * the normal (Package Specification DEP) lookup mechanism is to be used.
   */
  ResolverProvider packageResolverProvider;

  /**
   * The resolver provider used to create a file: URI resolver, or `null` if
   * the normal file URI resolver is to be used.
   */
  ResolverProvider fileResolverProvider;

  /**
   * The scheduler used by any analysis drivers created through this interface.
   */
  AnalysisDriverScheduler analysisDriverScheduler;

  /**
   * The performance log used by any analysis drivers created through this
   * interface.
   */
  PerformanceLog performanceLog;

  /**
   * The byte store used by any analysis drivers created through this interface.
   */
  ByteStore byteStore;

  /**
   * The file content overlay used by analysis drivers. If this builder will be
   * used to build analysis contexts, set the [contentCache] instead.
   */
  FileContentOverlay fileContentOverlay;

  /**
   * Whether any analysis driver created through this interface should support
   * indexing and search.
   */
  bool enableIndex = false;

  /**
   * Initialize a newly created builder to be ready to build a context rooted in
   * the directory with the given [rootDirectoryPath].
   */
  ContextBuilder(this.resourceProvider, this.sdkManager, this.contentCache,
      {ContextBuilderOptions options})
      : builderOptions = options ?? new ContextBuilderOptions();

  /**
   * Return an analysis context that is configured correctly to analyze code in
   * the directory with the given [path].
   *
   * *Note:* This method is not yet fully implemented and should not be used.
   */
  AnalysisContext buildContext(String path) {
    InternalAnalysisContext context =
        AnalysisEngine.instance.createAnalysisContext();
    AnalysisOptionsImpl options = getAnalysisOptions(path);
    context.sourceFactory = createSourceFactory(path, options);
    context.analysisOptions = options;
    //_processAnalysisOptions(context, optionMap);
    declareVariables(context);
    return context;
  }

  /**
   * Return an analysis driver that is configured correctly to analyze code in
   * the directory with the given [path].
   */
  AnalysisDriver buildDriver(ContextRoot contextRoot) {
    String path = contextRoot.root;
    AnalysisOptions options =
        getAnalysisOptions(path, contextRoot: contextRoot);
    //_processAnalysisOptions(context, optionMap);
    SummaryDataStore summaryData;
    if (builderOptions.librarySummaryPaths != null) {
      summaryData = SummaryDataStore(builderOptions.librarySummaryPaths);
    }
    final sf = createSourceFactory(path, options, summaryData: summaryData);

    AnalysisDriver driver = new AnalysisDriver(
        analysisDriverScheduler,
        performanceLog,
        resourceProvider,
        byteStore,
        fileContentOverlay,
        contextRoot,
        sf,
        options,
        enableIndex: enableIndex,
        externalSummaries: summaryData);

    // Set API AnalysisContext for the driver.
    var apiContextRoots = api.ContextLocator(
      resourceProvider: resourceProvider,
    ).locateRoots(
      includedPaths: [contextRoot.root],
      excludedPaths: contextRoot.exclude,
    );
    driver.analysisContext = api.DriverBasedAnalysisContext(
      resourceProvider,
      apiContextRoots.first,
      driver,
    );

    // temporary plugin support:
    if (onCreateAnalysisDriver != null) {
      onCreateAnalysisDriver(driver, analysisDriverScheduler, performanceLog,
          resourceProvider, byteStore, fileContentOverlay, path, sf, options);
    }
    declareVariablesInDriver(driver);
    return driver;
  }

  Map<String, List<Folder>> convertPackagesToMap(Packages packages) {
    Map<String, List<Folder>> folderMap = new HashMap<String, List<Folder>>();
    if (packages != null && packages != Packages.noPackages) {
      var pathContext = resourceProvider.pathContext;
      packages.asMap().forEach((String packageName, Uri uri) {
        String path = fileUriToNormalizedPath(pathContext, uri);
        folderMap[packageName] = [resourceProvider.getFolder(path)];
      });
    }
    return folderMap;
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

  /**
   * Return an analysis options object containing the default option values.
   */
  AnalysisOptions createDefaultOptions() {
    AnalysisOptions defaultOptions = builderOptions.defaultOptions;
    if (defaultOptions == null) {
      return new AnalysisOptionsImpl();
    }
    return new AnalysisOptionsImpl.from(defaultOptions);
  }

  Packages createPackageMap(String rootDirectoryPath) {
    String filePath = builderOptions.defaultPackageFilePath;
    if (filePath != null) {
      File configFile = resourceProvider.getFile(filePath);
      List<int> bytes = configFile.readAsBytesSync();
      Map<String, Uri> map = parse(bytes, configFile.toUri());
      resolveSymbolicLinks(map);
      return new MapPackages(map);
    }
    String directoryPath = builderOptions.defaultPackagesDirectoryPath;
    if (directoryPath != null) {
      Folder folder = resourceProvider.getFolder(directoryPath);
      return getPackagesFromFolder(folder);
    }
    return findPackagesFromFile(rootDirectoryPath);
  }

  SourceFactory createSourceFactory(String rootPath, AnalysisOptions options,
      {SummaryDataStore summaryData}) {
    Workspace workspace =
        ContextBuilder.createWorkspace(resourceProvider, rootPath, this);
    DartSdk sdk = findSdk(workspace.packageMap, options);
    if (summaryData != null && sdk is SummaryBasedDartSdk) {
      summaryData.addBundle(null, sdk.bundle);
    }
    return workspace.createSourceFactory(sdk, summaryData);
  }

  /**
   * Add any [declaredVariables] to the list of declared variables used by the
   * given [context].
   */
  void declareVariables(AnalysisContextImpl context) {
    Map<String, String> variables = builderOptions.declaredVariables;
    if (variables != null && variables.isNotEmpty) {
      context.declaredVariables = new DeclaredVariables.fromMap(variables);
    }
  }

  /**
   * Add any [declaredVariables] to the list of declared variables used by the
   * given analysis [driver].
   */
  void declareVariablesInDriver(AnalysisDriver driver) {
    Map<String, String> variables = builderOptions.declaredVariables;
    if (variables != null && variables.isNotEmpty) {
      driver.declaredVariables = new DeclaredVariables.fromMap(variables);
    }
  }

  /**
   * Finds a package resolution strategy for the directory at the given absolute
   * [path].
   *
   * This function first tries to locate a `.packages` file in the directory. If
   * that is not found, it instead checks for the presence of a `packages/`
   * directory in the same place. If that also fails, it starts checking parent
   * directories for a `.packages` file, and stops if it finds it. Otherwise it
   * gives up and returns [Packages.noPackages].
   */
  Packages findPackagesFromFile(String path) {
    Resource location = _findPackagesLocation(path);
    if (location is File) {
      List<int> fileBytes = location.readAsBytesSync();
      Map<String, Uri> map;
      try {
        map =
            parse(fileBytes, resourceProvider.pathContext.toUri(location.path));
      } catch (exception) {
        // If we cannot read the file, then we respond as if the file did not
        // exist.
        return Packages.noPackages;
      }
      resolveSymbolicLinks(map);
      return new MapPackages(map);
    } else if (location is Folder) {
      return getPackagesFromFolder(location);
    }
    return Packages.noPackages;
  }

  /**
   * Return the SDK that should be used to analyze code. Use the given
   * [packageMap] and [analysisOptions] to locate the SDK.
   */
  DartSdk findSdk(
      Map<String, List<Folder>> packageMap, AnalysisOptions analysisOptions) {
    String summaryPath = builderOptions.dartSdkSummaryPath;
    if (summaryPath != null) {
      return new SummaryBasedDartSdk(summaryPath, true,
          resourceProvider: resourceProvider);
    } else if (packageMap != null) {
      SdkExtensionFinder extFinder = new SdkExtensionFinder(packageMap);
      List<String> extFilePaths = extFinder.extensionFilePaths;
      EmbedderYamlLocator locator = new EmbedderYamlLocator(packageMap);
      Map<Folder, YamlMap> embedderYamls = locator.embedderYamls;
      EmbedderSdk embedderSdk =
          new EmbedderSdk(resourceProvider, embedderYamls);
      if (embedderSdk.sdkLibraries.isNotEmpty) {
        //
        // There is an embedder file that defines the content of the SDK and
        // there might be an extension file that extends it.
        //
        List<String> paths = <String>[];
        for (Folder folder in embedderYamls.keys) {
          paths.add(folder
              .getChildAssumingFile(EmbedderYamlLocator.EMBEDDER_FILE_NAME)
              .path);
        }
        paths.addAll(extFilePaths);
        SdkDescription description = new SdkDescription(paths, analysisOptions);
        DartSdk dartSdk = sdkManager.getSdk(description, () {
          if (extFilePaths.isNotEmpty) {
            embedderSdk.addExtensions(extFinder.urlMappings);
          }
          embedderSdk.analysisOptions = analysisOptions;
          embedderSdk.useSummary = sdkManager.canUseSummaries;
          return embedderSdk;
        });
        return dartSdk;
      } else if (extFilePaths != null && extFilePaths.isNotEmpty) {
        //
        // We have an extension file, but no embedder file.
        //
        String sdkPath = sdkManager.defaultSdkDirectory;
        List<String> paths = <String>[sdkPath];
        paths.addAll(extFilePaths);
        SdkDescription description = new SdkDescription(paths, analysisOptions);
        return sdkManager.getSdk(description, () {
          FolderBasedDartSdk sdk = new FolderBasedDartSdk(
              resourceProvider, resourceProvider.getFolder(sdkPath));
          if (extFilePaths.isNotEmpty) {
            sdk.addExtensions(extFinder.urlMappings);
          }
          sdk.analysisOptions = analysisOptions;
          sdk.useSummary = sdkManager.canUseSummaries;
          return sdk;
        });
      }
    }
    String sdkPath = sdkManager.defaultSdkDirectory;
    SdkDescription description =
        new SdkDescription(<String>[sdkPath], analysisOptions);
    return sdkManager.getSdk(description, () {
      FolderBasedDartSdk sdk = new FolderBasedDartSdk(
          resourceProvider, resourceProvider.getFolder(sdkPath), true);
      sdk.analysisOptions = analysisOptions;
      sdk.useSummary = sdkManager.canUseSummaries;
      return sdk;
    });
  }

  /**
   * Return the analysis options that should be used to analyze code in the
   * directory with the given [path]. Use [verbosePrint] to echo verbose
   * information about the analysis options selection process.
   */
  AnalysisOptions getAnalysisOptions(String path,
      {void verbosePrint(String text), ContextRoot contextRoot}) {
    void verbose(String text) {
      if (verbosePrint != null) {
        verbosePrint(text);
      }
    }

    // TODO(danrubel) restructure so that we don't create a workspace
    // both here and in createSourceFactory
    Workspace workspace =
        ContextBuilder.createWorkspace(resourceProvider, path, this);
    SourceFactory sourceFactory = workspace.createSourceFactory(null, null);
    AnalysisOptionsProvider optionsProvider =
        new AnalysisOptionsProvider(sourceFactory);

    AnalysisOptionsImpl options = createDefaultOptions();
    File optionsFile = getOptionsFile(path);
    YamlMap optionMap;

    if (optionsFile != null) {
      try {
        optionMap = optionsProvider.getOptionsFromFile(optionsFile);
        if (contextRoot != null) {
          contextRoot.optionsFilePath = optionsFile.path;
        }
        verbose('Loaded analysis options from ${optionsFile.path}');
      } catch (e) {
        // Ignore exceptions thrown while trying to load the options file.
        verbose('Exception: $e\n  when loading ${optionsFile.path}');
      }
    } else {
      // Search for the default analysis options.
      // TODO(danrubel) determine if bazel or gn project depends upon flutter
      Source source;
      if (workspace.hasFlutterDependency) {
        source = sourceFactory.forUri(flutterAnalysisOptionsPath);
      }
      if (source == null || !source.exists()) {
        source = sourceFactory.forUri(bazelAnalysisOptionsPath);
      }

      if (source != null && source.exists()) {
        try {
          optionMap = optionsProvider.getOptionsFromSource(source);
          if (contextRoot != null) {
            contextRoot.optionsFilePath = source.fullName;
          }
          verbose('Loaded analysis options from ${source.fullName}');
        } catch (e) {
          // Ignore exceptions thrown while trying to load the options file.
          verbose('Exception: $e\n  when loading ${source.fullName}');
        }
      }
    }

    if (optionMap != null) {
      applyToAnalysisOptions(options, optionMap);
      if (builderOptions.argResults != null) {
        applyAnalysisOptionFlags(options, builderOptions.argResults,
            verbosePrint: verbosePrint);
      }
    } else {
      verbose('Using default analysis options');
    }

    var pubspecFile = _findPubspecFile(path);
    if (pubspecFile != null) {
      var extractor = new SdkConstraintExtractor(pubspecFile);
      var sdkVersionConstraint = extractor.constraint();
      if (sdkVersionConstraint != null) {
        options.sdkVersionConstraint = sdkVersionConstraint;
      }
    }

    return options;
  }

  /**
   * Return the analysis options file that should be used when analyzing code in
   * the directory with the given [path].
   *
   * If [forceSearch] is true, then don't return the default analysis options
   * path. This allows cli to locate what *would* have been the analysis options
   * file path, and super-impose the defaults over it in-place.
   */
  File getOptionsFile(String path, {bool forceSearch: false}) {
    if (!forceSearch) {
      String filePath = builderOptions.defaultAnalysisOptionsFilePath;
      if (filePath != null) {
        return resourceProvider.getFile(filePath);
      }
    }
    Folder root = resourceProvider.getFolder(path);
    for (Folder folder = root; folder != null; folder = folder.parent) {
      File file =
          folder.getChildAssumingFile(AnalysisEngine.ANALYSIS_OPTIONS_FILE);
      if (file.exists) {
        return file;
      }
      file = folder
          .getChildAssumingFile(AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
      if (file.exists) {
        return file;
      }
    }
    return null;
  }

  /**
   * Create a [Packages] object for a 'package' directory ([folder]).
   *
   * Package names are resolved as relative to sub-directories of the package
   * directory.
   */
  Packages getPackagesFromFolder(Folder folder) {
    Context pathContext = resourceProvider.pathContext;
    Map<String, Uri> map = new HashMap<String, Uri>();
    for (Resource child in folder.getChildren()) {
      if (child is Folder) {
        // Inline resolveSymbolicLinks for performance reasons.
        String packageName = pathContext.basename(child.path);
        String folderPath = resolveSymbolicLink(child);
        String uriPath = pathContext.join(folderPath, '.');
        map[packageName] = pathContext.toUri(uriPath);
      }
    }
    return new MapPackages(map);
  }

  /**
   * Resolve any symbolic links encoded in the path to the given [folder].
   */
  String resolveSymbolicLink(Folder folder) {
    try {
      return folder.resolveSymbolicLinksSync().path;
    } on FileSystemException {
      return folder.path;
    }
  }

  /**
   * Resolve any symbolic links encoded in the URI's in the given [map] by
   * replacing the values in the map.
   */
  void resolveSymbolicLinks(Map<String, Uri> map) {
    Context pathContext = resourceProvider.pathContext;
    for (String packageName in map.keys) {
      var uri = map[packageName];
      String path = fileUriToNormalizedPath(pathContext, uri);
      Folder folder = resourceProvider.getFolder(path);
      String folderPath = resolveSymbolicLink(folder);
      // Add a '.' so that the URI is suitable for resolving relative URI's
      // against it.
      String uriPath = pathContext.join(folderPath, '.');
      map[packageName] = pathContext.toUri(uriPath);
    }
  }

  /**
   * Find the location of the package resolution file/directory for the
   * directory at the given absolute [path].
   *
   * Checks for a `.packages` file in the [path]. If not found,
   * checks for a `packages` directory in the same directory. If still not
   * found, starts checking parent directories for `.packages` until reaching
   * the root directory.
   *
   * Return a [File] object representing a `.packages` file if one is found, a
   * [Folder] object for the `packages/` directory if that is found, or `null`
   * if neither is found.
   */
  Resource _findPackagesLocation(String path) {
    Folder folder = resourceProvider.getFolder(path);
    if (!folder.exists) {
      return null;
    }

    File checkForConfigFile(Folder folder) {
      File file = folder.getChildAssumingFile('.packages');
      if (file.exists) {
        return file;
      }
      return null;
    }

    // Check for $cwd/.packages
    File packagesCfgFile = checkForConfigFile(folder);
    if (packagesCfgFile != null) {
      return packagesCfgFile;
    }
    // Check for $cwd/packages/
    Folder packagesDir = folder.getChildAssumingFolder("packages");
    if (packagesDir.exists) {
      return packagesDir;
    }
    // Check for cwd(/..)+/.packages
    Folder parentDir = folder.parent;
    while (parentDir != null) {
      packagesCfgFile = checkForConfigFile(parentDir);
      if (packagesCfgFile != null) {
        return packagesCfgFile;
      }
      parentDir = parentDir.parent;
    }
    return null;
  }

  /**
   * Return the `pubspec.yaml` file that should be used when analyzing code in
   * the directory with the given [path], possibly `null`.
   */
  File _findPubspecFile(String path) {
    var resource = resourceProvider.getResource(path);
    while (resource != null) {
      if (resource is Folder) {
        File pubspecFile = resource.getChildAssumingFile('pubspec.yaml');
        if (pubspecFile.exists) {
          return pubspecFile;
        }
      }
      resource = resource.parent;
    }
    return null;
  }

  /**
   * Return `true` if either the directory at [rootPath] or a parent of that
   * directory contains a `.packages` file.
   */
  static bool _hasPackageFileInPath(
      ResourceProvider resourceProvider, String rootPath) {
    Folder folder = resourceProvider.getFolder(rootPath);
    while (folder != null) {
      File file = folder.getChildAssumingFile('.packages');
      if (file.exists) {
        return true;
      }
      folder = folder.parent;
    }
    return false;
  }

  static Workspace createWorkspace(ResourceProvider resourceProvider,
      String rootPath, ContextBuilder contextBuilder) {
    if (_hasPackageFileInPath(resourceProvider, rootPath)) {
      // A Bazel or Gn workspace that includes a '.packages' file is treated
      // like a normal (non-Bazel/Gn) directory. But may still use
      // package:build or Pub.
      return PackageBuildWorkspace.find(
              resourceProvider, rootPath, contextBuilder) ??
          PubWorkspace.find(resourceProvider, rootPath, contextBuilder) ??
          BasicWorkspace.find(resourceProvider, rootPath, contextBuilder);
    }
    Workspace workspace = BazelWorkspace.find(resourceProvider, rootPath);
    workspace ??= GnWorkspace.find(resourceProvider, rootPath);
    workspace ??=
        PackageBuildWorkspace.find(resourceProvider, rootPath, contextBuilder);
    workspace ??= PubWorkspace.find(resourceProvider, rootPath, contextBuilder);
    return workspace ??
        BasicWorkspace.find(resourceProvider, rootPath, contextBuilder);
  }
}

/**
 * Options used by a [ContextBuilder].
 */
class ContextBuilderOptions {
  /**
   * The results of parsing the command line arguments as defined by
   * [defineAnalysisArguments] or `null` if none.
   */
  ArgResults argResults;

  /**
   * The file path of the file containing the summary of the SDK that should be
   * used to "analyze" the SDK. This option should only be specified by
   * command-line tools such as 'dartanalyzer' or 'ddc'.
   */
  String dartSdkSummaryPath;

  /**
   * The file path of the analysis options file that should be used in place of
   * any file in the root directory or a parent of the root directory, or `null`
   * if the normal lookup mechanism should be used.
   */
  String defaultAnalysisOptionsFilePath;

  /**
   * A table mapping variable names to values for the declared variables, or
   * `null` if no additional variables should be declared.
   */
  Map<String, String> declaredVariables;

  /**
   * The default analysis options that should be used unless some or all of them
   * are overridden in the analysis options file, or `null` if the default
   * defaults should be used.
   */
  AnalysisOptions defaultOptions;

  /**
   * The file path of the .packages file that should be used in place of any
   * file found using the normal (Package Specification DEP) lookup mechanism,
   * or `null` if the normal lookup mechanism should be used.
   */
  String defaultPackageFilePath;

  /**
   * The file path of the packages directory that should be used in place of any
   * file found using the normal (Package Specification DEP) lookup mechanism,
   * or `null` if the normal lookup mechanism should be used.
   */
  String defaultPackagesDirectoryPath;

  /**
   * A list of the paths of summary files that are to be used, or `null` if no
   * summary information is available.
   */
  List<String> librarySummaryPaths;

  /**
   * Initialize a newly created set of options
   */
  ContextBuilderOptions();
}

/**
 * Given a package map, check in each package's lib directory for the existence
 * of an `_embedder.yaml` file. If the file contains a top level YamlMap, it
 * will be added to the [embedderYamls] map.
 */
class EmbedderYamlLocator {
  /**
   * The name of the embedder files being searched for.
   */
  static const String EMBEDDER_FILE_NAME = '_embedder.yaml';

  /**
   * A mapping from a package's library directory to the parsed YamlMap.
   */
  final Map<Folder, YamlMap> embedderYamls = new HashMap<Folder, YamlMap>();

  /**
   * Initialize a newly created locator by processing the packages in the given
   * [packageMap].
   */
  EmbedderYamlLocator(Map<String, List<Folder>> packageMap) {
    if (packageMap != null) {
      _processPackageMap(packageMap);
    }
  }

  /**
   * Programmatically add an `_embedder.yaml` mapping.
   */
  void addEmbedderYaml(Folder libDir, String embedderYaml) {
    _processEmbedderYaml(libDir, embedderYaml);
  }

  /**
   * Refresh the map of located files to those found by processing the given
   * [packageMap].
   */
  void refresh(Map<String, List<Folder>> packageMap) {
    // Clear existing.
    embedderYamls.clear();
    if (packageMap != null) {
      _processPackageMap(packageMap);
    }
  }

  /**
   * Given the yaml for an embedder ([embedderYaml]) and a folder ([libDir]),
   * setup the uri mapping.
   */
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

  /**
   * Given a package [name] and a list of folders ([libDirs]), process any
   * `_embedder.yaml` files that are found in any of the folders.
   */
  void _processPackage(String name, List<Folder> libDirs) {
    for (Folder libDir in libDirs) {
      String embedderYaml = _readEmbedderYaml(libDir);
      if (embedderYaml != null) {
        _processEmbedderYaml(libDir, embedderYaml);
      }
    }
  }

  /**
   * Process each of the entries in the [packageMap].
   */
  void _processPackageMap(Map<String, List<Folder>> packageMap) {
    packageMap.forEach(_processPackage);
  }

  /**
   * Read and return the contents of [libDir]/[EMBEDDER_FILE_NAME], or `null` if
   * the file doesn't exist.
   */
  String _readEmbedderYaml(Folder libDir) {
    File file = libDir.getChild(EMBEDDER_FILE_NAME);
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      // File can't be read.
      return null;
    }
  }
}
