// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidVoidAsyncTest);
  });
}

@reflectiveTest
class AvoidVoidAsyncTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_void_async;

  test_function_async_futureVoidReturnType_arrow() async {
    await assertNoDiagnostics(r'''
Future<void> f() async => null;
''');
  }

  test_function_async_futureVoidReturnType_block() async {
    await assertNoDiagnostics(r'''
Future<void> c() async {}
''');
  }

  test_function_async_voidReturnType_arrow() async {
    await assertDiagnostics(r'''
void f() async => null;
''', [
      lint(5, 1),
    ]);
  }

  test_function_async_voidReturnType_block() async {
    await assertDiagnostics(r'''
void f() async {}
''', [
      lint(5, 1),
    ]);
  }

  test_function_asyncStar() async {
    await assertNoDiagnostics(r'''
Stream<void> f() async* {}
''');
  }

  test_function_notAsync_arrow_topLevel() async {
    await assertNoDiagnostics(r'''
void e() => null;
''');
  }

  test_function_notAsync_voidReturnType() async {
    await assertNoDiagnostics(r'''
void f() {}
''');
  }

  test_function_syncStar() async {
    await assertNoDiagnostics(r'''
Iterable<void> f() sync* {}
''');
  }

  test_functionExpression_async_arrow() async {
    await assertNoDiagnostics(r'''
void f() {
  () async => null;
}
''');
  }

  test_functionExpression_async_block() async {
    await assertNoDiagnostics(r'''
void f() {
  () async {};
}
''');
  }

  test_functionExpression_notAsync_arrow() async {
    await assertNoDiagnostics(r'''
void f() {
  () => null;
}
''');
  }

  test_functionExpression_notAsync_body() async {
    await assertNoDiagnostics(r'''
void f() {
  () {};
}
''');
  }

  test_functionLocal_async_arrow() async {
    await assertDiagnostics(r'''
void f() {
  void g() async => null;
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 18, 1),
      lint(18, 1),
    ]);
  }

  test_functionLocal_main_async_arrow() async {
    await assertDiagnostics(r'''
void f() {
  void main() async => null;
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 18, 4),
      lint(18, 4),
    ]);
  }

  test_getter_async() async {
    await assertDiagnostics(r'''
void get l async => null;
''', [
      lint(9, 1),
    ]);
  }

  test_getter_async_voidReturnType() async {
    await assertDiagnostics(r'''
void get f async => null;
''', [
      lint(9, 1),
    ]);
  }

  test_getter_notAsync() async {
    await assertNoDiagnostics(r'''
void get f => null;
''');
  }

  test_localFunction_async() async {
    await assertDiagnostics(r'''
Future<void> f() async {
  void g() async {}
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 32, 1),
      lint(32, 1),
    ]);
  }

  test_main_async() async {
    await assertNoDiagnostics(r'''
Future<void> f() async { }
void main() async {
  await f();
}
''');
  }

  test_method_async_arrow() async {
    await assertDiagnostics(r'''
class Foo {
  void d() async => null;
}
''', [
      lint(19, 1),
    ]);
  }

  test_method_async_block() async {
    await assertDiagnostics(r'''
class Foo {
  void f() async {}
}
''', [
      lint(19, 1),
    ]);
  }

  test_method_async_futureVoidReturnType_arrow() async {
    await assertNoDiagnostics(r'''
class Foo {
  Future<void> f() async => null;
}
''');
  }

  test_method_async_futureVoidReturnType_block() async {
    await assertNoDiagnostics(r'''
class Foo {
  Future<void> f() async {}
}
''');
  }

  test_method_asyncStar() async {
    await assertNoDiagnostics(r'''
class Foo {
  Stream<void> f() async* {}
}
''');
  }

  test_method_main_async_arrow() async {
    await assertDiagnostics(r'''
class Foo {
  void main() async => null;
}
''', [
      lint(19, 4),
    ]);
  }

  test_method_notAsync_arrow() async {
    await assertNoDiagnostics(r'''
class Foo {
  void e() => null;
}
''');
  }

  test_method_notAsync_block() async {
    await assertNoDiagnostics(r'''
class Foo {
  void f() {}
}
''');
  }

  test_method_syncStar() async {
    await assertNoDiagnostics(r'''
class Foo {
  Iterable<void> f() sync* {}
}
''');
  }

  test_operator_async() async {
    await assertDiagnostics(r'''
class Foo {
  void operator |(_) async => null;
}
''', [
      lint(28, 1),
    ]);
  }

  test_operator_notAsync() async {
    await assertNoDiagnostics(r'''
class Foo {
  void operator &(_) => null;
}
''');
  }

  test_setter_notAsync() async {
    await assertNoDiagnostics(r'''
void set f(_) => null;
''');
  }

  test_setter_notAsync_implicitReturnType() async {
    await assertNoDiagnostics(r'''
set f(_) => null;
''');
  }

  test_typedef_futureVoidReturnType() async {
    await assertNoDiagnostics(r'''
typedef Future<void> F(int x);
''');
  }

  test_typedef_voidReturnType() async {
    await assertNoDiagnostics(r'''
typedef void F(int x);
''');
  }
}
