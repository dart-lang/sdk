// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryAwaitInReturnTest);
  });
}

@reflectiveTest
class UnnecessaryAwaitInReturnTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_await_in_return';

  test_asyncArrow_awaited() async {
    await assertDiagnostics(r'''
Future<int> f() async => await future;
final future = Future.value(1);
''', [
      lint(25, 5),
    ]);
  }

  test_asyncArrow_awaited_futureOfFuture() async {
    await assertNoDiagnostics(r'''
Future<int> f() async => await future;
final future = Future<Future<int>>.value(Future<int>.value(1));
''');
  }

  test_asyncArrow_awaited_instanceMethod() async {
    await assertDiagnostics(r'''
class A {
  Future<int> f() async => await future;
}
final future = Future.value(1);
''', [
      lint(37, 5),
    ]);
  }

  test_asyncArrow_awaited_subtype() async {
    await assertDiagnostics(r'''
class B {
  Future<num> foo() async => 1;
  Future<int> bar() async => await foo() as int;
  Future<num> buzz() async => await bar();
}
''', [
      lint(121, 5),
    ]);
  }

  test_asyncArrow_awaited_withAs() async {
    await assertNoDiagnostics(r'''
class B {
  Future<num> foo() async => 1;
  Future<int> bar() async => await foo() as int;
}
''');
  }

  test_asyncArrow_notAwaited() async {
    await assertNoDiagnostics(r'''
Future<int> f() async => future;
final future = Future.value(1);
''');
  }

  test_asyncArrow_notAwaited_instanceMethod() async {
    await assertNoDiagnostics(r'''
class A {
  Future<int> f() async => future;
}
final future = Future.value(1);
''');
  }

  test_asyncBlock_awaited() async {
    await assertDiagnostics(r'''
Future<int> f() async {
  return await future;
}
final future = Future.value(1);
''', [
      lint(33, 5),
    ]);
  }

  test_asyncBlock_awaited_futureOfFuture() async {
    await assertNoDiagnostics(r'''
Future<int> f() async {
  return await future;
}
final future = Future<Future<int>>.value(Future<int>.value(1));
''');
  }

  test_asyncBlock_awaited_instanceMethod() async {
    await assertDiagnostics(r'''
class A {
  Future<int> f() async {
    return await future;
  }
}
final future = Future.value(1);
''', [
      lint(47, 5),
    ]);
  }

  test_asyncBlock_awaited_inTry() async {
    await assertDiagnostics(r'''
Future<dynamic> f() async {
  try {
    return await future;
  } catch (e) {
    return await future;
  }
}
final future = Future.value(1);
''', [
      lint(88, 5),
    ]);
  }

  test_asyncBlock_awaited_inTry_instanceMethod() async {
    await assertDiagnostics(r'''
class A {
  Future<dynamic> f() async {
    try {
      return await future;
    } catch (e) {
      return await future;
    }
  }
}
final future = Future.value(1);
''', [
      lint(108, 5),
    ]);
  }

  test_asyncBlock_notAwaited() async {
    await assertNoDiagnostics(r'''
Future<int> f() async {
  return future;
}
final future = Future.value(1);
''');
  }

  test_asyncBlock_notAwaited_instanceMethod() async {
    await assertNoDiagnostics(r'''
class A {
  Future<int> f() async {
    return future;
  }
}
final future = Future.value(1);
''');
  }
}
