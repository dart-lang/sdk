// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.context.context_builder;

import 'dart:collection';
import 'dart:core' hide Resource;

import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/packages_file.dart';
import 'package:package_config/src/packages_impl.dart';
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
   * The file path of the analysis options file that should be used in place of
   * any file in the root directory or a parent of the root directory, or `null`
   * if the normal lookup mechanism should be used.
   */
  String defaultAnalysisOptionsFilePath;

  /**
   * The default analysis options that should be used unless some or all of them
   * are overridden in the analysis options file, or `null` if the default
   * defaults should be used.
   */
  AnalysisOptions defaultOptions;

  /**
   * A table mapping variable names to values for the declared variables, or
   * `null` if no additional variables should be declared.
   */
  Map<String, String> declaredVariables;

  /**
   * Initialize a newly created builder to be ready to build a context rooted in
   * the directory with the given [rootDirectoryPath].
   */
  ContextBuilder(this.resourceProvider, this.sdkManager, this.contentCache);

  /**
   * Return an analysis context that is configured correctly to analyze code in
   * the directory with the given [path].
   *
   * *Note:* This method is not yet fully implemented and should not be used.
   */
  AnalysisContext buildContext(String path) {
    // TODO(brianwilkerson) Split getAnalysisOptions so we can capture the
    // option map and use it to run the options processors.
    AnalysisOptions options = getAnalysisOptions(path);
    InternalAnalysisContext context =
        AnalysisEngine.instance.createAnalysisContext();
    context.contentCache = contentCache;
    context.sourceFactory = createSourceFactory(path, options);
    context.analysisOptions = options;
    //_processAnalysisOptions(context, optionMap);
    declareVariables(context);
    return context;
  }

  Map<String, List<Folder>> convertPackagesToMap(Packages packages) {
    if (packages == null || packages == Packages.noPackages) {
      return null;
    }
    Map<String, List<Folder>> folderMap = new HashMap<String, List<Folder>>();
    packages.asMap().forEach((String packagePath, Uri uri) {
      String path = resourceProvider.pathContext.fromUri(uri);
      folderMap[packagePath] = [resourceProvider.getFolder(path)];
    });
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
    if (defaultOptions == null) {
      return new AnalysisOptionsImpl();
    }
    return new AnalysisOptionsImpl.from(defaultOptions);
  }

  Packages createPackageMap(String rootDirectoryPath) {
    if (defaultPackageFilePath != null) {
      File configFile = resourceProvider.getFile(defaultPackageFilePath);
      List<int> bytes = configFile.readAsBytesSync();
      Map<String, Uri> map = parse(bytes, configFile.toUri());
      return new MapPackages(map);
    } else if (defaultPackagesDirectoryPath != null) {
      Folder folder = resourceProvider.getFolder(defaultPackagesDirectoryPath);
      return getPackagesFromFolder(folder);
    }
    return findPackagesFromFile(rootDirectoryPath);
  }

  SourceFactory createSourceFactory(
      String rootDirectoryPath, AnalysisOptions options) {
    Folder _folder = null;
    Folder folder() {
      return _folder ??= resourceProvider.getFolder(rootDirectoryPath);
    }

    UriResolver fileResolver;
    if (fileResolverProvider != null) {
      fileResolver = fileResolverProvider(folder());
    }
    fileResolver ??= new ResourceUriResolver(resourceProvider);
    if (packageResolverProvider != null) {
      UriResolver packageResolver = packageResolverProvider(folder());
      if (packageResolver != null) {
        // TODO(brianwilkerson) This doesn't support either embedder files or
        // sdk extensions because we don't have a way to get the package map
        // from the resolver.
        List<UriResolver> resolvers = <UriResolver>[
          new DartUriResolver(findSdk(null, options)),
          packageResolver,
          fileResolver
        ];
        return new SourceFactory(resolvers);
      }
    }
    Packages packages = createPackageMap(rootDirectoryPath);
    Map<String, List<Folder>> packageMap = convertPackagesToMap(packages);
    List<UriResolver> resolvers = <UriResolver>[];
    resolvers.add(new DartUriResolver(findSdk(packageMap, options)));
    if (packageMap != null) {
      // TODO(brianwilkerson) I think that we don't need a PackageUriResolver
      // when we can pass the packages object to the source factory directly.
      resolvers.add(new PackageMapUriResolver(resourceProvider, packageMap));
    }
    resolvers.add(fileResolver);
    return new SourceFactory(resolvers);
  }

  /**
   * Add any [declaredVariables] to the list of declared variables used by the
   * given [context].
   */
  void declareVariables(InternalAnalysisContext context) {
    if (declaredVariables != null && declaredVariables.isNotEmpty) {
      DeclaredVariables contextVariables = context.declaredVariables;
      declaredVariables.forEach((String variableName, String value) {
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
      return new MapPackages(map);
    } else if (location is Folder) {
      return getPackagesFromFolder(location);
    }
    return Packages.noPackages;
  }

  /**
   * Return the SDK that should be used to analyze code. Use the given
   * [packageMap] and [options] to locate the SDK.
   */
  DartSdk findSdk(
      Map<String, List<Folder>> packageMap, AnalysisOptions options) {
    if (packageMap != null) {
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
        SdkDescription description = new SdkDescription(paths, options);
        DartSdk dartSdk = sdkManager.getSdk(description, () {
          if (extFilePaths.isNotEmpty) {
            embedderSdk.addExtensions(extFinder.urlMappings);
          }
          embedderSdk.analysisOptions = options;
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
        SdkDescription description = new SdkDescription(paths, options);
        return sdkManager.getSdk(description, () {
          FolderBasedDartSdk sdk = new FolderBasedDartSdk(
              resourceProvider, resourceProvider.getFolder(sdkPath));
          if (extFilePaths.isNotEmpty) {
            sdk.addExtensions(extFinder.urlMappings);
          }
          sdk.analysisOptions = options;
          sdk.useSummary = sdkManager.canUseSummaries;
          return sdk;
        });
      }
    }
    String sdkPath = sdkManager.defaultSdkDirectory;
    SdkDescription description = new SdkDescription(<String>[sdkPath], options);
    return sdkManager.getSdk(description, () {
      FolderBasedDartSdk sdk = new FolderBasedDartSdk(
          resourceProvider, resourceProvider.getFolder(sdkPath));
      sdk.analysisOptions = options;
      sdk.useSummary = sdkManager.canUseSummaries;
      return sdk;
    });
  }

  /**
   * Return the analysis options that should be used when analyzing code in the
   * directory with the given [path].
   */
  AnalysisOptions getAnalysisOptions(String path) {
    AnalysisOptionsImpl options = createDefaultOptions();
    File optionsFile = getOptionsFile(path);
    if (optionsFile != null) {
      Map<String, YamlNode> fileOptions =
          new AnalysisOptionsProvider().getOptionsFromFile(optionsFile);
      applyToAnalysisOptions(options, fileOptions);
    }
    return options;
  }

  /**
   * Return the analysis options file that should be used when analyzing code in
   * the directory with the given [path].
   */
  File getOptionsFile(String path) {
    if (defaultAnalysisOptionsFilePath != null) {
      return resourceProvider.getFile(defaultAnalysisOptionsFilePath);
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
    Map<String, Uri> map = new HashMap<String, Uri>();
    for (Resource child in folder.getChildren()) {
      if (child is Folder) {
        String packageName = resourceProvider.pathContext.basename(child.path);
        // Create a file URI (rather than a directory URI) and add a '.' so that
        // the URI is suitable for resolving relative URI's against it.
        //
        // TODO(brianwilkerson) Decide whether we need to pass in a 'windows:'
        // argument for testing purposes.
        map[packageName] = resourceProvider.pathContext.toUri(
            resourceProvider.pathContext.join(folder.path, packageName, '.'));
      }
    }
    return new MapPackages(map);
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
