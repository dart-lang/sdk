// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateExtensionGetterTest);
    defineReflectiveTests(CreateGetterTest);
    defineReflectiveTests(CreateGetterMixinTest);
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
class CreateGetterMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_GETTER;

  Future<void> test_qualified_instance() async {
    await resolveTestCode('''
mixin M {
}

void f(M m) {
  int v = m.test;
  print(v);
}
''');
    await assertHasFix('''
mixin M {
  int get test => null;
}

void f(M m) {
  int v = m.test;
  print(v);
}
''');
  }

  Future<void> test_unqualified_instance_assignmentLhs() async {
    await resolveTestCode('''
mixin M {
  void f() {
    test = 42;
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_unqualified_instance_assignmentRhs() async {
    await resolveTestCode('''
mixin M {
  void f() {
    int v = test;
    print(v);
  }
}
''');
    await assertHasFix('''
mixin M {
  int get test => null;

  void f() {
    int v = test;
    print(v);
  }
}
''');
  }
}

@reflectiveTest
class CreateGetterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_GETTER;

  Future<void> test_extension_type() async {
    await resolveTestCode('''
extension type A(String s) {
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertHasFix('''
extension type A(String s) {
  int get test => null;
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
  }

  Future<void> test_hint_getter() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  var x = a;
  int v = x.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int get test => null;
}
void f(A a) {
  var x = a;
  int v = x.test;
  print(v);
}
''');
  }

  Future<void> test_inSDK() async {
    await resolveTestCode('''
void f(List p) {
  int v = p.foo;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_internal_instance() async {
    await resolveTestCode('''
extension E on String {
  int m()  => g;
}
''');
    await assertHasFix('''
extension E on String {
  int get g => null;

  int m()  => g;
}
''');
  }

  Future<void> test_internal_static() async {
    await resolveTestCode('''
extension E on String {
  static int m()  => g;
}
''');
    await assertHasFix('''
extension E on String {
  static int get g => null;

  static int m()  => g;
}
''');
  }

  Future<void> test_location_afterLastGetter() async {
    await resolveTestCode('''
class A {
  int existingField = 0;

  int get existingGetter => 0;

  existingMethod() {}
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int existingField = 0;

  int get existingGetter => 0;

  int get test => null;

  existingMethod() {}
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
  }

  Future<void> test_multiLevel() async {
    await resolveTestCode('''
class A {
}
class B {
  A a = A();
}
class C {
  B b = B();
}
void f(C c) {
  int v = c.b.a.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int get test => null;
}
class B {
  A a = A();
}
class C {
  B b = B();
}
void f(C c) {
  int v = c.b.a.test;
  print(v);
}
''');
  }

  Future<void> test_objectPattern_explicitName_variablePattern_typed() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(test: int y)) {
    y;
  }
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(test: int y)) {
    y;
  }
}

class A {
  int get test => null;
}
''');
  }

  Future<void> test_objectPattern_explicitName_variablePattern_untyped() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(test: var y)) {
    y;
  }
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(test: var y)) {
    y;
  }
}

class A {
  Object? get test => null;
}
''');
  }

  Future<void> test_objectPattern_explicitName_wildcardPattern() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(test: int _)) {}
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(test: int _)) {}
}

class A {
  int get test => null;
}
''');
  }

  Future<void> test_objectPattern_implicitName_variablePattern() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(:int test)) {
    test;
  }
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(:int test)) {
    test;
  }
}

class A {
  int get test => null;
}
''');
  }

  Future<void> test_override() async {
    await resolveTestCode('''
extension E on String {
}

void f(String s) {
  int v = E(s).test;
  print(v);
}
''');
    await assertHasFix('''
extension E on String {
  int get test => null;
}

void f(String s) {
  int v = E(s).test;
  print(v);
}
''');
  }

  Future<void> test_qualified_instance() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int get test => null;
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
  }

  Future<void> test_qualified_instance_differentLibrary() async {
    newFile('$testPackageLibPath/other.dart', '''
/**
 * A comment to push the offset of the braces for the following class
 * declaration past the end of the content of the test file. Used to catch an
 * index out of bounds exception that occurs when using the test source instead
 * of the target source to compute the location at which to insert the field.
 */
class A {
}
''');

    await resolveTestCode('''
import 'package:test/other.dart';

void f(A a) {
  int v = a.test;
  print(v);
}
''');

    await assertHasFix('''
/**
 * A comment to push the offset of the braces for the following class
 * declaration past the end of the content of the test file. Used to catch an
 * index out of bounds exception that occurs when using the test source instead
 * of the target source to compute the location at which to insert the field.
 */
class A {
  int get test => null;
}
''', target: '$testPackageLibPath/other.dart');
  }

  Future<void> test_qualified_instance_dynamicType() async {
    await resolveTestCode('''
class A {
  B b = B();
  void f(dynamic context) {
    context + b.test;
  }
}
class B {
}
''');
    await assertHasFix('''
class A {
  B b = B();
  void f(dynamic context) {
    context + b.test;
  }
}
class B {
  get test => null;
}
''');
  }

  Future<void> test_qualified_instance_inPart_self() async {
    await resolveTestCode('''
part of 'a.dart';

class A {
}

void f(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_qualified_propagatedType() async {
    await resolveTestCode('''
class A {
  A get self => this;
}
void f() {
  var a = new A();
  int v = a.self.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  A get self => this;

  int get test => null;
}
void f() {
  var a = new A();
  int v = a.self.test;
  print(v);
}
''');
  }

  Future<void> test_setterContext() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  a.test = 42;
}
''');
    await assertNoFix();
  }

  Future<void> test_static() async {
    await resolveTestCode('''
extension E on String {
}

void f(String s) {
  int v = E.test;
  print(v);
}
''');
    await assertHasFix('''
extension E on String {
  static int get test => null;
}

void f(String s) {
  int v = E.test;
  print(v);
}
''');
  }

  Future<void> test_unqualified_instance_asInvocationArgument() async {
    await resolveTestCode('''
class A {
  void m() {
    f(test);
  }
}
f(String s) {}
''');
    await assertHasFix('''
class A {
  String get test => null;

  void m() {
    f(test);
  }
}
f(String s) {}
''');
  }

  Future<void> test_unqualified_instance_assignmentLhs() async {
    await resolveTestCode('''
class A {
  void f() {
    test = 42;
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_unqualified_instance_assignmentRhs() async {
    await resolveTestCode('''
class A {
  void f() {
    int v = test;
    print(v);
  }
}
''');
    await assertHasFix('''
class A {
  int get test => null;

  void f() {
    int v = test;
    print(v);
  }
}
''');
  }

  Future<void> test_unqualified_instance_asStatement() async {
    await resolveTestCode('''
class A {
  void f() {
    test;
  }
}
''');
    await assertHasFix('''
class A {
  get test => null;

  void f() {
    test;
  }
}
''');
  }
}
