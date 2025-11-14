// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_testing/package_root.dart' as package_root;
import 'package:analyzer_testing/src/mock_packages/fixnum/fixnum.dart'
    as mock_fixnum;
import 'package:analyzer_testing/src/mock_packages/mock_library.dart';
import 'package:analyzer_testing/src/mock_packages/test_reflective_loader/test_reflective_loader.dart'
    as test_reflective_loader;
import 'package:analyzer_testing/src/mock_packages/vector_math/vector_math.dart'
    as mock_vector_math;
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';
import 'package:path/path.dart' as path;

Map<String, String> _cacheFiles() {
  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  var pathContext = resourceProvider.pathContext;
  var packageRoot = pathContext.normalize(package_root.packageRoot);
  var mockPath = pathContext.join(
    packageRoot,
    'analyzer_testing',
    'lib',
    'mock_packages',
    'package_content',
  );

  var cachedFiles = <String, String>{};

  void addFiles(Resource resource) {
    if (resource is Folder) {
      resource.getChildren().forEach(addFiles);
    } else if (resource is File) {
      var relativePath = pathContext.relative(resource.path, from: mockPath);
      var relativePathComponents = pathContext.split(relativePath);
      var relativePosixPath = relativePathComponents.join('/');
      cachedFiles[relativePosixPath] = resource.readAsStringSync();
    }
  }

  addFiles(resourceProvider.getFolder(mockPath));
  return cachedFiles;
}

/// Helper for copying files from "tests/mock_packages" to memory file system
/// for Blaze.
class BlazeMockPackages {
  static final BlazeMockPackages instance = BlazeMockPackages._();

  /// The mapping from relative Posix paths of files to the file contents.
  final Map<String, String> _cachedFiles = _cacheFiles();

  BlazeMockPackages._();

  void addFlutter(ResourceProvider provider) {
    _addFiles(provider, 'flutter');
  }

  void addMeta(ResourceProvider provider) {
    _addFiles(provider, 'meta');
  }

  /// Add files of the given [packageName] to the [provider].
  Folder _addFiles(ResourceProvider provider, String packageName) {
    var packagesPath = provider.convertPath('/workspace/third_party/dart');

    for (var entry in _cachedFiles.entries) {
      var relativePosixPath = entry.key;
      var relativePathComponents = relativePosixPath.split('/');
      if (relativePathComponents[0] == packageName) {
        var relativePath = provider.pathContext.joinAll(relativePathComponents);
        var path = provider.pathContext.join(packagesPath, relativePath);
        provider.getFile(path).writeAsStringSync(entry.value);
      }
    }

    var packagesFolder = provider.getFolder(packagesPath);
    return packagesFolder.getChildAssumingFolder(packageName);
  }
}

/// Helper for copying files from "test/mock_packages" to memory file system.
mixin MockPackagesMixin {
  /// The mapping from relative Posix paths of files to the file contents.
  late final Map<String, String> _cachedFiles = _cacheFiles();

  /// The path to a folder where mock packages can be written.
  String get packagesRootPath;

  path.Context get pathContext => resourceProvider.pathContext;

  ResourceProvider get resourceProvider;

  @Deprecated(
    'The mock angular_meta package is deprecated; use '
    '`PubPackageResolutionTest.newPackage` to make a custom mock',
  )
  Folder addAngularMeta() {
    var packageFolder = _addFiles('angular_meta');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addFfi() {
    var packageFolder = _addFiles('ffi');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addFixnum() {
    var packageFolder = _addFiles2('fixnum', mock_fixnum.units);
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addFlutter() {
    var packageFolder = _addFiles('flutter');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addFlutterTest() {
    var packageFolder = _addFiles('flutter_test');
    return packageFolder.getChildAssumingFolder('lib');
  }

  @Deprecated(
    'The mock js package is deprecated; use '
    '`PubPackageResolutionTest.newPackage` to make a custom mock',
  )
  Folder addJs() {
    var packageFolder = _addFiles('js');
    return packageFolder.getChildAssumingFolder('lib');
  }

  @Deprecated(
    'The mock kernel package is deprecated; use '
    '`PubPackageResolutionTest.newPackage` to make a custom mock',
  )
  Folder addKernel() {
    var packageFolder = _addFiles('kernel');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addMeta() {
    var packageFolder = _addFiles('meta');
    return packageFolder.getChildAssumingFolder('lib');
  }

  @Deprecated(
    'The mock pedantic package is deprecated; use '
    '`PubPackageResolutionTest.newPackage` to make a custom mock',
  )
  Folder addPedantic() {
    var packageFolder = _addFiles('pedantic');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addTestReflectiveLoader() {
    var packageFolder = _addFiles2(
      'test_reflective_loader',
      test_reflective_loader.units,
    );
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addUI() {
    var packageFolder = _addFiles('ui');
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addVectorMath() {
    var packageFolder = _addFiles2('vector_math', mock_vector_math.units);
    return packageFolder.getChildAssumingFolder('lib');
  }

  /// Adds files of the given [packageName] to the [resourceProvider].
  ///
  /// This method adds files from the sources found in
  /// [package_root.packageRoot]. The mock sources are being moved to
  /// `lib/src/mock_sources/`, accessible via [_addFiles2].
  Folder _addFiles(String packageName) {
    Map<String, String> cachedFiles;
    try {
      cachedFiles = _cachedFiles;
    } on StateError catch (e) {
      throw StateError(
        '${e.message}\nAdding built-in mock library for "$packageName" is '
        'not supported when writing a test outside of the Dart SDK source repository.',
      );
    }

    for (var entry in cachedFiles.entries) {
      var relativePosixPath = entry.key;
      var relativePathComponents = relativePosixPath.split('/');
      if (relativePathComponents[0] == packageName) {
        var relativePath = pathContext.joinAll(relativePathComponents);
        var path = resourceProvider.convertPath(
          '$packagesRootPath/$relativePath',
        );
        resourceProvider.getFile(path).writeAsStringSync(entry.value);
      }
    }

    var packagesFolder = resourceProvider.getFolder(
      resourceProvider.convertPath(packagesRootPath),
    );
    return packagesFolder.getChildAssumingFolder(packageName);
  }

  /// Adds files of the given [packageName] to the [resourceProvider].
  Folder _addFiles2(String packageName, List<MockLibraryUnit> units) {
    var absolutePackagePath = resourceProvider.convertPath(
      '$packagesRootPath/$packageName/$packageName',
    );
    for (var unit in units) {
      var absoluteUnitPath = resourceProvider.convertPath(
        '$absolutePackagePath/${unit.path}',
      );
      resourceProvider
          .getFile(absoluteUnitPath)
          .writeAsStringSync(unit.content);
    }

    return resourceProvider.getFolder(absolutePackagePath);
  }
}
