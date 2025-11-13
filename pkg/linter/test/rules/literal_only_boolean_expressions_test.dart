// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LiteralOnlyBooleanExpressionsTest);
  });
}

@reflectiveTest
class LiteralOnlyBooleanExpressionsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.literal_only_boolean_expressions;

  test_adjacent_string_interpolation_constant() async {
    await assertDiagnostics(
      r'''
void f() {
  const a = 20;
  if ('$a' '0' == 20) {}
}
''',
      [lint(29, 22)],
    );
  }

  test_adjacent_string_interpolation_nonconstant() async {
    await assertNoDiagnostics(r'''
void f(int a) {
  if ('$a' '0' == 20) {}
}
''');
  }

  test_doWhile_false() async {
    await assertDiagnostics(
      r'''
void f() {
  do {} while (false);
}
''',
      [lint(13, 20)],
    );
  }

  test_for_trueCondition() async {
    await assertDiagnostics(
      r'''
void f() {
  for (; true; ) {}
}
''',
      [lint(13, 17)],
    );
  }

  test_if_andTrue() async {
    await assertDiagnostics(
      r'''
void f() {
  if (1 != 0 && true) {}
}
''',
      [lint(13, 22)],
    );
  }

  test_if_notTrue() async {
    await assertDiagnostics(
      r'''
void f() {
  if (!true) {}
}
''',
      [lint(13, 13), error(diag.deadCode, 24, 2)],
    );
  }

  test_if_nullAware_notEqual() async {
    await assertNoDiagnostics(r'''
void f(String? text) {
  if ((text?.length ?? 0) != 0) {}
}
''');
  }

  test_if_or_thenAndTrue() async {
    await assertDiagnostics(
      r'''
void f() {
  if (1 != 0 || 3 < 4 && true) {}
}
''',
      [lint(13, 31)],
    );
  }

  test_if_true() async {
    await assertDiagnostics(
      r'''
void f() {
  if (true) {}
}
''',
      [lint(13, 12)],
    );
  }

  test_if_trueAnd() async {
    await assertDiagnostics(
      r'''
void f() {
  if (true && 1 != 0) {}
}
''',
      [lint(13, 22)],
    );
  }

  test_if_trueAnd_thenOr() async {
    await assertDiagnostics(
      r'''
void f() {
  if (true && 1 != 0 || 3 < 4) {}
}
''',
      [lint(13, 31)],
    );
  }

  test_if_trueAndFalse() async {
    await assertDiagnostics(
      r'''
void bad() {
  if (true && false) {}
}
''',
      [lint(15, 21), error(diag.deadCode, 34, 2)],
    );
  }

  test_if_x() async {
    await assertDiagnostics(
      r'''
void f() {
  if (1 != 0) {}
}
''',
      [lint(13, 14)],
    );
  }

  test_ifCase_intLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  if (1 case {1:0}) {
    print('');
  }
}
''',
      [
        // No lint
        error(diag.patternNeverMatchesValueType, 24, 5),
      ],
    );
  }

  test_ifCase_listLiteral() async {
    await assertNoDiagnostics(r'''
void f() {
  if ([1] case [1]) {
    print('');
  }
}
''');
  }

  test_ifCase_mapLiteral() async {
    await assertNoDiagnostics(r'''
void f() {
  if ({1:0} case {1:0}) {
    print('');
  }
}
''');
  }

  test_ifCase_objectInstantiation() async {
    await assertNoDiagnostics(r'''
class A {
  final int a;
  A(this.a);
}

void f() {
  if (A(1) case A(a: 1)) {
    print('');
  }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4352
  test_ifCase_record() async {
    await assertNoDiagnostics(r'''
void f() {
  if (('', '') case (String(), String())) {
    print('');
  }
}
''');
  }

  test_nullAware() async {
    await assertDiagnostics(
      r'''
void f(bool p) {
  if (null ?? p) {}
}
''',
      [lint(19, 17)],
    );
  }

  test_string_interpolation_constant() async {
    await assertDiagnostics(
      r'''
void f() {
  const a = 15;
  if ('$a'=='20') {}
}
''',
      [lint(29, 18)],
    );
  }

  test_string_interpolation_nonconstant() async {
    await assertNoDiagnostics(r'''
void f(int a) {
  if ('$a'=='20') {}
}
''');
  }

  test_switchExpression() async {
    await assertNoDiagnostics(r'''
bool f(Object o) => switch(o) {
    [1] => true,
    {1:1} => false,
    (1, 1) => false,
    String(isEmpty: false) => false,
    _ => false,
  };
''');
  }

  test_whenClause() async {
    await assertDiagnostics(
      r'''
void f() {
  switch (1) {
    case [int a] when true: print(a);
  }
}
''',
      [error(diag.patternNeverMatchesValueType, 35, 7), lint(43, 9)],
    );
  }

  test_while_notTrue() async {
    await assertDiagnostics(
      r'''
void f() {
  while (!true) {}
}
''',
      [lint(13, 16), error(diag.deadCode, 27, 2)],
    );
  }

  test_whileTrue() async {
    await assertNoDiagnostics(r'''
void f() {
  while (true) {
    print('!');
  }
}
''');
  }
}
