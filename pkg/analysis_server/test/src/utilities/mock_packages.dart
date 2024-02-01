// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;
import 'package:path/path.dart' as path;

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
mixin MockPackagesMixin<T extends ResourceProvider> {
  /// The mapping from relative Posix paths of files to the file contents.
  ///
  /// `null` until the cache is first populated.
  Map<String, String>? _cachedFiles;

  /// The path to a folder where mock packages can be written.
  String get packagesRootPath;

  path.Context get pathContext => resourceProvider.pathContext;

  T get resourceProvider;

  Folder addFlutter() {
    var packageFolder = _addFiles('flutter');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addMeta() {
    var packageFolder = _addFiles('meta');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addPedantic() {
    var packageFolder = _addFiles('pedantic');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addUI() {
    var packageFolder = _addFiles('ui');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addVectorMath() {
    var packageFolder = _addFiles('vector_math');
    return packageFolder.getChildAssumingFolder('lib');
  }

  /// Convert the given posix [path] to conform to this provider's path context.
  ///
  /// This is a utility method for testing; paths passed in to other methods in
  /// this class are never converted automatically.
  String convertPath(String inputPath) {
    // TODO(dantup): Copied from MemoryResourceProvider so it can be used by
    //  shared code that's also used in integration tests.
    if (pathContext.style == path.windows.style) {
      if (inputPath.startsWith(path.posix.separator)) {
        inputPath = r'C:' + inputPath;
      }
      inputPath =
          inputPath.replaceAll(path.posix.separator, path.windows.separator);
    }
    return inputPath;
  }

  /// Add files of the given [packageName] to the [provider].
  Folder _addFiles(String packageName) {
    var cachedFiles = _cachedFiles;
    if (cachedFiles == null) {
      cachedFiles = {};
      _cacheFiles(cachedFiles);
      _cachedFiles = cachedFiles;
    }

    for (var entry in cachedFiles.entries) {
      var relativePosixPath = entry.key;
      var relativePathComponents = relativePosixPath.split('/');
      if (relativePathComponents[0] == packageName) {
        var relativePath = pathContext.joinAll(relativePathComponents);
        var path = convertPath('$packagesRootPath/$relativePath');
        resourceProvider.getFile(path).writeAsStringSync(entry.value);
      }
    }

    var packagesFolder =
        resourceProvider.getFolder(convertPath(packagesRootPath));
    return packagesFolder.getChildAssumingFolder(packageName);
  }
}
