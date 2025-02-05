// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryOverridesTest);
  });
}

@reflectiveTest
class UnnecessaryOverridesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.unnecessary_overrides;

  test_binaryOperator_expressionFunctionBody() async {
    await assertDiagnostics(r'''
class A {
  int operator +(int other) => 0;
}
class C extends A {
  @override
  int operator +(int other) => super + other;
}
''', [
      lint(93, 1),
    ]);
  }

  test_class_augmentation_method_withoutOverride_noSuper() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  void foo() {}
}
''');

    await assertNoDiagnosticsInFile(a.path);
    await assertNoDiagnosticsInFile(b.path);
  }

  test_enum_field() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  @override
  Type get runtimeType => super.runtimeType;
}
''', [
      lint(41, 11),
    ]);
  }

  test_enum_method() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  @override
  String toString() => super.toString();
}
''', [
      lint(39, 8),
    ]);
  }

  test_getter_expressionFunctionBody_otherTarget() async {
    await assertNoDiagnostics(r'''
class A {
  int get x => 7;
}
class C extends A {
  final a = A();
  @override
  int get x => a.x;
}
''');
  }

  test_getter_expressionFunctionBody_superCall() async {
    await assertDiagnostics(r'''
class A {
  int get x => 0;
}
class C extends A {
  @override
  int get x => super.x;
}
''', [
      lint(72, 1),
    ]);
  }

  test_getter_returnTypeChanged() async {
    await assertNoDiagnostics(r'''
class A {
  num get g => 0;
}
class C extends A {
  @override
  int get g => super.g as int;
}
''');
  }

  test_method_blockBody() async {
    await assertDiagnostics(r'''
class A {
  void m() {}
}
class C extends A {
  @override
  void m() {
    super.m();
  }
}
''', [
      lint(65, 1),
    ]);
  }

  test_method_blockBody_noSuper() async {
    await assertNoDiagnostics(r'''
class A {
  void m() {}
}
class C extends A {
  @override
  void m() {
    m();
  }
}
''');
  }

  test_method_blockBody_otherStatements() async {
    await assertNoDiagnostics(r'''
class A {
  int m(int a) => 0;
}
class C extends A {
  @override
  int m(int a) {
    print("something");
    return super.m(a);
  }
}
''');
  }

  test_method_differentDocumentation() async {
    await assertNoDiagnostics(r'''
class C {
  num get g => 7;
}
class E extends C {
  /// Text.
  @override
  num get g => super.g;
}
''');
  }

  test_method_expressionFunctionBody_everythingTheSame() async {
    await assertDiagnostics(r'''
class A {
  int m(int a, int b) => 0;
}
class C extends A {
  @override
  int m(int a, int b) => super.m(a, b);
}
''', [
      lint(78, 1),
    ]);
  }

  test_method_expressionFunctionBody_mismatchedAguments() async {
    await assertNoDiagnostics(r'''
class A {
  int m(int a, int b) => 0;
}
class C extends A {
  @override
  int m(int a, int b) => super.m(b, a);
}
''');
  }

  test_method_expressionFunctionBody_namedParameters() async {
    await assertDiagnostics(r'''
class A {
  int m({int a = 0, int b = 0}) => 0;
}
class C extends A {
  @override
  int m({int a = 0, int b = 0}) => super.m(a: a, b: b);
}
''', [
      lint(88, 1),
    ]);
  }

  test_method_expressionFunctionBody_namedParameters_mismatchedArguments() async {
    await assertNoDiagnostics(r'''
class A {
  int m({int a = 0, int b = 0}) => 0;
}
class C extends A {
  @override
  int m({int a = 0, int b = 0}) => super.m(b: a, a: b);
}
''');
  }

  test_method_expressionFunctionBody_namedParameters_outOfOrder() async {
    await assertDiagnostics(r'''
class A {
  int m({int a = 0, int b = 0}) => 0;
}
class C extends A {
  @override
  int m({int a = 0, int b = 0}) => super.m(b: b, a: a);
}
''', [
      lint(88, 1),
    ]);
  }

  test_method_hasOtherAnnotations() async {
    await assertNoDiagnostics(r'''
class A {
  int m() => 7;
}
class C extends A {
  @override
  @MyAnnotation()
  int m() => super.m();
}
class MyAnnotation {
  const MyAnnotation();
}
''');
  }

  test_method_ok_commentsInBody() async {
    await assertNoDiagnostics(r'''
class A {
  void a() { }
}

