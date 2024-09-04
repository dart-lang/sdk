// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidDynamicCallsTest);
  });
}

@reflectiveTest
class AvoidDynamicCallsTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_dynamic_calls';

  test_binaryExpression() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a + 1;
}
''', [
      lint(22, 1),
    ]);
  }

  test_binaryExpression_asDynamic() async {
    await assertNoDiagnostics(r'''
void f(Object? a) {
  (a as dynamic) + 1;
}
''');
  }

  test_callInvocation_cascade_Function() async {
    await assertDiagnostics(r'''
void f(Function p) {
  p..call();
}
''', [
      lint(26, 4),
    ]);
  }

  test_callInvocation_cascade_functionType() async {
    await assertNoDiagnostics(r'''
void f(void Function() p) {
  p..call();
}
''');
  }

  test_callInvocation_Function() async {
    await assertDiagnostics(r'''
void f(Function p) {
  p.call();
}
''', [
      lint(25, 4),
    ]);
  }

  test_callInvocation_Function_tearoff() async {
    await assertNoDiagnostics(r'''
void f(Function p) {
  p.call;
}
''');
  }

  test_callInvocation_functionType() async {
    await assertNoDiagnostics(r'''
void f(void Function() p) {
  p.call();
}
''');
  }

  test_callInvocation_functionType_tearoff() async {
    await assertNoDiagnostics(r'''
void f(void Function() p) {
  p.call;
}
''');
  }

  test_callInvocation_nullAware_functionType() async {
    await assertNoDiagnostics(r'''
void f(void Function()? p) {
  p?.call();
}
''');
  }

  test_callInvocation_nullAware_functionType_tearoff() async {
    await assertNoDiagnostics(r'''
void f(void Function()? p) {
  p?.call;
}
''');
  }

  test_functionExpressionInvocation() async {
    await assertDiagnostics(r'''
void f(Function? g1, Function g2) {
  (g1 ?? g2)();
}
''', [
      lint(38, 10),
    ]);
  }

  test_functionExpressionInvocation_asFunction() async {
    await assertNoDiagnostics(r'''
void f(Object? g1, Object? g2) {
  ((g1 ?? g2) as Function)();
}
''');
  }

  test_functionInvocation() async {
    await assertDiagnostics(r'''
void f(Function g) {
  g();
}
''', [
      lint(23, 1),
    ]);
  }

  test_functionInvocation_asFunction() async {
    await assertNoDiagnostics(r'''
void f(Object? g) {
  (g as Function)();
}
''');
  }

  test_indexAssignmentExpression() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a[1] = 7;
}
''', [
      lint(22, 1),
    ]);
  }

  test_indexAssignmentExpression_asDynamic() async {
    await assertNoDiagnostics(r'''
void f(Object? a) {
  (a as dynamic)[1] = 7;
}
''');
  }

  test_indexExpression() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a[1];
}
''', [
      lint(22, 1),
    ]);
  }

  test_indexExpression_asDynamic() async {
    await assertNoDiagnostics(r'''
void f(Object? a) {
  (a as dynamic)[1];
}
''');
  }

  test_prefixedIdentifier() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a.foo;
}
''', [
      lint(22, 1),
    ]);
  }

  test_prefixedIdentifier_asDynamic() async {
    await assertNoDiagnostics(r'''
void f(Object? a) {
  (a as dynamic).foo;
}
''');
  }

  test_prefixedIdentifier_runtimeType() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  a.runtimeType;
}
''');
  }

  test_propertyAccess() async {
    await assertDiagnostics(r'''
void f(C c) {
  c.a.foo;
}
class C {
  dynamic a;
}
''', [
      lint(16, 3),
    ]);
  }

  test_propertyAccess_asDynamic() async {
    await assertNoDiagnostics(r'''
void f(C c) {
  (c.a as dynamic).foo;
}
class C {
  Object? a;
}
''');
  }

  test_propertyAccess_hashCode() async {
    await assertNoDiagnostics(r'''
void f(C c) {
  c.a.hashCode;
}
class C {
  dynamic a;
}
''');
  }

  test_propertyAccess_runtimeType() async {
    await assertNoDiagnostics(r'''
void f(C c) {
  c.a.runtimeType;
}
class C {
  dynamic a;
}
''');
  }

  test_propertyAccess_toString() async {
    await assertNoDiagnostics(r'''
void f(C c) {
  c.a.toString;
}
class C {
  dynamic a;
}
''');
  }
}
