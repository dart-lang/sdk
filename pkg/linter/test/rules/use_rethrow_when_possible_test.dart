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
  String get lintRule => 'use_rethrow_when_possible';

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

  test_throwUsedAsAnExpression1() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    1 == 2 ? e.toString() : throw e;
  }
}
''');
  }

  test_throwUsedAsAnExpression2() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    print(throw e);
  }
}
''');
  }
}
