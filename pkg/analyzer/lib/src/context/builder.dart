// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.context.context_builder;

import 'dart:collection';
import 'dart:core';

import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/bazel.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/pub_summary.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/task/options.dart';
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
 * 4. Look for an analysis options file (`analyis_options.yaml` or
 *    `.analysis_options`) and process the options in the file.
 *
 * 5. Create a new context. Initialize its source factory based on steps 1, 2
 *    and 3. Initialize its analysis options from step 4.
 *
 * [1]: https://github.com/dart-lang/dart_enhancement_proposals/blob/master/Accepted/0005%20-%20Package%20Specification/DEP-pkgspec.md.
 */
class ContextBuilder {
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
   * The cache containing the contents of overlaid files.
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
    AnalysisOptions options = getAnalysisOptions(context, path);
    context.contentCache = contentCache;
    context.sourceFactory = createSourceFactory(path, options);
    context.analysisOptions = options;
    context.name = path;
    //_processAnalysisOptions(context, optionMap);
    declareVariables(context);
    configureSummaries(context);
    return context;
  }

  /**
   * Configure the context to make use of summaries.
   */
  void configureSummaries(InternalAnalysisContext context) {
    PubSummaryManager manager = builderOptions.pubSummaryManager;
    if (manager != null) {
      List<LinkedPubPackage> linkedBundles = manager.getLinkedBundles(context);
      if (linkedBundles.isNotEmpty) {
        SummaryDataStore store = new SummaryDataStore([]);
        for (LinkedPubPackage package in linkedBundles) {
          store.addBundle(null, package.unlinked);
          store.addBundle(null, package.linked);
        }
        context.resultProvider =
            new InputPackagesResultProvider(context, store);
      }
    }
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
    BazelWorkspace bazelWorkspace =
        BazelWorkspace.find(resourceProvider, rootPath);
    if (bazelWorkspace != null) {
      List<UriResolver> resolvers = <UriResolver>[
        new DartUriResolver(findSdk(null, options)),
        new BazelPackageUriResolver(bazelWorkspace),
        new BazelFileUriResolver(bazelWorkspace)
      ];
      return new SourceFactory(resolvers, null, resourceProvider);
    }

    Packages packages = createPackageMap(rootPath);
    Map<String, List<Folder>> packageMap = convertPackagesToMap(packages);
    List<UriResolver> resolvers = <UriResolver>[
      new DartUriResolver(findSdk(packageMap, options)),
      new PackageMapUriResolver(resourceProvider, packageMap),
      new ResourceUriResolver(resourceProvider)
    ];
    return new SourceFactory(resolvers, packages, resourceProvider);
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
      return new SummaryBasedDartSdk(summaryPath, analysisOptions.strongMode);
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
   * Return the analysis options that should be used when the given [context] is
   * used to analyze code in the directory with the given [path].
   */
  AnalysisOptions getAnalysisOptions(AnalysisContext context, String path) {
    AnalysisOptionsImpl options = createDefaultOptions();
    File optionsFile = getOptionsFile(path);
    if (optionsFile != null) {
      List<OptionsProcessor> optionsProcessors =
          AnalysisEngine.instance.optionsPlugin.optionsProcessors;
      // TODO(danrubel) restructure so that we don't recalculate the package map
      // more than once per path.
      Packages packages = createPackageMap(path);
      Map<String, List<Folder>> packageMap = convertPackagesToMap(packages);
      List<UriResolver> resolvers = <UriResolver>[
        new ResourceUriResolver(resourceProvider),
        new PackageMapUriResolver(resourceProvider, packageMap),
      ];
      SourceFactory sourceFactory =
          new SourceFactory(resolvers, packages, resourceProvider);
      try {
        Map<String, YamlNode> optionMap =
            new AnalysisOptionsProvider(sourceFactory)
                .getOptionsFromFile(optionsFile);
        optionsProcessors.forEach(
            (OptionsProcessor p) => p.optionsProcessed(context, optionMap));
        applyToAnalysisOptions(options, optionMap);
      } on Exception catch (exception) {
        optionsProcessors.forEach((OptionsProcessor p) => p.onError(exception));
      }
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
      throw new ArgumentError.value(path, "path", "Directory does not exist.");
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
}

/**
 * Options used by a [ContextBuilder].
 */
class ContextBuilderOptions {
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
   * The manager of pub package summaries.
   */
  PubSummaryManager pubSummaryManager;

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
