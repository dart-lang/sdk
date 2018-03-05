// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' hide File;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';

/**
 * A mixin for test classes that adds a [ResourceProvider] and utility methods
 * for manipulating the file system. The utility methods all take a posix style
 * path and convert it as appropriate for the actual platform.
 */
class ResourceProviderMixin {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  void deleteFile(String path) {
    String convertedPath = resourceProvider.convertPath(path);
    resourceProvider.deleteFile(convertedPath);
  }

  void deleteFolder(String path) {
    String convertedPath = resourceProvider.convertPath(path);
    resourceProvider.deleteFolder(convertedPath);
  }

  File getFile(String path) {
    String convertedPath = resourceProvider.convertPath(path);
    return resourceProvider.getFile(convertedPath);
  }

  Folder getFolder(String path) {
    String convertedPath = resourceProvider.convertPath(path);
    return resourceProvider.getFolder(convertedPath);
  }

  void modifyFile(String path, String content) {
    String convertedPath = resourceProvider.convertPath(path);
    resourceProvider.modifyFile(convertedPath, content);
  }

  File newFile(String path, {String content = ''}) {
    String convertedPath = resourceProvider.convertPath(path);
    return resourceProvider.newFile(convertedPath, content);
  }

  File newFileWithBytes(String path, List<int> bytes) {
    String convertedPath = resourceProvider.convertPath(path);
    return resourceProvider.newFileWithBytes(convertedPath, bytes);
  }

  Folder newFolder(String path) {
    String convertedPath = resourceProvider.convertPath(path);
    return resourceProvider.newFolder(convertedPath);
  }

  String join(String part1,
          [String part2,
          String part3,
          String part4,
          String part5,
          String part6,
          String part7,
          String part8]) =>
      resourceProvider.pathContext
          .join(part1, part2, part3, part4, part5, part6, part7, part8);

  String convertPath(String path) => resourceProvider.convertPath(path);

  /// Convert the given [path] to be a valid import uri for this provider's path context.
  String convertPathForImport(String path) {
    path = resourceProvider.convertPath(path);

    // On Windows, absolute import paths are not quite the same as a normal fs path.
    // C:\test.dart must be imported as one of:
    //   import "file:///C:/test.dart"
    //   import "/C:/test.dart"
    if (Platform.isWindows && resourceProvider.pathContext.isAbsolute(path)) {
      // The .path on a file Uri is in the form "/C:/test.dart"
      path = new Uri.file(path).path;
    }

    return path;
  }
}
