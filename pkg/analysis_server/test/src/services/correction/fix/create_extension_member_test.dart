// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateExtensionGetterTest);
    defineReflectiveTests(CreateExtensionMethodTest);
  });
}

@reflectiveTest
class CreateExtensionGetterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_EXTENSION_GETTER;

  Future<void> test_contextType() async {
    await resolveTestCode('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test;
}
''');
    await assertHasFix('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test;
}

extension on String {
  int get test => null;
}
''');
  }

  Future<void> test_contextType_no() async {
    await resolveTestCode('''
void f() {
  ''.test;
}
''');
    await assertHasFix('''
void f() {
  ''.test;
}

extension on String {
  get test => null;
}
''');
    assertLinkedGroup(change.linkedEditGroups[0], ['null']);
  }

  Future<void> test_existingExtension_contextType() async {
    await resolveTestCode('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test;
}

extension on String {}
''');
    await assertHasFix('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test;
}

extension on String {
  int get test => null;
}
''');
  }

  Future<void> test_existingExtension_generic_matching() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test;
}

extension E<T> on Iterable<T> {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test;
}

extension E<T> on Iterable<T> {
  get test => null;
}
''');
  }

  Future<void> test_existingExtension_generic_notMatching() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test;
}

extension E<K, V> on Map<K, V> {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test;
}

extension on List<int> {
  get test => null;
}

extension E<K, V> on Map<K, V> {}
''');
  }

  Future<void> test_existingExtension_hasMethod() async {
    await resolveTestCode('''
void f() {
  ''.test;
}

extension E on String {
  // ignore:unused_element
  void foo() {}
}
''');
    await assertHasFix('''
void f() {
  ''.test;
}

extension E on String {
  get test => null;

  // ignore:unused_element
  void foo() {}
}
''');
  }

  Future<void> test_existingExtension_notGeneric_matching() async {
    await resolveTestCode('''
void f() {
  ''.test;
}

extension on String {}
''');
    await assertHasFix('''
void f() {
  ''.test;
}

extension on String {
  get test => null;
}
''');
  }

  Future<void> test_existingExtension_notGeneric_notMatching() async {
    await resolveTestCode('''
void f() {
  ''.test;
}

extension on int {}
''');
    await assertHasFix('''
void f() {
  ''.test;
}

extension on String {
  get test => null;
}

extension on int {}
''');
  }

  Future<void> test_parent_nothing() async {
    await resolveTestCode('''
void f() {
  test;
}
''');
    await assertNoFix();
  }

  Future<void> test_parent_prefixedIdentifier() async {
    await resolveTestCode('''
void f(String a) {
  a.test;
}
''');
    await assertHasFix('''
void f(String a) {
  a.test;
}

extension on String {
  get test => null;
}
''');
  }

  Future<void> test_parent_propertyAccess_cascade() async {
    await resolveTestCode('''
void f(String a) {
  a..test;
}
''');
    await assertHasFix('''
void f(String a) {
  a..test;
}

extension on String {
  get test => null;
}
''');
  }

  Future<void> test_targetType_hasTypeArguments() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test;
}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test;
}

extension on List<int> {
  get test => null;
}
''');
  }
}

@reflectiveTest
class CreateExtensionMethodTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_EXTENSION_METHOD;

  Future<void> test_arguments() async {
    await resolveTestCode('''
void f() {
  ''.test(0, 1.2);
}
''');
    await assertHasFix('''
void f() {
  ''.test(0, 1.2);
}

extension on String {
  void test(int i, double d) {}
}
''');
  }

  Future<void> test_contextType() async {
    await resolveTestCode('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test();
}
''');
    await assertHasFix('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test();
}

extension on String {
  int test() {}
}
''');
  }

  Future<void> test_contextType_no() async {
    await resolveTestCode('''
void f() {
  ''.test();
}
''');
    await assertHasFix('''
void f() {
  ''.test();
}

extension on String {
  void test() {}
}
''');
  }

  Future<void> test_existingExtension_contextType() async {
    await resolveTestCode('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test();
}

extension on String {}
''');
    await assertHasFix('''
void f() {
  // ignore:unused_local_variable
  int v = ''.test();
}

extension on String {
  int test() {}
}
''');
  }

  Future<void> test_existingExtension_generic_matching() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test();
}

extension E<T> on Iterable<T> {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test();
}

extension E<T> on Iterable<T> {
  void test() {}
}
''');
  }

  Future<void> test_existingExtension_generic_notMatching() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test();
}

extension E<K, V> on Map<K, V> {}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test();
}

extension on List<int> {
  void test() {}
}

extension E<K, V> on Map<K, V> {}
''');
  }

  Future<void> test_existingExtension_hasMethod() async {
    await resolveTestCode('''
void f() {
  ''.test();
}

extension E on String {
  // ignore:unused_element
  void foo() {}
}
''');
    await assertHasFix('''
void f() {
  ''.test();
}

extension E on String {
  // ignore:unused_element
  void foo() {}

  void test() {}
}
''');
  }

  Future<void> test_existingExtension_notGeneric_matching() async {
    await resolveTestCode('''
void f() {
  ''.test();
}

extension on String {}
''');
    await assertHasFix('''
void f() {
  ''.test();
}

extension on String {
  void test() {}
}
''');
  }

  Future<void> test_existingExtension_notGeneric_notMatching() async {
    await resolveTestCode('''
void f() {
  ''.test();
}

extension on int {}
''');
    await assertHasFix('''
void f() {
  ''.test();
}

extension on String {
  void test() {}
}

extension on int {}
''');
  }

  Future<void> test_target_identifier() async {
    await resolveTestCode('''
void f(String a) {
  a.test();
}
''');
    await assertHasFix('''
void f(String a) {
  a.test();
}

extension on String {
  void test() {}
}
''');
  }

  Future<void> test_target_identifier_cascade() async {
    await resolveTestCode('''
void f(String a) {
  a..test();
}
''');
    await assertHasFix('''
void f(String a) {
  a..test();
}

extension on String {
  void test() {}
}
''');
  }

  Future<void> test_target_nothing() async {
    await resolveTestCode('''
void f() {
  test();
}
''');
    await assertNoFix();
  }

  Future<void> test_targetType_hasTypeArguments() async {
    await resolveTestCode('''
void f(List<int> a) {
  a.test();
}
''');
    await assertHasFix('''
void f(List<int> a) {
  a.test();
}

extension on List<int> {
  void test() {}
}
''');
  }
}
