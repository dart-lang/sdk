// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/modify_parameters.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/value_extractor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ModifyParameters_DeprecatedMemberUseTest);
    defineReflectiveTests(ModifyParameters_NotEnoughPositionalArgumentsTest);
    defineReflectiveTests(ModifyParameters_UndefinedMethodTest);
  });
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
class ModifyParameters_DeprecatedMemberUseTest extends _ModifyParameters {
  Future<void> test_add_function_first_requiredNamed() async {
    setPackageContent('''
@deprecated
void f(int b) {}
void g(int a, int b) {}
''');
    setPackageData(_modify([
      'f'
    ], [
      AddParameter(0, 'a', true, true, null, LiteralExtractor('0')),
    ], newName: 'g'));
    await resolveTestUnit('''
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

  Future<void> test_add_method_first_optionalNamed() async {
    setPackageContent('''
class C {
  @deprecated
  void m({int b}) {}
  void m2({int a, int b}) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(0, 'a', false, false, null, null)],
        newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_add_method_first_optionalPositional() async {
    setPackageContent('''
class C {
  @deprecated
  void m([int b]) {}
  void m2([int a, int b]) {}
}
''');
    setPackageData(_modify([
      'C',
      'm'
    ], [
      AddParameter(0, 'a', false, true, null, LiteralExtractor('0'))
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_add_method_first_requiredNamed() async {
    setPackageContent('''
class C {
  @deprecated
  void m({int b}) {}
  void m2({int a, int b}) {}
}
''');
    setPackageData(_modify([
      'C',
      'm'
    ], [
      AddParameter(0, 'a', true, false, null, LiteralExtractor('0'))
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_add_method_first_requiredPositional() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int b) {}
  void m2(int a, int b) {}
}
''');
    setPackageData(_modify([
      'C',
      'm'
    ], [
      AddParameter(0, 'a', true, true, null, LiteralExtractor('0'))
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_add_method_last_optionalNamed() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a) {}
  void m2(int a, {int b}) {}
}
''');
    setPackageData(_modify(
        ['C', 'm'], [AddParameter(1, 'b', false, false, null, null)],
        newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_add_method_last_optionalPositional() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a) {}
  void m2(int a, [int b]) {}
}
''');
    setPackageData(_modify([
      'C',
      'm'
    ], [
      AddParameter(1, 'b', false, true, null, LiteralExtractor('1'))
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_add_method_last_requiredNamed() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a) {}
  void m2(int a, {int b}) {}
}
''');
    setPackageData(_modify([
      'C',
      'm'
    ], [
      AddParameter(1, 'b', true, false, null, LiteralExtractor('1'))
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_add_method_last_requiredPositional() async {
    setPackageContent('''
class C {
  @deprecated
  void m(int a) {}
  void m2(int a, int b) {}
}
''');
    setPackageData(_modify([
      'C',
      'm'
    ], [
      AddParameter(1, 'b', true, true, null, LiteralExtractor('1'))
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_add_method_multiple() async {
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
      AddParameter(1, 'b', true, true, null, LiteralExtractor('1')),
      AddParameter(2, 'c', true, true, null, LiteralExtractor('2')),
      AddParameter(4, 'e', true, true, null, LiteralExtractor('4')),
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_mixed_method_noOverlap_removedFirst() async {
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
      AddParameter(2, 'c', true, true, null, LiteralExtractor('2'))
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_mixed_method_noOverlap_removedLast() async {
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
      AddParameter(0, 'a', true, true, null, LiteralExtractor('0'))
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_mixed_method_overlap_first() async {
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
      AddParameter(0, 'c', true, true, null, LiteralExtractor('2')),
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_mixed_method_overlap_last() async {
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
      AddParameter(1, 'd', true, true, null, LiteralExtractor('3')),
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_mixed_method_overlap_middle() async {
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
      AddParameter(0, 'a', true, true, null, LiteralExtractor('0')),
      RemoveParameter(PositionalParameterReference(1)),
      RemoveParameter(PositionalParameterReference(3)),
      AddParameter(2, 'd', true, true, null, LiteralExtractor('3')),
    ], newName: 'm2'));
    await resolveTestUnit('''
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

  Future<void> test_remove_function_first_requiredPositional() async {
    setPackageContent('''
@deprecated
void f(int a, int b) {}
void g(int b) {}
''');
    setPackageData(_modify(
        ['f'], [RemoveParameter(PositionalParameterReference(0))],
        newName: 'g'));
    await resolveTestUnit('''
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

  Future<void> test_remove_method_first_optionalNamed() async {
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
    await resolveTestUnit('''
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

  Future<void> test_remove_method_first_optionalPositional() async {
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
    await resolveTestUnit('''
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

  Future<void> test_remove_method_first_requiredPositional() async {
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
    await resolveTestUnit('''
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

  Future<void> test_remove_method_last_optionalNamed() async {
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
    await resolveTestUnit('''
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

  Future<void> test_remove_method_last_optionalPositional() async {
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
    await resolveTestUnit('''
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

  Future<void> test_remove_method_last_requiredPositional() async {
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
    await resolveTestUnit('''
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

  Future<void> test_remove_method_multiple() async {
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
    await resolveTestUnit('''
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

  Future<void> test_remove_method_only_optionalNamed_withArg() async {
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
    await resolveTestUnit('''
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

  Future<void> test_remove_method_only_optionalNamed_withoutArg() async {
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
    await resolveTestUnit('''
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

  Future<void> test_remove_method_only_optionalPositional_withArg() async {
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
    await resolveTestUnit('''
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

  Future<void> test_remove_method_only_optionalPositional_withoutArg() async {
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
    await resolveTestUnit('''
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

  Future<void> test_remove_method_only_requiredPositional() async {
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
    await resolveTestUnit('''
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

@reflectiveTest
class ModifyParameters_NotEnoughPositionalArgumentsTest
    extends _ModifyParameters {
  Future<void> test_method_sameName() async {
    setPackageContent('''
class C {
  void m(int a, int b) {}
}
''');
    setPackageData(_modify(['C', 'm'],
        [AddParameter(0, 'a', true, true, null, LiteralExtractor('0'))]));
    await resolveTestUnit('''
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
}

@reflectiveTest
class ModifyParameters_UndefinedMethodTest extends _ModifyParameters {
  Future<void> test_method_renamed() async {
    setPackageContent('''
class C {
  void m2(int a, int b) {}
}
''');
    setPackageData(_modify([
      'C',
      'm'
    ], [
      AddParameter(0, 'a', true, true, null, LiteralExtractor('0'))
    ], newName: 'm2'));
    await resolveTestUnit('''
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
}

abstract class _ModifyParameters extends DataDrivenFixProcessorTest {
  Transform _modify(List<String> originalComponents,
          List<ParameterModification> modifications, {String newName}) =>
      Transform(
          title: 'title',
          element: ElementDescriptor(
              libraryUris: [importUri], components: originalComponents),
          changes: [
            ModifyParameters(modifications: modifications),
            if (newName != null) Rename(newName: newName),
          ]);
}
