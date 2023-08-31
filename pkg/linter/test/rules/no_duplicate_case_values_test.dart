// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDuplicateCaseValuesTestLanguage219);
    defineReflectiveTests(NoDuplicateCaseValuesTest);
  });
}

abstract class BaseNoDuplicateCaseValuesTest extends LintRuleTest {
  @override
  String get lintRule => 'no_duplicate_case_values';
}

@reflectiveTest
class NoDuplicateCaseValuesTest extends BaseNoDuplicateCaseValuesTest {
  test_duplicateConstClassValue_ok() async {
    await assertDiagnostics(r'''
class ConstClass {
  final int v;
  const ConstClass(this.v);
}

void switchConstClass() {
  ConstClass v = new ConstClass(1);

  switch (v) {
    case const ConstClass(1):
    case const ConstClass(2):
    case const ConstClass(3):
    case const ConstClass(2):
    default:
  }
}
''', [
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 237, 4),
    ]);
  }

  test_duplicateEnumValue_ok() async {
    await assertDiagnostics(r'''
enum E {
  one,
  two,
  three
}

void switchEnum() {
  E v = E.one;

  switch (v) {
    case E.one:
    case E.two:
    case E.three:
    case E.two:
    default:
  }
}
''', [
      // No lint.
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 139, 4),
    ]);
  }

  test_duplicateIntConstant_ok() async {
    await assertDiagnostics(r'''
void switchInt() {
  const int A = 1;
  int v = 5;

  switch (v) {
    case 1:
    case 2:
    case A:
    case 2:
    case 3:
    default:
  }
}
''', [
      // No lint.
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 95, 4),
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 107, 4),
    ]);
  }

  test_duplicateStringConstant_ok() async {
    await assertDiagnostics(r'''
void switchString() {
  const String A = 'a';
  String v = 'aa';

  switch (v) {
    case 'aa':
    case 'bb':
    case A + A:
    case 'bb':
    case A + 'b':
    default:
  }
}
''', [
      // No lint.
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 115, 4),
      error(ParserErrorCode.INVALID_CONSTANT_PATTERN_BINARY, 122, 1),
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 131, 4),
      error(ParserErrorCode.INVALID_CONSTANT_PATTERN_BINARY, 153, 1),
    ]);
  }
}

@reflectiveTest
class NoDuplicateCaseValuesTestLanguage219 extends BaseNoDuplicateCaseValuesTest
    with LanguageVersion219Mixin {
  test_duplicateConstClassValue() async {
    await assertDiagnostics(r'''
class ConstClass {
  final int v;
  const ConstClass(this.v);
}

void switchConstClass() {
  ConstClass v = new ConstClass(1);

  switch (v) {
    case const ConstClass(1):
    case const ConstClass(2):
    case const ConstClass(3):
    case const ConstClass(2):
    default:
  }
}
''', [
      lint(242, 19),
    ]);
  }

  test_duplicateEnumValue() async {
    await assertDiagnostics(r'''
enum E {
  one,
  two,
  three
}

void switchEnum() {
  E v = E.one;

  switch (v) {
    case E.one:
    case E.two:
    case E.three:
    case E.two:
    default:
  }
}
''', [
      lint(144, 5),
    ]);
  }

  test_duplicateIntConstant() async {
    await assertDiagnostics(r'''
void switchInt() {
  const int A = 1;
  int v = 5;

  switch (v) {
    case 1:
    case 2:
    case A:
    case 2:
    case 3:
    default:
  }
}
''', [
      lint(100, 1),
      lint(112, 1),
    ]);
  }

  test_duplicateStringConstant() async {
    await assertDiagnostics(r'''
void switchString() {
  const String A = 'a';
  String v = 'aa';

  switch (v) {
    case 'aa':
    case 'bb':
    case A + A:
    case 'bb':
    case A + 'b':
    default:
  }
}
''', [
      lint(120, 5),
      lint(136, 4),
    ]);
  }
}
