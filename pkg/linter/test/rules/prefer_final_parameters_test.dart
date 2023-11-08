// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferFinalParametersTest);
    // TODO(srawlins): Add tests of abstract functions.
  });
}

@reflectiveTest
class PreferFinalParametersTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_final_parameters';

  test_blockBody_reassigned() async {
    await assertNoDiagnostics(r'''
void f(String p) {
  p = 'Lint away!';
}
''');
  }

  test_closure() async {
    await assertDiagnostics(r'''
var f = (Object p) {
  print(p);
};
''', [
      lint(9, 8),
    ]);
  }

  test_closure_final() async {
    await assertNoDiagnostics(r'''
void f(final List<int> x) {
  x.forEach((final int e) => print(e + 4));
}
''');
  }

  test_closure_final_untyped() async {
    await assertNoDiagnostics(r'''
void f(final List<int> x) {
  x.forEach((final e) => print(e + 4));
}
''');
  }

  test_closure_untyped() async {
    await assertDiagnostics(r'''
void f(final List<int> x) {
  x.forEach((e) => print(e + 4));
}
''', [
      lint(41, 1),
    ]);
  }

  test_constructor_usedInBody() async {
    await assertDiagnostics(r'''
class C {
  int x = 0;
  C(String p) {
    x = p.length;
  }
}
''', [
      lint(27, 8),
    ]);
  }

  test_constructor_usedInInitializer() async {
    await assertDiagnostics(r'''
class C {
  String x = '';
  C(String x): this.x = x;
}
''', [
      lint(31, 8),
    ]);
  }

  test_constructor_usedInInitializer_final() async {
    await assertNoDiagnostics(r'''
class C {
  int x = 0;
  C(final int x): x = x;
}
''');
  }

  test_expressionBody_reassigned() async {
    await assertNoDiagnostics(r'''
void f(int p) => p = 3;
''');
  }

  test_getter() async {
    await assertNoDiagnostics(r'''
class C {
  int _f = 0;
  int get f => _f;
}
''');
  }

  test_initializingFormal_named() async {
    await assertNoDiagnostics(r'''
class C {
  String f;
  C({required this.f});
}
''');
  }

  test_initializingFormal_positional() async {
    await assertNoDiagnostics(r'''
class C {
  String f;
  C(this.f);
}
''');
  }

  test_listPattern_destructured() async {
    await assertNoDiagnostics('''
void f(int p) {
  [_, p, _] = [1, 2, 3];
}
''');
  }

  test_method() async {
    await assertDiagnostics(r'''
class C {
  void m(String p) {
    print(p);
  }
}
''', [
      lint(19, 8),
    ]);
  }

  test_method_final() async {
    await assertNoDiagnostics(r'''
class C {
  void m(final String p) {
    print(p);
  }
}
''');
  }

  test_operator() async {
    await assertDiagnostics(r'''
class C {
  C operator +(C other) {
    return other;
  }
}
''', [
      lint(25, 7),
    ]);
  }

  test_operator_final() async {
    await assertNoDiagnostics(r'''
class C {
  C operator +(final C other) {
    return other;
  }
}
''');
  }

  test_recordPattern_destructured() async {
    await assertNoDiagnostics(r'''
void f(int a, int b) {
  (a, b) = (1, 2);
}
''');
  }

  test_setter() async {
    await assertDiagnostics(r'''
class C {
  int x = 0;
  void set f(int y) => x = y;
}
''', [
      lint(36, 5),
    ]);
  }

  test_setter_final() async {
    await assertNoDiagnostics(r'''
class C {
  int x = 0;
  void set f(final int y) => x = y;
}
''');
  }

  test_superParameter() async {
    await assertNoDiagnostics('''
class D {
  D(final int superParameter);
}

class E extends D {
  E(super.superParameter);
}
''');
  }

  test_superParameter_optional() async {
    await assertNoDiagnostics('''
class A {
  final String? a;
  A({this.a});
}

class B extends A {
  B({super.a});
}
''');
  }

  test_topLevelFunction() async {
    await assertDiagnostics(r'''
void f(int p) => print(p);
''', [
      lint(7, 5),
    ]);
  }

  test_topLevelFunction_final() async {
    await assertNoDiagnostics(r'''
void f(final int p) => print(p);
''');
  }

  test_topLevelFunction_final_multiple() async {
    await assertNoDiagnostics(r'''
void f(final String p, final String p2) {
  print(p);
  print(p2);
}
''');
  }

  test_topLevelFunction_named() async {
    await assertDiagnostics(r'''
void f({String? p}) {
  print(p);
}
''', [
      lint(8, 9),
    ]);
  }

  test_topLevelFunction_named_final() async {
    await assertNoDiagnostics(r'''
void f({final String? p}) {
  print(p);
}
''');
  }

  test_topLevelFunction_namedRequired() async {
    await assertDiagnostics(r'''
void f({required String p}) {
  print(p);
}
''', [
      lint(8, 17),
    ]);
  }

  test_topLevelFunction_namedRequired_final() async {
    await assertNoDiagnostics(r'''
void f({required final String p}) {
  print(p);
}
''');
  }

  test_topLevelFunction_optional() async {
    await assertDiagnostics(r'''
void f([String? p]) {
  print(p);
}
''', [
      lint(8, 9),
    ]);
  }

  test_topLevelFunction_optional_final() async {
    await assertNoDiagnostics(r'''
void f([final String? p]) {
  print(p);
}
''');
  }
}