class B extends A {
  @override
  void a() {
    // There's something we want to document here.
    super.a();
  }
}
''');
  }

  test_method_ok_expressionStatement_commentsInBody() async {
    await assertNoDiagnostics(r'''
class A {
  void a() { }
}

class B extends A {
  @override
  void a() =>
    // There's something we want to document here.
    super.a();
}
''');
  }

  test_method_ok_returnExpression_commentsInBody() async {
    await assertNoDiagnostics(r'''
class A {
  @override
  String toString() {
    // There's something we want to document here.
    return super.toString();
  }
}
''');
  }

  test_method_parameterAdditional_named() async {
    await assertNoDiagnostics(r'''
class A {
  num m(int v) => 7;
}
class C extends A {
  @override
  num m(int v, {int v2 = 1}) => super.m(v);
}
''');
  }

  test_method_parameterAdditional_positional() async {
    await assertNoDiagnostics(r'''
class A {
  num m(int v) => 7;
}
class C extends A {
  @override
  num m(int v, [int v2 = 1]) => super.m(v);
}
''');
  }

  test_method_parameterCovariance() async {
    await assertNoDiagnostics(r'''
class A {
  num m(num v) => 7;
}
class C extends A {
  @override
  num m(covariant int v) => super.m(v);
}
''');
  }

  test_method_parameterDefaultChanged() async {
    await assertNoDiagnostics(r'''
class A {
  num m({int v = 0}) => 7;
}
class C extends A {
  @override
  num m({int v = 10}) => super.m(v: v);
}
''');
  }

  test_method_parameterRenamed() async {
    await assertNoDiagnostics(r'''
class A {
  num m(int v) => 7;
}
class C extends A {
  @override
  num m(int v2) => super.m(v2);
}
''');
  }

  test_method_parameterTypeChanged() async {
    await assertNoDiagnostics(r'''
class A {
  num m(int v) => 0;
}
class C extends A {
  @override
  num m(num v) => super.m(v as int);
}
''');
  }

  test_method_parameterTypeChanged_named() async {
    await assertNoDiagnostics(r'''
class A {
  num m({int v = 20}) => 0;
}
class C extends A {
  @override
  num m({num v = 20}) => super.m(v: v as int);
}
''');
  }

  test_method_parameterTypeChanged_optionalPositional() async {
    await assertNoDiagnostics(r'''
class A {
  num m([int v = 20]) => 0;
}
class C extends A {
  @override
  num m([num v = 20]) => super.m(v as int);
}
''');
  }

  test_method_protectedBecomesPublic() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  num m(int v) => 7;
}
class C extends A {
  @override
  num m(int v) => super.m(v);
}
''');
  }

  test_method_returnTypeChanged() async {
    await assertNoDiagnostics(r'''
class A {
  num m(int v) => 0;
}
class C extends A {
  @override
  int m(int v) => super.m(v) as int;
}
''');
  }

  test_noSuchMethod() async {
    await assertNoDiagnostics(r'''
class A {}
class C implements A {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  test_operator_parameterRenamed() async {
    await assertNoDiagnostics(r'''
class A {
  num operator +(int other) => 7;
}
class C extends A {
  @override
  num operator +(int other2) => super + other2;
}
''');
  }

  test_operator_returnTypeChanged() async {
    await assertNoDiagnostics(r'''
class A {
  num operator +(int other) => 0;
}
class C extends A {
  @override
  int operator +(int other) => super + other as int;
}
''');
  }

  test_setter_blockBody_superCall() async {
    await assertDiagnostics(r'''
class A {
  set x(other) {}
}
class C extends A {
  @override
  set x(other) {
    super.x = other;
  }
}
''', [
      lint(68, 1),
    ]);
  }

  test_setter_expressionFunctionBody_otherTarget() async {
    await assertNoDiagnostics(r'''
class A {
  set x(int value) {}
}
class C extends A {
  final a = A();
  @override
  set x(int value) => a.x = value;
}
''');
  }

  test_setter_parameterRenamed() async {
    await assertNoDiagnostics(r'''
class A {
  set s(num v) {}
}
class C extends A {
  @override
  set s(num v2) => super.s = v2 as int;
}
''');
  }

  test_setter_parameterTypeChanged() async {
    await assertNoDiagnostics(r'''
class A {
  set s(int v) {}
}
class C extends A {
  @override
  set s(num v) => super.s = v as int;
}
''');
  }

  test_unaryOperator_expressionFunctionBody() async {
    await assertDiagnostics(r'''
class A {
  A operator ~() => A();
}
class C extends A {
  @override
  A operator ~() => ~super;
}
''', [
      lint(82, 1),
    ]);
  }
}
