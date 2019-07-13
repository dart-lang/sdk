// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:front_end/src/testing/package_root.dart' as package_root;

/// Helper for copying files from "tests/mock_packages" to memory file system.
class MockPackages {
  static final MockPackages instance = MockPackages._();

  /// The mapping from relative Posix paths of files to the file contents.
  Map<String, String> _cachedFiles = {};

  MockPackages._() {
    _cacheFiles();
  }

  Folder addFlutter(MemoryResourceProvider provider) {
    var packageFolder = _addFiles(provider, 'flutter');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addMeta(MemoryResourceProvider provider) {
    var packageFolder = _addFiles(provider, 'meta');
    return packageFolder.getChildAssumingFolder('lib');
  }

  /// Add files of the given [packageName] to the [provider].
  Folder _addFiles(MemoryResourceProvider provider, String packageName) {
    var packagesPath = provider.convertPath('/packages');

    for (var relativePath in _cachedFiles.keys) {
      if (relativePath.startsWith('$packageName/')) {
        var content = _cachedFiles[relativePath];
        var path = provider.pathContext
            .normalize(provider.pathContext.join(packagesPath, relativePath));
        provider.newFile(path, content);
      }
    }

    var packagesFolder = provider.getFolder(packagesPath);
    return packagesFolder.getChildAssumingFolder(packageName);
  }

  void _cacheFiles() {
    var resourceProvider = PhysicalResourceProvider.INSTANCE;
    var pathContext = resourceProvider.pathContext;
    var packageRoot = pathContext.normalize(package_root.packageRoot);
    var mockPath = pathContext.join(
      packageRoot,
      'analysis_server',
      'test',
      'mock_packages',
    );

    void addFiles(Resource resource) {
      if (resource is Folder) {
        resource.getChildren().forEach(addFiles);
      } else if (resource is File) {
        var relativePath = pathContext.relative(
          resource.path,
          from: mockPath,
        );
        var relativePosixPath = pathContext.split(relativePath).join('/');
        _cachedFiles[relativePosixPath] = resource.readAsStringSync();
      }
    }

    addFiles(
      resourceProvider.getFolder(mockPath),
    );
  }
}
