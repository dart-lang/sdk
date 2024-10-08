// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidReturningNullForVoidTest);
  });
}

@reflectiveTest
class AvoidReturningNullForVoidTest extends LintRuleTest {
  @override
  List<AnalyzerErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_ELEMENT,
        WarningCode.UNUSED_LOCAL_VARIABLE,
      ];

  @override
  String get lintRule => 'avoid_returning_null_for_void';

  test_function_async_returnsFutureVoid_blockBody_returnNull() async {
    await assertDiagnostics(r'''
Future<void> f3f() async {
  return null;
}
''', [
      lint(29, 12),
    ]);
  }

  test_function_async_returnsFutureVoid_expressionBody_returnNothing() async {
    await assertNoDiagnostics(r'''
Future<void> f() async => print('');
''');
  }

  test_function_async_returnsFutureVoid_expressionBody_returnNull() async {
    await assertDiagnostics(r'''
Future<void> f() async => null;
''', [
      lint(17, 14),
    ]);
  }

  test_function_blockBody_conditional_returnNothing() async {
    await assertNoDiagnostics(r'''
void f(bool b) {
  if (b) {
    return;
  }
}
''');
  }

  test_function_blockBody_conditional_returnNull() async {
    await assertDiagnostics(r'''
void f(bool b) {
  if (b) {
    return null;
  }
}
''', [
      lint(32, 12),
    ]);
  }

  test_function_blockBody_returnNothing() async {
    await assertNoDiagnostics(r'''
void f() {
  return;
}
''');
  }

  test_function_blockBody_returnNull() async {
    await assertDiagnostics(r'''
void f() {
  return null;
}
''', [
      lint(13, 12),
    ]);
  }

  test_function_expressionBody_returnNothing() async {
    await assertNoDiagnostics(r'''
void f() => print('');
''');
  }

  test_function_expressionBody_returnNull() async {
    await assertDiagnostics(r'''
void f() => null;
''', [
      lint(9, 8),
    ]);
  }

  test_function_expressionBody_returnNullExpressionResult() async {
    await assertNoDiagnostics(r'''
Null get nullFromGetter => null;
void f() => nullFromGetter;
''');
  }

  test_localFunction_async_returnsFutureVoid_blockBody_returnNull() async {
    await assertDiagnostics(r'''
void f() {
  Future<void> g() async {
    return null;
  }
}
''', [
      lint(42, 12),
    ]);
  }

  test_localFunction_blockBody_returnNull() async {
    await assertDiagnostics(r'''
void f() {
  void g() {
    return null;
  }
}
''', [
      lint(28, 12),
    ]);
  }

  test_localFunction_expressionBody_returnNull() async {
    await assertDiagnostics(r'''
void f() {
  void g() => null;
}
''', [
      lint(22, 8),
    ]);
  }

  test_method_class_blockBody_returnNull() async {
    await assertDiagnostics(r'''
class C {
  void m() {
    return null;
  }
}
''', [
      lint(27, 12),
    ]);
  }

  test_method_inClass_blockBody_async_returnsFutureVoid_blockBody_returnNull() async {
    await assertDiagnostics(r'''
class C {
  Future<void> m() async {
    return null;
  }
}
''', [
      lint(41, 12),
    ]);
  }

  test_method_inExtension_blockBody_returnNull() async {
    await assertDiagnostics(r'''
extension E on int {
  void f() {
    return null;
  }
}
''', [lint(38, 12)]);
  }

  test_method_inExtensionType_blockBody_returnNull() async {
    await assertDiagnostics(r'''
extension type E(int i) {
  void f() {
    return null;
  }
}
''', [lint(43, 12)]);
  }

  test_method_inMixin_blockBody_returnNull() async {
    await assertDiagnostics(r'''
mixin M {
  void f() {
    return null;
  }
}
''', [lint(27, 12)]);
  }

  test_staticMethod_inClass_blockBody_returnNull() async {
    await assertDiagnostics(r'''
class C {
  static void m() {
    return null;
  }
}
''', [
      lint(34, 12),
    ]);
  }
}
