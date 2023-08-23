// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidTypesOnClosureParametersTest);
  });
}

@reflectiveTest
class AvoidTypesOnClosureParametersTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_types_on_closure_parameters';

  test_argument() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.map((e) => e.isEven);
}
''');
  }

  test_argument_typedParameter() async {
    await assertDiagnostics(r'''
void f(List<int> list) {
  list.map((int e) => e.isEven);
}
''', [
      lint(37, 3),
    ]);
  }

  test_initializerInDeclaration_namedOptional() async {
    // TODO(srawlins): Any test which just assigns a function literal to a
    // variable should be converted to something like an argument, or let
    // downwards inference work in some other way.
    // See https://github.com/dart-lang/linter/issues/1099.
    await assertNoDiagnostics(r'''
var f = ({e}) => e.isEven;
''');
  }

  test_initializerInDeclaration_optionalNullable() async {
    // TODO(srawlins): Any test which just assigns a function literal to a
    // variable should be converted to something like an argument, or let
    // downwards inference work in some other way.
    // See https://github.com/dart-lang/linter/issues/1099.
    await assertNoDiagnostics(r'''
var f = ([e]) => e.name;
''');
  }

  test_initializerInDeclaration_optionalWithDefault() async {
    // TODO(srawlins): Any test which just assigns a function literal to a
    // variable should be converted to something like an argument, or let
    // downwards inference work in some other way.
    // See https://github.com/dart-lang/linter/issues/1099.
    await assertNoDiagnostics(r'''
var f = ({e = ''}) => e;
''');
  }

  test_initializerInDeclaration_parameterIsTyped_dynamic() async {
    // TODO(srawlins): Any test which just assigns a function literal to a
    // variable should be converted to something like an argument, or let
    // downwards inference work in some other way.
    // See https://github.com/dart-lang/linter/issues/1099.
    await assertNoDiagnostics(r'''
var goodName5 = (dynamic person) => person.name;
''');
  }

  test_initializerInDeclaration_parameterIsTyped_functionType() async {
    // TODO(srawlins): Any test which just assigns a function literal to a
    // variable should be converted to something like an argument, or let
    // downwards inference work in some other way.
    // See https://github.com/dart-lang/linter/issues/1099.
    await assertDiagnostics(r'''
var functionWithFunction = (int f(int x)) => f(0);
''', [
      lint(28, 12),
    ]);
  }

  test_initializerInDeclaration_parameterIsTyped_namedRequired() async {
    // TODO(srawlins): Any test which just assigns a function literal to a
    // variable should be converted to something like an argument, or let
    // downwards inference work in some other way.
    // See https://github.com/dart-lang/linter/issues/1099.
    await assertDiagnostics(r'''
var f = ({required int e}) => e.isEven;
''', [
      lint(19, 3),
    ]);
  }

  test_initializerInDeclaration_parameterIsTyped_optionalNullable() async {
    // TODO(srawlins): Any test which just assigns a function literal to a
    // variable should be converted to something like an argument, or let
    // downwards inference work in some other way.
    // See https://github.com/dart-lang/linter/issues/1099.
    await assertDiagnostics(r'''
var f = ([int? e]) => e?.isEven;
''', [
      lint(10, 4),
    ]);
  }

  test_initializerInDeclaration_parameterIsTyped_optionalWithDefault() async {
    // TODO(srawlins): Any test which just assigns a function literal to a
    // variable should be converted to something like an argument, or let
    // downwards inference work in some other way.
    // See https://github.com/dart-lang/linter/issues/1099.
    await assertDiagnostics(r'''
var f = ([String e = '']) => e;
''', [
      lint(10, 6),
    ]);
  }
}
