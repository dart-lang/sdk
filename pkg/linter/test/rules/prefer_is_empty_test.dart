// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferIsEmptyTest);
  });
}

@reflectiveTest
class PreferIsEmptyTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_is_empty;

  test_iterableLength_notEq_zero() async {
    await assertDiagnostics(r'''
var i = Iterable.empty();
var x = i.length != 0;
''', [
      lint(34, 13),
    ]);
  }

  test_listLength_asInt_greaterThan_zero() async {
    await assertDiagnostics(r'''
var x = ([].length as int) > 0;
''', [
      lint(8, 22),
      error(WarningCode.UNNECESSARY_CAST, 9, 16),
    ]);
  }

  test_listLength_eqEq_negativeOne() async {
    await assertDiagnostics(r'''
var x = [].length == -1;
''', [
      lint(8, 15),
    ]);
  }

  test_listLength_eqEq_one() async {
    await assertNoDiagnostics(r'''
var x = [].length == 1;
''');
  }

  test_listLength_eqEq_zero() async {
    await assertDiagnostics(r'''
var x = [].length == 0;
''', [
      lint(8, 14),
    ]);
  }

  test_listLength_greaterThan_negativeOne() async {
    await assertDiagnostics(r'''
var x = [].length > -1;
''', [
      lint(8, 14),
    ]);
  }

  test_listLength_greaterThan_one() async {
    await assertNoDiagnostics(r'''
var x = [].length > 1;
''');
  }

  test_listLength_greaterThan_one_boolTarget() async {
    await assertNoDiagnostics(r'''
bool x = [].length > 1;
''');
  }

  test_listLength_greaterThan_zero() async {
    await assertDiagnostics(r'''
var x = [].length > 0;
''', [
      lint(8, 13),
    ]);
  }

  test_listLength_greaterThan_zero_inConditional() async {
    await assertDiagnostics(r'''
var x = [].length > 0 ? 7 : 6;
''', [
      lint(8, 13),
    ]);
  }

  test_listLength_greaterThan_zero_inConstructorAssertInitializer() async {
    await assertNoDiagnostics(r'''
class A {
  final List<String> x;
  const A(this.x) : assert(x.length > 0);
}
''');
  }

  test_listLength_greaterThanEq_negativeOne() async {
    await assertDiagnostics(r'''
var x = [].length >= -1;
''', [
      lint(8, 15),
    ]);
  }

  test_listLength_greaterThanEq_one() async {
    await assertDiagnostics(r'''
var x = [].length >= 1;
''', [
      lint(8, 14),
    ]);
  }

  test_listLength_greaterThanEq_zero() async {
    await assertDiagnostics(r'''
var x = [].length >= 0;
''', [
      lint(8, 14),
    ]);
  }

  test_listLength_lessThan_negativeOne() async {
    await assertDiagnostics(r'''
var x = [].length < -1;
''', [
      lint(8, 14),
    ]);
  }

  test_listLength_lessThan_one() async {
    await assertDiagnostics(r'''
var x = [].length < 1;
''', [
      lint(8, 13),
    ]);
  }

  test_listLength_lessThan_variable() async {
    await assertNoDiagnostics(r'''
var zero  = 0;
var x = [].length < zero;
''');
  }

  test_listLength_lessThan_zero() async {
    await assertDiagnostics(r'''
var x = [].length < 0;
''', [
      lint(8, 13),
    ]);
  }

  test_listLength_lessThanEq_negativeOne() async {
    await assertDiagnostics(r'''
var x = [].length <= -1;
''', [
      lint(8, 15),
    ]);
  }

  test_listLength_lessThanEq_one() async {
    await assertNoDiagnostics(r'''
var x = [].length <= 1;
''');
  }

  test_listLength_lessThanEq_zero() async {
    await assertDiagnostics(r'''
var x = [].length <= 0;
''', [
      lint(8, 14),
    ]);
  }

  test_listLength_notEq_negativeOne() async {
    await assertDiagnostics(r'''
var x = [].length != -1;
''', [
      lint(8, 15),
    ]);
  }

  test_listLength_notEq_one() async {
    await assertNoDiagnostics(r'''
var x = [].length != 1;
''');
  }

  test_listLength_notEq_zero() async {
    await assertDiagnostics(r'''
var x = [].length != 0;
''', [
      lint(8, 14),
    ]);
  }

  test_listLength_plusExpression_greaterThan_zero() async {
    await assertNoDiagnostics(r'''
var x = [].length + 1 > 0;
''');
  }

  test_mapLength_parenthesized_eqEq_zero() async {
    await assertDiagnostics(r'''
var x = ({1: 2}.length) == 0;
''', [
      lint(8, 20),
    ]);
  }

  test_negativeOne_eqEq_listLength() async {
    await assertDiagnostics(r'''
var x = -1 == [].length;
''', [
      lint(8, 15),
    ]);
  }

  test_negativeOne_greaterThan_listLength() async {
    await assertDiagnostics(r'''
var x = -1 > [].length;
''', [
      lint(8, 14),
    ]);
  }

  test_negativeOne_greaterThanEq_listLength() async {
    await assertDiagnostics(r'''
var x = -1 >= [].length;
''', [
      lint(8, 15),
    ]);
  }

  test_negativeOne_lessThan_listLength() async {
    await assertDiagnostics(r'''
var x = -1 < [].length;
''', [
      lint(8, 14),
    ]);
  }

  test_negativeOne_lessThanEq_listLength() async {
    await assertDiagnostics(r'''
var x = -1 <= [].length;
''', [
      lint(8, 15),
    ]);
  }

  test_negativeOne_notEq_listLength() async {
    await assertDiagnostics(r'''
var x = -1 != [].length;
''', [
      lint(8, 15),
    ]);
  }

  test_one_eqEq_listLength() async {
    await assertNoDiagnostics(r'''
var x = 1 == [].length;
''');
  }

  test_one_greaterThan_listLength() async {
    await assertDiagnostics(r'''
var x = 1 > [].length;
''', [
      lint(8, 13),
    ]);
  }

  test_one_greaterThanEq_listLength() async {
    await assertNoDiagnostics(r'''
var x = 1 >= [].length;
''');
  }

  test_one_lessThan_listLength() async {
    await assertNoDiagnostics(r'''
var x = 1 < [].length;
''');
  }

  test_one_lessThanEq_listLength() async {
    await assertDiagnostics(r'''
var x = 1 <= [].length;
''', [
      lint(8, 14),
    ]);
  }

  test_one_notEq_listLength() async {
    await assertNoDiagnostics(r'''
var x = 1 != [].length;
''');
  }

  test_stringLength_eqEq_zero_inConstructorInitializer() async {
    await assertDiagnostics(r'''
class C {
  final bool x;
  C(String s) : x = s.length == 0;
}
''', [
      lint(46, 13),
    ]);
  }

  test_stringLength_greaterThan_zero_constructorAssertInitializer() async {
    await assertNoDiagnostics(r'''
class C {
  final String s;
  const C(this.s) : assert(s.length > 0);
}
''');
  }

  test_variable_lessThan_listLength() async {
    await assertNoDiagnostics(r'''
var zero = 0;
var x = zero < [].length;
''');
  }

  test_zero_eqEq_listLength() async {
    await assertDiagnostics(r'''
var x = 0 == [].length;
''', [
      lint(8, 14),
    ]);
  }

  test_zero_greaterThan_listLength() async {
    await assertDiagnostics(r'''
var x = 0 > [].length;
''', [
      lint(8, 13),
    ]);
  }

  test_zero_greaterThanEq_listLength() async {
    await assertDiagnostics(r'''
var x = 0 >= [].length;
''', [
      lint(8, 14),
    ]);
  }

  test_zero_lessThan_listLength() async {
    await assertDiagnostics(r'''
var x = 0 < [].length;
''', [
      lint(8, 13),
    ]);
  }

  test_zero_lessThanOrEq_listLength() async {
    await assertDiagnostics(r'''
var x = 0 <= [].length;
''', [
      lint(8, 14),
    ]);
  }

  test_zero_notEq_listLength() async {
    await assertDiagnostics(r'''
var x = 0 != [].length;
''', [
      lint(8, 14),
    ]);
  }
}
