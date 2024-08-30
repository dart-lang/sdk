// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../fix_processor.dart';
import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TestUseCaseTest);
  });
}

@reflectiveTest
class TestUseCaseTest extends DataDrivenFixProcessorTest {
  Future<void> test_expect_export_deprecated() async {
    newFile('$workspaceRootPath/p/lib/lib.dart', '''
library p;
@deprecated
export 'package:matcher/expect.dart' show expect;
''');
    newFile('$workspaceRootPath/matcher/lib/expect.dart', '''
void expect(actual, matcher) {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'matcher', rootPath: '$workspaceRootPath/matcher')
        ..add(name: 'p', rootPath: '$workspaceRootPath/p'),
    );

    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace expect'
    date: 2022-05-12
    bulkApply: false
    element:
      uris: ['$importUri']
      function: 'expect'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:matcher/expect.dart']
          function: 'expect'
''');
    await resolveTestCode('''
import '$importUri';

main() {
  expect(true, true);
}
''');
    await assertHasFix('''
import 'package:matcher/expect.dart';
import '$importUri';

main() {
  expect(true, true);
}
''');
  }

  Future<void> test_expect_removed() async {
    setPackageContent('''
''');

    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace expect'
    date: 2022-05-12
    bulkApply: false
    element:
      uris: ['$importUri']
      function: 'expect'
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['package:matcher/expect.dart']
          function: 'expect'
''');
    await resolveTestCode('''
import '$importUri';

main() {
  expect(true, true);
}
''');
    await assertHasFix('''
import 'package:matcher/expect.dart';
import '$importUri';

main() {
  expect(true, true);
}
''', errorFilter: ignoreUnusedImport);
  }
}
