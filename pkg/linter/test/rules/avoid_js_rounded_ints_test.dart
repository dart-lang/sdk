// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidJsRoundedIntsTest);
  });
}

@reflectiveTest
class AvoidJsRoundedIntsTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_js_rounded_ints';

  test_maxSafeInteger() async {
    await assertNoDiagnostics(r'''
final r = 9007199254740991;
''');
  }

  test_maxSafeInteger_negative() async {
    await assertNoDiagnostics(r'''
final r = -9007199254740991;
''');
  }

  test_maxSafeInteger_plusTwo() async {
    await assertDiagnostics(r'''
final r = 9007199254740993;
''', [
      lint(10, 16),
    ]);
  }

  test_maxSafeInteger_plusTwo_negative() async {
    await assertDiagnostics(r'''
final r = -9007199254740993;
''', [
      lint(11, 16),
    ]);
  }

  test_smallInt() async {
    await assertNoDiagnostics(r'''
final r = 1;
''');
  }

  test_smallInt_negative() async {
    await assertNoDiagnostics(r'''
final r = -45321;
''');
  }

  test_tenToTheEighteen() async {
    await assertNoDiagnostics(r'''
final r = 1000000000000000000;
''');
  }

  test_tenToTheEighteen_plusOne() async {
    await assertDiagnostics(r'''
final r = 1000000000000000001;
''', [
      lint(10, 19),
    ]);
  }

  test_twoToTheSixtyThree_negative() async {
    // value.abs() for this number is negative on the 64-bit integer VM.
    // Lucky it is not rounded! (-2^63)
    await assertNoDiagnostics(r'''
final absNegative = -9223372036854775808; // OK
''');
  }
}
