// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.context.context_builder;

import 'dart:collection';
import 'dart:core' hide Resource;
import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/embedder.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:package_config/discovery.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/packages_file.dart';
import 'package:package_config/src/packages_impl.dart';
import 'package:path/path.dart' as path;
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
   * The file path of the .packages file that should be used in place of any
   * file found using the normal (Package Specification DEP) lookup mechanism.
   */
  String defaultPackageFilePath;

  /**
   * The file path of the packages directory that should be used in place of any
   * file found using the normal (Package Specification DEP) lookup mechanism.
   */
  String defaultPackagesDirectoryPath;

  /**
   * The file path of the analysis options file that should be used in place of
   * any file in the root directory.
   */
  String defaultAnalysisOptionsFilePath;

  /**
   * The default analysis options that should be used unless some or all of them
   * are overridden in the analysis options file.
   */
  AnalysisOptions defaultOptions;

  /**
   * Initialize a newly created builder to be ready to build a context rooted in
   * the directory with the given [rootDirectoryPath].
   */
  ContextBuilder(this.resourceProvider, this.sdkManager, this.contentCache);

  AnalysisContext buildContext(String rootDirectoryPath) {
    // TODO(brianwilkerson) Split getAnalysisOptions so we can capture the
    // option map and use it to run the options processors.
    AnalysisOptions options = getAnalysisOptions(rootDirectoryPath);
    InternalAnalysisContext context =
        AnalysisEngine.instance.createAnalysisContext();
    context.contentCache = contentCache;
    context.sourceFactory = createSourceFactory(rootDirectoryPath, options);
    context.analysisOptions = options;
    //_processAnalysisOptions(context, optionMap);
    return context;
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

  Map<String, List<Folder>> convertPackagesToMap(Packages packages) {
    if (packages == null || packages == Packages.noPackages) {
      return null;
    }
    Map<String, List<Folder>> folderMap = new HashMap<String, List<Folder>>();
    packages.asMap().forEach((String packagePath, Uri uri) {
      folderMap[packagePath] = [resourceProvider.getFolder(path.fromUri(uri))];
    });
    return folderMap;
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
    if (packageResolverProvider != null) {
      Folder folder = resourceProvider.getResource('.');
      UriResolver resolver = packageResolverProvider(folder);
      if (resolver != null) {
        // TODO(brianwilkerson) This doesn't support either embedder files or
        // sdk extensions because we don't have a way to get the package map
        // from the resolver.
        List<UriResolver> resolvers = <UriResolver>[
          new DartUriResolver(findSdk(null, options)),
          resolver,
          new ResourceUriResolver(resourceProvider)
        ];
        return new SourceFactory(resolvers);
      }
    }
    Map<String, List<Folder>> packageMap =
        convertPackagesToMap(createPackageMap(rootDirectoryPath));
    List<UriResolver> resolvers = <UriResolver>[];
    resolvers.add(new DartUriResolver(findSdk(packageMap, options)));
    if (packageMap != null) {
      resolvers.add(new SdkExtUriResolver(packageMap));
      resolvers.add(new PackageMapUriResolver(resourceProvider, packageMap));
    }
    resolvers.add(new ResourceUriResolver(resourceProvider));
    return new SourceFactory(resolvers);
  }

  /**
   * Use the given [packageMap] and [options] to locate the SDK.
   */
  DartSdk findSdk(
      Map<String, List<Folder>> packageMap, AnalysisOptions options) {
    if (packageMap != null) {
      EmbedderYamlLocator locator = new EmbedderYamlLocator(packageMap);
      Map<Folder, YamlMap> embedderYamls = locator.embedderYamls;
      EmbedderSdk embedderSdk = new EmbedderSdk(embedderYamls);
      if (embedderSdk.sdkLibraries.length > 0) {
        List<String> paths = <String>[];
        for (Folder folder in embedderYamls.keys) {
          paths.add(folder
              .getChildAssumingFile(EmbedderYamlLocator.EMBEDDER_FILE_NAME)
              .path);
        }
        SdkDescription description = new SdkDescription(paths, options);
        DartSdk dartSdk = sdkManager.getSdk(description, () {
          embedderSdk.analysisOptions = options;
          embedderSdk.useSummary = sdkManager.canUseSummaries;
          return embedderSdk;
        });
        return dartSdk;
      }
    }
    String sdkPath = sdkManager.defaultSdkDirectory;
    SdkDescription description = new SdkDescription(<String>[sdkPath], options);
    return sdkManager.getSdk(description, () {
      DirectoryBasedDartSdk sdk =
          new DirectoryBasedDartSdk(new JavaFile(sdkPath));
      sdk.analysisOptions = options;
      sdk.useSummary = sdkManager.canUseSummaries;
      return sdk;
    });
  }

  AnalysisOptions getAnalysisOptions(String rootDirectoryPath) {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl.from(defaultOptions);
    File optionsFile = getOptionsFile(rootDirectoryPath);
    if (optionsFile != null) {
      Map<String, YamlNode> fileOptions =
          new AnalysisOptionsProvider().getOptionsFromFile(optionsFile);
      applyToAnalysisOptions(options, fileOptions);
    }
    return options;
  }

  File getOptionsFile(String rootDirectoryPath) {
    if (defaultAnalysisOptionsFilePath != null) {
      return resourceProvider.getFile(defaultAnalysisOptionsFilePath);
    }
    Folder root = resourceProvider.getFolder(rootDirectoryPath);
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
