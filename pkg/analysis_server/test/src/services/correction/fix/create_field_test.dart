// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateFieldTest);
    defineReflectiveTests(CreateFieldMixinTest);
  });
}

@reflectiveTest
class CreateFieldMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_FIELD;

  Future<void> test_getter_qualified_instance() async {
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
  int test;
}

void f(M m) {
  int v = m.test;
  print(v);
}
''');
  }

  Future<void> test_setter_qualified_instance_hasField() async {
    await resolveTestCode('''
mixin M {
  int aaa = 0;
  int zzz = 25;

  existingMethod() {}
}

void f(M m) {
  m.test = 5;
}
''');
    await assertHasFix('''
mixin M {
  int aaa = 0;
  int zzz = 25;

  int test;

  existingMethod() {}
}

void f(M m) {
  m.test = 5;
}
''');
  }
}

@reflectiveTest
class CreateFieldTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_FIELD;

  Future<void> test_getter_multiLevel() async {
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
  int test;
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

  Future<void> test_getter_qualified_instance() async {
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
  int test;
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
  }

  Future<void> test_getter_qualified_instance_differentLibrary() async {
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
  int test;
}
''', target: '$testPackageLibPath/other.dart');
  }

  Future<void> test_getter_qualified_instance_dynamicType() async {
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
  var test;
}
''');
  }

  Future<void> test_getter_qualified_propagatedType() async {
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
  int test;

  A get self => this;
}
void f() {
  var a = new A();
  int v = a.self.test;
  print(v);
}
''');
  }

  Future<void> test_getter_unqualified_instance_asInvocationArgument() async {
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
  String test;

  void m() {
    f(test);
  }
}
f(String s) {}
''');
  }

  Future<void> test_getter_unqualified_instance_assignmentRhs() async {
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
  int test;

  void f() {
    int v = test;
    print(v);
  }
}
''');
  }

  Future<void> test_getter_unqualified_instance_asStatement() async {
    await resolveTestCode('''
class A {
  void f() {
    test;
  }
}
''');
    await assertHasFix('''
class A {
  var test;

  void f() {
    test;
  }
}
''');
  }

  Future<void> test_hint() async {
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
  int test;
}
void f(A a) {
  var x = a;
  int v = x.test;
  print(v);
}
''');
  }

  Future<void> test_hint_setter() async {
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
  int test;
}
void f(A a) {
  var x = a;
  x.test = 0;
}
''');
  }

  Future<void> test_importType() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'package:test/a.dart';

A getA() => null;
''');

    await resolveTestCode('''
import 'package:test/b.dart';

class C {
}

void f(C c) {
  c.test = getA();
}
''');

    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

class C {
  A test;
}

void f(C c) {
  c.test = getA();
}
''');
  }

  Future<void> test_inEnum() async {
    await resolveTestCode('''
enum MyEnum {
  AAA, BBB
}
void f() {
  MyEnum.foo;
}
''');
    await assertNoFix();
  }

  Future<void> test_inPart_self() async {
    await resolveTestCode('''
part of lib;
class A {
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_inSDK() async {
    await resolveTestCode('''
void f(List p) {
  p.foo = 1;
}
''');
    await assertNoFix();
  }

  Future<void> test_invalidInitializer_withoutType() async {
    await resolveTestCode('''
class C {
  C(this.text);
}
''');
    await assertHasFix('''
class C {
  var text;

  C(this.text);
}
''');
  }

  Future<void> test_invalidInitializer_withType() async {
    await resolveTestCode('''
class C {
  C(String this.text);
}
''');
    await assertHasFix('''
class C {
  String text;

  C(String this.text);
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
  int test;
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
  Object? test;
}
''');
  }

  Future<void> test_objectPattern_explicitName_wildcardPattern_typed() async {
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
  int test;
}
''');
  }

  Future<void> test_objectPattern_implicitName_variablePattern_typed() async {
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
  int test;
}
''');
  }

  Future<void> test_setter_generic_BAD() async {
    await resolveTestCode('''
class A {
}
class B<T> {
  List<T> items = [];
  void f(A a) {
    a.test = items;
  }
}
''');
    await assertHasFix('''
class A {
  List test;
}
class B<T> {
  List<T> items = [];
  void f(A a) {
    a.test = items;
  }
}
''');
  }

  Future<void> test_setter_generic_OK_local() async {
    await resolveTestCode('''
class A<T> {
  List<T> items = [];

  void f(A a) {
    test = items;
  }
}
''');
    await assertHasFix('''
class A<T> {
  List<T> items = [];

  List<T> test;

  void f(A a) {
    test = items;
  }
}
''');
  }

  Future<void> test_setter_qualified_instance_hasField() async {
    await resolveTestCode('''
class A {
  int aaa = 0;
  int zzz = 25;

  existingMethod() {}
}
void f(A a) {
  a.test = 5;
}
''');
    await assertHasFix('''
class A {
  int aaa = 0;
  int zzz = 25;

  int test;

  existingMethod() {}
}
void f(A a) {
  a.test = 5;
}
''');
  }

  Future<void> test_setter_qualified_instance_hasMethod() async {
    await resolveTestCode('''
class A {
  existingMethod() {}
}
void f(A a) {
  a.test = 5;
}
''');
    await assertHasFix('''
class A {
  int test;

  existingMethod() {}
}
void f(A a) {
  a.test = 5;
}
''');
  }

  Future<void> test_setter_qualified_static() async {
    await resolveTestCode('''
class A {
}
void f() {
  A.test = 5;
}
''');
    await assertHasFix('''
class A {
  static int test;
}
void f() {
  A.test = 5;
}
''');
  }

  Future<void> test_setter_unqualified_instance() async {
    await resolveTestCode('''
class A {
  void f() {
    test = 5;
  }
}
''');
    await assertHasFix('''
class A {
  int test;

  void f() {
    test = 5;
  }
}
''');
  }

  Future<void> test_setter_unqualified_static() async {
    await resolveTestCode('''
class A {
  static void f() {
    test = 5;
  }
}
''');
    await assertHasFix('''
class A {
  static int test;

  static void f() {
    test = 5;
  }
}
''');
  }
}
