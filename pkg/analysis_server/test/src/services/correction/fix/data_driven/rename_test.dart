// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameClassTest);
    defineReflectiveTests(RenameConstructorTest);
    defineReflectiveTests(RenameExtensionTest);
    defineReflectiveTests(RenameFieldTest);
    defineReflectiveTests(RenameGetterTest);
    defineReflectiveTests(RenameMethodTest);
    defineReflectiveTests(RenameMixinTest);
    defineReflectiveTests(RenameTopLevelFunctionTest);
    defineReflectiveTests(RenameTypedefTest);
  });
}

@reflectiveTest
class RenameClassTest extends _AbstractRenameTest {
  @override
  String get _kind => 'class';

  Future<void> test_constructor_named_deprecated() async {
    setPackageContent('''
@deprecated
class Old {
  Old.c();
}
class New {
  New.c();
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

void f() {
  Old.c();
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  New.c();
}
''');
  }

  Future<void> test_constructor_named_removed() async {
    setPackageContent('''
class New {
  New.c();
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

void f() {
  Old.c();
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  New.c();
}
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_constructor_unnamed_deprecated() async {
    setPackageContent('''
@deprecated
class Old {
  Old();
}
class New {
  New();
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
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

  Future<void> test_constructor_unnamed_removed() async {
    setPackageContent('''
class New {
  New();
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
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

  Future<void> test_inExtends_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

class C extends Old {}
''');
    await assertHasFix('''
import '$importUri';

class C extends New {}
''');
  }

  Future<void> test_inExtends_removed() async {
    setPackageContent('''
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

class C extends Old {}
''');
    await assertHasFix('''
import '$importUri';

class C extends New {}
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_inImplements_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

class C implements Old {}
''');
    await assertHasFix('''
import '$importUri';

class C implements New {}
''');
  }

  Future<void> test_inImplements_removed() async {
    setPackageContent('''
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

class C implements Old {}
''');
    await assertHasFix('''
import '$importUri';

class C implements New {}
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_inOn_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

extension E on Old {}
''');
    await assertHasFix('''
import '$importUri';

extension E on New {}
''');
  }

  Future<void> test_inOn_removed() async {
    setPackageContent('''
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

extension E on Old {}
''');
    await assertHasFix('''
import '$importUri';

extension E on New {}
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_inTypeAnnotation_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

void f(Old o) {}
''');
    await assertHasFix('''
import '$importUri';

void f(New o) {}
''');
  }

  Future<void> test_inTypeAnnotation_removed() async {
    setPackageContent('''
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

void f(Old o) {}
''');
    await assertHasFix('''
import '$importUri';

void f(New o) {}
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_inWith_deprecated() async {
    setPackageContent('''
@deprecated
class Old {}
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

class C with Old {}
''');
    await assertHasFix('''
import '$importUri';

class C with New {}
''');
  }

  Future<void> test_inWith_removed() async {
    setPackageContent('''
class New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

class C with Old {}
''');
    await assertHasFix('''
import '$importUri';

class C with New {}
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_staticField_deprecated() async {
    setPackageContent('''
@deprecated
class Old {
  static String empty = '';
}
class New {
  static String empty = '';
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

var s = Old.empty;
''');
    await assertHasFix('''
import '$importUri';

var s = New.empty;
''');
  }

  Future<void> test_staticField_removed() async {
    setPackageContent('''
class New {
  static String empty = '';
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
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
class RenameConstructorTest extends _AbstractRenameTest {
  @override
  String get _kind => 'constructor';

  Future<void> test_named_named_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  C.old();
  C.new();
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_named_named_removed() async {
    setPackageContent('''
class C {
  C.new();
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_named_unnamed_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  C.old();
  C();
}
''');
    setPackageData(_rename(['C', 'old'], ''));
    await resolveTestCode('''
import '$importUri';

void f() {
  C.old();
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C();
}
''');
  }

  Future<void> test_named_unnamed_removed() async {
    setPackageContent('''
class C {
  C();
}
''');
    setPackageData(_rename(['C', 'old'], ''));
    await resolveTestCode('''
import '$importUri';

void f() {
  C.old();
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C();
}
''');
  }

  Future<void> test_unnamed_named_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  C();
  C.new();
}
''');
    setPackageData(_rename(['C', ''], 'new'));
    await resolveTestCode('''
import '$importUri';

void f() {
  C();
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  C.new();
}
''');
  }

  Future<void> test_unnamed_named_removed() async {
    setPackageContent('''
class C {
  C.new();
}
''');
    setPackageData(_rename(['C', ''], 'new'));
    await resolveTestCode('''
import '$importUri';

void f() {
  C();
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
class RenameExtensionTest extends _AbstractRenameTest {
  @override
  String get _kind => 'extension';

  Future<void> test_override_deprecated() async {
    setPackageContent('''
@deprecated
extension Old on String {
  int get double => length * 2;
}
extension New on String {
  int get double => length * 2;
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

var l = Old('a').double;
''');
    await assertHasFix('''
import '$importUri';

var l = New('a').double;
''');
  }

  Future<void> test_override_removed() async {
    setPackageContent('''
extension New on String {
  int get double => length * 2;
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

var l = Old('a').double;
''');
    await assertHasFix('''
import '$importUri';

var l = New('a').double;
''', errorFilter: ignoreUnusedImport);
  }

  Future<void> test_staticField_deprecated() async {
    setPackageContent('''
@deprecated
extension Old on String {
  static String empty = '';
}
extension New on String {
  static String empty = '';
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

var s = Old.empty;
''');
    await assertHasFix('''
import '$importUri';

var s = New.empty;
''');
  }

  Future<void> test_staticField_removed() async {
    setPackageContent('''
extension New on String {
  static String empty = '';
}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
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
class RenameFieldTest extends _AbstractRenameTest {
  @override
  String get _kind => 'field';

  Future<void> test_instance_reference_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  int old;
  int new;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_instance_reference_removed() async {
    setPackageContent('''
class C {
  int new;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_static_assignment_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  static int old;
  static int new;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_static_assignment_removed() async {
    setPackageContent('''
class C {
  static int new;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_static_reference_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  static int old;
  static int new;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_static_reference_removed() async {
    setPackageContent('''
class C {
  static int new;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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
class RenameGetterTest extends _AbstractRenameTest {
  @override
  String get _kind => 'getter';

  Future<void> test_instance_nonReference_method_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  int get a => 0;
  int get b => 1;
}
class D {
  @deprecated
  void a(int b) {}
}
''');
    setPackageData(_rename(['C', 'a'], 'b'));
    await resolveTestCode('''
import '$importUri';

void f(D d) {
  d.a(2);
}
''');
    await assertNoFix();
  }

  Future<void> test_instance_nonReference_parameter_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  int get a => 0;
  int get b => 1;
}
class D {
  D({@deprecated int a; int c});
}
''');
    setPackageData(_rename(['C', 'a'], 'b'));
    await resolveTestCode('''
import '$importUri';

D d = D(a: 2);
''');
    await assertNoFix();
  }

  Future<void> test_instance_reference_direct_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  int get old => 0;
  int get new => 1;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_instance_reference_direct_removed() async {
    setPackageContent('''
class C {
  int get new => 1;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_instance_reference_indirect_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  int get old => 0;
  int get new => 1;
}
class D {
  C c() => C();
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
import '$importUri';

void f(D d) {
  print(d.c().old);
}
''');
    await assertHasFix('''
import '$importUri';

void f(D d) {
  print(d.c().new);
}
''');
  }

  Future<void> test_instance_reference_indirect_removed() async {
    setPackageContent('''
class C {
  int get new => 1;
}
class D {
  C c() => C();
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
import '$importUri';

void f(D d) {
  print(d.c().old);
}
''');
    await assertHasFix('''
import '$importUri';

void f(D d) {
  print(d.c().new);
}
''');
  }

  Future<void> test_topLevel_reference_deprecated() async {
    setPackageContent('''
@deprecated
int get old => 0;
int get new => 1;
''');
    setPackageData(_rename(['old'], 'new'));
    await resolveTestCode('''
import '$importUri';

void f() {
  old;
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  new;
}
''');
  }

  Future<void> test_topLevel_reference_removed() async {
    setPackageContent('''
int get new => 1;
''');
    setPackageData(_rename(['old'], 'new'));
    await resolveTestCode('''
import '$importUri';

void f() {
  old;
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  new;
}
''', errorFilter: ignoreUnusedImport);
  }
}

@reflectiveTest
class RenameMethodTest extends _AbstractRenameTest {
  @override
  String get _kind => 'method';

  @failingTest
  Future<void> test_instance_override_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  int old() => 0;
  int new() => 0;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_instance_override_removed() async {
    setPackageContent('''
class C {
  int new() => 0;
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_instance_reference_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  int old() {}
  int new() {}
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_instance_reference_removed() async {
    setPackageContent('''
class C {
  int new() {}
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_static_reference_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  static int old() {}
  static int new() {}
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_static_reference_removed() async {
    setPackageContent('''
class C {
  static int new() {}
}
''');
    setPackageData(_rename(['C', 'old'], 'new'));
    await resolveTestCode('''
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
class RenameMixinTest extends _AbstractRenameTest {
  @override
  String get _kind => 'mixin';

  Future<void> test_inWith_deprecated() async {
    setPackageContent('''
@deprecated
mixin Old {}
mixin New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

class C with Old {}
''');
    await assertHasFix('''
import '$importUri';

class C with New {}
''');
  }

  Future<void> test_inWith_removed() async {
    setPackageContent('''
mixin New {}
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
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
class RenameTopLevelFunctionTest extends _AbstractRenameTest {
  @override
  String get _kind => 'function';

  Future<void> test_deprecated() async {
    setPackageContent('''
@deprecated
int old() {}
int new() {}
''');
    setPackageData(_rename(['old'], 'new'));
    await resolveTestCode('''
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

  Future<void> test_removed() async {
    setPackageContent('''
int new() {}
''');
    setPackageData(_rename(['old'], 'new'));
    await resolveTestCode('''
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
class RenameTypedefTest extends _AbstractRenameTest {
  @override
  String get _kind => 'typedef';

  Future<void> test_deprecated() async {
    setPackageContent('''
@deprecated
typedef Old = int Function(int);
typedef New = int Function(int);
''');
    setPackageData(_rename(['Old'], 'New'));
    await resolveTestCode('''
import '$importUri';

void f(Old o) {}
''');
    await assertHasFix('''
import '$importUri';

void f(New o) {}
''');
  }

  Future<void> test_removed() async {
    setPackageContent('''
typedef New = int Function(int);
''');
    setPackageData(_rename(['Old'], 'New'));
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

abstract class _AbstractRenameTest extends DataDrivenFixProcessorTest {
  /// Return the kind of element being renamed.
  String get _kind;

  Transform _rename(List<String> components, String newName) => Transform(
          title: 'title',
          element: ElementDescriptor(
              libraryUris: [Uri.parse(importUri)],
              kind: ElementKindUtilities.fromName(_kind),
              components: components),
          bulkApply: false,
          changes: [
            Rename(newName: newName),
          ]);
}
