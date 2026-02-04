// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateSetterTest);
    defineReflectiveTests(CreateSetterMixinTest);
  });
}

@reflectiveTest
class CreateSetterMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createSetter;

  Future<void> test_main_part() async {
    var partPath = join(testPackageLibPath, 'part.dart');
    newFile(partPath, '''
part of 'test.dart';

mixin M {
}
''');
    await resolveTestCode('''
part 'part.dart';

void foo(M a) {
  a.myUndefinedSetter = 0;
}
''');
    await assertHasFix('''
part of 'test.dart';

mixin M {
  set myUndefinedSetter(int myUndefinedSetter) {}
}
''', target: partPath);
  }

  Future<void> test_part_main() async {
    var mainPath = join(testPackageLibPath, 'main.dart');
    newFile(mainPath, '''
part 'test.dart';

mixin M {
}
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(M a) {
  a.myUndefinedSetter = 0;
}
''');
    await assertHasFix('''
part 'test.dart';

mixin M {
  set myUndefinedSetter(int myUndefinedSetter) {}
}
''', target: mainPath);
  }

  Future<void> test_part_sibling() async {
    var part1Path = join(testPackageLibPath, 'part1.dart');
    newFile(part1Path, '''
part of 'main.dart';

mixin M {
}
''');
    newFile(join(testPackageLibPath, 'main.dart'), '''
part 'part1.dart';
part 'test.dart';
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(M a) {
  a.myUndefinedSetter = 0;
}
''');
    await assertHasFix('''
part of 'main.dart';

mixin M {
  set myUndefinedSetter(int myUndefinedSetter) {}
}
''', target: part1Path);
  }

  Future<void> test_qualified_instance() async {
    await resolveTestCode('''
mixin M {
}

void f(M m) {
  m.test = 0;
}
''');
    await assertHasFix('''
mixin M {
  set test(int test) {}
}

void f(M m) {
  m.test = 0;
}
''');
  }

  Future<void> test_unqualified_instance_assignmentLhs() async {
    await resolveTestCode('''
mixin M {
  void f() {
    test = 0;
  }
}
''');
    await assertHasFix('''
mixin M {
  set test(int test) {}

  void f() {
    test = 0;
  }
}
''');
  }

  Future<void> test_unqualified_instance_assignmentRhs() async {
    await resolveTestCode('''
mixin M {
  void f() {
    test;
  }
}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class CreateSetterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createSetter;

  Future<void> test_extension_type() async {
    await resolveTestCode('''
extension type A(String s) {
}
void f(A a) {
  a.test = 0;
}
''');
    await assertHasFix('''
extension type A(String s) {
  set test(int test) {}
}
void f(A a) {
  a.test = 0;
}
''');
  }

  Future<void> test_generics() async {
    await resolveTestCode('''
class A {}

void g<T>(T? v) => A().setter = v;
''');
    await assertHasFix('''
class A {
  set setter(Object? setter) {}
}

void g<T>(T? v) => A().setter = v;
''');
  }

  Future<void> test_generics_bound() async {
    await resolveTestCode('''
class A {}

void g<T extends int>(T? v) => A().setter = v;
''');
    await assertHasFix('''
class A {
  set setter(int? setter) {}
}

void g<T extends int>(T? v) => A().setter = v;
''');
  }

  Future<void> test_generics_class() async {
    await resolveTestCode('''
class A<O> {}

void g<T>(T? v) => A<T>().setter = v;
''');
    await assertHasFix('''
class A<O> {
  set setter(O? setter) {}
}

void g<T>(T? v) => A<T>().setter = v;
''');
  }

  Future<void> test_generics_unqualified() async {
    await resolveTestCode('''
class A<T> {
  void m(T? v) => setter = v;
}
''');
    await assertHasFix('''
class A<T> {
  set setter(T? setter) {}

  void m(T? v) => setter = v;
}
''');
  }

  Future<void> test_getterContext() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  a.test;
}
''');
    await assertNoFix();
  }

  Future<void> test_inferredTargetType() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  var x = a;
  x.test = 0;
}
''');
    await assertHasFix('''
class A {
  set test(int test) {}
}
void f(A a) {
  var x = a;
  x.test = 0;
}
''');
  }

  Future<void> test_inSDK() async {
    await resolveTestCode('''
