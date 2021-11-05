// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_manager.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkFixCollectionTest);
    defineReflectiveTests(SdkFixCoreTest);
    defineReflectiveTests(SdkNoDataFileTest);
  });
}

class AbstractSdkFixTest extends DataDrivenFixProcessorTest {
  void addSdkDataFile(String content) {
    newFile('${sdkRoot.path}/lib/_internal/${TransformSetManager.dataFileName}',
        content: content);
  }

  @override
  void setUp() {
    addSdkDataFile('''
version: 1
transforms:
- title: 'Rename to Bar'
  date: 2021-01-22
  element:
    uris:
      - '$importUri'
    class: 'Foo'
  changes:
    - kind: 'rename'
      newName: 'Bar'
''');
    super.setUp();
  }
}

@reflectiveTest
class SdkFixCollectionTest extends AbstractSdkFixTest {
  @override
  String importUri = 'dart:collection';

  Future<void> test_rename() async {
    await resolveTestCode('''
import '$importUri';

void f(Foo o) {}
''');
    await assertHasFix('''
import '$importUri';

void f(Bar o) {}
''', errorFilter: ignoreUnusedImport);
  }
}

@reflectiveTest
class SdkFixCoreTest extends AbstractSdkFixTest {
  @override
  String importUri = 'dart:core';

  Future<void> test_rename() async {
    await resolveTestCode('''
import '$importUri';

void f(Foo o) {}
''');
    await assertHasFix('''
import '$importUri';

void f(Bar o) {}
''');
  }

  Future<void> test_rename_noImport() async {
    await resolveTestCode('''
void f(Foo o) {}
''');
    await assertHasFix('''
void f(Bar o) {}
''');
  }
}

@reflectiveTest
class SdkNoDataFileTest extends DataDrivenFixProcessorTest {
  Future<void> test_noExceptions() async {
    await resolveTestCode('''
var x = '';
''');
    assertNoExceptions();
  }
}
