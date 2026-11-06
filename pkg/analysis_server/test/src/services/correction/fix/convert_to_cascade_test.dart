// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToCascadeTest);
  });
}

@reflectiveTest
class ConvertToCascadeTest extends FixProcessorForBuiltInLintRuleTest {
  @override
  FixKind get kind => DartFixKind.convertToCascade;

  @override
  String get lintCode => LintNames.cascade_invocations;

  Future<void> test_cascade_method() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..x = 2;
  a..m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..x = 2
  ..m();
}
''');
  }

  Future<void> test_declaration_binaryExpression_nullAware() async {
    await resolveTestCode('''
void foo(int? one, int two) {
  var result = one ?? two;
  result.abs();
}
''');
    await assertHasFix('''
void foo(int? one, int two) {
  var result = (one ?? two)
  ..abs();
}
''');
  }

  Future<void> test_declaration_binaryExpression_plus() async {
    await resolveTestCode('''
void foo(int two) {
  var result = two + 1;
  result.abs();
}
''');
    await assertHasFix('''
void foo(int two) {
  var result = (two + 1)
  ..abs();
}
''');
  }

  Future<void> test_declaration_closure() async {
    await resolveTestCode('''
void foo() {
  var g = () => print('');
  g.toString();
}
''');
    await assertHasFix('''
void foo() {
  var g = (() => print(''))
  ..toString();
}
''');
  }

  Future<void> test_declaration_method() async {
    await resolveTestCode('''
class A {
  void m() {}
}
void f() {
  final a = A();
  a.m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
}
void f() {
  final a = A()
  ..m();
}
''');
  }

  Future<void> test_declaration_method_method() async {
    await resolveTestCode('''
class A {
  void m() {}
}
void f() {
  final a = A();
  a.m();
  a.m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
}
void f() {
  final a = A()
  ..m()
  ..m();
}
''');
  }

  Future<void> test_method_method() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.m();
  a.m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a..m()
  ..m();
}
''');
  }

  Future<void> test_method_property() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.m();
  a.x = 1;
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a..m()
  ..x = 1;
}
''');
  }

  Future<void> test_method_property_method() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.m();
  a.x = 1;
  a.m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a..m()
  ..x = 1
  ..m();
}
''');
  }

  Future<void> test_multipleDeclaration_first_method() async {
    await resolveTestCode('''
class A {
  void m() {}
}
void f() {
  final a = A(), a2 = A();
  a.m();
}
''');
    await assertNoFix();
  }

  Future<void> test_multipleDeclaration_last_method() async {
    await resolveTestCode('''
class A {
  void m() {}
}
void f() {
  final a = A(), a2 = A();
  a2.m();
}
''');
    await assertNoFix();
  }

  Future<void> test_property_cascade() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}

void f(A a) {
  a.x = 1;
  a..m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..m();
}
''');
  }

  Future<void> test_property_cascadeMethod_cascadeMethod() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}

void f(A a) {
  a.x = 1;
  a..m();
  a..m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..m()
  ..m();
}
''');
  }

  Future<void> test_property_closure_alreadyParenthesized_middle() async {
    await resolveTestCode('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void foo(A a) {
  a.x = 1;
  a.g = (() => print(''));
  a.h = 3;
}
''');
    await assertHasFix('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void foo(A a) {
  a..x = 1
  ..g = (() => print(''))
  ..h = 3;
}
''');
  }

  Future<void> test_property_closure_async_middle() async {
    await resolveTestCode('''
class A {
  int? x;
  Future<void> Function()? g;
  int? h;
}
void foo(A a) {
  a.x = 1;
  a.g = () async => print('');
  a.h = 3;
}
''');
    await assertHasFix('''
class A {
  int? x;
  Future<void> Function()? g;
  int? h;
}
void foo(A a) {
  a..x = 1
  ..g = (() async => print(''))
  ..h = 3;
}
''');
  }

  Future<void> test_property_closure_blockBody_middle() async {
    // A block body is terminated by its closing brace, so it can't absorb the
    // cascade section that follows it.
    await resolveTestCode('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void foo(A a) {
  a.x = 1;
  a.g = () { print(''); };
  a.h = 3;
}
''');
    await assertHasFix('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void foo(A a) {
  a..x = 1
  ..g = () { print(''); }
  ..h = 3;
}
''');
  }

  Future<void> test_property_closure_inArgument_middle() async {
    // The argument list's closing parenthesis terminates the expression body.
    await resolveTestCode('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void Function() wrap(void Function() f) => f;
void foo(A a) {
  a.x = 1;
  a.g = wrap(() => print(''));
  a.h = 3;
}
''');
    await assertHasFix('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void Function() wrap(void Function() f) => f;
void foo(A a) {
  a..x = 1
  ..g = wrap(() => print(''))
  ..h = 3;
}
''');
  }

  Future<void> test_property_closure_middle() async {
    await resolveTestCode('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void foo(A a) {
  a.x = 1;
  a.g = () => print('');
  a.h = 3;
}
''');
    await assertHasFix('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void foo(A a) {
  a..x = 1
  ..g = (() => print(''))
  ..h = 3;
}
''');
  }

  Future<void> test_property_closure_property() async {
    await resolveTestCode('''
class A {
  void Function()? f;
  void Function()? g;
}
void foo(A a) {
  a.f = () => print('');
  a.g = () => print('');
}
''');
    await assertHasFix('''
class A {
  void Function()? f;
  void Function()? g;
}
void foo(A a) {
  a..f = (() => print(''))
  ..g = () => print('');
}
''');
  }

  Future<void> test_property_conditional_closure_middle() async {
    // The closure is not the right-hand side itself, but it does end it, so
    // its body would still absorb the following cascade section.
    await resolveTestCode('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void foo(A a, bool b) {
  a.x = 1;
  a.g = b ? null : () => print('');
  a.h = 3;
}
''');
    await assertHasFix('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void foo(A a, bool b) {
  a..x = 1
  ..g = (b ? null : () => print(''))
  ..h = 3;
}
''');
  }

  Future<void> test_property_method() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.x = 1;
  a.m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a..x = 1
  ..m();
}
''');
  }

  Future<void> test_property_property() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.x = 1;
  a.x = 2;
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a..x = 1
  ..x = 2;
}
''');
  }

  Future<void> test_property_property_method_method() async {
    await resolveTestCode('''
class A {
  void m(int _) {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..x = 2;
  a.m(1);
  a.m(2);
}
''');
    await assertHasFix('''
class A {
  void m(int _) {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..x = 2
  ..m(1)
  ..m(2);
}
''');
  }

  Future<void> test_property_property_property() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.x = 1;
  a.x = 2;
  a.x = 3;
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a..x = 1
  ..x = 2
  ..x = 3;
}
''');
  }

  Future<void> test_property_switchExpression_closure_middle() async {
    // The switch expression's closing brace terminates the expression body.
    await resolveTestCode('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void foo(A a, int k) {
  a.x = 1;
  a.g = switch (k) { _ => () => print('') };
  a.h = 3;
}
''');
    await assertHasFix('''
class A {
  int? x;
  void Function()? g;
  int? h;
}
void foo(A a, int k) {
  a..x = 1
  ..g = switch (k) { _ => () => print('') }
  ..h = 3;
}
''');
  }
}
