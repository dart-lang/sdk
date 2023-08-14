// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferContainsTest);
  });
}

@reflectiveTest
class PreferContainsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_contains';

  test_argumentTypeNotAssignable() async {
    await assertDiagnostics(r'''
List<int> list = [];
condition() {
  var next;
  while ((next = list.indexOf('{')) != -1) {}
}
''', [
      // No lint
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 77, 3),
    ]);
  }

  test_list_indexOf_greaterThan_negativeOne() async {
    await assertDiagnostics(r'''
void f(List<int> list) {
  list.indexOf(1) > -1;
}
''', [
      lint(27, 20),
    ]);
  }

  test_list_indexOf_notEqual_negativeOne() async {
    await assertDiagnostics(r'''
void f(List<int> list) {
  list.indexOf(1) != -1;
}
''', [
      lint(27, 21),
    ]);
  }

  test_listConcatenation_indexOfWithDifferentArguments() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.indexOf(1) + "a".indexOf("ab") > 0;
}
''');
  }

  test_listLiteral_indexOf_equalEqual_negativeOne() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) == -1;
}
''', [
      lint(13, 19),
    ]);
  }

  test_listLiteral_indexOf_equalEqual_negativeTwo() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) == -2;
}
''', [
      lint(13, 19),
    ]);
  }

  test_listLiteral_indexOf_equalEqual_zero() async {
    await assertNoDiagnostics(r'''
void f() {
  [].indexOf(1) == 0;
}
''');
  }

  test_listLiteral_indexOf_greater_negativeTwo() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) > -2;
}
''', [
      lint(13, 18),
    ]);
  }

  test_listLiteral_indexOf_greaterOr_negativeTwo() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) >= -2;
}
''', [
      lint(13, 19),
    ]);
  }

  test_listLiteral_indexOf_greaterOrEqual_negativeOne() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) >= -1;
}
''', [
      lint(13, 19),
    ]);
  }

  test_listLiteral_indexOf_greaterOrEqual_zero() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) >= 0;
}
''', [
      lint(13, 18),
    ]);
  }

  test_listLiteral_indexOf_greaterThan_negativeOne() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) > -1;
}
''', [
      lint(13, 18),
    ]);
  }

  test_listLiteral_indexOf_greaterThan_one() async {
    await assertNoDiagnostics(r'''
void f() {
  [].indexOf(1) > 1;
}
''');
  }

  test_listLiteral_indexOf_greaterThan_zero() async {
    await assertNoDiagnostics(r'''
void f() {
  [].indexOf(1) > 0;
}
''');
  }

  test_listLiteral_indexOf_lessOrEqual_negativeOne() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) <= -1;
}
''', [
      lint(13, 19),
    ]);
  }

  test_listLiteral_indexOf_lessOrEqual_negativeTwo() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) <= -2;
}
''', [
      lint(13, 19),
    ]);
  }

  test_listLiteral_indexOf_lessOrEqual_zero() async {
    await assertNoDiagnostics(r'''
void f() {
  [].indexOf(1) <= 0;
}
''');
  }

  test_listLiteral_indexOf_lessThan_negativeOne() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) < -1;
}
''', [
      lint(13, 18),
    ]);
  }

  test_listLiteral_indexOf_lessThan_negativeOneConst() async {
    await assertDiagnostics(r'''
const int MINUS_ONE = -1;
void f() {
  [].indexOf(1) < MINUS_ONE;
}
''', [
      lint(39, 25),
    ]);
  }

  test_listLiteral_indexOf_lessThan_negativeTwo() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) < -2;
}
''', [
      lint(13, 18),
    ]);
  }

  test_listLiteral_indexOf_lessThan_zero() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) < 0;
}
''', [
      lint(13, 17),
    ]);
  }

  test_listLiteral_indexOf_notEqual_negativeOne() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) != -1;
}
''', [
      lint(13, 19),
    ]);
  }

  test_listLiteral_indexOf_notEqual_negativeTwo() async {
    await assertDiagnostics(r'''
void f() {
  [].indexOf(1) != -2;
}
''', [
      lint(13, 19),
    ]);
  }

  test_listLiteral_indexOf_notEqual_zero() async {
    await assertNoDiagnostics(r'''
void f() {
  [].indexOf(1) != 0;
}
''');
  }

  test_listTypedef_indexOf_equalEqual_negativeOne() async {
    await assertDiagnostics(r'''
typedef F = List<int>;
void f(F list) {
  list.indexOf(1) == -1;
}
''', [
      lint(42, 21),
    ]);
  }

  test_negativeOne_equalEqual_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -1 == [].indexOf(1);
}
''', [
      lint(13, 19),
    ]);
  }

  test_negativeOne_greaterOrEqual_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -1 >= [].indexOf(1);
}
''', [
      lint(13, 19),
    ]);
  }

  test_negativeOne_greaterThan_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -1 > [].indexOf(1);
}
''', [
      lint(13, 18),
    ]);
  }

  test_negativeOne_lessOrEqual_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -1 <= [].indexOf(1);
}
''', [
      lint(13, 19),
    ]);
  }

  test_negativeOne_lessThan_list_indexOf() async {
    await assertDiagnostics(r'''
void f(List<int> list) {
  -1 < list.indexOf(1);
}
''', [
      lint(27, 20),
    ]);
  }

  test_negativeOne_lessThan_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -1 < [].indexOf(1);
}
''', [
      lint(13, 18),
    ]);
  }

  test_negativeOne_notEqual_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -1 != [].indexOf(1);
}
''', [
      lint(13, 19),
    ]);
  }

  test_negativeOneConst_lessThan_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
