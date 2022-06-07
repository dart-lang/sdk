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
  List<String> get experiments => [EnableString.named_arguments_anywhere];

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

  test_requiredNullable() async {
    await assertNoDiagnostics(r'''
void f({required int? x}) { }

void main() {
  f(x: null);
} 
''');
  }
}
