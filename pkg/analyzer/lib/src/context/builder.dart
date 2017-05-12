// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.context.context_builder;

import 'dart:collection';
import 'dart:core';

import 'package:analyzer/context/context_root.dart';
import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/command_line/arguments.dart'
    show
        applyAnalysisOptionFlags,
        bazelAnalysisOptionsPath,
        flutterAnalysisOptionsPath;
import 'package:analyzer/src/dart/analysis/driver.dart'
    show AnalysisDriver, AnalysisDriverScheduler;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/bazel.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/gn.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/workspace.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:args/args.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/incremental/byte_store.dart';
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
  static Function onCreateAnalysisDriver = null;

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
    AnalysisOptions options = getAnalysisOptions(path);
    context.contentCache = contentCache;
    context.sourceFactory = createSourceFactory(path, options);
    context.analysisOptions = options;
    context.name = path;
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
    AnalysisOptions options = getAnalysisOptions(path);
    //_processAnalysisOptions(context, optionMap);
    final sf = createSourceFactory(path, options);
    AnalysisDriver driver = new AnalysisDriver(
        analysisDriverScheduler,
        performanceLog,
        resourceProvider,
        byteStore,
        fileContentOverlay,
        contextRoot,
        sf,
        options);
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
      packages.asMap().forEach((String packageName, Uri uri) {
        String path = resourceProvider.pathContext.fromUri(uri);
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

  SourceFactory createSourceFactory(String rootPath, AnalysisOptions options) {
    Workspace workspace = createWorkspace(rootPath);
    DartSdk sdk = findSdk(workspace.packageMap, options);
    return workspace.createSourceFactory(sdk);
  }

  Workspace createWorkspace(String rootPath) {
    if (_hasPackageFileInPath(rootPath)) {
      // Bazel workspaces that include package files are treated like normal
      // (non-Bazel) directories.
      return _BasicWorkspace.find(resourceProvider, rootPath, this);
    }
    Workspace workspace = BazelWorkspace.find(resourceProvider, rootPath);
    workspace ??= GnWorkspace.find(resourceProvider, rootPath);
    return workspace ?? _BasicWorkspace.find(resourceProvider, rootPath, this);
  }

  /**
   * Add any [declaredVariables] to the list of declared variables used by the
   * given [context].
   */
  void declareVariables(InternalAnalysisContext context) {
    Map<String, String> variables = builderOptions.declaredVariables;
    if (variables != null && variables.isNotEmpty) {
      DeclaredVariables contextVariables = context.declaredVariables;
      variables.forEach((String variableName, String value) {
        contextVariables.define(variableName, value);
      });
    }
  }

  /**
   * Add any [declaredVariables] to the list of declared variables used by the
   * given analysis [driver].
   */
  void declareVariablesInDriver(AnalysisDriver driver) {
    Map<String, String> variables = builderOptions.declaredVariables;
    if (variables != null && variables.isNotEmpty) {
      DeclaredVariables contextVariables = driver.declaredVariables;
      variables.forEach((String variableName, String value) {
        contextVariables.define(variableName, value);
      });
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
      Map<String, Uri> map =
          parse(fileBytes, resourceProvider.pathContext.toUri(location.path));
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
      return new SummaryBasedDartSdk(summaryPath, analysisOptions.strongMode,
          resourceProvider: resourceProvider);
    } else if (packageMap != null) {
      SdkExtensionFinder extFinder = new SdkExtensionFinder(packageMap);
      List<String> extFilePaths = extFinder.extensionFilePaths;
      EmbedderYamlLocator locator = new EmbedderYamlLocator(packageMap);
      Map<Folder, YamlMap> embedderYamls = locator.embedderYamls;
      EmbedderSdk embedderSdk =
          new EmbedderSdk(resourceProvider, embedderYamls);
      if (embedderSdk.sdkLibraries.length > 0) {
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
      FolderBasedDartSdk sdk = new FolderBasedDartSdk(resourceProvider,
          resourceProvider.getFolder(sdkPath), analysisOptions.strongMode);
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
      {void verbosePrint(String text)}) {
    void verbose(String text) {
      if (verbosePrint != null) {
        verbosePrint(text);
      }
    }

    // TODO(danrubel) restructure so that we don't create a workspace
    // both here and in createSourceFactory
    Workspace workspace = createWorkspace(path);
    SourceFactory sourceFactory = workspace.createSourceFactory(null);
    AnalysisOptionsProvider optionsProvider =
        new AnalysisOptionsProvider(sourceFactory);

    AnalysisOptionsImpl options = createDefaultOptions();
    File optionsFile = getOptionsFile(path);
    Map<String, YamlNode> optionMap;

    if (optionsFile != null) {
      try {
        optionMap = optionsProvider.getOptionsFromFile(optionsFile);
        verbose('Loaded analysis options from ${optionsFile.path}');
      } catch (e) {
        // Ignore exceptions thrown while trying to load the options file.
        verbose('Exception: $e\n  when loading ${optionsFile.path}');
      }
    } else {
      // Search for the default analysis options
      // unless explicitly directed not to do so.
      Source source;
      if (builderOptions.packageDefaultAnalysisOptions) {
        // TODO(danrubel) determine if bazel or gn project depends upon flutter
        if (workspace.hasFlutterDependency) {
          source = sourceFactory.forUri(flutterAnalysisOptionsPath);
        }
        if (source == null || !source.exists()) {
          source = sourceFactory.forUri(bazelAnalysisOptionsPath);
        }
        if (source != null && source.exists()) {
          try {
            optionMap = optionsProvider.getOptionsFromSource(source);
            verbose('Loaded analysis options from ${source.fullName}');
          } catch (e) {
            // Ignore exceptions thrown while trying to load the options file.
            verbose('Exception: $e\n  when loading ${source.fullName}');
          }
        }
      }
    }

    if (optionMap != null) {
      applyToAnalysisOptions(options, optionMap);
      if (builderOptions.argResults != null) {
        applyAnalysisOptionFlags(options, builderOptions.argResults,
            verbosePrint: verbosePrint);
        // If lints turned on but none specified, then enable default lints
        if (options.lint && options.lintRules.isEmpty) {
          options.lintRules = Registry.ruleRegistry.defaultRules;
          verbose('Using default lint rules');
        }
      }
    } else {
      verbose('Using default analysis options');
    }
    return options;
  }

  /**
   * Return the analysis options file that should be used when analyzing code in
   * the directory with the given [path].
   */
  File getOptionsFile(String path) {
    String filePath = builderOptions.defaultAnalysisOptionsFilePath;
    if (filePath != null) {
      return resourceProvider.getFile(filePath);
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
      Folder folder =
          resourceProvider.getFolder(pathContext.fromUri(map[packageName]));
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
   * Return `true` if either the directory at [rootPath] or a parent of that
   * directory contains a `.packages` file.
   */
  bool _hasPackageFileInPath(String rootPath) {
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
   * Allow Flutter and bazel default analysis options to be used.
   */
  bool packageDefaultAnalysisOptions = true;

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

/**
 * Information about a default Dart workspace.
 */
class _BasicWorkspace extends Workspace {
  /**
   * The [ResourceProvider] by which paths are converted into [Resource]s.
   */
  final ResourceProvider provider;

  /**
   * The absolute workspace root path.
   */
  final String root;

  final ContextBuilder _builder;

  Map<String, List<Folder>> _packageMap;

  Packages _packages;

  _BasicWorkspace._(this.provider, this.root, this._builder);

  @override
  // Alternately, we could check the pubspec for "sdk: flutter"
  bool get hasFlutterDependency => packageMap.containsKey('flutter');

  @override
  Map<String, List<Folder>> get packageMap {
    _packageMap ??= _builder.convertPackagesToMap(packages);
    return _packageMap;
  }

  Packages get packages {
    _packages ??= _builder.createPackageMap(root);
    return _packages;
  }

  @override
  UriResolver get packageUriResolver =>
      new PackageMapUriResolver(provider, packageMap);

  @override
  SourceFactory createSourceFactory(DartSdk sdk) {
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(new DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(new ResourceUriResolver(provider));
    return new SourceFactory(resolvers, packages, provider);
  }

  /**
   * Find the basic workspace that contains the given [path].
   */
  static _BasicWorkspace find(
      ResourceProvider provider, String path, ContextBuilder builder) {
    Context context = provider.pathContext;

    // Ensure that the path is absolute and normalized.
    if (!context.isAbsolute(path)) {
      throw new ArgumentError('not absolute: $path');
    }
    path = context.normalize(path);
    Resource resource = provider.getResource(path);
    if (resource is File) {
      path = resource.parent.path;
    }
    return new _BasicWorkspace._(provider, path, builder);
  }
}
