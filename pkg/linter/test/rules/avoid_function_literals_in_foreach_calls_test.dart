// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFunctionLiteralsInForeachCalls);
    defineReflectiveTests(AvoidFunctionLiteralsInForeachCallsPreNNBDTest);
  });
}

@reflectiveTest
class AvoidFunctionLiteralsInForeachCalls extends LintRuleTest {
  @override
  String get lintRule => 'avoid_function_literals_in_foreach_calls';

  test_expectedIdentifier() async {
    await assertDiagnostics(r'''
void f(dynamic iter) => iter?.forEach(...);
''', [
      // No lint
      error(ParserErrorCode.MISSING_IDENTIFIER, 38, 3),
    ]);
  }

  test_functionExpression_nullableTarget() async {
    await assertNoDiagnostics(r'''
void f(List<String>? people) {
  people?.forEach((person) => print('$person!'));
}
''');
  }

  test_functionExpression_nullAwareChain() async {
    await assertNoDiagnostics(r'''
void f(Map<String, int>? people) {
  people?.keys.forEach((person) => print('$person!'));
}
''');
  }

  test_functionExpression_targetDoesNotHaveMethodChain() async {
    await assertDiagnostics(r'''
void f(List<List<String>> people) {
  people
      .first
      .forEach((person) => print('$person!'));
}
''', [
      lint(65, 7),
    ]);
  }

  test_functionExpression_targetHasCascade() async {
    await assertNoDiagnostics(r'''
void f(List<List<List<String>>> lists) {
  final lists2 = lists..first.forEach((list) {
    list.add('y');
  });
}
''');
  }

  test_functionExpression_targetHasCascadeAndNullAssert() async {
    await assertNoDiagnostics(r'''
class C {
  List<String>? items;
}

void f(C obj) {
  final result = obj..items!.forEach((s) {
    print(s);
  });
}
''');
  }

  test_functionExpression_targetHasMethodChain() async {
    await assertNoDiagnostics(r'''
void f(List<String> people) {
  people
      .map((person) => person.toUpperCase())
      .forEach((person) => print('$person!'));
}
''');
  }

  test_functionExpression_targetInIrrelevantNestedCascade() async {
    await assertDiagnostics(r'''
void f(List<List<List<String>>> lists) {
  final lists2 = lists..forEach((list) {
    list.forEach((item) {
      print(item);
    });
  });
}
''', [
      lint(91, 7),
    ]);
  }

  test_functionExpressionWithBlockBody() async {
    await assertDiagnostics(r'''
void f(List<String> people) {
  people.forEach((person) {
    print('$person!');
  });
}
''', [
      lint(39, 7),
    ]);
  }

  test_functionExpressionWithExpressionBody() async {
    await assertDiagnostics(r'''
void f(List<String> people) {
  people.forEach((person) => print('$person!'));
}
''', [
      lint(39, 7),
    ]);
  }

  test_nonFunctionExpression() async {
    await assertNoDiagnostics(r'''
void f(List<String> people) {
  people.forEach(print);
}
''');
  }

  test_nonFunctionExpression_targetHasMethodChain() async {
    await assertNoDiagnostics(r'''
void f(List<String> people) {
  people
      .map((person) => person.toUpperCase())
      .forEach(print);
}
''');
  }
}

@reflectiveTest
class AvoidFunctionLiteralsInForeachCallsPreNNBDTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_function_literals_in_foreach_calls';

  @override
  setUp() {
    super.setUp();
    noSoundNullSafety = false;
  }

  tearDown() {
    noSoundNullSafety = true;
  }

  test_functionExpression_basic() async {
    await assertDiagnostics(r'''
// @dart=2.9
void f(List<String> people) {
  people.forEach((person) => print('$person'));
}
''', [lint(52, 7)]);
  }

  test_functionExpression_nullAware() async {
    await assertNoDiagnostics(r'''
// @dart=2.9
void f(List<String> people) {
  people?.forEach((person) => print('$person'));
}
''');
  }
}
