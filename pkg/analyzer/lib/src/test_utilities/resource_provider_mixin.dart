// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:path/path.dart' as path;
import 'package:path/path.dart';

/// A mixin for test classes that adds a memory-backed [ResourceProvider] (that
/// can be overriden via [createResourceProvider]) and utility methods for
/// manipulating the file system.
///
/// The resource provider will use paths in the same style as the current
/// platform unless the `TEST_ANALYZER_WINDOWS_PATHS` environment variable is
/// set to `true`, in which case it will use Windows-style paths.
///
/// The utility methods all take a posix style path and convert it as
/// appropriate for the actual platform.
mixin ResourceProviderMixin {
  late final resourceProvider = createResourceProvider();

  path.Context get pathContext => resourceProvider.pathContext;

  String convertPath(String filePath) => resourceProvider.convertPath(filePath);

  ResourceProvider createResourceProvider() {
    return Platform.environment['TEST_ANALYZER_WINDOWS_PATHS'] == 'true'
        ? MemoryResourceProvider(context: path.windows)
        : MemoryResourceProvider();
  }

  void deleteAnalysisOptionsYamlFile(String directoryPath) {
    var path = join(directoryPath, file_paths.analysisOptionsYaml);
    deleteFile(path);
  }

  void deleteFile(String path) {
    String convertedPath = convertPath(path);
    resourceProvider.getFile(convertedPath).delete();
  }

  void deleteFile2(File file) {
    deleteFile(file.path);
  }

  void deleteFolder(String path) {
    String convertedPath = convertPath(path);
    resourceProvider.getFolder(convertedPath).delete();
  }

  void deletePackageConfigJsonFile(String directoryPath) {
    var path = join(
      directoryPath,
      file_paths.dotDartTool,
      file_paths.packageConfigJson,
    );
    deleteFile(path);
  }

  String fromUri(Uri uri) {
    return resourceProvider.pathContext.fromUri(uri);
  }

  File getFile(String path) {
    String convertedPath = convertPath(path);
    return resourceProvider.getFile(convertedPath);
  }

  Folder getFolder(String path) {
    String convertedPath = convertPath(path);
    return resourceProvider.getFolder(convertedPath);
  }

  String join(String part1,
          [String? part2,
          String? part3,
          String? part4,
          String? part5,
          String? part6,
          String? part7,
          String? part8]) =>
      resourceProvider.pathContext
          .join(part1, part2, part3, part4, part5, part6, part7, part8);

  void modifyFile(String path, String content) {
    String convertedPath = convertPath(path);
    resourceProvider.getFile(convertedPath).writeAsStringSync(content);
  }

  void modifyFile2(File file, String content) {
    modifyFile(file.path, content);
  }

  File newAnalysisOptionsYamlFile(String directoryPath, String content) {
    String path = join(directoryPath, file_paths.analysisOptionsYaml);
    return newFile(path, content);
  }

  File newBlazeBuildFile(String directoryPath, String content) {
    String path = join(directoryPath, file_paths.blazeBuild);
    return newFile(path, content);
  }

  File newBuildGnFile(String directoryPath, String content) {
    String path = join(directoryPath, file_paths.buildGn);
    return newFile(path, content);
  }

  File newFile(String path, String content) {
    String convertedPath = convertPath(path);
    return resourceProvider.getFile(convertedPath)..writeAsStringSync(content);
  }

  Folder newFolder(String path) {
    String convertedPath = convertPath(path);
    return resourceProvider.getFolder(convertedPath)..create();
  }

  Link newLink(String path, String target) {
    String convertedPath = convertPath(path);
    String convertedTarget = convertPath(target);
    return resourceProvider.getLink(convertedPath)..create(convertedTarget);
  }

  File newPackageConfigJsonFile(String directoryPath, String content) {
    String path = join(
      directoryPath,
      file_paths.dotDartTool,
      file_paths.packageConfigJson,
    );
    return newFile(path, content);
  }

  File newPackageConfigJsonFileFromBuilder(
    String directoryPath,
    PackageConfigFileBuilder builder,
  ) {
    var content = builder.toContent(toUriStr: toUriStr);
    return newPackageConfigJsonFile(directoryPath, content);
  }

  File newPubspecYamlFile(String directoryPath, String content) {
    String path = join(directoryPath, file_paths.pubspecYaml);
    return newFile(path, content);
  }

  void newSinglePackageConfigJsonFile({
    required String packagePath,
    required String name,
  }) {
    var builder = PackageConfigFileBuilder()
      ..add(name: name, rootPath: packagePath);
    newPackageConfigJsonFileFromBuilder(packagePath, builder);
  }

  Uri toUri(String path) {
    path = convertPath(path);
    return resourceProvider.pathContext.toUri(path);
  }

  String toUriStr(String path) {
    return toUri(path).toString();
  }
}

extension ResourceProviderExtensions on ResourceProvider {
  /// Convert the given posix [path] to conform to this provider's path context.
  ///
  /// This is a utility method for testing.
  String convertPath(String filePath) {
    if (pathContext.style == windows.style) {
      if (filePath.startsWith(posix.separator)) {
        filePath = r'C:' + filePath;
      }
      filePath = filePath.replaceAll(posix.separator, windows.separator);
    }
    return filePath;
  }
}
