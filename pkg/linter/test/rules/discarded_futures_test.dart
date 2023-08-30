// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DiscardedFuturesTest);
  });
}

@reflectiveTest
class DiscardedFuturesTest extends LintRuleTest {
  @override
  String get lintRule => 'discarded_futures';

  test_assignment_ok() async {
    await assertNoDiagnostics(r'''
var handler = <String, Function>{};

void ff(String command) {
  handler[command] = () async {
    await g();
    g();
  };
}
Future<int> g() async => 0;
''');
  }

  test_constructor() async {
    await assertDiagnostics(r'''
class A {
  A() {
    g();
  }
}

Future<int> g() async => 0;
''', [
      lint(22, 1),
    ]);
  }

  test_field_assignment() async {
    await assertDiagnostics(r'''
class A {
  var a = () {
    g();
  };
}

Future<int> g() async => 0;
''', [
      lint(29, 1),
    ]);
  }

  test_function() async {
    await assertDiagnostics(r'''
void recreateDir(String path) {
  deleteDir(path);
  createDir(path);
}

Future<void> deleteDir(String path) async {}
Future<void> createDir(String path) async {}
''', [
      lint(34, 9),
      lint(53, 9),
    ]);
  }

  test_function_closure() async {
    await assertDiagnostics(r'''
void f() {
  () {
    createDir('.');
  }();
}

Future<void> createDir(String path) async {}
''', [
      lint(22, 9),
    ]);
  }

  test_function_closure_ok() async {
    await assertNoDiagnostics(r'''
Future<void> f() async {
  () {
    createDir('.');
  }();
}

Future<void> createDir(String path) async {}
''');
  }

  test_function_expression() async {
    await assertDiagnostics(r'''
void f() {
  var x = h(() => g());
  print(x);
}

int h(Function f) => 0;

Future<int> g() async => 0;
''', [
      lint(29, 1),
    ]);
  }

  test_function_ok_async() async {
    await assertNoDiagnostics(r'''
Future<void> recreateDir(String path) async {
  await deleteDir(path);
  await createDir(path);
}

Future<void> deleteDir(String path) async {}
Future<void> createDir(String path) async {}
''');
  }

  test_function_ok_return_invocation() async {
    await assertNoDiagnostics(r'''
Future<int> f() {
  return g();
}
Future<int> g() async => 0;
''');
  }

  test_function_ok_unawaited() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void recreateDir(String path) {
  unawaited(deleteDir(path));
  unawaited(createDir(path));
}

Future<void> deleteDir(String path) async {}
Future<void> createDir(String path) async {}
''');
  }

  test_method() async {
    await assertDiagnostics(r'''
class Dir{
  void recreateDir(String path) {
    deleteDir(path);
    createDir(path);
  }

  Future<void> deleteDir(String path) async {}
  Future<void> createDir(String path) async {}
}
''', [
      lint(49, 9),
      lint(70, 9),
    ]);
  }

  test_topLevel_assignment() async {
    await assertDiagnostics(r'''
var a = () {
  g();
};

Future<int> g() async => 0;
''', [
      lint(15, 1),
    ]);
  }

  test_topLevel_assignment_expression_body() async {
    await assertDiagnostics(r'''
var a = () => g();

Future<int> g() async => 0;
''', [
      lint(14, 1),
    ]);
  }

  test_topLevel_assignment_ok_async() async {
    await assertNoDiagnostics(r'''
var a = () async {
  g();
};

Future<int> g() async => 0;
''');
  }

  test_topLevel_assignment_ok_future() async {
    await assertNoDiagnostics(r'''
Future<int> a = g();

Future<int> g() async => 0;
''');
  }

  test_variable_assignment() async {
    await assertDiagnostics(r'''
var handler = <String, Function>{};

void ff(String command) {
  handler[command] = () {
    g();
  };
}

Future<int> g() async => 0;
''', [
      lint(93, 1),
    ]);
  }
}
