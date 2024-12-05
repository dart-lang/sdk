// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidTypesAsParameterNamesTest);
  });
}

@reflectiveTest
class AvoidTypesAsParameterNamesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_types_as_parameter_names;

  test_catchClauseParameter() async {
    await assertDiagnostics(r'''
class C {}

void f() {
  try {} catch (C) {}
}
''', [
      lint(39, 1),
    ]);
  }

  test_extensionType() async {
    await assertDiagnostics(r'''
extension type E(int i) { }

void f(E) { }
''', [
      lint(36, 1),
    ]);
  }

  test_factoryParameter_shadowingTypeParameter() async {
    await assertDiagnostics(r'''
class C<X> {
  factory C(X) => C.name();
  C.name();
}
''', [
      lint(25, 1),
    ]);
  }

  test_fieldFormalParameter_missingType() async {
    await assertNoDiagnostics(r'''
class C {
  final int num;
  C(this.num);
}
''');
  }

  test_functionTypedParameter_missingName() async {
    await assertDiagnostics(r'''
void f(void g(int)) {}
''', [
      lint(14, 3),
    ]);
  }

  test_functionTypedParameter_missingType_named() async {
    await assertDiagnostics(r'''
void f(void g({int})) {}
''', [
      lint(15, 3),
    ]);
  }

  test_functionTypedParameter_missingType_optionalPositional() async {
    await assertDiagnostics(r'''
void f(void g([int])) {}
''', [
      lint(15, 3),
    ]);
  }

  test_functionTypedParameter_noShadowing() async {
    await assertNoDiagnostics(r'''
void f(void g(int a)) {}
''');
  }

  test_functionTypeParameter_missingName() async {
    await assertNoDiagnostics(r'''
void f(int Function(int) g) {}
''');
  }

  test_functionTypeParameter_withParameter_noShadowing() async {
    await assertNoDiagnostics(r'''
class C<X> {
  void m(void Function(X) g) {}
}
''');
  }

  test_functionTypeParameter_withParameter_shadowingTypeParameter() async {
    await assertNoDiagnostics(r'''
void f(int Function<T>(T) g) {}
''');
  }

  test_parameter_shadowingTypeParameter() async {
    await assertDiagnostics(r'''
void f<X>(X) {}
''', [
      lint(10, 1),
    ]);
  }

  test_parameterIsFunctionName() async {
    await assertNoDiagnostics(r'''
void f(g) {}
void g() {}
''');
  }

  test_parameterIsTypedefName() async {
    await assertDiagnostics(r'''
void f(T) {}
typedef T = int;
''', [
      lint(7, 1),
    ]);
  }

  test_super() async {
    await assertDiagnostics(r'''
class A {
  String a;
  A(this.a);
}
class B extends A {
  B(super.String);
}
''', [
      lint(67, 6),
    ]);
  }

  test_typedefParameter_legacy_missingType() async {
    await assertDiagnostics(r'''
typedef void T(int);
''', [
      lint(15, 3),
    ]);
  }

  test_typedefParameter_legacy_missingType_named() async {
    await assertDiagnostics(r'''
typedef void T({int});
''', [
      lint(16, 3),
    ]);
  }

  test_typedefParameter_legacy_missingType_optionalPositional() async {
    await assertDiagnostics(r'''
typedef void f([int]);
''', [
      lint(16, 3),
    ]);
  }

  test_typedefParameter_legacy_noShadowing() async {
    await assertNoDiagnostics(r'''
typedef void T(int a);
''');
  }

  test_typedefParameter_legacy_undefinedName() async {
    await assertNoDiagnostics(r'''
typedef void f(Undefined);
''');
  }

  test_typedefParameter_missingName() async {
    await assertNoDiagnostics(r'''
typedef T = int Function(int);
''');
  }

  test_typeParameter_wildcard() async {
    await assertDiagnostics(r'''
class C<_> {
  var _;
  C.c(this._, _);
}
''', [
      error(WarningCode.UNUSED_FIELD, 19, 1),
    ]);
  }
}
