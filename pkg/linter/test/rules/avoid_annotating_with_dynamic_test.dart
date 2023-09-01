// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAnnotatingWithDynamicTest);
  });
}

@reflectiveTest
class AvoidAnnotatingWithDynamicTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_annotating_with_dynamic';

  // TODO(srawlins): Test parameter of function-typed typedef (both old and
  // new style).
  // Test parameter of function-typed parameter (`f(void g(dynamic x))`).
  // Test parameter with a default value.

  test_fieldFormals() async {
    await assertDiagnostics(r'''
class A {
  var a;
  A(dynamic this.a);
}
''', [
      lint(23, 14),
    ]);
  }

  test_implicitDynamic() async {
    await assertNoDiagnostics(r'''
void f(p) {}
''');
  }

  test_optionalNamedParameter() async {
    await assertDiagnostics(r'''
void f({dynamic p}) {}
''', [
      lint(8, 9),
    ]);
  }

  test_optionalParameter() async {
    await assertDiagnostics(r'''
void f([dynamic p]) {}
''', [
      lint(8, 9),
    ]);
  }

  test_requiredParameter() async {
    await assertDiagnostics(r'''
void f(dynamic p) {}
''', [
      lint(7, 9),
    ]);
  }

  test_returnType() async {
    await assertNoDiagnostics(r'''
dynamic f() {
  return null;
}
''');
  }

  test_super() async {
    await assertDiagnostics(r'''
class A {
  var a;
  var b;
  A(this.a, this.b);
}
class B extends A {
  B(dynamic super.a, dynamic super.b);
}
''', [
      lint(75, 15),
      lint(92, 15),
    ]);
  }
}
