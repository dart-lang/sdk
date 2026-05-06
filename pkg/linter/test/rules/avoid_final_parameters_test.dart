// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  String get lintRule => LintNames.avoid_final_parameters;

  test_constructorFieldFormal_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class C {
  int p;
  C(final this.p);
}
''',
      [error(diag.unnecessaryFinal, 37, 5)],
    );
  }

  test_constructorFieldFormal_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class C {
  int p;
  C(this.p);
}
''');
  }

  test_constructorSimple_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class C {
  C(final int p);
}
''',
      [lint(28, 5)],
    );
  }

  test_constructorSimple_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class C {
  C(int p);
}
''');
  }

  test_enum_constructor_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
enum E {
  a(1);
  const E(final int p);
}
''',
      [lint(41, 5)],
    );
  }

  test_enum_constructor_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
enum E {
  a(1);
  const E(int p);
}
''');
  }

  test_enum_method_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
enum E {
  a;
  void f(final p) {}
}
''',
      [lint(37, 5)],
    );
  }

  test_enum_method_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
enum E {
  a;
  void f(int p) {}
}
''');
  }

  test_extension_method_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
extension E on int {
  void f(final p) {}
}
''',
      [lint(44, 5)],
    );
  }

  test_extension_method_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
extension E on int {
  void f(int p) {}
}
''');
  }

  test_extensionType_method_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
extension type E(int i) {
  void f(final p) {}
}
''',
      [lint(49, 5)],
    );
  }

  test_extensionType_method_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
extension type E(int i) {
  void f(int p) {}
}
''');
  }

  test_functionExpression_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
var f = (final int value) {};
''',
      [lint(23, 5)],
    );
  }

  test_functionExpression_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
var f = (int value) {};
''');
  }

  test_functionTyped_fieldFormal_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class C {
  final void Function(int) f;
  C(void this.f(final p));
}
''',
      [lint(70, 5)],
    );
  }

  test_functionTyped_fieldFormal_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class C {
  final void Function(int) f;
  C(void this.f(int p));
}
''');
  }

  test_functionTyped_final() async {
    // No lint because a warning already exists for this case.
    await assertDiagnostics(
      r'''
// @dart=3.12
void f(final p()) {}
''',
      [error(diag.functionTypedParameterVar, 21, 5)],
    );
  }

  test_functionTyped_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f(int p()) {}
''');
  }

  test_functionTyped_parameter_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f(void g(final p)) {}
''',
      [lint(28, 5)],
    );
  }

  test_functionTyped_parameter_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f(void g(int p)) {}
''');
  }

  test_functionTyped_superFormal_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class A {
  A(void f(int p));
}
class B extends A {
  B(void super.f(final p));
}
''',
      [lint(83, 5)],
    );
  }

  test_functionTyped_superFormal_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class A {
  A(void f(int p));
}
class B extends A {
  B(void super.f(int p));
}
''');
  }

  test_localFunction_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f() {
  void g(final p) {}
}
''',
      [lint(34, 5)],
    );
  }

  test_localFunction_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f() {
  void g(int p) {}
}
''');
  }

  test_mixin_method_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
mixin M {
  void f(final p) {}
}
''',
      [lint(33, 5)],
    );
  }

  test_mixin_method_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
mixin M {
  void f(int p) {}
}
''');
  }

  test_operator_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class C {
  int operator +(final int other) => 0;
}
''',
      [lint(41, 5)],
    );
  }

  test_operator_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class C {
  int operator +(int other) => 0;
}
''');
  }

  test_optionalNamed_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f({final int? p}) {}
''',
      [lint(22, 5)],
    );
  }

  test_optionalNamed_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f({int? p}) {}
''');
  }

  test_optionalPositional_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f([final int? p]) {}
''',
      [lint(22, 5)],
    );
  }

  test_optionalPositional_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f([int? p]) {}
''');
  }

  test_optionalPositionalWithDefault_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f([final int p = 0]) {}
''',
      [lint(22, 5)],
    );
  }

  test_optionalPositionalWithDefault_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f([int p = 0]) {}
''');
  }

  test_requiredNamed_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f({required final int? p}) {}
''',
      [lint(31, 5)],
    );
  }

  test_requiredNamed_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f({required int p}) {}
''');
  }

  test_requiredPositional_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f(final int p) {}
''',
      [lint(21, 5)],
    );
  }

  test_requiredPositional_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f(int p) {}
''');
  }

  test_requiredPositional_wildcard() async {
    // Wildcards are treated just like any param.
    // https://github.com/dart-lang/linter/issues/5045
    await assertDiagnostics(
      r'''
// @dart=3.12
void f(final int _) {}
''',
      [lint(21, 5)],
    );
  }

  test_setter_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
set f(final int value) {}
''',
      [lint(20, 5)],
    );
  }

  test_setter_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
set f(int value) {}
''');
  }

  test_super_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
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
        error(diag.unnecessaryFinal, 97, 5),
        error(diag.unnecessaryFinal, 112, 5),
      ],
    );
  }

  test_super_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class A {
  String? a;
  String? b;
  A(this.a, this.b);
}
class B extends A {
  B(super.a, super.b);
}
''');
  }

  test_typedef_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
typedef String Type(final value);
''',
      [lint(34, 5)],
    );
  }

  test_typedef_genericFunctionType_final() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
typedef F = void Function(final x);
''',
      [
        // No lint reported to avoid redundancy with
        // `functionTypedParameterVar`.
        error(diag.functionTypedParameterVar, 40, 5),
        error(diag.undefinedClass, 46, 1),
      ],
    );
  }

  test_typedef_genericFunctionType_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
typedef F = void Function(int x);
''');
  }

  test_typedef_noFinal() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
typedef String Type(int value);
''');
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
