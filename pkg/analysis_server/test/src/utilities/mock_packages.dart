// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;

void _cacheFiles(Map<String, String> cachedFiles) {
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
      var relativePathComponents = pathContext.split(relativePath);
      var relativePosixPath = relativePathComponents.join('/');
      cachedFiles[relativePosixPath] = resource.readAsStringSync();
    }
  }

  addFiles(
    resourceProvider.getFolder(mockPath),
  );
}

/// Helper for copying files from "tests/mock_packages" to memory file system
/// for Blaze.
class BlazeMockPackages {
  static final BlazeMockPackages instance = BlazeMockPackages._();

  /// The mapping from relative Posix paths of files to the file contents.
  final Map<String, String> _cachedFiles = {};

  BlazeMockPackages._() {
    _cacheFiles(_cachedFiles);
  }

  void addFlutter(MemoryResourceProvider provider) {
    _addFiles(provider, 'flutter');
  }

  void addMeta(MemoryResourceProvider provider) {
    _addFiles(provider, 'meta');
  }

  /// Add files of the given [packageName] to the [provider].
  Folder _addFiles(MemoryResourceProvider provider, String packageName) {
    var packagesPath = provider.convertPath('/workspace/third_party/dart');

    for (var entry in _cachedFiles.entries) {
      var relativePosixPath = entry.key;
      var relativePathComponents = relativePosixPath.split('/');
      if (relativePathComponents[0] == packageName) {
        var relativePath = provider.pathContext.joinAll(relativePathComponents);
        var path = provider.pathContext.join(packagesPath, relativePath);
        provider.newFile(path, entry.value);
      }
    }

    var packagesFolder = provider.getFolder(packagesPath);
    return packagesFolder.getChildAssumingFolder(packageName);
  }
}

/// Helper for copying files from "test/mock_packages" to memory file system.
class MockPackages {
  static final MockPackages instance = MockPackages._();

  /// The mapping from relative Posix paths of files to the file contents.
  final Map<String, String> _cachedFiles = {};

  MockPackages._() {
    _cacheFiles(_cachedFiles);
  }

  Folder addFlutter(MemoryResourceProvider provider) {
    var packageFolder = _addFiles(provider, 'flutter');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addMeta(MemoryResourceProvider provider) {
    var packageFolder = _addFiles(provider, 'meta');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addPedantic(MemoryResourceProvider provider) {
    var packageFolder = _addFiles(provider, 'pedantic');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addUI(MemoryResourceProvider provider) {
    var packageFolder = _addFiles(provider, 'ui');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addVectorMath(MemoryResourceProvider provider) {
    var packageFolder = _addFiles(provider, 'vector_math');
    return packageFolder.getChildAssumingFolder('lib');
  }

  /// Add files of the given [packageName] to the [provider].
  Folder _addFiles(MemoryResourceProvider provider, String packageName) {
    var packagesPath = provider.convertPath('/packages');

    for (var entry in _cachedFiles.entries) {
      var relativePosixPath = entry.key;
      var relativePathComponents = relativePosixPath.split('/');
      if (relativePathComponents[0] == packageName) {
        var relativePath = provider.pathContext.joinAll(relativePathComponents);
        var path = provider.pathContext.join(packagesPath, relativePath);
        provider.newFile(path, entry.value);
      }
    }

    var packagesFolder = provider.getFolder(packagesPath);
    return packagesFolder.getChildAssumingFolder(packageName);
  }
}
