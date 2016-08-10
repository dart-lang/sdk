// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.context.context_builder;

import 'dart:collection';
import 'dart:core' hide Resource;
import 'dart:io' as io;

import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:package_config/discovery.dart';
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
   * The cache containing the contents of overlayed files.
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
      if (path.endsWith(resourceProvider.pathContext.separator)) {
        path = path.substring(0, path.length - 1);
      }
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
      // TODO(brianwilkerson) Figure out why we're going through Uri rather than
      // just creating the file from the path.
      Uri fileUri = new Uri.file(defaultPackageFilePath);
      io.File configFile = new io.File.fromUri(fileUri).absolute;
      List<int> bytes = configFile.readAsBytesSync();
      Map<String, Uri> map = parse(bytes, configFile.uri);
      return new MapPackages(map);
    } else if (defaultPackagesDirectoryPath != null) {
      return getPackagesDirectory(
          new Uri.directory(defaultPackagesDirectoryPath));
    }
    return findPackagesFromFile(new Uri.directory(rootDirectoryPath));
  }

  SourceFactory createSourceFactory(
      String rootDirectoryPath, AnalysisOptions options) {
    Folder _folder = null;
    Folder folder() {
      return _folder ??= resourceProvider.getResource('.');
    }

    UriResolver fileResolver = fileResolverProvider == null
        ? new ResourceUriResolver(resourceProvider)
        : fileResolverProvider(folder());
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
    Map<String, List<Folder>> packageMap =
        convertPackagesToMap(createPackageMap(rootDirectoryPath));
    List<UriResolver> resolvers = <UriResolver>[];
    resolvers.add(new DartUriResolver(findSdk(packageMap, options)));
    if (packageMap != null) {
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
   * Return the SDK that should be used to analyze code. Use the given
   * [packageMap] and [options] to locate the SDK.
   */
  DartSdk findSdk(
      Map<String, List<Folder>> packageMap, AnalysisOptions options) {
    if (packageMap != null) {
      // TODO(brianwilkerson) Fix it so that we don't have to create a resolver
      // to figure out what the extensions are.
      SdkExtUriResolver extResolver = new SdkExtUriResolver(packageMap);
      List<String> extFilePaths = extResolver.extensionFilePaths;
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
            embedderSdk.addExtensions(extResolver.urlMappings);
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
            sdk.addExtensions(extResolver.urlMappings);
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
   * Programatically add an `_embedder.yaml` mapping.
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
