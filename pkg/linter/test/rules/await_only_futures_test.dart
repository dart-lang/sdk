// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitOnlyFuturesTest);
  });
}

@reflectiveTest
class AwaitOnlyFuturesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.await_only_futures;

  test_dynamic() async {
    await assertNoDiagnostics(r'''
void f(dynamic future) async {
  await future;
}
''');
  }

  // TODO(srawlins): Test `await x` for `T extends Future` type variable.

  test_extensionType_implementingFuture() async {
    await assertNoDiagnostics(r'''
extension type E(Future f) implements Future { }

void f() async {
  await E(Future.value());
}
''');
  }

  test_extensionType_notImplementingFuture() async {
    await assertDiagnostics(r'''
extension type E(int c) { }

void f() async {
  await E(1);
}
''', [
      // No lint.
      error(CompileTimeErrorCode.AWAIT_OF_INCOMPATIBLE_TYPE, 48, 5),
    ]);
  }

  test_future() async {
    await assertNoDiagnostics(r'''
void f(Future<void> future) async {
  await future;
}
''');
  }

  test_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(FutureOr<int> future) async {
  await future;
}
''');
  }

  test_futureSubClass() async {
    await assertNoDiagnostics(r'''
void f(MyFuture future) async {
  await future;
}
abstract class MyFuture<T> implements Future<T> {}
''');
  }

  test_int() async {
    await assertDiagnostics(r'''
void f() async {
  await 23;
}
''', [
      lint(19, 5),
    ]);
  }

  test_null() async {
    await assertNoDiagnostics(r'''
void f() async {
  await null;
}
''');
  }

  test_undefinedClass() async {
    await assertDiagnostics(r'''
Undefined f() async => await f();
''', [
      // No lint.
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 0, 9),
    ]);
  }
}