void f(List p) {
  p.foo = 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_internal_extension_instance() async {
    await resolveTestCode('''
extension E on String {
  int m(int x) => s = x;
}
''');
    // This should be handled by create extension member fixes
    await assertNoFix();
  }

  Future<void> test_internal_extension_static() async {
    await resolveTestCode('''
extension E on String {
  static int m(int x) => s = x;
}
''');
    // This should be handled by create extension member fixes
    await assertNoFix();
  }

  Future<void> test_internal_instance() async {
    await resolveTestCode('''
class A {
  int m(int x) => s = x;
}
''');
    await assertHasFix('''
class A {
  set s(int s) {}

  int m(int x) => s = x;
}
''');
  }

  Future<void> test_internal_static() async {
    await resolveTestCode('''
class A {
  static int m(int x) => s = x;
}
''');
    await assertHasFix('''
class A {
  static set s(int s) {}

  static int m(int x) => s = x;
}
''');
  }

  Future<void> test_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.always_specify_types]);
    await resolveTestCode('''
class A {}

void g(dynamic v) => A().setter = v;
''');
    await assertHasFix('''
class A {
  set setter(dynamic setter) {}
}

void g(dynamic v) => A().setter = v;
''');
  }

  Future<void> test_location_afterLastAccessor() async {
    await resolveTestCode('''
class A {
  int existingField = 0;

  int get existingGetter => 0;

  existingMethod() {}
}
void f(A a) {
  a.test = 0;
}
''');
    await assertHasFix('''
class A {
  int existingField = 0;

  int get existingGetter => 0;

  set test(int test) {}

  existingMethod() {}
}
void f(A a) {
  a.test = 0;
}
''');
  }

  Future<void> test_main_part() async {
    var partPath = join(testPackageLibPath, 'part.dart');
    newFile(partPath, '''
part of 'test.dart';

class A {
}
''');
    await resolveTestCode('''
part 'part.dart';

void foo(A a) {
  a.myUndefinedSetter = 0;
}
''');
    await assertHasFix('''
part of 'test.dart';

class A {
  set myUndefinedSetter(int myUndefinedSetter) {}
}
''', target: partPath);
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
  c.b.a.test = 0;
}
''');
    await assertHasFix('''
class A {
  set test(int test) {}
}
class B {
  A a = A();
}
class C {
  B b = B();
}
void f(C c) {
  c.b.a.test = 0;
}
''');
  }

  Future<void> test_noLint() async {
    await resolveTestCode('''
class A {}

void g(dynamic v) => A().setter = v;
''');
    await assertHasFix('''
class A {
  set setter(setter) {}
}

void g(dynamic v) => A().setter = v;
''');
  }

  Future<void> test_override() async {
    await resolveTestCode('''
extension E on String {
}

void f(String s) {
  E(s).test = '0';
}
''');
    // This should be handled by create extension member fixes
    await assertNoFix();
  }

  Future<void> test_override_userType() async {
    await resolveTestCode('''
class A {}

extension E on A {}

void f(A a) {
  E(a).test = '0';
}
''');
    await assertHasFix('''
class A {
  set test(String test) {}
}

extension E on A {}

void f(A a) {
  E(a).test = '0';
}
''');
  }

  Future<void> test_part_main() async {
    var mainPath = join(testPackageLibPath, 'main.dart');
    newFile(mainPath, '''
part 'test.dart';

class A {
}
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(A a) {
  a.myUndefinedSetter = 0;
}
''');
    await assertHasFix('''
part 'test.dart';

class A {
  set myUndefinedSetter(int myUndefinedSetter) {}
}
''', target: mainPath);
  }

  Future<void> test_part_sibling() async {
    var part1Path = join(testPackageLibPath, 'part1.dart');
    newFile(part1Path, '''
part of 'main.dart';

class A {
}
''');
    newFile(join(testPackageLibPath, 'main.dart'), '''
part 'part1.dart';
part 'test.dart';
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(A a) {
  a.myUndefinedSetter = 0;
}
''');
    await assertHasFix('''
part of 'main.dart';

class A {
  set myUndefinedSetter(int myUndefinedSetter) {}
}
''', target: part1Path);
  }

  Future<void> test_qualified_instance() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  a.test = 0;
}
''');
    await assertHasFix('''
class A {
  set test(int test) {}
}
void f(A a) {
  a.test = 0;
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
  a.test = 0;
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
  set test(int test) {}
}
''', target: '$testPackageLibPath/other.dart');
  }

  Future<void> test_qualified_instance_dynamicType() async {
    await resolveTestCode('''
class A {
  B b = B();
  void f(p) {
    b.test = p;
  }
}
class B {
}
''');
    await assertHasFix('''
class A {
  B b = B();
  void f(p) {
    b.test = p;
  }
}
class B {
  set test(test) {}
}
''');
  }

  Future<void> test_qualified_instance_inPart_self() async {
    await resolveTestCode('''
part of 'a.dart';

class A {
}

void f(A a) {
  a.test = 0;
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
  a.self.test = 0;
}
''');
    await assertHasFix('''
class A {
  A get self => this;

  set test(int test) {}
}
void f() {
  var a = new A();
  a.self.test = 0;
}
''');
  }

  Future<void> test_static() async {
    await resolveTestCode('''
class A {
}

void f() {
  A.test = 0;
}
''');
    await assertHasFix('''
class A {
  static set test(int test) {}
}

void f() {
  A.test = 0;
}
''');
  }

  Future<void> test_static_extension() async {
    await resolveTestCode('''
extension E on String {
}

void f(String s) {
  E.test = 0;
}
''');
    // This should be handled by create extension member fixes
    await assertNoFix();
  }

  Future<void> test_unqualified_instance_assignmentLhs() async {
    await resolveTestCode('''
class A {
  void f() {
    test = 0;
  }
}
''');
    await assertHasFix('''
class A {
  set test(int test) {}

  void f() {
    test = 0;
  }
}
''');
  }

  Future<void> test_unqualified_instance_assignmentRhs() async {
    await resolveTestCode('''
class A {
  void f() {
    test;
  }
}
''');
    await assertNoFix();
  }
}
