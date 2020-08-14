// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename_change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameChange_DeprecatedMemberUseTest);
  });
}

@reflectiveTest
class RenameChange_DeprecatedMemberUseTest extends DataDrivenFixProcessorTest {
  @override
  FixKind get kind => DartFixKind.DATA_DRIVEN;

  Future<void> test_class() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

@deprecated
class Old {}
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

void f(Old o) {}
''');
    await assertHasFix('''
import '$importUri';

void f(New o) {}
''');
  }

  Future<void> test_constructor_named() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  C.old();
  C.new();
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestUnit('''
import '$importUri';

void f() {
  C.old();
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C.new();
}
''');
  }

  Future<void> test_constructor_unnamed() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

@deprecated
class Old {
  Old();
}
class New {
  New();
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

void f() {
  Old();
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  New();
}
''');
  }

  Future<void> test_field_instance() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int old;
  int new;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.old;
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.new;
}
''');
  }

  Future<void> test_field_static() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  static int old;
  static int new;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestUnit('''
import '$importUri';

void f() {
  C.old;
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C.new;
}
''');
  }

  Future<void> test_method_instance() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int old() {}
  int new() {}
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestUnit('''
import '$importUri';

void f(C c) {
  c.old();
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.new();
}
''');
  }

  Future<void> test_method_static() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  static int old() {}
  static int new() {}
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestUnit('''
import '$importUri';

void f() {
  C.old();
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C.new();
}
''');
  }

  Future<void> test_topLevelFunction() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

@deprecated
int old() {}
int new() {}
''');
    setPackageData(_rename(['old'], 'new'));
    await resolveTestUnit('''
import '$importUri';

void f() {
  old();
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  new();
}
''');
  }

  Transform _rename(List<String> components, String newName) => Transform(
          title: 'title',
          element: ElementDescriptor(
              libraryUris: [importUri], components: components),
          changes: [
            RenameChange(newName: newName),
          ]);
}
