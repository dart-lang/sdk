// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:package_config/packages.dart';
import 'package:yaml/yaml.dart';

/**
 * Traverses the package structure to determine the transitive dependencies for
 * a given package.
 */
class DependencyFinder {
  /**
   * The name of the pubspec.yaml file.
   */
  static const String pubspecName = 'pubspec.yaml';

  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider resourceProvider;

  /**
   * A table mapping the absolute paths of packages to a list of the names of
   * the packages on which those packages depend.
   */
  final Map<String, List<String>> dependencyMap =
      new HashMap<String, List<String>>();

  /**
   * Initialize a newly created dependency finder to use the given
   * [resourceProvider] to access the file system.
   */
  DependencyFinder(this.resourceProvider);

  /**
   * Return a sorted list of the directories containing all of the packages on
   * which the package at the given [packagePath] depends. The [packageMap]
   * maps the names of packages to the directories in which they are contained.
   *
   * Throws an [AnalysisException] if any of the packages are missing their
   * 'pubspec.yaml' file.
   */
  List<String> transitiveDependenciesFor(
      Map<String, List<Folder>> packageMap, String packagePath) {
    Set<String> processedPackages = new HashSet<String>();
    Set<String> processedPaths = new HashSet<String>();
    void process(String packageName) {
      if (processedPackages.add(packageName)) {
        List<Folder> folderList = packageMap[packageName];
        if (folderList == null || folderList.isEmpty) {
          throw new StateError('No mapping for package "$packageName"');
        }
        String packagePath = folderList[0].path;
        processedPaths.add(packagePath);
        List<String> dependencies = _dependenciesFor(packagePath);
        for (String dependency in dependencies) {
          process(dependency);
        }
      }
    }

    List<String> dependencies = _dependenciesFor(packagePath);
    dependencies.forEach(process);
    processedPaths.remove(packagePath);
    List<String> transitiveDependencies = processedPaths.toList();
    transitiveDependencies.sort();
    return transitiveDependencies;
  }

  /**
   * Add to the given set of [dependecies] all of the package names used as keys
   * in the given [yamlMap].
   */
  void _collectDependencies(HashSet<String> dependencies, YamlMap yamlMap) {
    if (yamlMap is Map) {
      for (var key in yamlMap.keys) {
        if (key is String) {
          dependencies.add(key);
        }
      }
    }
  }

  /**
   * Return a list of the names of the packages on which the package at the
   * [packagePath] depends.
   */
  List<String> _dependenciesFor(String packagePath) {
    return dependencyMap.putIfAbsent(packagePath, () {
      Set<String> dependencies = new HashSet<String>();
      YamlNode yamlNode = _readPubspec(packagePath);
      if (yamlNode is YamlMap) {
        _collectDependencies(dependencies, yamlNode['dependencies']);
      }
      return dependencies.toList();
    });
  }

  /**
   * Read the content of the pubspec file in the directory at the given
   * [directoryPath]. Return `null` if the file does not exist, cannot be read,
   * or has content that is not valid YAML.
   */
  YamlNode _readPubspec(String directoryPath) {
    try {
      File yamlFile = resourceProvider
          .getFolder(directoryPath)
          .getChildAssumingFile(pubspecName);
      String yamlContent = yamlFile.readAsStringSync();
      return loadYamlNode(yamlContent);
    } catch (exception, stackTrace) {
      throw new AnalysisException('Missing $pubspecName in $directoryPath',
          new CaughtException(exception, stackTrace));
    }
  }
}

/**
 * A description of the context in which a package will be analyzed.
 */
class PackageDescription {
  /**
   * The id of the package being described. The id encodes the actual locations
   * of the package itself and all of the packages on which it depends.
   */
  final String id;

  /**
   * The SDK against which the package will be analyzed.
   */
  final DartSdk sdk;

  /**
   * The analysis options that will be used when analyzing the package.
   */
  final AnalysisOptions options;

  /**
   * Initialize a newly create package description to describe the package with
   * the given [id] that is being analyzed against the given [sdk] using the
   * given [options].
   */
  PackageDescription(this.id, this.sdk, this.options);

  @override
  int get hashCode {
    int hashCode = 0;
    for (int value in options.signature) {
      hashCode = JenkinsSmiHash.combine(hashCode, value);
    }
    hashCode = JenkinsSmiHash.combine(hashCode, id.hashCode);
    hashCode = JenkinsSmiHash.combine(hashCode, sdk.hashCode);
    return JenkinsSmiHash.finish(hashCode);
  }

  @override
  bool operator ==(Object other) {
    return other is PackageDescription &&
        other.sdk == sdk &&
        AnalysisOptions.signaturesEqual(
            other.options.signature, options.signature) &&
        other.id == id;
  }
}

/**
 * Manages the contexts in which each package is analyzed.
 */
class PackageManager {
  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider resourceProvider;

  /**
   * A table mapping the id's of packages to the context in which the package is
   * analyzed.
   */
  final Map<PackageDescription, AnalysisContext> contextMap =
      new HashMap<PackageDescription, AnalysisContext>();

  /**
   * Initialize a newly created package manager.
   */
  PackageManager(this.resourceProvider);

  /**
   * Return the context in which the package at the given [packagePath] should
   * be analyzed when the given [packages] object is used to resolve package
   * names, the given [resolver] will be used to resolve 'dart:' URI's, and the
   * given [options] will control the analysis.
   */
  AnalysisContext getContext(String packagePath, Packages packages,
      DartUriResolver resolver, AnalysisOptions options) {
    DartSdk sdk = resolver.dartSdk;
    Map<String, List<Folder>> packageMap =
        new ContextBuilder(resourceProvider, null, null)
            .convertPackagesToMap(packages);
    PackageDescription description =
        new PackageDescription(_buildId(packagePath, packageMap), sdk, options);
    return contextMap.putIfAbsent(description, () {
      AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
      context.sourceFactory = new SourceFactory(<UriResolver>[
        resolver,
        new PackageMapUriResolver(resourceProvider, packageMap),
        new ResourceUriResolver(resourceProvider)
      ], packages, resourceProvider);
      context.analysisOptions = options;
      return context;
    });
  }

  /**
   * Return the id associated with the package at the given [packagePath] when
   * the given [packageMap] is used to resolve package names.
   */
  String _buildId(String packagePath, Map<String, List<Folder>> packageMap) {
    DependencyFinder finder = new DependencyFinder(resourceProvider);
    List<String> dependencies =
        finder.transitiveDependenciesFor(packageMap, packagePath);
    StringBuffer buffer = new StringBuffer();
    buffer.write(packagePath);
    for (String dependency in dependencies) {
      buffer.write(';');
      buffer.write(dependency);
    }
    return buffer.toString();
  }
}
