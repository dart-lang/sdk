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
  Future<void> test_addParameter() async {
    setPackageContent('''
class C {
  void m(int x, int y) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add parameter'
  date: 2020-09-09
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addParameter'
      index: 1
      name: 'y'
      style: required_positional
      argumentValue:
        expression: '{% y %}'
        variables:
          y:
            kind: 'fragment'
            value: 'arguments[0]'
''');
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m(0, 0);
}
''');
  }

  Future<void> test_addTypeParameter() async {
    setPackageContent('''
class C {
  void m<S, T>(Type t) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type argument'
  date: 2020-09-03
  element:
    uris:
      - '$importUri'
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: '{% t %}'
        variables:
          t:
            kind: 'fragment'
            value: 'arguments[0]'
''');
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m<int>(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m<int, String>(String);
}
''');
  }

  Future<void> test_removeParameter() async {
    setPackageContent('''
class C {
  void m(int x) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add argument'
  date: 2020-09-09
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'removeParameter'
      index: 1
''');
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0, 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m(0);
}
''');
  }

  Future<void> test_rename() async {
    setPackageContent('''
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  element:
    uris:
      - '$importUri'
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';

void f(Old o) {}
''');
    await assertHasFix('''
import '$importUri';

void f(New o) {}
''', errorFilter: ignoreUnusedImport);
  }
}
