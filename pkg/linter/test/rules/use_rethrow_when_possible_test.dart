// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseRethrowWhenPossibleTest);
  });
}

@reflectiveTest
class UseRethrowWhenPossibleTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.use_rethrow_when_possible;

  test_catchError_throwSameError() async {
    await assertDiagnostics(r'''
void f() {
  try {} catch (e) {
    throw e;
  }
}
''', [
      lint(36, 7),
    ]);
  }

  test_catchErrorAndStackTrace_throwSameError() async {
    await assertDiagnostics(r'''
void f() {
  try {} catch (e, stackTrace) {
    print(stackTrace);
    throw e;
  }
}
''', [
      lint(71, 7),
    ]);
  }

  test_rethrow() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    rethrow;
  }
}
''');
  }

  test_throw_usedAsAnArgument() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    print(throw e);
  }
}
''');
  }

  test_throw_usedAsAnExpression() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    1 == 2 ? e.toString() : throw e;
  }
}
''');
  }

  test_throw_usedAsASwitchExpressionCase() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    var x = switch(e) {
      'a' => 1,
      'b' => 2,
      _ => throw e,
    };
  }
}
''');
  }

  test_throw_usedInAssignment() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    var x = throw e;
  }
}

void g({int? p}) {}
''');
  }

  test_throw_usedInIfElement() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    [if (true) throw e];
  }
}

void g({int? p}) {}
''');
  }

  test_throwDifferentError() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e1) {
    try {} catch (e2) {
      throw e1;
    }
  }
}
''');
  }

  test_throwNewError() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    throw Exception();
  }
}
''');
  }
}
