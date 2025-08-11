// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrictTopLevelInferenceTest);
  });
}

@reflectiveTest
class StrictTopLevelInferenceTest extends LintRuleTest {
  @override
  bool get addTestReflectiveLoaderPackageDep => true;

  @override
  String get lintRule => LintNames.strict_top_level_inference;

  test_constructorParameter_named() async {
    await assertDiagnostics(
      r'''
class C {
  C({p1}) {}
}
''',
      [lint(15, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_constructorParameter_named_final() async {
    await assertDiagnostics(
      r'''
class C {
  C({final p1});
}
''',
      [lint(21, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_constructorParameter_named_initializingFormal() async {
    await assertNoDiagnostics(r'''
class C {
  int? p1;
  C({this.p1});
}
''');
  }

  test_constructorParameter_named_superParameter() async {
    await assertNoDiagnostics(r'''
class S {
  S({int? p1});
}
class C extends S {
  C({super.p1});
}
''');
  }

  test_constructorParameter_named_typed() async {
    await assertNoDiagnostics(r'''
class C {
  C({int? p1});
}
''');
  }

  test_constructorParameter_named_var() async {
    await assertDiagnostics(
      r'''
class C {
  C({var p1});
}
''',
      [
        lint(
          19,
          2,
          correctionContains: "Try replacing 'var' with a type annotation",
        ),
      ],
    );
  }

  test_constructorParameter_positional() async {
    await assertDiagnostics(
      r'''
class C {
  C(p1);
}
''',
      [lint(14, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_constructorParameter_positional_final() async {
    await assertDiagnostics(
      r'''
class C {
  C(final p1);
}
''',
      [lint(20, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_constructorParameter_positional_initializingFormal() async {
    await assertNoDiagnostics(r'''
class C {
  int p1;
  C(this.p1);
}
''');
  }

  test_constructorParameter_positional_superParameter() async {
    await assertNoDiagnostics(r'''
class S {
  S(int p1);
}
class C extends S {
  C(super.p1);
}
''');
  }

  test_constructorParameter_positional_typed() async {
    await assertNoDiagnostics(r'''
class C {
  C(int p1);
}
''');
  }

  test_constructorParameter_positional_var() async {
    await assertDiagnostics(
      r'''
class C {
  C(var p1);
}
''',
      [
        lint(
          18,
          2,
          correctionContains: "Try replacing 'var' with a type annotation",
        ),
      ],
    );
  }

  test_instanceField_final() async {
    await assertNoDiagnostics(r'''
class C {
  final f = 0;
}
''');
  }

  test_instanceField_final_noInitializer() async {
    await assertDiagnostics(
      r'''
class C {
  final f;
  C(this.f);
}
''',
      [lint(18, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceField_final_override_noInitializer() async {
    await assertNoDiagnostics(r'''
abstract class C {
  int? get f;
}
class D implements C {
  final f;
  D(this.f);
}
''');
  }

  test_instanceField_multiple() async {
    await assertNoDiagnostics(r'''
class C {
  var x = '', y = '';
}
''');
  }

  test_instanceField_multiple_someMissingInitializer() async {
    await assertDiagnostics(
      r'''
class C {
  var x = '', y = '', z;
}
''',
      [lint(32, 1, correctionContains: 'Try splitting the declaration')],
    );
  }

  test_instanceField_multiple_someMissingInitializer_butOverride() async {
    await assertNoDiagnostics(r'''
class C {
  int? x = 1;
}
class D implements C {
  var x, y = '';
}
''');
  }

  test_instanceField_typed() async {
    await assertNoDiagnostics(r'''
class C {
  int? x;
}
''');
  }

  test_instanceField_var() async {
    await assertNoDiagnostics(r'''
class C {
  var f = 0;
}
''');
  }

  test_instanceField_var_noInitializer() async {
    await assertDiagnostics(
      r'''
class C {
  var x;
}
''',
      [
        lint(
          16,
          1,
          correctionContains: "Try replacing 'var' with a type annotation",
        ),
      ],
    );
  }

  test_instanceField_var_noInitializer_override() async {
    await assertNoDiagnostics(r'''
abstract class C {
  abstract int? f;
}
class D implements C {
  var f;
}
''');
  }

  test_instanceGetter() async {
    await assertDiagnostics(
      r'''
class C {
  get g => 1;
}
''',
      [lint(16, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceGetter_inExtension() async {
    await assertDiagnostics(
      r'''
extension E on int {
  get g => 1;
}
''',
      [lint(27, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_parameter_named() async {
    await assertDiagnostics(
      r'''
class C {
  void m({p1}) {}
}
''',
      [lint(20, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_parameter_named_final() async {
    await assertDiagnostics(
      r'''
class C {
  void m({final p1}) {}
}
''',
      [lint(26, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_parameter_named_hasDefault() async {
    await assertDiagnostics(
      r'''
class C {
  void m({var p1 = false}) {}
}
''',
      [
        lint(
          24,
          2,
          correctionContains: "Try replacing 'var' with a type annotation",
        ),
      ],
    );
  }

  test_instanceMethod_parameter_named_hasDefault_typed() async {
    await assertNoDiagnostics(r'''
class C {
  void m({bool p1 = false}) {}
}
''');
  }

  test_instanceMethod_parameter_named_typed() async {
    await assertNoDiagnostics(r'''
class C {
  void m({int? p1}) {}
}
''');
  }

  test_instanceMethod_parameter_named_var() async {
    await assertDiagnostics(
      r'''
class C {
  void m({var p1}) {}
}
''',
      [
        lint(
          24,
          2,
          correctionContains: "Try replacing 'var' with a type annotation",
        ),
      ],
    );
  }

  test_instanceMethod_parameter_override_additionalNamed() async {
    await assertDiagnostics(
      r'''
class C {
  void m(int p1) {}
}
class D implements C {
  void m(p1, {p2}) {}
}
''',
      [lint(69, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_parameter_override_additionalNamed_typed() async {
    await assertNoDiagnostics(r'''
class C {
  void m(int p1) {}
}
class D implements C {
  void m(p1, {int? p2}) {}
}
''');
  }

  test_instanceMethod_parameter_override_additionalPositional() async {
    await assertDiagnostics(
      r'''
class C {
  void m(int p1) {}
}
class D implements C {
  void m(p1, [p2]) {}
}
''',
      [lint(69, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_parameter_override_additionalPositional_typed() async {
    await assertNoDiagnostics(r'''
class C {
  void m(int p1) {}
}
class D implements C {
  void m(p1, [int? p2]) {}
}
''');
  }

  test_instanceMethod_parameter_override_partOfSuperSignature() async {
    await assertNoDiagnostics(r'''
class C {
  void m(int p1) {}
}
class D implements C {
  void m(p1) {}
}
''');
  }

  test_instanceMethod_parameter_override_partOfSuperSignature_named() async {
    await assertNoDiagnostics(r'''
class C {
  void m({int? p1}) {}
}
class D implements C {
  void m({p1}) {}
}
''');
  }

  test_instanceMethod_parameter_positional() async {
    await assertDiagnostics(
      r'''
class C {
  void m(p1) {}
}
''',
      [lint(19, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_parameter_positional_final() async {
    await assertDiagnostics(
      r'''
class C {
  void m(final p1) {}
}
''',
      [lint(25, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_parameter_positional_hasDefault() async {
    await assertDiagnostics(
      r'''
class C {
  void m([var p1 = false]) {}
}
''',
      [
        lint(
          24,
          2,
          correctionContains: "Try replacing 'var' with a type annotation",
        ),
      ],
    );
  }

  test_instanceMethod_parameter_positional_hasDefault_typed() async {
    await assertNoDiagnostics(r'''
class C {
  void m([bool p1 = false]) {}
}
''');
  }

  test_instanceMethod_parameter_positional_onExtension() async {
    await assertDiagnostics(
      r'''
extension E on int {
  void m(p1) {}
}
''',
      [lint(30, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_parameter_positional_onExtensionType() async {
    await assertDiagnostics(
      r'''
extension type ET(int it) {
  void m(p1) {}
}
''',
      [lint(37, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_parameter_positional_typed() async {
    await assertNoDiagnostics(r'''
class C {
  void m(int p1) {}
}
''');
  }

  test_instanceMethod_parameter_positional_var() async {
    await assertDiagnostics(
      r'''
class C {
  void m(var p1) {}
}
''',
      [
        lint(
          23,
          2,
          correctionContains: "Try replacing 'var' with a type annotation",
        ),
      ],
    );
  }

  test_instanceMethod_returnType() async {
    await assertDiagnostics(
      r'''
class C {
  m() {}
}
''',
      [lint(12, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_returnType_onExtension() async {
    await assertDiagnostics(
      r'''
extension E on int {
  m() {}
}
''',
      [lint(23, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_returnType_onExtensionType() async {
    await assertDiagnostics(
      r'''
extension type ET(int it) {
  m() {}
}
''',
      [lint(30, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceMethod_returnType_override() async {
    await assertNoDiagnostics(r'''
abstract class I {
  int m();
}
abstract class J {
  num m();
}
abstract class C implements I, J {
  m();
}
''');
  }

  test_instanceMethod_returnType_override_inconsistentCombinedSuperSignature() async {
    await assertDiagnostics(
      r'''
abstract class I {
  int m();
}
abstract class J {
  double m();
}
abstract class C implements I, J {
  m();
}
''',
      [
        // In the presense of this error, we do not report.
        error(CompileTimeErrorCode.NO_COMBINED_SUPER_SIGNATURE, 104, 1),
      ],
    );
  }

  test_instanceMethod_returnType_typed() async {
    await assertNoDiagnostics(r'''
class C {
  void m() {}
}
''');
  }

  test_instanceOperator_parameter() async {
    await assertDiagnostics(
      r'''
class C {
  void operator +(p1) {}
}
''',
      [lint(28, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceOperator_parameter_typed() async {
    await assertNoDiagnostics(r'''
class C {
  void operator +(int p1) {}
}
''');
  }

  test_instanceOperator_returnType() async {
    await assertDiagnostics(
      r'''
class C {
  operator +(int p1) {}
}
''',
      [lint(21, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceOperator_returnType_typed() async {
    await assertNoDiagnostics(r'''
class C {
  void operator +(int p1) {}
}
''');
  }

  test_instanceSetter_parameterType() async {
    await assertDiagnostics(
      r'''
class C {
  set s(value) {}
}
''',
      [lint(16, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceSetter_parameterType_inExtension() async {
    await assertDiagnostics(
      r'''
extension E on int {
  set s(value) {}
}
''',
      [lint(27, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_instanceSetter_returnType() async {
    await assertNoDiagnostics(r'''
class C {
  set s(int value) {}
}
''');
  }

  test_localFunction() async {
    await assertNoDiagnostics(r'''
void f() {
  m(p1) {}
}
''');
  }

  test_localVariable() async {
    await assertNoDiagnostics(r'''
void f() {
  var x;
}
''');
  }

  test_reflectiveTest_nonTest() async {
    await assertDiagnostics(
      r'''
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class ReflectiveTest {
  foo() {}
}
''',
      [lint(111, 3)],
    );
  }

  test_reflectiveTest_soloTest() async {
    await assertNoDiagnostics(r'''
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class ReflectiveTest {
  solo_test_foo() {}
}
''');
  }

  test_reflectiveTest_test() async {
    await assertNoDiagnostics(r'''
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class ReflectiveTest {
  test_foo() {}
}
''');
  }

  test_staticField_final() async {
    await assertNoDiagnostics(r'''
class C {
  static final f = 0;
}
''');
  }

  test_staticField_multiple() async {
    await assertNoDiagnostics(r'''
class C {
  static var x = '', y = '';
}
''');
  }

  test_staticField_multiple_someMissingInitializer() async {
    await assertDiagnostics(
      r'''
class C {
  static var x = '', y = '', z;
}
''',
      [lint(39, 1, correctionContains: 'Try splitting the declaration')],
    );
  }

  test_staticField_typed() async {
    await assertNoDiagnostics(r'''
class C {
  static int? f;
}
''');
  }

  test_staticField_var() async {
    await assertNoDiagnostics(r'''
class C {
  static var f = 7;
}
''');
  }

  test_staticField_var_noInitializer() async {
    await assertDiagnostics(
      r'''
class C {
  static var f;
}
''',
      [
        lint(
          23,
          1,
          correctionContains: "Try replacing 'var' with a type annotation",
        ),
      ],
    );
  }

  test_staticMethod_parameter_named() async {
    await assertDiagnostics(
      r'''
class C {
  static void m({p1}) {}
}
''',
      [lint(27, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_staticMethod_parameter_named_final() async {
    await assertDiagnostics(
      r'''
class C {
  static void m({final p1}) {}
}
''',
      [lint(33, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_staticMethod_parameter_named_typed() async {
    await assertNoDiagnostics(r'''
class C {
  static void m({int? p1}) {}
}
''');
  }

  test_staticMethod_parameter_named_var() async {
    await assertDiagnostics(
      r'''
class C {
  static void m({var p1}) {}
}
''',
      [
        lint(
          31,
          2,
          correctionContains: "Try replacing 'var' with a type annotation.",
        ),
      ],
    );
  }

  test_staticMethod_parameter_positional() async {
    await assertDiagnostics(
      r'''
class C {
  static void m(p1) {}
}
''',
      [lint(26, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_staticMethod_parameter_positional_final() async {
    await assertDiagnostics(
      r'''
class C {
  static void m(final p1) {}
}
''',
      [lint(32, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_staticMethod_parameter_positional_typed() async {
    await assertNoDiagnostics(r'''
class C {
  static void m(int p1) {}
}
''');
  }

  test_staticMethod_parameter_positional_var() async {
    await assertDiagnostics(
      r'''
class C {
  static void m(var p1) {}
}
''',
      [
        lint(
          30,
          2,
          correctionContains: "Try replacing 'var' with a type annotation",
        ),
      ],
    );
  }

  test_staticMethod_returnType() async {
    await assertDiagnostics(
      r'''
class C {
  static m() {}
}
''',
      [lint(19, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_staticMethod_returnType_typed() async {
    await assertNoDiagnostics(r'''
class C {
  static void m() {}
}
''');
  }

  test_topLevelFunction_parameter_named() async {
    await assertDiagnostics(
      r'''
void m({p1}) {}
''',
      [lint(8, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_topLevelFunction_parameter_named_final() async {
    await assertDiagnostics(
      r'''
void m({final p1}) {}
''',
      [lint(14, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_topLevelFunction_parameter_named_typed() async {
    await assertNoDiagnostics(r'''
void m({int? p1}) {}
''');
  }

  test_topLevelFunction_parameter_named_var() async {
    await assertDiagnostics(
      r'''
void m({var p1}) {}
''',
      [
        lint(
          12,
          2,
          correctionContains: "Try replacing 'var' with a type annotation.",
        ),
      ],
    );
  }

  test_topLevelFunction_parameter_positional() async {
    await assertDiagnostics(
      r'''
void m(p1) {}
''',
      [lint(7, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_topLevelFunction_parameter_positional_final() async {
    await assertDiagnostics(
      r'''
void m(final p1) {}
''',
      [lint(13, 2, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_topLevelFunction_parameter_positional_typed() async {
    await assertNoDiagnostics(r'''
void m(int p1) {}
''');
  }

  test_topLevelFunction_parameter_positional_var() async {
    await assertDiagnostics(
      r'''
void m(var p1) {}
''',
      [lint(11, 2)],
    );
  }

  test_topLevelFunction_returnType() async {
    await assertDiagnostics(
      r'''
m() {}
''',
      [lint(0, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_topLevelFunction_returnType_typed() async {
    await assertNoDiagnostics(r'''
void m() {}
''');
  }

  test_topLevelGetter() async {
    await assertDiagnostics(
      r'''
get g => 1;
''',
      [lint(4, 1, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_topLevelSetter_parameterType() async {
    await assertDiagnostics(
      r'''
set s(value) {}
''',
      [lint(6, 5, correctionContains: 'Try adding a type annotation')],
    );
  }

  test_topLevelVariable_final() async {
    await assertNoDiagnostics(r'''
final f = 0;
''');
  }

  test_topLevelVariable_final_multiple() async {
    await assertNoDiagnostics(r'''
final x = 1, y = '', z = 1.2;
''');
  }

  test_topLevelVariable_multiple() async {
    await assertNoDiagnostics(r'''
var x = '', y = '';
''');
  }

  test_topLevelVariable_multiple_someMissingInitializer() async {
    await assertDiagnostics(
      r'''
var x = '', y = '', z;
''',
      [lint(20, 1, correctionContains: 'Try splitting the declaration')],
    );
  }

  test_topLevelVariable_typed() async {
    await assertNoDiagnostics(r'''
final int x = 3;
''');
  }

  test_topLevelVariable_var() async {
    await assertNoDiagnostics(r'''
var f = 0;
''');
  }

  test_topLevelVariable_var_noInitializer() async {
    await assertDiagnostics(
      r'''
var f;
''',
      [
        lint(
          4,
          1,
          correctionContains: "Try replacing 'var' with a type annotation",
        ),
      ],
    );
  }

  test_wildcardVariable_constructorParameter() async {
    await assertNoDiagnostics(r'''
class C {
  C(_) {}
}
''');
  }

  test_wildcardVariable_constructorParameter_preWildcards() async {
    await assertDiagnostics(
      r'''
// @dart = 3.4
// (pre wildcard-variables)
class C {
  C(_) {}
}
''',
      [lint(57, 1)],
    );
  }

  test_wildcardVariable_function() async {
    await assertNoDiagnostics(r'''
void m(_) {}
''');
  }

  test_wildcardVariable_function_preWildcards() async {
    await assertDiagnostics(
      r'''
// @dart = 3.4
// (pre wildcard-variables)
void m(_) {}
''',
      [lint(50, 1)],
    );
  }

  test_wildcardVariable_method() async {
    await assertNoDiagnostics(r'''
class C {
  void m(_) {}
}
''');
  }

  test_wildcardVariable_method_preWilcards() async {
    await assertDiagnostics(
      r'''
// @dart = 3.4
// (pre wildcard-variables)
class C {
  void m(_) {}
}
''',
      [lint(62, 1)],
    );
  }
}
