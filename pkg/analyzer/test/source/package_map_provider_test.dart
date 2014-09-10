// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.package.map.provider;

import 'dart:convert';

import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';

  group('PubPackageMapProvider', () {
    group('parsePackageMap', () {
      MemoryResourceProvider resourceProvider;
      PubPackageMapProvider packageMapProvider;
      const String projectPath = '/path/to/project';
      Folder projectFolder;

      setUp(() {
        resourceProvider = new MemoryResourceProvider();
        packageMapProvider = new PubPackageMapProvider(resourceProvider, DirectoryBasedDartSdk.defaultSdk);
        projectFolder = resourceProvider.newFolder(projectPath);
      });

      PackageMapInfo parsePackageMap(Object obj) {
        return packageMapProvider.parsePackageMap(JSON.encode(obj), projectFolder);
      }

      test('normal folder', () {
        String packageName = 'foo';
        String folderPath = '/path/to/folder';
        resourceProvider.newFolder(folderPath);
        Map<String, List<Folder>> result = parsePackageMap(
            {'packages': {packageName: folderPath}}).packageMap;
        expect(result, hasLength(1));
        expect(result.keys, contains(packageName));
        expect(result[packageName], hasLength(1));
        expect(result[packageName][0], new isInstanceOf<Folder>());
        expect(result[packageName][0].path, equals(folderPath));
      });

      test('ignore nonexistent folder', () {
        String packageName = 'foo';
        String folderPath = '/path/to/folder';
        Map<String, List<Folder>> result = parsePackageMap(
            {'packages': {packageName: folderPath}}).packageMap;
        expect(result, hasLength(0));
      });

      test('package maps to list', () {
        String packageName = 'foo';
        String folderPath1 = '/path/to/folder1';
        String folderPath2 = '/path/to/folder2';
        resourceProvider.newFolder(folderPath1);
        resourceProvider.newFolder(folderPath2);
        Map<String, List<Folder>> result = parsePackageMap(
            {'packages': {packageName: [folderPath1, folderPath2]}}).packageMap;
        expect(result, hasLength(1));
        expect(result.keys, contains(packageName));
        expect(result[packageName], hasLength(2));
        for (int i = 0; i < 2; i++) {
          expect(result[packageName][i], new isInstanceOf<Folder>());
          expect(result[packageName][i].path, isIn([folderPath1, folderPath2]));
        }
      });

      test('Handle dependencies', () {
        String path1 = '/path/to/folder1/pubspec.lock';
        String path2 = '/path/to/folder2/pubspec.lock';
        resourceProvider.newFile(path1, '...');
        resourceProvider.newFile(path2, '...');
        Set<String> dependencies = parsePackageMap(
            {'packages': {}, 'input_files': [path1, path2]}).dependencies;
        expect(dependencies, hasLength(2));
        expect(dependencies, contains(path1));
        expect(dependencies, contains(path2));
      });

      test('Relative path in packages', () {
        String packagePath = '/path/to/package';
        String relativePackagePath = '../package';
        String packageName = 'foo';
        resourceProvider.newFolder(projectPath);
        resourceProvider.newFolder(packagePath);
        Map<String, List<Folder>> result = parsePackageMap(
            {'packages': {packageName: [relativePackagePath]}}).packageMap;
        expect(result[packageName][0].path, equals(packagePath));
      });

      test('Relative path in dependencies', () {
        String dependencyPath = '/path/to/pubspec.lock';
        String relativeDependencyPath = '../pubspec.lock';
        resourceProvider.newFolder(projectPath);
        resourceProvider.newFile(dependencyPath, 'contents');
        Set<String> dependencies = parsePackageMap(
            {'packages': {}, 'input_files': [relativeDependencyPath]}).dependencies;
        expect(dependencies, hasLength(1));
        expect(dependencies, contains(dependencyPath));
      });
    });
  });
}
