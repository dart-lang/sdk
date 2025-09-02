// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryAsyncTest);
  });
}

@reflectiveTest
class UnnecessaryAsyncTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_async;

  test_closure_imposedReturnTypeFuture_noAwait() async {
    await assertNoDiagnostics(r'''
void f() {
  useFunction(() async {});
}

void useFunction(Future<void> Function() x) {}
''');
  }

  test_closure_imposedReturnTypeVoid_hasAwait() async {
    await assertNoDiagnostics(r'''
void f() {
  useFunction(() async {
    await 0;
  });
}

void useFunction(void Function() x) {}
''');
  }

  test_closure_imposedReturnTypeVoid_noAwait() async {
    await assertDiagnostics(
      r'''
void f() {
  useFunction(() async {});
}

void useFunction(void Function() x) {}
''',
      [lint(28, 5)],
    );
  }

  test_closure_noImposedReturnType_hasAwait() async {
    await assertNoDiagnostics(r'''
void f() {
  var v = () async {
    await 0;
  };
}
''');
  }

  test_closure_noImposedReturnType_noAwait() async {
    await assertDiagnostics(
      r'''
void f() {
  var v = () async {};
}
''',
      [lint(24, 5)],
    );
  }

  test_localFunction_void_hasAwait() async {
    await assertNoDiagnostics(r'''
void foo() {
  void f() async {
    await 0;
  }
}
''');
  }

  test_localFunction_void_noAwait() async {
    await assertDiagnostics(
      r'''
void foo() {
  void f() async {}
}
''',
      [lint(24, 5)],
    );
  }

  test_localFunction_void_noAwait_outerHasAwait() async {
    await assertDiagnostics(
      r'''
Future<void> foo() async {
  void f() async {}
  await 0;
}
''',
      [lint(38, 5)],
    );
  }

  test_method_future_returnFuture() async {
    await assertDiagnostics(
      r'''
class A {
  Future<int> f() async {
    return Future.value(0);
  }
}
''',
      [lint(28, 5)],
    );
  }

  test_method_future_returnValue() async {
    await assertNoDiagnostics(r'''
class A {
  Future<int> f() async {
    return 0;
  }
}
''');
  }

  test_method_futureOr_returnFuture() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

class A {
  FutureOr<int> f() async {
    return Future.value(0);
  }
}
''',
      [lint(52, 5)],
    );
  }

  test_method_futureOr_returnValue() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

class A {
  FutureOr<int> f() async {
    return 0;
  }
}
''',
      [lint(52, 5)],
    );
  }

  test_method_void_hasAwaitExpression() async {
    await assertNoDiagnostics(r'''
class A {
  void f() async {
    await 0;
  }
}
''');
  }

  test_method_void_noAwait() async {
    await assertDiagnostics(
      r'''
class A {
  void f() async {}
}
''',
      [lint(21, 5)],
    );
  }

  test_topLevelFunction_block_future_intNullable_returnNullable() async {
    await assertNoDiagnostics(r'''
Future<int?> f(int? x) async {
  return x == null ? null : Future.value(x);
}
''');
  }

  test_topLevelFunction_blockBody_dynamic() async {
    await assertNoDiagnostics(r'''
dynamic f() async {
  return 0;
}
''');
  }

  test_topLevelFunction_blockBody_future_int_hasReturn_futureCustom() async {
    await assertDiagnostics(
      r'''
Future<int> f() async {
  return MyFuture.value(0);
}

class MyFuture<T> implements Future<T> {
  MyFuture.value(T _);

  @override
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}
''',
      [lint(16, 5)],
    );
  }

  test_topLevelFunction_blockBody_future_int_returnFuture() async {
    await assertDiagnostics(
      r'''
Future<int> f() async {
  return Future.value(0);
}
''',
      [lint(16, 5)],
    );
  }

  test_topLevelFunction_blockBody_future_int_returnValue() async {
    await assertNoDiagnostics(r'''
Future<int> f() async {
  return 0;
}
''');
  }

  test_topLevelFunction_blockBody_future_intNullable_hasReturn_null() async {
    await assertNoDiagnostics(r'''
Future<int?> f() async {
  return null;
}
''');
  }

  test_topLevelFunction_blockBody_future_void_hasReturn_future() async {
    await assertDiagnostics(
      r'''
Future<void> f() async {
  return foo();
}

Future<void> foo() {
  return Future.value();
}
''',
      [lint(17, 5)],
    );
  }

  test_topLevelFunction_blockBody_future_void_hasReturn_nothing() async {
    await assertNoDiagnostics(r'''
Future<void> f() async {
  return;
}
''');
  }

  test_topLevelFunction_blockBody_future_void_noReturn_atAll() async {
    await assertNoDiagnostics(r'''
Future<void> f() async {}
''');
  }

  test_topLevelFunction_blockBody_future_void_noReturn_atEnd_hasReturnFuture() async {
    await assertNoDiagnostics(r'''
Future<void> f() async {
  if (0 == 0) {
    return Future.value();
  }
}
''');
  }

  test_topLevelFunction_blockBody_future_void_noReturn_atEnd_hasReturnNothing() async {
    await assertNoDiagnostics(r'''
Future<void> f() async {
  if (0 == 0) {
    return;
  }
}
''');
  }

  test_topLevelFunction_blockBody_futureNullable_int_hasReturn_future() async {
    await assertDiagnostics(
      r'''
Future<int>? f() async {
  return Future.value(0);
}
''',
      [lint(17, 5)],
    );
  }

  test_topLevelFunction_blockBody_futureNullable_int_hasReturn_value() async {
    await assertNoDiagnostics(r'''
Future<int>? f() async {
  return 0;
}
''');
  }

  test_topLevelFunction_blockBody_futureNullable_intNullable_hasReturn_null() async {
    await assertNoDiagnostics(r'''
Future<int?>? f() async {
  return null;
}
''');
  }

  test_topLevelFunction_blockBody_futureNullable_intNullable_noReturn() async {
    await assertDiagnostics(
      r'''
Future<int?>? f() async {}
''',
      [error(WarningCode.bodyMightCompleteNormallyNullable, 14, 1)],
    );
  }

  test_topLevelFunction_blockBody_futureNullable_void_hasReturn_nothing() async {
    await assertNoDiagnostics(r'''
Future<void>? f() async {
  return;
}
''');
  }

  test_topLevelFunction_blockBody_futureNullable_void_noReturn_atAll() async {
    await assertNoDiagnostics(r'''
Future<void>? f() async {}
''');
  }

  test_topLevelFunction_blockBody_futureNullable_void_noReturn_atEnd_hasReturnFuture() async {
    await assertNoDiagnostics(r'''
Future<void>? f() async {
  if (0 == 0) {
    return Future.value();
  }
}
''');
  }

  test_topLevelFunction_blockBody_futureNullable_void_noReturn_atEnd_hasReturnNull() async {
    await assertNoDiagnostics(r'''
Future<void>? f() async {
  if (0 == 0) {
    return null;
  }
}
''');
  }

  test_topLevelFunction_blockBody_futureOr_returnFuture() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

