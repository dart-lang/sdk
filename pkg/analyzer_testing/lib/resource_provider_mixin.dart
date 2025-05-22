// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
// TODO(srawlins): Move this into public API.
// ignore: implementation_imports
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';
import 'package:path/path.dart' as path;

/// A mixin for test classes that adds a memory-backed [ResourceProvider] and
/// utility methods for manipulating the file system.
///
/// The resource provider will use paths in the same style as the current
/// platform unless the `TEST_ANALYZER_WINDOWS_PATHS` environment variable is
/// set to `true`, in which case it will use Windows-style paths.
///
/// The utility methods all take a posix style path and convert it as
/// appropriate for the actual platform.
mixin ResourceProviderMixin {
  late final ResourceProvider resourceProvider =
      Platform.environment['TEST_ANALYZER_WINDOWS_PATHS'] == 'true'
          ? MemoryResourceProvider(context: path.windows)
          : MemoryResourceProvider();

  /// The path context of [resourceProvider].
  path.Context get pathContext => resourceProvider.pathContext;

  /// Converts the given posix [filePath] to conform to [resourceProvider]'s
  /// path context.
  String convertPath(String filePath) => resourceProvider.convertPath(filePath);

  /// Deletes the file at [path].
  void deleteFile(String path) {
    resourceProvider.getFile(convertPath(path)).delete();
  }

  /// Deletes the folder at [path].
  void deleteFolder(String path) {
    resourceProvider.getFolder(convertPath(path)).delete();
  }

  /// Returns [uri] as a String.
  String fromUri(Uri uri) {
    return resourceProvider.pathContext.fromUri(uri);
  }

  /// Gets the [File] at [path].
  File getFile(String path) {
    String convertedPath = convertPath(path);
    return resourceProvider.getFile(convertedPath);
  }

  /// Gets the [Folder] at [path].
  Folder getFolder(String path) {
    String convertedPath = convertPath(path);
    return resourceProvider.getFolder(convertedPath);
  }

  /// Joins the part paths as per [path.Context.join].
  String join(
    String part1, [
    String? part2,
    String? part3,
    String? part4,
    String? part5,
    String? part6,
    String? part7,
    String? part8,
  ]) => resourceProvider.pathContext.join(
    part1,
    part2,
    part3,
    part4,
    part5,
    part6,
    part7,
    part8,
  );

  /// Writes [content] to [file].
  void modifyFile2(File file, String content) {
    String convertedPath = convertPath(file.path);
    resourceProvider.getFile(convertedPath).writeAsStringSync(content);
  }

  /// Writes a new `analysis_options.yaml` file at [directoryPath] with
  /// [content].
  File newAnalysisOptionsYamlFile(String directoryPath, String content) {
    String path = join(directoryPath, file_paths.analysisOptionsYaml);
    return newFile(path, content);
  }

  /// Creates a new Bazel BUILD file at [directoryPath] with [content].
  File newBazelBuildFile(String directoryPath, String content) {
    String filePath = join(directoryPath, file_paths.blazeBuild);
    return newFile(filePath, content);
  }

  /// Creates a new BUILD.gn file at [directoryPath] with [content].
  File newBuildGnFile(String directoryPath, String content) {
    String path = join(directoryPath, file_paths.buildGn);
    return newFile(path, content);
  }

  /// Writes [content] to the file at [path].
  File newFile(String path, String content) {
    String convertedPath = convertPath(path);
    return resourceProvider.getFile(convertedPath)..writeAsStringSync(content);
  }

  /// Creates and returns a new [Folder] at [path].
  Folder newFolder(String path) {
    String convertedPath = convertPath(path);
    return resourceProvider.getFolder(convertedPath)..create();
  }

  /// Creates and returns a new [Link] at [path] to [target].
  Link newLink(String path, String target) {
    String convertedPath = convertPath(path);
    String convertedTarget = convertPath(target);
    return resourceProvider.getLink(convertedPath)..create(convertedTarget);
  }

  /// Writes a `.dart_tool/package_config.json` file at [directoryPath] with
  /// [content].
  File newPackageConfigJsonFile(String directoryPath, String content) {
    String path = join(
      directoryPath,
      file_paths.dotDartTool,
      file_paths.packageConfigJson,
    );
    return newFile(path, content);
  }

  /// Writes a `.dart_tool/package_config.json` file at [directoryPath].
  File newPackageConfigJsonFileFromBuilder(
    String directoryPath,
    PackageConfigFileBuilder builder,
  ) {
    var content = builder.toContent(pathContext: pathContext);
    return newPackageConfigJsonFile(directoryPath, content);
  }

  /// Writes a `pubspec.yaml` file at [directoryPath] with [content].
  File newPubspecYamlFile(String directoryPath, String content) {
    String path = join(directoryPath, file_paths.pubspecYaml);
    return newFile(path, content);
  }

  /// Writes a new `.dart_tool/package_config.json` file for a package rooted at
  /// [packagePath], named [name].
  void newSinglePackageConfigJsonFile({
    required String packagePath,
    required String name,
  }) {
    var builder =
        PackageConfigFileBuilder()..add(name: name, rootPath: packagePath);
    newPackageConfigJsonFileFromBuilder(packagePath, builder);
  }

  /// Converts [path] to a URI.
  Uri toUri(String path) {
    path = convertPath(path);
    return resourceProvider.pathContext.toUri(path);
  }

  /// Converts [path] to a URI and returns the normalized String representation
  /// of the URI.
  String toUriStr(String path) {
    return toUri(path).toString();
  }
}
