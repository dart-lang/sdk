// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidEmptyElseTest);
  });
}

@reflectiveTest
class AvoidEmptyElseTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_empty_else;

  test_else_emptyStatement_hasElseIf() async {
    await assertDiagnostics(r'''
void f() {
  var x = 0;
  var y = 1;
  if (x > y)
    print('');
  else if (x < y)
    print('');
  else ;
    print('');
}
''', [
      lint(105, 1),
    ]);
  }

  test_else_emptyStatement_noElseIf() async {
    await assertDiagnostics(r'''
void f() {
  var x = 0;
  var y = 1;
  if (x > y)
    print('');
  else ;
    print('');
}
''', [
      lint(72, 1),
    ]);
  }

  test_else_noEmptyStatement_enclosed() async {
    await assertNoDiagnostics(r'''
void f() {
  var x = 0;
  var y = 1;
  if (x > y) {
    print('');
  } else {
    print('');
  }
}
''');
  }

  test_else_noEmptyStatement_notEnclosed() async {
    await assertNoDiagnostics(r'''
void f() {
  var x = 0;
  var y = 1;
  if (x > y)
    print('');
  else
    print('');
}
''');
  }

  test_else_noStatement_notEnclosed() async {
    await assertDiagnostics(r'''
void f() {
  var x = 0;
  var y = 1;
  if (x > y)
    print('');
  else
}
''', [
      // No lint
      error(ParserErrorCode.EXPECTED_TOKEN, 67, 4),
      error(ParserErrorCode.MISSING_IDENTIFIER, 72, 1),
    ]);
  }
}
