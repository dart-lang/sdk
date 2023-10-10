// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidRedundantArgumentValuesTest);
    defineReflectiveTests(AvoidRedundantArgumentValuesNamedArgsAnywhereTest);
  });
}

@reflectiveTest
class AvoidRedundantArgumentValuesNamedArgsAnywhereTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_redundant_argument_values';

  test_namedArgumentBeforePositional() async {
    await assertDiagnostics(r'''
void foo(int a, int b, {bool c = true}) {}

void f() {
  foo(0, c: true, 1);
}
''', [
      lint(67, 4),
    ]);
  }
}

@reflectiveTest
class AvoidRedundantArgumentValuesTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_redundant_argument_values';

  @override
  void setUp() {
    super.setUp();
    noSoundNullSafety = false;
  }

  void tearDown() {
    noSoundNullSafety = true;
  }

  /// https://github.com/dart-lang/linter/issues/3617
  test_enumDeclaration() async {
    await assertDiagnostics(r'''
enum TestEnum {
  a(test: false);

  const TestEnum({this.test = false});

  final bool test;
}
''', [
      lint(26, 5),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3447')
  test_fromEnvironment() async {
    await assertNoDiagnostics(r'''
const bool someDefine = bool.fromEnvironment('someDefine');

void f({bool test = true}) {}

void g() {
  f(
    test: !someDefine,
  );
}
''');
  }

  /// https://github.com/dart-lang/sdk/issues/49596
  test_legacyRequired() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
class Foo {
  int? foo;
  Foo({required this.foo});
}
''');
    await resolveFile(a.path);

    await assertNoDiagnostics(r'''
// @dart = 2.9
import 'a.dart';

void f() {
  Foo(foo: null);
}
''');
  }

  test_redirectingFactoryConstructor() async {
    await assertNoDiagnostics(r'''
class A {
  factory A([int? value]) = B;
  A._();
}
class B extends A {
  B([int? value = 2]) : super._();
}
void f() {
  A();
  A(null);
  A(1);
}
''');
  }

  test_redirectingFactoryConstructor_multipleOptional() async {
    await assertNoDiagnostics(r'''
class A {
  factory A([int? one, int? two]) = B;
  A._();
}
class B extends A {
  int? one;
  int? two;
  B([this.one = 2, this.two = 2]) : super._();
}
void f() {
  A();
  A(null, null);
  A(1, 1);
}
''');
  }

  test_redirectingFactoryConstructor_named() async {
    await assertNoDiagnostics(r'''
class A {
  factory A({int? value}) = B;
  A._();
}
class B extends A {
  B({int? value = 2}) : super._();
}
void f() {
  A();
  A(value: null);
  A(value: 1);
}
''');
  }

  test_redirectingFactoryConstructor_named_redundant() async {
    await assertDiagnostics(r'''
class A {
  factory A({int? value}) = B;
  A._();
}
class B extends A {
  B({int? value = 2}) : super._();
}
void f() {
  A(value: 2);
}
''', [
      lint(124, 8),
    ]);
  }

  test_redirectingFactoryConstructor_namedArgumentsAnywhere() async {
    await assertNoDiagnostics(r'''
class A {
  factory A(int? one, int? two, {int? three}) = B;
  A._();
}
class B extends A {
  B(int? one, int? two, {int? three = 3}) : super._();
}
void f() {
  A(1, 2);
  A(1, three: null, 2);
  A(1, 2, three: null);
  A(1, three: 4, 2);
  A(three: 4, 1, 2);
}
''');
  }

  test_redirectingFactoryConstructor_namedArgumentsAnywhere_redundant() async {
    await assertDiagnostics(r'''
class A {
  factory A(int? one, int? two, {int? three}) = B;
  A._();
}
class B extends A {
  B(int? one, int? two, {int? three = 3}) : super._();
}
void f() {
  A(1, three: 3, 2);
}
''', [
      lint(167, 8),
    ]);
  }

  test_redirectingFactoryConstructor_nested() async {
    await assertNoDiagnostics(r'''
class A {
  factory A([num? value]) = B;
  A._();
}
class B extends A {
  factory B([num? value]) = C;
  B._() : super._();
}
class C extends B {
  num? value;
  C([this.value = 2]) : super._();

  @override
  String toString() => '$value';
}
void f() {
  A();
  A(null);
  A(1);
}
''');
  }

  test_redirectingFactoryConstructor_redundant() async {
    await assertDiagnostics(r'''
class A {
  factory A([int? value]) = B;
  A._();
}
class B extends A {
  B([int? value = 2]) : super._();
}
void f() {
  A(2);
}
''', [
      lint(124, 1),
    ]);
  }

  test_redirectingGenerativeConstructor() async {
    await assertNoDiagnostics(r'''
class A {
  A([int? value]) : this._(value);
  A._([int? value = 2]);
}
void f() {
  A(2);
}
''');
  }

  test_redirectingGenerativeConstructor_named() async {
    await assertNoDiagnostics(r'''
class A {
  A({int? value}) : this._(value: value);
  A._({int? value = 2});
}
void f() {
  A(value: 2);
}
''');
  }

  test_redirectingGenerativeConstructor_named_redundant() async {
    await assertDiagnostics(r'''
class A {
  A({int? value}) : this._(value: value);
  A._({int? value = 2});
}
void f() {
  A(value: null);
}
''', [
      lint(101, 4),
    ]);
  }

  test_redirectingGenerativeConstructor_redundant() async {
    await assertDiagnostics(r'''
class A {
  A([int? value]) : this._(value);
  A._([int? value = 2]);
}
void f() {
  A(null);
}
''', [
      lint(87, 4),
    ]);
  }

  test_requiredNullable() async {
    await assertNoDiagnostics(r'''
void f({required int? x}) { }

void main() {
  f(x: null);
}
''');
  }
}