FutureOr<int> f() async {
  return Future.value(0);
}
''',
      [lint(40, 5)],
    );
  }

  test_topLevelFunction_blockBody_futureOr_returnValue() async {
    await assertDiagnostics(
      r'''
import 'dart:async';

FutureOr<int> f() async {
  return 0;
}
''',
      [lint(40, 5)],
    );
  }

  test_topLevelFunction_blockBody_object() async {
    await assertNoDiagnostics(r'''
Object f() async {
  return 0;
}
''');
  }

  test_topLevelFunction_blockBody_void_hasAwait_expression() async {
    await assertNoDiagnostics(r'''
void f() async {
  await 0;
}
''');
  }

  test_topLevelFunction_blockBody_void_hasAwait_forElement() async {
    await assertNoDiagnostics(r'''
void f(Stream<int> values) async {
  [
    await for (var value in values) value,
  ];
}
''');
  }

  test_topLevelFunction_blockBody_void_hasAwait_forStatement() async {
    await assertNoDiagnostics(r'''
void f(Stream<int> values) async {
  await for (var value in values) {}
}
''');
  }

  test_topLevelFunction_blockBody_void_hasAwait_nestedFunctionExpression() async {
    await assertDiagnostics(
      r'''
void f() async {
  () async {
    await 0;
  }();
}
''',
      [lint(9, 5)],
    );
  }

  test_topLevelFunction_blockBody_void_noAwait() async {
    await assertDiagnostics(
      r'''
void f() async {}
''',
      [lint(9, 5)],
    );
  }

  test_topLevelFunction_exprBody_future_int_returnFuture() async {
    await assertDiagnostics(
      r'''
Future<int> f() async => Future.value(0);
''',
      [lint(16, 5)],
    );
  }

  test_topLevelFunction_exprBody_future_int_returnValue() async {
    await assertNoDiagnostics(r'''
Future<int> f() async => 0;
''');
  }

  test_topLevelFunction_exprBody_future_intNullable_returnNullable() async {
    await assertNoDiagnostics(r'''
Future<int?> f(int? x) async => x == null ? null : Future.value(x);
''');
  }

  test_topLevelFunction_exprBody_futureNullable_intNullable_returnNull() async {
    await assertNoDiagnostics(r'''
Future<int?>? f() async => null;
''');
  }
}
