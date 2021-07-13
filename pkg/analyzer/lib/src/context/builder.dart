// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
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
/// 3. Look for an analysis options file (`analysis_options.yaml`) and process
///    the options in the file.
///
/// 4. Create a new context. Initialize its source factory based on steps 1, 2
///    and 3. Initialize its analysis options from step 4.
///
/// [1]: https://github.com/dart-lang/dart_enhancement_proposals/blob/master/Accepted/0005%20-%20Package%20Specification/DEP-pkgspec.md.
class ContextBuilder {
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
