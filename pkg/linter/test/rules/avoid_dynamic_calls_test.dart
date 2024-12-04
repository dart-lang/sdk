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
  String get lintRule => LintNames.avoid_dynamic_calls;

  test_asDynamic_dynamicBinaryExpression() async {
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

  test_dynamicBinaryExpression_ampersandAmpersand() async {
    // OK because there is an implicit downcast here, rather than a dynamic
    // call.
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  a && false;
}
''');
  }

  test_dynamicBinaryExpression_caret() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a ^ 1;
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicBinaryExpression_lessThan() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a < 1;
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicBinaryExpression_lessThanLessThan() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a << 1;
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicBinaryExpression_plus() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a + 1;
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicBinaryExpression_questionQuestion() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  a ?? 1;
}
''');
  }

  test_dynamicBinaryExpression_tildeSlash() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a ~/ 1;
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicCascadedMethodCall() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a..b();
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicCascadedMethodCall_subsequent() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a
    ..toString()
    ..b();
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicCascadedPropertyAccess() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a..b;
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicCascadedPropertyAccess_subsequent() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a
    ..toString()
    ..b;
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicCompoundAssignment_ampersandEqualsOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a &= 1;
}
''', [
      lint(22, 6),
    ]);
  }

  test_dynamicCompoundAssignment_caretEqualsOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a ^= 1; // LINT
}
''', [
      lint(22, 6),
    ]);
  }

  test_dynamicCompoundAssignment_minusEqualsOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a -= 1;
}
''', [
      lint(22, 6),
    ]);
  }

  test_dynamicCompoundAssignment_pipeEqualsOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a |= 1;
}
''', [
      lint(22, 6),
    ]);
  }

  test_dynamicCompoundAssignment_plusEqualsOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a += 1;
}
''', [
      lint(22, 6),
    ]);
  }

  test_dynamicCompoundAssignment_questionQuestionEqualsOperator() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  a ??= 1;
}
''');
  }

  test_dynamicCompoundAssignment_slashEqualsOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a /= 1; // LINT
}
''', [
      lint(22, 6),
    ]);
  }

  test_dynamicCompoundAssignment_starEqualsOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a *= 1;
}
''', [
      lint(22, 6),
    ]);
  }

  test_dynamicDecrementPostfixOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a--;
}
''', [
      lint(22, 3),
    ]);
  }

  test_dynamicDecrementPrefixOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  --a;
}
''', [
      lint(22, 3),
    ]);
  }

  test_dynamicEqualOperator() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  a == 7;
}
''');
  }

  test_dynamicImplicitCall() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a();
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicIncrementPostfixOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a++;
}
''', [
      lint(22, 3),
    ]);
  }

  test_dynamicIncrementPrefixOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  ++a;
}
''', [
      lint(22, 3),
    ]);
  }

  test_dynamicIndexAssignmetOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a[1] = 1;
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicIndexOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a[1];
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicNotEqualOperator() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  a != 7;
}
''');
  }

  test_dynamicNullAssertMethodCall() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a!.b();
}
''', [
      lint(22, 2),
    ]);
  }

  test_dynamicNullAssertPropertyAccess() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a!.b;
}
''', [
      lint(22, 2),
    ]);
  }

  test_dynamicNullAwareMethodCall() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a?.b();
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicNullAwarePropertyAccess() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a?.b;
}
''', [
      lint(22, 1),
    ]);
  }

  test_dynamicUnaryMinusOperator() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  -a;
}
''', [
      lint(23, 1),
    ]);
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

  test_functionInvocation_parenthesized() async {
    await assertDiagnostics(r'''
void f(Function a) {
  (a)();
}
''', [
      lint(23, 3),
    ]);
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

  test_parenthesizedExpression() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  (a).b;
}
''', [
      lint(22, 3),
    ]);
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

  test_prefixedIdentifier_dynamicMethodCall() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a.foo();
}
''', [
      lint(22, 1),
    ]);
  }

  test_prefixedIdentifier_dynamicMethodCall_asDynamic() async {
    await assertNoDiagnostics(r'''
void f(Object? a) {
  (a as dynamic).foo();
}
''');
  }

  test_prefixedIdentifier_noSuchMethod() async {
    await assertNoDiagnostics(r'''
void f(dynamic a, Invocation i) {
  a.noSuchMethod(i);
}
''');
  }

  test_prefixedIdentifier_noSuchMethod_withAdditionalPositionalArgument() async {
    await assertDiagnostics(r'''
void f(dynamic a, Invocation i) {
  a.noSuchMethod(i, 7);
}
''', [
      lint(36, 1),
    ]);
  }

  test_prefixedIdentifier_noSuchMethod_withNamedArgument() async {
    await assertDiagnostics(r'''
void f(dynamic a, Invocation i) {
  a.noSuchMethod(i, p: 7);
}
''', [
      lint(36, 1),
    ]);
  }

  test_prefixedIdentifier_noSuchMethod_withNamedArgumentBeforePositional() async {
    await assertDiagnostics(r'''
void f(dynamic a, Invocation i) {
  a.noSuchMethod(i, p: 7);
}
''', [
      lint(36, 1),
    ]);
  }

  test_prefixedIdentifier_runtimeType() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  a.runtimeType;
}
''');
  }

  test_prefixedIdentifier_toString() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  a.toString();
}
''');
  }

  test_prefixedIdentifier_toString_withNamedArgument() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a.toString(p: 7);
}
''', [
      lint(22, 1),
    ]);
  }

  test_prefixedIdentifier_toString_withPositionalArgument() async {
    await assertDiagnostics(r'''
void f(dynamic a) {
  a.toString(7);
}
''', [
      lint(22, 1),
    ]);
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

  test_propertyAccess_toStringTearoff() async {
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
