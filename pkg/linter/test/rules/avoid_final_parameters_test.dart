// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFinalParametersTest);
    defineReflectiveTests(AvoidFinalParametersPrePrimaryConstructorsTest);
  });
}

@reflectiveTest
class AvoidFinalParametersPrePrimaryConstructorsTest extends LintRuleTest {
  @override
  List<String> get experiments => super.experiments
      .where((e) => e != Feature.primary_constructors.enableString)
      .toList();

  @override
  String get lintRule => LintNames.avoid_final_parameters;

  test_constructorFieldFormal_final() async {
    await assertDiagnostics(
      r'''
class C {
  int p;
  C(final this.p);
}
''',
      [
        // TODO(srawlins): Do not report this lint rule here, as it is redundant
        // with the Warning.
        error(diag.unnecessaryFinal, 23, 5),
        lint(23, 5),
      ],
    );
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
    await assertDiagnostics(
      r'''
class C {
  C(final int p);
}
''',
      [lint(14, 5)],
    );
  }

  test_constructorSimple_noFinal() async {
    await assertNoDiagnostics(r'''
class C {
  C(int p);
}
''');
  }

  test_functionExpression_final() async {
    await assertDiagnostics(
      r'''
var f = (final int value) {};
''',
      [lint(9, 5)],
    );
  }

  test_functionExpression_noFinal() async {
    await assertNoDiagnostics(r'''
var f = (int value) {};
''');
  }

  test_functionTyped_final() async {
    // No lint because a warning already exists for this case.
    await assertDiagnostics(
      r'''
void f(final p()) {}
''',
      [error(diag.functionTypedParameterVar, 7, 5)],
    );
  }

  test_functionTyped_noFinal() async {
    await assertNoDiagnostics(r'''
void f(int p()) {}
''');
  }

  test_operator_final() async {
    await assertDiagnostics(
      r'''
class C {
  int operator +(final int other) => 0;
}
''',
      [lint(27, 5)],
    );
  }

  test_operator_noFinal() async {
    await assertNoDiagnostics(r'''
class C {
  int operator +(int other) => 0;
}
''');
  }

  test_optionalNamed_final() async {
    await assertDiagnostics(
      r'''
void f({final int? p}) {}
''',
      [lint(8, 5)],
    );
  }

  test_optionalNamed_noFinal() async {
    await assertNoDiagnostics(r'''
void f({int? p}) {}
''');
  }

  test_optionalPositional_final() async {
    await assertDiagnostics(
      r'''
void f([final int? p]) {}
''',
      [lint(8, 5)],
    );
  }

  test_optionalPositional_noFinal() async {
    await assertNoDiagnostics(r'''
void f([int? p]) {}
''');
  }

  test_optionalPositionalWithDefault_final() async {
    await assertDiagnostics(
      r'''
void f([final int p = 0]) {}
''',
      [lint(8, 5)],
    );
  }

  test_optionalPositionalWithDefault_noFinal() async {
    await assertNoDiagnostics(r'''
void f([int p = 0]) {}
''');
  }

  test_requiredNamed_final() async {
    await assertDiagnostics(
      r'''
void f({required final int? p}) {}
''',
      [lint(17, 5)],
    );
  }

  test_requiredNamed_noFinal() async {
    await assertNoDiagnostics(r'''
void f({required int p}) {}
''');
  }

  test_requiredPositional_final() async {
    await assertDiagnostics(
      r'''
void f(final int p) {}
''',
      [lint(7, 5)],
    );
  }

  test_requiredPositional_noFinal() async {
    await assertNoDiagnostics(r'''
void f(int p) {}
''');
  }

  test_requiredPositional_wildcard() async {
    // Wildcards are treated just like any param.
    // https://github.com/dart-lang/linter/issues/5045
    await assertDiagnostics(
      r'''
void f(final int _) {}
''',
      [lint(7, 5)],
    );
  }

  test_setter_final() async {
    await assertDiagnostics(
      r'''
set f(final int value) {}
''',
      [lint(6, 5)],
    );
  }

  test_setter_noFinal() async {
    await assertNoDiagnostics(r'''
set f(int value) {}
''');
  }

  test_super() async {
    await assertDiagnostics(
      r'''
class A {
  String? a;
  String? b;
  A(this.a, this.b);
}
class B extends A {
  B(final super.a, final super.b);
}
''',
      [
        // TODO(srawlins): Do not report this lint rule here, as it is redundant
        // with the Hint.
        error(diag.unnecessaryFinal, 83, 5),
        error(diag.unnecessaryFinal, 98, 5),
        lint(83, 5),
        lint(98, 5),
      ],
    );
  }
}

@reflectiveTest
class AvoidFinalParametersTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_final_parameters;

  // With primary constructors, this lint is disabled.
  // No need to repeat all the tests; one will do.
  test_constructorSimple_final() async {
    await assertDiagnostics(
      r'''
class C {
  // Would be flagged.
  C(final int p);
}
''',
      [error(diag.extraneousModifier, 37, 5)],
    );
  }
}
