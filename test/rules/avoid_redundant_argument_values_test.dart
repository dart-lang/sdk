// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
      lint('avoid_redundant_argument_values', 67, 4),
    ]);
  }
}

@reflectiveTest
class AvoidRedundantArgumentValuesTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_redundant_argument_values';

  /// https://github.com/dart-lang/linter/issues/3617
  test_enumDeclaration() async {
    await assertDiagnostics(r'''
enum TestEnum {
  a(test: false);

  const TestEnum({this.test = false});

  final bool test;
}
''', [
      lint(lintRule, 26, 5),
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

  test_requiredNullable() async {
    await assertNoDiagnostics(r'''
void f({required int? x}) { }

void main() {
  f(x: null);
} 
''');
  }
}
