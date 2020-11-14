// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/changes_selector.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/modify_parameters.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ModifyParametersOfMethodTest);
    defineReflectiveTests(ModifyParametersOfTopLevelFunctionTest);
  });
}

@reflectiveTest
class ModifyParametersOfMethodTest extends _ModifyParameters {
  @override
  String get _kind => 'method';

  Future<void> test_add_first_optionalNamed_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m({int b}) {}
  void m2({int a, int b}) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(0, 'a', false, false, null)],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(b: 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(b: 1);
}
''');
  }

  Future<void> test_add_first_optionalPositional_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m([int b]) {}
  void m2([int a, int b]) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(0, 'a', false, true, codeTemplate('0'))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0, 1);
}
''');
  }

  Future<void> test_add_first_requiredNamed_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m({int b}) {}
  void m2({int a, int b}) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(0, 'a', true, false, codeTemplate('0'))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(b: 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(b: 1, a: 0);
}
''');
  }

  Future<void> test_add_first_requiredPositional_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int b) {}
  void m2(int a, int b) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(0, 'a', true, true, codeTemplate('0'))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0, 1);
}
''');
  }

  Future<void> test_add_last_optionalNamed_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a) {}
  void m2(int a, {int b}) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(1, 'b', false, false, null)],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0);
}
''');
  }

  Future<void> test_add_last_optionalPositional_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a) {}
  void m2(int a, [int b]) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(1, 'b', false, true, codeTemplate('1'))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0);
}
''');
  }

  Future<void> test_add_last_requiredNamed_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a) {}
  void m2(int a, {int b}) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(1, 'b', true, false, codeTemplate('1'))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0, b: 1);
}
''');
  }

  Future<void> test_add_last_requiredPositional_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a) {}
  void m2(int a, int b) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(1, 'b', true, true, codeTemplate('1'))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0, 1);
}
''');
  }

  Future<void> test_add_multiple_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a, int d, int f) {}
  void m2(int a, int b, int c, int d, int e, int f) {}
}
''');
    setPackageData(_modify([
      'C',
      'm'
    ], [
      AddParameter(1, 'b', true, true, codeTemplate('1')),
      AddParameter(2, 'c', true, true, codeTemplate('2')),
      AddParameter(4, 'e', true, true, codeTemplate('4')),
    ], newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0, 3, 5);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0, 1, 2, 3, 4, 5);
}
''');
  }

  Future<void> test_add_renamed_removed() async {
    setPackageContent('''
class C {
  void m2(int a, int b) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(0, 'a', true, true, codeTemplate('0'))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0, 1);
}
''');
  }

  Future<void> test_add_sameName_removed() async {
    setPackageContent('''
class C {
  void m(int a, int b) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(0, 'a', true, true, codeTemplate('0'))]));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m(0, 1);
}
''');
  }

  Future<void> test_mixed_noOverlap_removedFirst_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a, int b) {}
  void m2(int b, int c) {}
}
''');
    setPackageData(_modify([
      'C',
      'm'
    ], [
      RemoveParameter(PositionalParameterReference(0)),
      AddParameter(2, 'c', true, true, codeTemplate('2'))
    ], newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0, 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(1, 2);
}
''');
  }

  Future<void> test_mixed_noOverlap_removedLast_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int b, int c) {}
  void m2(int a, int b) {}
}
''');
    setPackageData(_modify([
      'C',
      'm'
    ], [
      RemoveParameter(PositionalParameterReference(1)),
      AddParameter(0, 'a', true, true, codeTemplate('0'))
    ], newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(1, 2);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0, 1);
}
''');
  }

  Future<void> test_mixed_overlap_first_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m1(int a, int b, int d) {}
  void m2(       int c, int d) {}
}
''');
    setPackageData(_modify([
      'C',
      'm1'
    ], [
      RemoveParameter(PositionalParameterReference(0)),
      RemoveParameter(PositionalParameterReference(1)),
      AddParameter(0, 'c', true, true, codeTemplate('2')),
    ], newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m1(0, 1, 3);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(2, 3);
}
''');
  }

  Future<void> test_mixed_overlap_last_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m1(int a, int b, int c) {}
  void m2(int a,        int d) {}
}
''');
    setPackageData(_modify([
      'C',
      'm1'
    ], [
      RemoveParameter(PositionalParameterReference(1)),
      RemoveParameter(PositionalParameterReference(2)),
      AddParameter(1, 'd', true, true, codeTemplate('3')),
    ], newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m1(0, 1, 2);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0, 3);
}
''');
  }

  Future<void> test_mixed_overlap_middle_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m1(       int b, int c, int e, int f, int g) {}
  void m2(int a, int b, int d, int e,        int g) {}
}
''');
    setPackageData(_modify([
      'C',
      'm1'
    ], [
      AddParameter(0, 'a', true, true, codeTemplate('0')),
      RemoveParameter(PositionalParameterReference(1)),
      RemoveParameter(PositionalParameterReference(3)),
      AddParameter(2, 'd', true, true, codeTemplate('3')),
    ], newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m1(1, 2, 4, 5, 6);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0, 1, 3, 4, 6);
}
''');
  }

  Future<void> test_mixed_replaced_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m1({int a}) {}
  void m2({int b}) {}
}
''');
    setPackageData(_modify([
      'C',
      'm1'
    ], [
      AddParameter(0, 'b', true, false, codeTemplate('0')),
      RemoveParameter(NamedParameterReference('a')),
    ], newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m1(a: 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(b: 0);
}
''');
  }

  Future<void> test_remove_first_optionalNamed_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m({int a, int b}) {}
  void m2({int b}) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [RemoveParameter(NamedParameterReference('a'))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(a: 0, b: 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(b: 1);
}
''');
  }

  Future<void> test_remove_first_optionalPositional_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m([int a, int b]) {}
  void m2([int b]) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [RemoveParameter(PositionalParameterReference(0))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0, 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(1);
}
''');
  }

  Future<void> test_remove_first_requiredPositional_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a, int b) {}
  void m2(int b) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [RemoveParameter(PositionalParameterReference(0))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0, 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(1);
}
''');
  }

  Future<void> test_remove_last_optionalNamed_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m({int a, int b}) {}
  void m2({int b}) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [RemoveParameter(NamedParameterReference('b'))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(a: 0, b: 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(a: 0);
}
''');
  }

  Future<void> test_remove_last_optionalPositional_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m([int a, int b]) {}
  void m2([int b]) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [RemoveParameter(PositionalParameterReference(1))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0, 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0);
}
''');
  }

  Future<void> test_remove_last_requiredPositional_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a, int b) {}
  void m2(int b) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [RemoveParameter(PositionalParameterReference(1))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0, 1);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(0);
}
''');
  }

  Future<void>
      test_remove_middle_optionalNamed_withArg_notRenamed_deprecated() async {
    setPackageContent('''
class C {
  void m({int a, @deprecated int b, int c}) {}
}
''');
    setPackageData(
        _modify(['C', 'm'], [RemoveParameter(NamedParameterReference('b'))]));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(a: 0, b: 1, c: 2);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m(a: 0, c: 2);
}
''');
  }

  Future<void> test_remove_multiple_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a, int b, int c, int d) {}
  void m2(int b) {}
}
''');
    setPackageData(_modify([
      'C',
      'm'
    ], [
      RemoveParameter(PositionalParameterReference(0)),
      RemoveParameter(PositionalParameterReference(2)),
      RemoveParameter(PositionalParameterReference(3)),
    ], newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0, 1, 2, 3);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2(1);
}
''');
  }

  Future<void> test_remove_only_optionalNamed_withArg_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m({int a}) {}
  void m2() {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [RemoveParameter(NamedParameterReference('a'))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(a: 0);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2();
}
''');
  }

  Future<void> test_remove_only_optionalNamed_withoutArg_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m({int a}) {}
  void m2() {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [RemoveParameter(NamedParameterReference('a'))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m();
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2();
}
''');
  }

  Future<void> test_remove_only_optionalPositional_withArg_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m([int a]) {}
  void m2() {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [RemoveParameter(PositionalParameterReference(0))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2();
}
''');
  }

  Future<void>
      test_remove_only_optionalPositional_withoutArg_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m([int a]) {}
  void m2() {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [RemoveParameter(PositionalParameterReference(0))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m();
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2();
}
''');
  }

  Future<void> test_remove_only_requiredPositional_deprecated() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a) {}
  void m2() {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [RemoveParameter(PositionalParameterReference(0))],
        newName: 'm2'));
    await resolveTestCode('''
import '$importUri';

void f(C c) {
  c.m(0);
}
''');
    await assertHasFix('''
import '$importUri';

void f(C c) {
  c.m2();
}
''');
  }
}

/// In the tests where a required named parameter is being added, the tests
/// avoid the question of whether the defining library is opted in to the
/// null-safety feature by omitting both the `required` keyword and annotation.
/// This works because the information the change needs is taken from the
/// `AddParameter` object rather than the source code.
///
/// The tests for 'function' exist to check that these changes can also be
/// applied to top-level functions, but are not intended to be exhaustive.
@reflectiveTest
class ModifyParametersOfTopLevelFunctionTest extends _ModifyParameters {
  @override
  String get _kind => 'function';

  Future<void> test_add_first_requiredNamed_deprecated() async {
    setPackageContent('''
@deprecated
void f(int b) {}
void g(int a, int b) {}
''');
    setPackageData(_modify([
      'f'
    ], [
      AddParameter(0, 'a', true, true, codeTemplate('0')),
    ], newName: 'g'));
    await resolveTestCode('''
import '$importUri';

void h() {
  f(1);
}
''');
    await assertHasFix('''
import '$importUri';

void h() {
  g(0, 1);
}
''');
  }

  Future<void> test_remove_first_requiredPositional_deprecated() async {
    setPackageContent('''
@deprecated
void f(int a, int b) {}
void g(int b) {}
''');
    setPackageData(_modify(
        ['f'], [RemoveParameter(PositionalParameterReference(0))],
        newName: 'g'));
    await resolveTestCode('''
import '$importUri';

void h() {
  f(0, 1);
}
''');
    await assertHasFix('''
import '$importUri';

void h() {
  g(1);
}
''');
  }
}

abstract class _ModifyParameters extends DataDrivenFixProcessorTest {
  /// Return the kind of element whose parameters are being modified.
  String get _kind;

  Transform _modify(List<String> originalComponents,
          List<ParameterModification> modifications, {String newName}) =>
      Transform(
          title: 'title',
          element: ElementDescriptor(
              libraryUris: [Uri.parse(importUri)],
              kind: ElementKindUtilities.fromName(_kind),
              components: originalComponents),
          bulkApply: false,
          changesSelector: UnconditionalChangesSelector([
            ModifyParameters(modifications: modifications),
            if (newName != null) Rename(newName: newName),
          ]));
}
