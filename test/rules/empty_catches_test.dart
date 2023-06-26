// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmptyCatchesTest);
  });
}

@reflectiveTest
class EmptyCatchesTest extends LintRuleTest {
  @override
  String get lintRule => 'empty_catches';
  test_comment() async {
    await assertNoDiagnostics(r'''
void foo() {
  try {
    throw new Exception();
  } catch (e) {
    // Nothing.
  }
}
''');
  }

  test_emptyCatch() async {
    await assertDiagnostics(r'''
void foo() {
  try {
    throw Exception();
  } catch (e) {}
}
''', [
      lint(58, 2),
    ]);
  }

  test_statement() async {
    await assertNoDiagnostics(r'''
void foo() {
  try {
    throw new Exception();
  } catch (e) {
    print(e);
  }
}
''');
  }

  test_underscore() async {
    await assertNoDiagnostics(r'''
void foo() {
  try {
    throw Exception();
  } catch (_) {}
}
''');
  }
}
