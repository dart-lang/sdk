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
  String get lintRule => 'avoid_void_async';

  test_asyncStar() async {
    await assertNoDiagnostics(r'''
Stream<void> f() async* {}
''');
  }

  test_futureVoidReturnType_arrow() async {
    await assertNoDiagnostics(r'''
Future<void> f() async => null;
''');
  }

  test_futureVoidReturnType_block() async {
    await assertNoDiagnostics(r'''
Future<void> c() async {}
''');
  }

  test_getter() async {
    await assertNoDiagnostics(r'''
void get f => null;
''');
  }

  test_getter_async_voidReturnType() async {
    await assertDiagnostics(r'''
void get f async => null;
''', [
      lint(9, 1),
    ]);
  }

  test_implicitReturnType_arrow() async {
    await assertNoDiagnostics(r'''
void f() {
  () async => null;
}
''');
  }

  test_implicitReturnType_block() async {
    await assertNoDiagnostics(r'''
void f() {
  () async {};
}
''');
  }

  test_instanceGetter() async {
    await assertDiagnostics(r'''
class Foo {
  void get l async => null;
}
''', [
      lint(23, 1),
    ]);
  }

  test_instanceGetter_notAsync() async {
    await assertNoDiagnostics(r'''
class Foo {
  void get k => null;
}
''');
  }

  test_instanceMethod_arrow() async {
    await assertDiagnostics(r'''
class Foo {
  void d() async => null;
}
''', [
      lint(19, 1),
    ]);
  }

  test_instanceMethod_asyncStar() async {
    await assertNoDiagnostics(r'''
class Foo {
  Stream<void> f() async* {}
}
''');
  }

  test_instanceMethod_block() async {
    await assertDiagnostics(r'''
class Foo {
  void f() async {}
}
''', [
      lint(19, 1),
    ]);
  }

  test_instanceMethod_futureVoidReturnType_arrow() async {
    await assertNoDiagnostics(r'''
class Foo {
  Future<void> f() async => null;
}
''');
  }

  test_instanceMethod_futureVoidReturnType_block() async {
    await assertNoDiagnostics(r'''
class Foo {
  Future<void> f() async {}
}
''');
  }

  test_instanceMethod_notAsync_arrow() async {
    await assertNoDiagnostics(r'''
class Foo {
  void e() => null;
}
''');
  }

  test_instanceMethod_notAsync_block() async {
    await assertNoDiagnostics(r'''
class Foo {
  void f() {}
}
''');
  }

  test_instanceMethod_syncStar() async {
    await assertNoDiagnostics(r'''
class Foo {
  Iterable<void> f() sync* {}
}
''');
  }

  test_instanceOperator() async {
    await assertDiagnostics(r'''
class Foo {
  void operator |(_) async => null;
}
''', [
      lint(28, 1),
    ]);
  }

  test_instanceOperator_notAsync() async {
    await assertNoDiagnostics(r'''
class Foo {
  void operator &(_) => null;
}
''');
  }

  test_main() async {
    await assertNoDiagnostics(r'''
Future<void> f() async { }
void main() async {
  await f();
}
''');
  }

  test_notAsync_arrow() async {
    await assertNoDiagnostics(r'''
void f() {
  () => null;
}
''');
  }

  test_notAsync_arrow_topLevel() async {
    await assertNoDiagnostics(r'''
void e() => null;
''');
  }

  test_notAsync_body() async {
    await assertNoDiagnostics(r'''
void f() {
  () {};
}
''');
  }

  test_notAsync_voidReturnType() async {
    await assertNoDiagnostics(r'''
void f() {}
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

  test_staticMethod() async {
    await assertDiagnostics(r'''
class Foo {
  static void f() async {}
}
''', [
      lint(26, 1),
    ]);
  }

  test_staticMethod_futureVoidReturnType() async {
    await assertNoDiagnostics(r'''
class Foo {
  static Future<void> f() async {}
}
''');
  }

  test_staticMethod_notAsync() async {
    await assertNoDiagnostics(r'''
class Foo {
  static void f() {}
}
''');
  }

  test_syncStar() async {
    await assertNoDiagnostics(r'''
Iterable<void> f() sync* {}
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

  test_voidReturnType_arrow() async {
    await assertDiagnostics(r'''
void f() async => null;
''', [
      lint(5, 1),
    ]);
  }

  test_voidReturnType_block() async {
    await assertDiagnostics(r'''
void f() async {}
''', [
      lint(5, 1),
    ]);
  }
}
