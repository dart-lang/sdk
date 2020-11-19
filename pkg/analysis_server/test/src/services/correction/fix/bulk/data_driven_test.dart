// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_manager.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsNonClassTest);
    defineReflectiveTests(ExtraPositionalArgumentsCouldBeNamedTest);
    defineReflectiveTests(ExtraPositionalArgumentsTest);
    defineReflectiveTests(ImplementsNonClassTest);
    defineReflectiveTests(InvalidOverrideTest);
    defineReflectiveTests(MixinOfNonClassTest);
    defineReflectiveTests(NewWithUndefinedConstructorDefaultTest);
    defineReflectiveTests(NonBulkFixTest);
    defineReflectiveTests(NotEnoughPositionalArgumentsTest);
    defineReflectiveTests(OverrideOnNonOverridingMethodTest);
    defineReflectiveTests(UndefinedClassTest);
    defineReflectiveTests(UndefinedFunctionTest);
    defineReflectiveTests(UndefinedGetterTest);
    defineReflectiveTests(UndefinedIdentifierTest);
    defineReflectiveTests(UndefinedMethodTest);
    defineReflectiveTests(UndefinedSetterTest);
    defineReflectiveTests(WrongNumberOfTypeArgumentsConstructorTest);
    defineReflectiveTests(WrongNumberOfTypeArgumentsExtensionTest);
    defineReflectiveTests(WrongNumberOfTypeArgumentsMethodTest);
    defineReflectiveTests(WrongNumberOfTypeArgumentsTest);
    defineReflectiveTests(NoProducerOverlapsTest);
  });
}

