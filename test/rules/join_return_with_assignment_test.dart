// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/rules/join_return_with_assignment.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(JoinReturnWithAssignmentTest);
  });
}

@reflectiveTest
class JoinReturnWithAssignmentTest extends LintRuleTest {
  @override
  String get lintRule => JoinReturnWithAssignment.code.name;

  test_class_field_propertyAccess() async {
    await assertDiagnostics(r'''
class A {
  int f = 0;
}

int f(A a) {
  a.f = 0;
  return a.f;
}
''', [
      lint(41, 8),
    ]);
  }

  test_class_field_propertyAccess_nested() async {
    await assertDiagnostics(r'''
class A {
  int f = 0;
}

class B {
  A a = A();
}

int f(B b) {
  b.a.f = 0;
  return b.a.f;
}
''', [
      lint(67, 10),
    ]);
  }

  test_class_field_propertyAccess_nested_notSame() async {
    await assertNoDiagnostics(r'''
class A {
  int f = 0;
}

class B {
  A a = A();
}

int f(B b1, B b2) {
  b1.a.f = 0;
  return b2.a.f;
}
''');
  }

  test_class_field_propertyAccess_notSame() async {
    await assertNoDiagnostics(r'''
class A {
  int f = 0;
}

int f(A a1, A a2) {
  a1.f = 0;
  return a2.f;
}
''');
  }

  test_class_field_withoutPrefix() async {
    await assertDiagnostics(r'''
class A {
  int? _a;
  int? foo() {
    _a ??= 0;
    return _a;
  }
}
''', [
      lint(40, 9),
    ]);
  }

  test_class_field_withoutPrefix_ifThenElse() async {
    await assertDiagnostics(r'''
class A {
  int? _a;
  int? foo(bool b) {
    if (b) {
      _a = 0;
      return _a;
    } else {
      _a = 1;
      return _a;
    }
  }
}
''', [
      lint(61, 7),
      lint(105, 7),
    ]);
  }

  test_localVariable_assignment() async {
    await assertDiagnostics(r'''
int f(int a) {
  a = 0;
  return a;
}
''', [
      lint(17, 6),
    ]);
  }

  test_localVariable_assignment_compound() async {
    await assertDiagnostics(r'''
int f(int a) {
  a += 0;
  return a;
}
''', [
      lint(17, 7),
    ]);
  }

  @failingTest
  test_localVariable_assignment_multiple() async {
    await assertNoDiagnostics(r'''
int f1(int a, int b) {
  a = b = 0;
  return a;
}

int f2(int a, int b) {
  a = b = 0;
  return b;
}
''');
  }

  test_localVariable_declaration() async {
    await assertNoDiagnostics(r'''
int f(int a) {
  var a = 0;
  return a;
}
''');
  }

  test_localVariable_hasPreviousAssignment() async {
    await assertNoDiagnostics(r'''
int f(int a) {
  a += 1;
  a += 2;
  return a;
}
''');
  }

  test_localVariable_postfix() async {
    await assertDiagnostics(r'''
int f(int a) {
  a++;
  return a;
}
''', [
      lint(17, 4),
    ]);
  }

  test_localVariable_prefix() async {
    await assertDiagnostics(r'''
int f(int a) {
  ++a;
  return a;
}
''', [
      lint(17, 4),
    ]);
  }

  test_patternAssignment_multiple() async {
    await assertNoDiagnostics(r'''
int f(int a, int b) {
  (a, b) = (0, 1);
  return a;
}
''');
  }

  test_patternVariableDeclaration_multiple() async {
    await assertNoDiagnostics(r'''
int f() {
  var (a, b) = (0, 1);
  return a;
}
''');
  }
}
