// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/changes_selector.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename_parameter.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameParameterInConstructorTest);
    defineReflectiveTests(RenameParameterInMethodTest);
    defineReflectiveTests(RenameParameterInTopLevelFunctionTest);
  });
}

@reflectiveTest
class RenameParameterInConstructorTest extends _AbstractRenameParameterInTest {
  @override
  String get _kind => 'constructor';

  Future<void> test_named_deprecated() async {
    setPackageContent('''
class C {
  C.named({int b, @deprecated int a});
}
''');
    setPackageData(_rename(['C', 'named'], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

void f() {
  C.named(a: 0);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C.named(b: 0);
}
''');
  }

  Future<void> test_named_removed() async {
    setPackageContent('''
class C {
  C.named({int b});
}
''');
    setPackageData(_rename(['C', 'named'], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

void f() {
  C.named(a: 0);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C.named(b: 0);
}
''');
  }

  Future<void> test_unnamed_deprecated() async {
    setPackageContent('''
class C {
  C({int b, @deprecated int a});
}
''');
    setPackageData(_rename(['C', ''], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

void f() {
  C(a: 0);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C(b: 0);
}
''');
  }

  Future<void> test_unnamed_removed() async {
    setPackageContent('''
class C {
  C({int b});
}
''');
    setPackageData(_rename(['C', ''], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

void f() {
  C(a: 0);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C(b: 0);
}
''');
  }
}

@reflectiveTest
class RenameParameterInMethodTest extends _AbstractRenameParameterInTest {
  @override
  String get _kind => 'method';

  Future<void> test_differentMethod() async {
    setPackageContent('''
class C {
  int m({int b, @deprecated int a}) => 0;
}
''');
    setPackageData(_rename(['D', 'm'], 'a', 'nbew'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(a: 1);
}
''');
    await assertNoFix();
  }

  Future<void> test_instance_override_deprecated() async {
    setPackageContent('''
class C {
  int m({int b, @deprecated int a}) => 0;
}
''');
    setPackageData(_rename(['C', 'm'], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

class D extends C {
  @override
  int m({int a}) => 0;
}
''');
    await assertHasFix('''
import '$importUri';

class D extends C {
  @override
  int m({int b, @deprecated int a}) => 0;
}
''');
  }

  Future<void> test_instance_override_removed() async {
    setPackageContent('''
class C {
  int m({int b}) => 0;
}
''');
    setPackageData(_rename(['C', 'm'], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

class D extends C {
  @override
  int m({int a}) => 0;
}
''');
    await assertHasFix('''
import '$importUri';

class D extends C {
  @override
  int m({int b}) => 0;
}
''');
  }

  Future<void> test_instance_reference_deprecated() async {
    setPackageContent('''
class C {
  int m({int b, @deprecated int a}) => 0;
}
''');
    setPackageData(_rename(['C', 'm'], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(a: 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m(b: 1);
}
''');
  }

  Future<void> test_instance_reference_removed() async {
    setPackageContent('''
class C {
  int m({int b}) => 0;
}
''');
    setPackageData(_rename(['C', 'm'], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(a: 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m(b: 1);
}
''');
  }

  Future<void> test_static_deprecated() async {
    setPackageContent('''
class C {
  static int m({int b, @deprecated int a}) => 0;
}
''');
    setPackageData(_rename(['C', 'm'], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

void f() {
  C.m(a: 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C.m(b: 1);
}
''');
  }

  Future<void> test_static_removed() async {
    setPackageContent('''
class C {
  static int m({int b}) => 0;
}
''');
    setPackageData(_rename(['C', 'm'], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

void f() {
  C.m(a: 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C.m(b: 1);
}
''');
  }
}

@reflectiveTest
class RenameParameterInTopLevelFunctionTest
    extends _AbstractRenameParameterInTest {
  @override
  String get _kind => 'function';

  Future<void> test_deprecated() async {
    setPackageContent('''
int f({int b, @deprecated int a}) => 0;
''');
    setPackageData(_rename(['f'], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

var x = f(a: 1);
''');
    await assertHasFix('''
import '$importUri';

var x = f(b: 1);
''');
  }

  Future<void> test_removed() async {
    setPackageContent('''
int f({int b}) => 0;
''');
    setPackageData(_rename(['f'], 'a', 'b'));
    await resolveTestCode('''
import '$importUri';

var x = f(a: 1);
''');
    await assertHasFix('''
import '$importUri';

var x = f(b: 1);
''');
  }
}

abstract class _AbstractRenameParameterInTest
    extends DataDrivenFixProcessorTest {
  /// Return the kind of element containing the parameter being renamed.
  String get _kind;

  Transform _rename(List<String> components, String oldName, String newName) =>
      Transform(
          title: 'title',
          element: ElementDescriptor(
              libraryUris: [Uri.parse(importUri)],
              kind: ElementKindUtilities.fromName(_kind),
              components: components),
          bulkApply: false,
          changesSelector: UnconditionalChangesSelector([
            RenameParameter(newName: newName, oldName: oldName),
          ]));
}