@reflectiveTest
class ExtendsNonClassTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
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
    await resolveTestCode('''
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

  Future<void> test_rename_removed() async {
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
    await resolveTestCode('''
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
    // This fails for two reasons. First, we grab the argument from the outer
    // invocation before we modify it, which causes the unmodified version of
    // the argument to be used for the added named parameter. Second, we produce
    // overlapping edits.
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
    await resolveTestCode('''
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
    await resolveTestCode('''
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
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
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
    await resolveTestCode('''
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

  Future<void> test_rename_removed() async {
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
    await resolveTestCode('''
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
class InvalidOverrideTest extends _DataDrivenTest {
  @failingTest
  Future<void> test_addParameter() async {
    // This functionality hasn't been implemented yet.
    setPackageContent('''
class C {
  void m(int x, int y) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add parameter'
  date: 2020-09-01
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
        expression: '0'
''');
    await resolveTestCode('''
import '$importUri';
class A extends C {
  @override
  void m(int x) {}
}
class B extends C {
  @override
  void m(int x) {}
}
''');
    await assertHasFix('''
import '$importUri';
class A extends C {
  @override
  void m(int x, int y) {}
}
class B extends C {
  @override
  void m(int x, int y) {}
}
''');
  }

  Future<void> test_addTypeParameter() async {
    setPackageContent('''
class C {
  void m<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 0
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
class A extends C {
  @override
  void m() {}
}
class B extends C {
  @override
  void m() {}
}
''');
    await assertHasFix('''
import '$importUri';
class A extends C {
  @override
  void m<T>() {}
}
class B extends C {
  @override
  void m<T>() {}
}
''');
  }
}

@reflectiveTest
class MixinOfNonClassTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
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
    await resolveTestCode('''
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

  Future<void> test_rename_removed() async {
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
    await resolveTestCode('''
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
class NewWithUndefinedConstructorDefaultTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  C([C c]);
  C.new([C c]);
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    constructor: ''
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
C c() => C(C());
''');
    await assertHasFix('''
import '$importUri';
C c() => C.new(C.new());
''');
  }

  Future<void> test_rename_removed() async {
    setPackageContent('''
class C {
  C.new([C c]);
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    constructor: ''
    inClass: 'C'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
import '$importUri';
C c() => C(C());
''');
    await assertHasFix('''
import '$importUri';
C c() => C.new(C.new());
''');
  }
}

@reflectiveTest
class NonBulkFixTest extends _DataDrivenTest {
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
class New {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to New'
  date: 2020-09-01
  bulkApply: false
  element:
    uris: ['$importUri']
    class: 'Old'
  changes:
    - kind: 'rename'
      newName: 'New'
''');
    await resolveTestCode('''
import '$importUri';
class A extends Old {}
class B extends Old {}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class NoProducerOverlapsTest {
  void test_noProducerOverlaps() {
    // Ensure that no error code is used by both data-driven fixes and
    // non-data-driven fixes, as this could result in an LSP "Apply-all" code
    // action accidentally executing data-driven fixes.

    final dataDrivenCodes = <String>{};
    final nonDataDrivenCodes = <String>{
      ...BulkFixProcessor.lintProducerMap.keys,
      ...BulkFixProcessor.nonLintProducerMap.keys.map((c) => c.uniqueName),
    };

    for (final code in BulkFixProcessor.nonLintMultiProducerMap.keys) {
      for (final producerFunc
          in BulkFixProcessor.nonLintMultiProducerMap[code]) {
        final producer = producerFunc();
        if (producer is DataDriven) {
          dataDrivenCodes.add(code.uniqueName);
        } else {
          nonDataDrivenCodes.add(code.uniqueName);
        }
      }
    }

    final intersection = dataDrivenCodes.intersection(nonDataDrivenCodes);
    if (intersection.isNotEmpty) {
      fail(
          'Error codes $intersection have both data-driven and non-data-driven fixes');
    }
  }
}

@reflectiveTest
class NotEnoughPositionalArgumentsTest extends _DataDrivenTest {
  Future<void> test_addParameter() async {
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
    await resolveTestCode('''
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
    await resolveTestCode('''
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
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
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
    await resolveTestCode('''
import '$importUri';
void f(Old a, Old b) {}
''');
    await assertHasFix('''
import '$importUri';
void f(New a, New b) {}
''');
  }

  Future<void> test_rename_removed() async {
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
    await resolveTestCode('''
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
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
@deprecated
int old(int x) => x + 1;
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
    await resolveTestCode('''
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

  Future<void> test_rename_removed() async {
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
    await resolveTestCode('''
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
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  int get old => 0;
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
    await resolveTestCode('''
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

  Future<void> test_rename_removed() async {
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
    await resolveTestCode('''
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
  Future<void> test_rename_topLevelVariable_deprecated() async {
    setPackageContent('''
@deprecated
int old = 0;
int new = 0;
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Rename to new'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    variable: 'old'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
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

  Future<void> test_rename_topLevelVariable_removed() async {
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
    variable: 'old'
  changes:
    - kind: 'rename'
      newName: 'new'
''');
    await resolveTestCode('''
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
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  int old(int x) => x + 1;
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
    await resolveTestCode('''
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

  Future<void> test_rename_removed() async {
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
    await resolveTestCode('''
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
  Future<void> test_rename_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  set new(int x) {}
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
    await resolveTestCode('''
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

  Future<void> test_rename_removed() async {
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
    await resolveTestCode('''
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

@reflectiveTest
class WrongNumberOfTypeArgumentsConstructorTest extends _DataDrivenTest {
  Future<void> test_addTypeParameter() async {
    setPackageContent('''
class C<S, T> {
  C.c([C c]);
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
C f() => C<String>.c(C<String>.c());
''');
    await assertHasFix('''
import '$importUri';
C f() => C<String, int>.c(C<String, int>.c());
''');
  }
}

@reflectiveTest
class WrongNumberOfTypeArgumentsExtensionTest extends _DataDrivenTest {
  Future<void> test_addTypeParameter() async {
    setPackageContent('''
extension E<S, T> on String {
  int m(int x) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    extension: 'E'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
void f(String s) {
  E<String>(s).m(E<String>(s).m(0));
}
''');
    await assertHasFix('''
import '$importUri';
void f(String s) {
  E<String, int>(s).m(E<String, int>(s).m(0));
}
''');
  }
}

@reflectiveTest
class WrongNumberOfTypeArgumentsMethodTest extends _DataDrivenTest {
  Future<void> test_addTypeParameter() async {
    setPackageContent('''
class C {
  int m<S, T>(int x) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
void f(C c) {
  c.m<String>(c.m<String>(0));
}
''');
    await assertHasFix('''
import '$importUri';
void f(C c) {
  c.m<String, int>(c.m<String, int>(0));
}
''');
  }
}

@reflectiveTest
class WrongNumberOfTypeArgumentsTest extends _DataDrivenTest {
  Future<void> test_addTypeParameter() async {
    setPackageContent('''
class C<S, T> {}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
void f(C<String> c) {}
''');
    await assertHasFix('''
import '$importUri';
void f(C<String, int> c) {}
''');
  }

  Future<void> test_addTypeParameter_unnamedConstructor() async {
    setPackageContent('''
class C<S, T> {
  C([C c]);
}
''');
    addPackageDataFile('''
version: 1
transforms:
- title: 'Add type parameter'
  date: 2020-09-01
  element:
    uris: ['$importUri']
    class: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue:
        expression: 'int'
''');
    await resolveTestCode('''
import '$importUri';
C f() => C<String>(C<String>());
''');
    await assertHasFix('''
import '$importUri';
C f() => C<String, int>(C<String, int>());
''');
  }
}

class _DataDrivenTest extends BulkFixProcessorTest {
  /// Return the URI used to import the library created by [setPackageContent].
  String get importUri => 'package:p/lib.dart';

  /// Add the file containing the data used by the data-driven fix with the
  /// given [content].
  void addPackageDataFile(String content) {
    newFile('$workspaceRootPath/p/lib/${TransformSetManager.dataFileName}',
        content: content);
  }

  /// Set the content of the library that defines the element referenced by the
  /// data on which this test is based.
  void setPackageContent(String content) {
    newFile('$workspaceRootPath/p/lib/lib.dart', content: content);
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'p', rootPath: '$workspaceRootPath/p'),
    );
  }
}
