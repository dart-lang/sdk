// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Rename_DeprecatedMemberUseTest);
    defineReflectiveTests(Rename_ExtendsNonClassTest);
    defineReflectiveTests(Rename_ImplementsNonClassTest);
    defineReflectiveTests(Rename_MixinOfNonClassTest);
    defineReflectiveTests(Rename_OverrideOnNonOverridingMethodTest);
    defineReflectiveTests(Rename_UndefinedClassTest);
    defineReflectiveTests(Rename_UndefinedFunctionTest);
    defineReflectiveTests(Rename_UndefinedGetterTest);
    defineReflectiveTests(Rename_UndefinedIdentifierTest);
    defineReflectiveTests(Rename_UndefinedMethodTest);
  });
}

@reflectiveTest
class Rename_DeprecatedMemberUseTest extends _AbstractRenameTest {
  Future<void> test_class_reference_inExtends() async {
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

class C extends Old {}
''');
    await assertHasFix('''
import '$importUri';

class C extends New {}
''');
  }

  Future<void> test_class_reference_inImplements() async {
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

class C implements Old {}
''');
    await assertHasFix('''
import '$importUri';

class C implements New {}
''');
  }

  Future<void> test_class_reference_inOn() async {
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

extension E on Old {}
''');
    await assertHasFix('''
import '$importUri';

extension E on New {}
''');
  }

  Future<void> test_class_reference_inTypeAnnotation() async {
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

  Future<void> test_class_reference_inWith() async {
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

class C with Old {}
''');
    await assertHasFix('''
import '$importUri';

class C with New {}
''');
  }

  Future<void> test_class_reference_staticField() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

@deprecated
class Old {
  static String empty = '';
}
class New {
  static String empty = '';
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

var s = Old.empty;
''');
    await assertHasFix('''
import '$importUri';

var s = New.empty;
''');
  }

  Future<void> test_constructor_named_reference() async {
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

  Future<void> test_constructor_unnamed_reference() async {
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

  Future<void> test_extension_reference_override() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

@deprecated
extension Old on String {
  int get double => length * 2;
}
extension New on String {
  int get double => length * 2;
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

var l = Old('a').double;
''');
    await assertHasFix('''
import '$importUri';

var l = New('a').double;
''');
  }

  Future<void> test_extension_reference_staticField() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

