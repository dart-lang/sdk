// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_manager.dart';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../../abstract_context.dart';
import '../../../../../services/refactoring/abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TransformSetManagerTest);
  });
}

@reflectiveTest
class TransformSetManagerTest extends AbstractContextTest {
  TransformSetManager manager = TransformSetManager.instance;

  void test_twoFiles() async {
    _addDataFile('p1');
    _addDataFile('p2');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'p1', rootPath: '$workspaceRootPath/p1')
        ..add(name: 'p2', rootPath: '$workspaceRootPath/p2'),
    );

    addSource('/home/test/pubspec.yaml', '');

    var testFile = convertPath('/home/test/lib/test.dart');
    addSource(testFile, '');
    var result = await session.getResolvedLibrary(testFile);
    var sets = manager.forLibrary(result.element);
    expect(sets, hasLength(2));
  }

  void test_zeroFiles() async {
    // addTestPackageDependency('p1', '/.pub-cache/p1');
    // addTestPackageDependency('p2', '/.pub-cache/p2');
    addSource('/home/test/pubspec.yaml', '');
    var testFile = convertPath('/home/test/lib/test.dart');
    addSource(testFile, '');
    var result = await session.getResolvedLibrary(testFile);
    var sets = manager.forLibrary(result.element);
    expect(sets, hasLength(0));
  }

  void _addDataFile(String packageName) {
    newFile('$workspaceRootPath/$packageName/lib/fix_data.yaml', content: '''
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
