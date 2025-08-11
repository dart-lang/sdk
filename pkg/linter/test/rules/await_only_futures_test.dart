// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
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
void f(dynamic p) async {
  await p;
}
''');
  }

  test_extensionType_implementingFuture() async {
    await assertNoDiagnostics(r'''
extension type E(Future f) implements Future {}

void f(E p) async {
  await p;
}
''');
  }

  test_extensionType_implementingFuture_nullable() async {
    await assertNoDiagnostics(r'''
extension type E(Future f) implements Future {}

void f(E? p) async {
  await p;
}
''');
  }

  test_extensionType_notImplementingFuture() async {
    await assertDiagnostics(
      r'''
extension type E(int c) { }

void f() async {
  await E(1);
}
''',
      [
        // No lint.
        error(CompileTimeErrorCode.AWAIT_OF_INCOMPATIBLE_TYPE, 48, 5),
      ],
    );
  }

  test_future() async {
    await assertNoDiagnostics(r'''
void f(Future<void> p) async {
  await p;
}
''');
  }

  test_future_nullable() async {
    await assertNoDiagnostics(r'''
void f(Future<void>? p) async {
  await p;
}
''');
  }

  test_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(FutureOr<int> p) async {
  await p;
}
''');
  }

  test_futureOr_nullable() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(FutureOr<int>? p) async {
  await p;
}
''');
  }

  test_futureSubClass() async {
    await assertNoDiagnostics(r'''
void f(MyFuture<int> p) async {
  await p;
}
abstract class MyFuture<T> implements Future<T> {}
''');
  }

  test_int() async {
    await assertDiagnostics(
      r'''
void f() async {
  await 23;
}
''',
      [lint(19, 5)],
    );
  }

  test_intersectionType_subtypeOfFuture() async {
    await assertNoDiagnostics(r'''
void f<T>(T f) async {
  if (f is Future<int>) {
    await f;
  }
}
''');
  }

  test_null() async {
    await assertNoDiagnostics(r'''
void f() async {
  await null;
}
''');
  }

  test_typeVariable() async {
    await assertDiagnostics(
      r'''
void f<T>(T f) async {
  await f;
}
''',
      [lint(25, 5)],
    );
  }

  test_typeVariable_boundToFuture() async {
    await assertNoDiagnostics(r'''
void f<T extends Future<dynamic>>(T f) async {
  await f;
}
''');
  }

  test_undefinedClass() async {
    await assertDiagnostics(
      r'''
Undefined f() async => await f();
''',
      [
        // No lint.
        error(CompileTimeErrorCode.UNDEFINED_CLASS, 0, 9),
      ],
    );
  }
}