@deprecated
extension Old on String {
  static String empty = '';
}
extension New on String {
  static String empty = '';
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

var s = Old.empty;
''');
    await assertHasFix('''
import '$importUri';

var s = New.empty;
''');
  }

  Future<void> test_field_instance_reference() async {
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

  Future<void> test_field_static_assignment() async {
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
  C.old = 0;
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C.new = 0;
}
''');
  }

  Future<void> test_field_static_reference() async {
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

  @failingTest
  Future<void> test_method_instance_override() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

class C {
  @deprecated
  int old() => 0;
  int new() => 0;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestUnit('''
import '$importUri';

class D extends C {
  @override
  int old() => 0;
}
''');
    await assertHasFix('''
import '$importUri';

class D extends C {
  @override
  int new() => 0;
}
''');
  }

  Future<void> test_method_instance_reference() async {
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

  Future<void> test_method_static_reference() async {
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

  Future<void> test_mixin_reference_inWith() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

@deprecated
mixin Old {}
mixin New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

class C with Old {}
''');
    await assertHasFix('''
import '$importUri';

class C with New {}
''');
  }

  Future<void> test_topLevelFunction_reference() async {
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

  Future<void> test_typedef_reference() async {
    addMetaPackage();
    setPackageContent('''
import 'package:meta/meta.dart';

@deprecated
typedef Old = int Function(int);
typedef New = int Function(int);
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
}

@reflectiveTest
class Rename_ExtendsNonClassTest extends _AbstractRenameTest {
  Future<void> test_class_reference_inExtends() async {
    setPackageContent('''
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

class C extends Old {}
''');
    await assertHasFix('''
import '$importUri';

class C extends New {}
''', errorFilter: ignoreUnusedImport);
  }
}

@reflectiveTest
class Rename_ImplementsNonClassTest extends _AbstractRenameTest {
  Future<void> test_class_reference_inImplements() async {
    setPackageContent('''
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

class C implements Old {}
''');
    await assertHasFix('''
import '$importUri';

class C implements New {}
''', errorFilter: ignoreUnusedImport);
  }
}

@reflectiveTest
class Rename_MixinOfNonClassTest extends _AbstractRenameTest {
  Future<void> test_class_reference_inWith() async {
    setPackageContent('''
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

class C with Old {}
''');
    await assertHasFix('''
import '$importUri';

class C with New {}
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_mixin_reference_inWith() async {
    setPackageContent('''
mixin New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

class C with Old {}
''');
    await assertHasFix('''
import '$importUri';

class C with New {}
''', errorFilter: ignoreUnusedImport);
  }
}

@reflectiveTest
class Rename_OverrideOnNonOverridingMethodTest extends _AbstractRenameTest {
  Future<void> test_method_instance_override() async {
    setPackageContent('''
class C {
  int new() => 0;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestUnit('''
import '$importUri';

class D extends C {
  @override
  int old() => 0;
}
''');
    await assertHasFix('''
import '$importUri';

class D extends C {
  @override
  int new() => 0;
}
''');
  }
}

@reflectiveTest
class Rename_UndefinedClassTest extends _AbstractRenameTest {
  Future<void> test_class_reference_inOn() async {
    setPackageContent('''
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

extension E on Old {}
''');
    await assertHasFix('''
import '$importUri';

extension E on New {}
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_class_reference_inTypeAnnotation() async {
    setPackageContent('''
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
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_typedef_reference() async {
    setPackageContent('''
typedef New = int Function(int);
''');
    setPackageData(_rename(['Old'], 'New'));
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

@reflectiveTest
class Rename_UndefinedFunctionTest extends _AbstractRenameTest {
  Future<void> test_constructor_unnamed_reference() async {
    setPackageContent('''
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
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_extension_reference_override() async {
    setPackageContent('''
extension New on String {
  int get double => length * 2;
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

var l = Old('a').double;
''');
    await assertHasFix('''
import '$importUri';

var l = New('a').double;
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_field_instance_reference() async {
    setPackageContent('''
class C {
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

  Future<void> test_topLevelFunction_reference() async {
    setPackageContent('''
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
''', errorFilter: ignoreUnusedImport);
  }
}

@reflectiveTest
class Rename_UndefinedGetterTest extends _AbstractRenameTest {
  Future<void> test_field_static_reference() async {
    setPackageContent('''
class C {
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
}

@reflectiveTest
class Rename_UndefinedIdentifierTest extends _AbstractRenameTest {
  Future<void> test_class_reference_staticField() async {
    setPackageContent('''
class New {
  static String empty = '';
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

var s = Old.empty;
''');
    await assertHasFix('''
import '$importUri';

var s = New.empty;
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_extension_reference_staticField() async {
    setPackageContent('''
extension New on String {
  static String empty = '';
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestUnit('''
import '$importUri';

var s = Old.empty;
''');
    await assertHasFix('''
import '$importUri';

var s = New.empty;
''', errorFilter: ignoreUnusedImport);
  }
}

@reflectiveTest
class Rename_UndefinedMethodTest extends _AbstractRenameTest {
  Future<void> test_constructor_named_reference() async {
    setPackageContent('''
class C {
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

  Future<void> test_method_instance_reference() async {
    setPackageContent('''
class C {
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

  Future<void> test_method_static_reference() async {
    setPackageContent('''
class C {
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
}

@reflectiveTest
class Rename_UndefinedSetterTest extends _AbstractRenameTest {
  Future<void> test_field_static_assignment() async {
    setPackageContent('''
class C {
  static int new;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestUnit('''
import '$importUri';

void f() {
  C.old = 0;
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C.new = 0;
}
''');
  }
}

class _AbstractRenameTest extends DataDrivenFixProcessorTest {
  Transform _rename(List<String> components, String newName) => Transform(
          title: 'title',
          element: ElementDescriptor(
              libraryUris: [importUri], components: components),
          changes: [
            Rename(newName: newName),
          ]);
}
