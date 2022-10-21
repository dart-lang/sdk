// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_manager.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../../abstract_context.dart';
import '../../../../../services/refactoring/legacy/abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TransformSetManagerTest);
  });
}

@reflectiveTest
class TransformSetManagerTest extends AbstractContextTest {
  TransformSetManager manager = TransformSetManager.instance;

  @override
  void tearDown() {
    super.tearDown();
    manager.clearCache();
  }

  Future<void> test_twoFiles_onePackage() async {
    var folder = '$workspaceRootPath/p1/lib/fix_data';

    _addDataFileIn('$folder/one.yaml', 'p1');
    _addDataFileIn('$folder/deep/dive/two.yaml', 'p1');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'p1', rootPath: '$workspaceRootPath/p1'),
    );

    addSource('/home/test/pubspec.yaml', '');

    var testFile = convertPath('$testPackageLibPath/test.dart');
    addSource(testFile, '');
    var result = await (await session).getResolvedLibraryValid(testFile);
    var sets = manager.forLibrary(result.element);
    expect(sets, hasLength(2));
  }

  Future<void> test_twoFiles_twoPackages() async {
    _addDataFile('p1');
    _addDataFile('p2');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'p1', rootPath: '$workspaceRootPath/p1')
        ..add(name: 'p2', rootPath: '$workspaceRootPath/p2'),
    );

    addSource('/home/test/pubspec.yaml', '');

    var testFile = convertPath('$testPackageLibPath/test.dart');
    addSource(testFile, '');
    var result = await (await session).getResolvedLibraryValid(testFile);
    var sets = manager.forLibrary(result.element);
    expect(sets, hasLength(2));
  }

  Future<void> test_zeroFiles() async {
    // addTestPackageDependency('p1', '/.pub-cache/p1');
    // addTestPackageDependency('p2', '/.pub-cache/p2');
    addSource('/home/test/pubspec.yaml', '');
    var testFile = convertPath('$testPackageLibPath/test.dart');
    addSource(testFile, '');
    var result = await (await session).getResolvedLibraryValid(testFile);
    var sets = manager.forLibrary(result.element);
    expect(sets, hasLength(0));
  }

  void _addDataFile(String packageName) {
    _addDataFileIn(
        '$workspaceRootPath/$packageName/lib/fix_data.yaml', packageName);
  }

  void _addDataFileIn(String path, String packageName) {
    newFile(path, '''
version: 1
transforms:
- title: 'Rename A'
  element:
    uris:
      - 'test.dart'
    components:
      - 'A'
  changes:
    - kind: 'rename'
      newName: 'B'
''');
  }
}

extension on AnalysisSession {
  Future<ResolvedLibraryResult> getResolvedLibraryValid(String path) async {
    return await getResolvedLibrary(path) as ResolvedLibraryResult;
  }
}
