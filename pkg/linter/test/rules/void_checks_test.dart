// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VoidChecksTest);
  });
}

@reflectiveTest
class VoidChecksTest extends LintRuleTest {
  @override
  String get lintRule => 'void_checks';

  test_constructorArgument_genericParameter() async {
    await assertDiagnostics(r'''
void f(dynamic p) {
  A<void>.c(p);
}
class A<T> {
  T value;
  A.c(this.value);
}
''', [
      lint(32, 1),
    ]);
  }

  test_emptyFunctionExpressionReturningFutureOrVoid() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void emptyFunctionExpressionReturningFutureOrVoid(FutureOr<void> Function() f) {
  f = () {};
}
''');
  }

  test_extraPositionalArgument() async {
    await assertDiagnostics(r'''
missing_parameter_for_argument() {
  void foo() {}
  foo(0);
}
''', [
      // No lint
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 57, 1),
    ]);
  }

  test_functionArgument_FutureOrVoidParameter_dynamicArgument() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(dynamic p) {
  m(p);
}
void m(FutureOr<void> arg) {}
''');
  }

  test_functionArgument_FutureOrVoidParameter_FutureOrVoidArgument() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(FutureOr<void> p) {
  m(p);
}
void m(FutureOr<void> arg) {}
''');
  }

  test_functionArgument_FutureOrVoidParameter_FutureVoidArgument() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(Future<void> p) {
  m(p);
}
void m(FutureOr<void> arg) {}
''');
  }

  test_functionArgument_FutureOrVoidParameter_nullArgument() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f() {
  m(null);
}
void m(FutureOr<void> arg) {}
''');
  }

  test_functionArgument_voidParameter_dynamicArgument() async {
    await assertDiagnostics(r'''
void f(dynamic p) {
  m(p);
}
void m(void arg) {}
''', [
      lint(24, 1),
    ]);
  }

  test_functionArgument_voidParameter_named() async {
    await assertDiagnostics(r'''
void f(dynamic p) {
  m(p: p);
}
void m({required void p}) {}
''', [
      lint(27, 1),
    ]);
  }

  test_functionArgument_voidParameter_optional() async {
    await assertDiagnostics(r'''
void f(dynamic p) {
  m(p);
}
void m([void v]) {}
''', [
      lint(24, 1),
    ]);
  }

  // https://github.com/dart-lang/linter/issues/2685
  test_functionType_FutureOrVoidReturnType_Never() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f() {
  foo(() {
    fail(); // OK
  });
}

void foo(FutureOr<void> Function() p) {}
Never fail() { throw ''; }
''');
  }

  /// https://github.com/dart-lang/linter/issues/4019
  test_future_dynamic() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void f(FutureOr<void>? arg) {
  Future<dynamic>? future;
  f(future);
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/3172
  test_futureOrCallback() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void capture(FutureOr<void> Function() callback) {}

void f() {
  capture(() {
    throw "oh no";
  });
}
''');
  }

  test_listPattern_local() async {
    await assertDiagnostics(r'''
void f() {
  void p;
  [p] = <int>[7];
  return p;
}
''', [
      lint(24, 1),
    ]);
  }

  test_listPattern_param() async {
    await assertDiagnostics(r'''
void f(void p) {
  [p] = <int>[7];
}
''', [
      lint(20, 1),
    ]);
  }

  test_neverReturningCallbackThrows() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Never fail() { throw ''; }

void f() async {
  await Future.value(5).then<void>((x) {
    fail();
  });
}
''');
  }

  test_recordPattern() async {
    await assertDiagnostics(r'''
void f(void p) {
  (p, ) = (7, );
}
''', [
      lint(20, 1),
    ]);
  }

  test_returnOfInvalidType() async {
    await assertDiagnostics(r'''
void bug2813() {
  return 1;
}
''', [
      // No lint
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 26, 1),
    ]);
  }

  // https://github.com/dart-lang/linter/issues/2685
  test_returnTypeVoid_Never() async {
    await assertNoDiagnostics(r'''
void f(Future<int> p) {
  p.then<void>((_) {
    fail();
  });
}

Never fail() { throw ''; }
''');
  }

  test_returnTypeVoid_throw() async {
    await assertNoDiagnostics(r'''
void f(Future<int> p) {
  p.then<void>((_) {
    throw '';
  });
}
''');
  }

  test_setterArgument_genericParameter() async {
    await assertDiagnostics(r'''
void f(A<void> a, dynamic p) {
  a.f = p;
}
class A<T> {
  set f(T value) {}
}
''', [
      lint(33, 7),
    ]);
  }
}
