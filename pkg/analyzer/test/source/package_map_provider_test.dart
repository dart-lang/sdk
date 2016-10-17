// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.source.package_map_provider_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubPackageMapProviderTest);
  });
}

@reflectiveTest
class PubPackageMapProviderTest {
  DartSdk sdk;
  MemoryResourceProvider resourceProvider;
  PubPackageMapProvider packageMapProvider;
  String projectPath;
  Folder projectFolder;

  PackageMapInfo parsePackageMap(Map obj) {
    return packageMapProvider.parsePackageMap(obj, projectFolder);
  }

  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    Folder sdkFolder = resourceProvider
        .newFolder(resourceProvider.convertPath('/Users/user/dart-sdk'));
    sdk = new FolderBasedDartSdk(resourceProvider, sdkFolder);
    packageMapProvider = new PubPackageMapProvider(resourceProvider, sdk);
    projectPath = resourceProvider.convertPath('/path/to/project');
    projectFolder = resourceProvider.newFolder(projectPath);
  }

  void test_computePackageMap_noLockFile() {
    packageMapProvider =
        new PubPackageMapProvider(resourceProvider, sdk, (Folder folder) {
      fail('Unexpected "pub list" invocation');
    });
    PackageMapInfo info = packageMapProvider.computePackageMap(projectFolder);
    expect(info.packageMap, isNull);
    expect(
        info.dependencies,
        unorderedEquals(
            [resourceProvider.pathContext.join(projectPath, 'pubspec.lock')]));
  }

  void test_parsePackageMap_dontIgnoreNonExistingFolder() {
    String packageName = 'foo';
    String folderPath = resourceProvider.convertPath('/path/to/folder');
    Map<String, List<Folder>> result = parsePackageMap({
      'packages': {packageName: folderPath}
    }).packageMap;
    expect(result, hasLength(1));
    expect(result.keys, contains(packageName));
    expect(result[packageName], hasLength(1));
    expect(result[packageName][0], new isInstanceOf<Folder>());
    expect(result[packageName][0].path, equals(folderPath));
  }

  void test_parsePackageMap_handleDependencies() {
    String path1 =
        resourceProvider.convertPath('/path/to/folder1/pubspec.lock');
    String path2 =
        resourceProvider.convertPath('/path/to/folder2/pubspec.lock');
    resourceProvider.newFile(path1, '...');
    resourceProvider.newFile(path2, '...');
    Set<String> dependencies = parsePackageMap({
      'packages': {},
      'input_files': [path1, path2]
    }).dependencies;
    expect(dependencies, hasLength(2));
    expect(dependencies, contains(path1));
    expect(dependencies, contains(path2));
  }

  void test_parsePackageMap_normalFolder() {
    String packageName = 'foo';
    String folderPath = resourceProvider.convertPath('/path/to/folder');
    resourceProvider.newFolder(folderPath);
    Map<String, List<Folder>> result = parsePackageMap({
      'packages': {packageName: folderPath}
    }).packageMap;
    expect(result, hasLength(1));
    expect(result.keys, contains(packageName));
    expect(result[packageName], hasLength(1));
    expect(result[packageName][0], new isInstanceOf<Folder>());
    expect(result[packageName][0].path, equals(folderPath));
  }

  void test_parsePackageMap_packageMapsToList() {
    String packageName = 'foo';
    String folderPath1 = resourceProvider.convertPath('/path/to/folder1');
    String folderPath2 = resourceProvider.convertPath('/path/to/folder2');
    resourceProvider.newFolder(folderPath1);
    resourceProvider.newFolder(folderPath2);
    Map<String, List<Folder>> result = parsePackageMap({
      'packages': {
        packageName: [folderPath1, folderPath2]
      }
    }).packageMap;
    expect(result, hasLength(1));
    expect(result.keys, contains(packageName));
    expect(result[packageName], hasLength(2));
    for (int i = 0; i < 2; i++) {
      expect(result[packageName][i], new isInstanceOf<Folder>());
      expect(result[packageName][i].path, isIn([folderPath1, folderPath2]));
    }
  }

  void test_parsePackageMap_relativePahInPackages() {
    String packagePath = resourceProvider.convertPath('/path/to/package');
    String relativePackagePath = '../package';
    String packageName = 'foo';
    resourceProvider.newFolder(projectPath);
    resourceProvider.newFolder(packagePath);
    Map<String, List<Folder>> result = parsePackageMap({
      'packages': {
        packageName: [relativePackagePath]
      }
    }).packageMap;
    expect(result[packageName][0].path, equals(packagePath));
  }

  void test_parsePackageMap_relativePathInDependencies() {
    String dependencyPath =
        resourceProvider.convertPath('/path/to/pubspec.lock');
    String relativeDependencyPath = '../pubspec.lock';
    resourceProvider.newFolder(projectPath);
    resourceProvider.newFile(dependencyPath, 'contents');
    Set<String> dependencies = parsePackageMap({
      'packages': {},
      'input_files': [relativeDependencyPath]
    }).dependencies;
    expect(dependencies, hasLength(1));
    expect(dependencies, contains(dependencyPath));
  }
}
