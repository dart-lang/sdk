// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
}
