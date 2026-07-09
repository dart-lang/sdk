// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDuplicateCaseValuesTestLanguage219);
    defineReflectiveTests(NoDuplicateCaseValuesTest);
  });
}

abstract class BaseNoDuplicateCaseValuesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.no_duplicate_case_values;
}

@reflectiveTest
class NoDuplicateCaseValuesTest extends BaseNoDuplicateCaseValuesTest {
  test_duplicateConstClassValue_ok() async {
    await assertDiagnostics(
      r'''
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
''',
      [error(diag.unreachableSwitchCase, 237, 4)],
    );
  }

  test_duplicateEnumValue_ok() async {
    await assertDiagnostics(
      r'''
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
''',
      [
        // No lint.
        error(diag.unreachableSwitchCase, 139, 4),
        error(diag.unreachableSwitchDefault, 155, 7),
      ],
    );
  }

  test_duplicateIntConstant_ok() async {
    await assertDiagnostics(
      r'''
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
''',
      [
        // No lint.
        error(diag.unreachableSwitchCase, 95, 4),
        error(diag.unreachableSwitchCase, 107, 4),
      ],
    );
  }

  test_duplicateStringConstant_ok() async {
    await assertDiagnostics(
      r'''
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
''',
      [
        // No lint.
        error(diag.unreachableSwitchCase, 115, 4),
        error(diag.invalidConstantPatternBinary, 122, 1),
        error(diag.unreachableSwitchCase, 131, 4),
        error(diag.invalidConstantPatternBinary, 153, 1),
      ],
    );
  }
}

@reflectiveTest
class NoDuplicateCaseValuesTestLanguage219 extends BaseNoDuplicateCaseValuesTest
    with LanguageVersion219Mixin {
  test_duplicateConstClassValue() async {
    await assertDiagnosticsFromMarkup(r'''
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
    case [!const ConstClass(2)!]:
    default:
  }
}
''');
  }

  test_duplicateEnumValue() async {
    await assertDiagnosticsFromMarkup(r'''
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
    case [!E.two!]:
    default:
  }
}
''');
  }

  test_duplicateIntConstant() async {
    await assertDiagnosticsFromMarkup(r'''
void switchInt() {
  const int A = 1;
  int v = 5;

  switch (v) {
    case 1:
    case 2:
    case /*[0*/A/*0]*/:
    case /*[1*/2/*1]*/:
    case 3:
    default:
  }
}
''');
  }

  test_duplicateStringConstant() async {
    await assertDiagnosticsFromMarkup(r'''
void switchString() {
  const String A = 'a';
  String v = 'aa';

  switch (v) {
    case 'aa':
    case 'bb':
    case /*[0*/A + A/*0]*/:
    case /*[1*/'bb'/*1]*/:
    case A + 'b':
    default:
  }
}
''');
  }
}
