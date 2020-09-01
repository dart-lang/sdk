// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EndToEndTest);
  });
}

@reflectiveTest
class EndToEndTest extends DataDrivenFixProcessorTest {
  Future<void> test_rename() async {
    setPackageContent('''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  element:
    uris:
      - '$importUri'
    components:
      - 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestUnit('''
import '$importUri';

void f(Old o) {}
''');
    await assertHasFix('''
import '$importUri';

void f(New o) {}
''', errorFilter: ignoreUnusedImport);
  }
}
