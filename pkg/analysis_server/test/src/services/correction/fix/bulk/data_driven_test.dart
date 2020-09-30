// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_manager.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsNonClassTest);
    defineReflectiveTests(ExtraPositionalArgumentsCouldBeNamedTest);
    defineReflectiveTests(ExtraPositionalArgumentsTest);
    defineReflectiveTests(ImplementsNonClassTest);
    defineReflectiveTests(MixinOfNonClassTest);
    defineReflectiveTests(NotEnoughPositionalArgumentsTest);
    defineReflectiveTests(OverrideOnNonOverridingMethodTest);
    defineReflectiveTests(UndefinedClassTest);
    defineReflectiveTests(UndefinedFunctionTest);
    defineReflectiveTests(UndefinedGetterTest);
    defineReflectiveTests(UndefinedIdentifierTest);
    defineReflectiveTests(UndefinedMethodTest);
    defineReflectiveTests(UndefinedSetterTest);
  });
}

@reflectiveTest
class ExtendsNonClassTest extends _DataDrivenTest {
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
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestUnit('''
import '$importUri';
class A extends Old {}
class B extends Old {}
''');
    await assertHasFix('''
import '$importUri';
class A extends New {}
class B extends New {}
''');
  }
}

@reflectiveTest
class ExtraPositionalArgumentsCouldBeNamedTest extends _DataDrivenTest {
  @failingTest
  Future<void> test_replaceParameter() async {
    // This fails because we grab the argument from the outer invocation before
    // we modify it, but then we add the edits to modify it, which causes the
    // wrong code to be put in the wrong places.
    setPackageContent('''
int f(int x, {int y = 0}) => x;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Replace parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 1
      name: 'y'
      style: required_named
      argumentValue:
        expression: '{% old %}'
        variables:
          old:
            kind: 'argument'
            index: 1
    - kind: 'removeParameter'
      index: 1
''');
    await resolveTestUnit('''
import '$importUri';
void g() {
  f(0, f(1, 2));
}
''');
    await assertHasFix('''
import '$importUri';
void g() {
  f(0, y: f(1, y: 2));
}
''');
  }
}

@reflectiveTest
class ExtraPositionalArgumentsTest extends _DataDrivenTest {
  @failingTest
  Future<void> test_removeParameter() async {
    // This fails because we delete the extra argument from the inner invocation
    // (`, 2`) before deleting the argument from the outer invocation, which
    // results in three characters too many being deleted.
    setPackageContent('''
int f(int x) => x;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Remove parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    function: 'f'
  changes:
    - kind: 'removeParameter'
      index: 1
''');
    await resolveTestUnit('''
import '$importUri';
void g() {
  f(0, f(1, 2));
}
''');
    await assertHasFix('''
import '$importUri';
void g() {
  f(0);
}
''');
  }
}

@reflectiveTest
class ImplementsNonClassTest extends _DataDrivenTest {
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
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestUnit('''
import '$importUri';
class A implements Old {}
class B implements Old {}
''');
    await assertHasFix('''
import '$importUri';
class A implements New {}
class B implements New {}
''');
  }
}

@reflectiveTest
class MixinOfNonClassTest extends _DataDrivenTest {
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
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestUnit('''
import '$importUri';
class A with Old {}
class B with Old {}
''');
    await assertHasFix('''
import '$importUri';
class A with New {}
class B with New {}
''');
  }
}

@reflectiveTest
class NotEnoughPositionalArgumentsTest extends _DataDrivenTest {
  Future<void> test_removeParameter() async {
    setPackageContent('''
int f(int x, int y) => x + y;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 1
      name: 'y'
      style: required_positional
      argumentValue:
        expression: '0'
''');
    await resolveTestUnit('''
import '$importUri';
void g() {
  f(f(0));
}
''');
    await assertHasFix('''
import '$importUri';
void g() {
  f(f(0, 0), 0);
}
''');
  }
}

@reflectiveTest
class OverrideOnNonOverridingMethodTest extends _DataDrivenTest {
  Future<void> test_rename() async {
    setPackageContent('''
class C {
  int new(int x) => x + 1;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestUnit('''
import '$importUri';
class D extends C {
  @override
  int old(int x) => x + 2;
}
class E extends C {
  @override
  int old(int x) => x + 3;
}
''');
    await assertHasFix('''
import '$importUri';
class D extends C {
  @override
  int new(int x) => x + 2;
}
class E extends C {
  @override
  int new(int x) => x + 3;
}
''');
  }
}

@reflectiveTest
class UndefinedClassTest extends _DataDrivenTest {
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
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestUnit('''
import '$importUri';
void f(Old a, Old b) {}
''');
    await assertHasFix('''
import '$importUri';
void f(New a, New b) {}
''');
  }
}

@reflectiveTest
class UndefinedFunctionTest extends _DataDrivenTest {
  Future<void> test_rename() async {
    setPackageContent('''
int new(int x) => x + 1;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    function: 'old'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestUnit('''
import '$importUri';
void f() {
  old(old(0));
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  new(new(0));
}
''');
  }
}

@reflectiveTest
class UndefinedGetterTest extends _DataDrivenTest {
  Future<void> test_rename() async {
    setPackageContent('''
class C {
  int get new => 0;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    getter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestUnit('''
import '$importUri';
void f(C a, C b) {
  a.old + b.old;
}
''');
    await assertHasFix('''
import '$importUri';
void f(C a, C b) {
  a.new + b.new;
}
''');
  }
}

@reflectiveTest
class UndefinedIdentifierTest extends _DataDrivenTest {
  Future<void> test_rename_topLevelVariable() async {
    setPackageContent('''
int new = 0;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    function: 'old'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestUnit('''
import '$importUri';
void f() {
  old + old;
}
''');
    await assertHasFix('''
import '$importUri';
void f() {
  new + new;
}
''');
  }
}

@reflectiveTest
class UndefinedMethodTest extends _DataDrivenTest {
  Future<void> test_rename() async {
    setPackageContent('''
class C {
  int new(int x) => x + 1;
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestUnit('''
import '$importUri';
void f(C a, C b) {
  a.old(b.old(0));
}
''');
    await assertHasFix('''
import '$importUri';
void f(C a, C b) {
  a.new(b.new(0));
}
''');
  }
}

@reflectiveTest
class UndefinedSetterTest extends _DataDrivenTest {
  Future<void> test_rename() async {
    setPackageContent('''
class C {
  set new(int x) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    setter: 'old'
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestUnit('''
import '$importUri';
void f(C a, C b) {
  a.old = b.old = 1;
}
''');
    await assertHasFix('''
import '$importUri';
void f(C a, C b) {
  a.new = b.new = 1;
}
''');
  }
}

class _DataDrivenTest extends BulkFixProcessorTest {
  /// Return the URI used to import the library created by [setPackageContent].
  String get importUri => 'package:p/lib.dart';

  /// Add the file containing the data used by the data-driven fix with the
  /// given [content].
  void addPackageDataFile(String content) {
    addPackageFile('p', TransformSetManager.dataFileName, content);
  }

  /// Set the content of the library that defines the element referenced by the
  /// data on which this test is based.
  void setPackageContent(String content) {
    addPackageFile('p', 'lib.dart', content);
  }
}
