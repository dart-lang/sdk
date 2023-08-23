// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFinalParametersTest);
  });
}

@reflectiveTest
class AvoidFinalParametersTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_final_parameters';

  // TODO(srawlins): Test function-typed parameter like `void f(final p())`.

  test_constructorFieldFormal_final() async {
    await assertDiagnostics(r'''
class C {
  int p;
  C(final this.p);
}
''', [
      // TODO(srawlins): Do not report this lint rule here, as it is redundant
      // with the Warning.
      error(WarningCode.UNNECESSARY_FINAL, 23, 5),
      lint(23, 12),
    ]);
  }

  test_constructorFieldFormal_noFinal() async {
    await assertNoDiagnostics(r'''
class C {
  int p;
  C(this.p);
}
''');
  }

  test_constructorSimple_final() async {
    await assertDiagnostics(r'''
class C {
  C(final int p);
}
''', [
      lint(14, 11),
    ]);
  }

  test_constructorSimple_noFinal() async {
    await assertNoDiagnostics(r'''
class C {
  C(int p);
}
''');
  }

  test_functionExpression_final() async {
    await assertDiagnostics(r'''
var f = (final int value) {};
''', [
      lint(9, 15),
    ]);
  }

  test_functionExpression_noFinal() async {
    await assertNoDiagnostics(r'''
var f = (int value) {};
''');
  }

  test_operator_final() async {
    await assertDiagnostics(r'''
class C {
  int operator +(final int other) => 0;
}
''', [
      lint(27, 15),
    ]);
  }

  test_operator_noFinal() async {
    await assertNoDiagnostics(r'''
class C {
  int operator +(int other) => 0;
}
''');
  }

  test_optionalNamed_final() async {
    await assertDiagnostics(r'''
void f({final int? p}) {}
''', [
      lint(8, 12),
    ]);
  }

  test_optionalNamed_noFinal() async {
    await assertNoDiagnostics(r'''
void f({int? p}) {}
''');
  }

  test_optionalPositional_final() async {
    await assertDiagnostics(r'''
void f([final int? p]) {}
''', [
      lint(8, 12),
    ]);
  }

  test_optionalPositional_noFinal() async {
    await assertNoDiagnostics(r'''
void f([int? p]) {}
''');
  }

  test_optionalPositionalWithDefault_final() async {
    await assertDiagnostics(r'''
void f([final int p = 0]) {}
''', [
      lint(8, 15),
    ]);
  }

  test_optionalPositionalWithDefault_noFinal() async {
    await assertNoDiagnostics(r'''
void f([int p = 0]) {}
''');
  }

  test_requiredNamed_final() async {
    await assertDiagnostics(r'''
void f({required final int? p}) {}
''', [
      lint(8, 21),
    ]);
  }

  test_requiredNamed_noFinal() async {
    await assertNoDiagnostics(r'''
void f({required int p}) {}
''');
  }

  test_requiredPositional_final() async {
    await assertDiagnostics(r'''
void f(final int p) {}
''', [
      lint(7, 11),
    ]);
  }

  test_requiredPositional_noFinal() async {
    await assertNoDiagnostics(r'''
void f(int p) {}
''');
  }

  test_setter_final() async {
    await assertDiagnostics(r'''
set f(final int value) {}
''', [
      lint(6, 15),
    ]);
  }

  test_setter_noFinal() async {
    await assertNoDiagnostics(r'''
set f(int value) {}
''');
  }

  test_super() async {
    await assertDiagnostics(r'''
class A {
  String? a;
  String? b;
  A(this.a, this.b);
}
class B extends A {
  B(final super.a, final super.b);
}
''', [
      // TODO(srawlins): Do not report this lint rule here, as it is redundant
      // with the Hint.
      error(WarningCode.UNNECESSARY_FINAL, 83, 5),
      error(WarningCode.UNNECESSARY_FINAL, 98, 5),
      lint(83, 13),
      lint(98, 13),
    ]);
  }
}
