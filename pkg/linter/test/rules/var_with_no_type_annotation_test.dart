// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VarWithNoTypeAnnotationTest);
    defineReflectiveTests(VarWithNoTypeAnnotationPrePrimaryConstructorsTest);
  });
}

@reflectiveTest
class VarWithNoTypeAnnotationPrePrimaryConstructorsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.var_with_no_type_annotation;

  test_constructorFieldFormal_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class C {
  int p;
  C(this.p);
}
''');
  }

  test_constructorFieldFormal_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class C {
  int p;
  C(var this.p);
}
''',
      [lint(37, 3)],
    );
  }

  test_constructorSimple_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class C {
  C(int p);
}
''');
  }

  test_constructorSimple_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class C {
  C(var p);
}
''',
      [lint(28, 3)],
    );
  }

  test_extension_method_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
extension E on int {
  void f(int p) {}
}
''');
  }

  test_extension_method_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
extension E on int {
  void f(var p) {}
}
''',
      [lint(44, 3)],
    );
  }

  test_extensionType_method_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
extension type E(int i) {
  void f(int p) {}
}
''');
  }

  test_extensionType_method_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
extension type E(int i) {
  void f(var p) {}
}
''',
      [lint(49, 3)],
    );
  }

  test_functionExpression_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
var f = (int value) {};
''');
  }

  test_functionExpression_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
var f = (var value) {};
''',
      [lint(23, 3)],
    );
  }

  test_functionTyped_fieldFormal_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class C {
  final void Function(int) f;
  C(void this.f(int p));
}
''');
  }

  test_functionTyped_fieldFormal_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class C {
  final void Function(int) f;
  C(void this.f(var p));
}
''',
      [lint(70, 3)],
    );
  }

  test_functionTyped_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f(int p()) {}
''');
  }

  test_functionTyped_parameter_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f(void g(var p)) {}
''',
      [lint(28, 3)],
    );
  }

  test_functionTyped_superFormal_noVar() async {
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

  test_functionTyped_superFormal_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class A {
  A(void f(int p));
}
class B extends A {
  B(void super.f(var p));
}
''',
      [lint(83, 3)],
    );
  }

  test_functionTyped_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f(var p()) {}
''',
      [error(diag.functionTypedParameterVar, 21, 3)],
    );
  }

  test_functionTypedParameter_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f(void g(int p)) {}
''');
  }

  test_localFunction_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f() {
  void g(var p) {}
}
''',
      [lint(34, 3)],
    );
  }

  test_mixin_method_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
mixin M {
  void f(int p) {}
}
''');
  }

  test_mixin_method_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
mixin M {
  void f(var p) {}
}
''',
      [lint(33, 3)],
    );
  }

  test_operator_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class C {
  int operator +(int other) => 0;
}
''');
  }

  test_operator_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class C {
  int operator +(var other) => 0;
}
''',
      [lint(41, 3)],
    );
  }

  test_optionalNamed_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f({int? p}) {}
''');
  }

  test_optionalNamed_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f({var p}) {}
''',
      [lint(22, 3)],
    );
  }

  test_optionalPositional_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f([int? p]) {}
''');
  }

  test_optionalPositional_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f([var p]) {}
''',
      [lint(22, 3)],
    );
  }

  test_optionalPositionalWithDefault_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f([int p = 0]) {}
''');
  }

  test_optionalPositionalWithDefault_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f([var p = 0]) {}
''',
      [lint(22, 3)],
    );
  }

  test_requiredNamed_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f({required int p}) {}
''');
  }

  test_requiredNamed_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f({required var p}) {}
''',
      [lint(31, 3)],
    );
  }

  test_requiredPositional_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
void f(int p) {}
''');
  }

  test_requiredPositional_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f(var p) {}
''',
      [lint(21, 3)],
    );
  }

  test_requiredPositional_wildcard() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
void f(var _) {}
''',
      [lint(21, 3)],
    );
  }

  test_setter_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
set f(int value) {}
''');
  }

  test_setter_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
set f(var value) {}
''',
      [lint(20, 3)],
    );
  }

  test_super_noVar() async {
    await assertNoDiagnostics(r'''
// @dart=3.12
class A {
  String? a;
  A(this.a);
}
class B extends A {
  B(super.a);
}
''');
  }

  test_super_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class A {
  String? a;
  A(this.a);
}
class B extends A {
  B(var super.a);
}
''',
      [error(diag.extraneousModifier, 76, 3)],
    );
  }

  test_typedef_genericFunctionType_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
typedef F = void Function(var x);
''',
      [
        error(diag.functionTypedParameterVar, 40, 3),
        error(diag.varAndType, 40, 3),
        error(diag.undefinedClass, 44, 1),
      ],
    );
  }

  test_typedef_var() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
typedef String Type(var value);
''',
      [lint(34, 3)],
    );
  }

  test_var_type() async {
    await assertDiagnostics(
      r'''
// @dart=3.12
class C {
  C(var int p);
}
''',
      [error(diag.varAndType, 28, 3)],
    );
  }
}

@reflectiveTest
class VarWithNoTypeAnnotationTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.var_with_no_type_annotation;

  // With primary constructors, this lint is disabled.
  test_primaryConstructor() async {
    await assertNoDiagnostics(r'''
class C(var p);
''');
  }
}