const int MINUS_ONE = -1;
void f() {
  MINUS_ONE < [].indexOf(1);
}
''', [
      lint(39, 25),
    ]);
  }

  test_negativeTwo_equalEqual_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -2 == [].indexOf(1);
}
''', [
      lint(13, 19),
    ]);
  }

  test_negativeTwo_greaterOrEqual_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -2 >= [].indexOf(1);
}
''', [
      lint(13, 19),
    ]);
  }

  test_negativeTwo_greaterThan_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -2 > [].indexOf(1);
}
''', [
      lint(13, 18),
    ]);
  }

  test_negativeTwo_lessOrEqual_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -2 <= [].indexOf(1);
}
''', [
      lint(13, 19),
    ]);
  }

  test_negativeTwo_lessThan_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -2 < [].indexOf(1);
}
''', [
      lint(13, 18),
    ]);
  }

  test_negativeTwo_notEqual_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  -2 != [].indexOf(1);
}
''', [
      lint(13, 19),
    ]);
  }

  test_promotedToList_indexOf_lessThan_zero() async {
    await assertDiagnostics(r'''
bool f<T>(T list) =>
  list is List<int> && list.indexOf(1) < 0;
''', [
      lint(44, 19),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/3546
  test_secondArgNonZero() async {
    await assertNoDiagnostics(r'''
bool b = '11'.indexOf('2', 1) == -1;
''');
  }

  /// https://github.com/dart-lang/linter/issues/3546
  test_secondArgZero() async {
    await assertDiagnostics(r'''
bool b = '11'.indexOf('2', 0) == -1;
''', [
      lint(9, 26),
    ]);
  }

  test_stringLiteral_indexOf_equalEqual_negativeOne() async {
    await assertDiagnostics(r'''
void f() {
  'aaa'.indexOf('a') == -1;
}
''', [
      lint(13, 24),
    ]);
  }

  test_stringLiteral_indexOf_twoArguments() async {
    await assertNoDiagnostics(r'''
void f() {
  'aaa'.indexOf('a', 2);
}
''');
  }

  test_typeVariableExtendingList_indexOf_lessThan_zero() async {
    await assertDiagnostics(r'''
bool f<T extends List<int>>(T list) =>
  list.indexOf(1) < 0;
''', [
      lint(41, 19),
    ]);
  }

  test_unnecessaryCast() async {
    await assertDiagnostics(r'''
bool le3 = ([].indexOf(1) as int) > -1;
''', [
      lint(11, 27),
      error(WarningCode.UNNECESSARY_CAST, 12, 20),
    ]);
  }

  test_zero_equalEqual_listLiteral_indexOf() async {
    await assertNoDiagnostics(r'''
void f() {
  0 == [].indexOf(1);
}
''');
  }

  test_zero_greaterOrEqual_listLiteral_indexOf() async {
    await assertNoDiagnostics(r'''
void f() {
  0 >= [].indexOf(1);
}
''');
  }

  test_zero_greaterThan_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  0 > [].indexOf(1);
}
''', [
      lint(13, 17),
    ]);
  }

  test_zero_lessOrEqual_listLiteral_indexOf() async {
    await assertDiagnostics(r'''
void f() {
  0 <= [].indexOf(1);
}
''', [
      lint(13, 18),
    ]);
  }

  test_zero_lessThan_listLiteral_indexOf() async {
    await assertNoDiagnostics(r'''
void f() {
  0 < [].indexOf(1);
}
''');
  }

  test_zero_notEqual_listLiteral_indexOf() async {
    await assertNoDiagnostics(r'''
void f() {
  0 != [].indexOf(1);
}
''');
  }
}
