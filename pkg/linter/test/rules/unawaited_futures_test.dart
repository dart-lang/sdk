// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnawaitedFuturesTest);
  });
}

@reflectiveTest
class UnawaitedFuturesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unawaited_futures;

  test_classImplementsFuture() async {
    // https://github.com/dart-lang/linter/issues/2211
    await assertDiagnostics(r'''
void f(Future2 p) async {
  g(p);
}
Future2 g(Future2 p) => p;
abstract class Future2 implements Future {}
''', [
      lint(28, 5),
    ]);
  }

  test_functionCall_assigned() async {
    await assertNoDiagnostics(r'''
Future<int> f() async {
  var x = g();
  return x;
}
Future<int> g() => Future.value(0);
''');
  }

  test_functionCall_awaited() async {
    await assertNoDiagnostics(r'''
void f() async {
  await g();
}
Future<int> g() => Future.value(0);
''');
  }

  test_functionCall_inListContext() async {
    await assertNoDiagnostics(r'''
void f() async {
  var x = [g()];
  x..[0] = g();
}
Future<int> g() => Future.value(0);
''');
  }

  test_functionCall_interpolated_unawaited() async {
    await assertDiagnostics(r'''
void f() async {
  '${g()}';
}
Future<int> g() => Future.value(0);
''', [
      lint(22, 3),
    ]);
  }

  test_functionCall_returnedWithFutureType() async {
    await assertNoDiagnostics(r'''
void f() async {
  <String, Future>{}.putIfAbsent('foo', () => g());
}
Future<int> g() => Future.value(0);
''');
  }

  test_functionCall_unawaited() async {
    await assertDiagnostics(r'''
void f() async {
  g();
}
Future<int> g() => Future.value(0);
''', [
      lint(19, 4),
    ]);
  }

  test_functionCallInCascade_assignment() async {
    await assertNoDiagnostics(r'''
void f() async {
  C()..futureField = g();
}
Future<int> g() => Future.value(0);
class C {
  Future<int>? futureField;
}
''');
  }

  test_functionCallInCascade_inAsync() async {
    await assertDiagnostics(r'''
void f() async {
  C()..doAsync();
}
class C {
  Future<void> doAsync() async {}
}
''', [
      lint(22, 11),
    ]);
  }

  test_functionCallInCascade_indexAssignment() async {
    await assertNoDiagnostics(r'''
void f() async {
  C()
    ..x?[0] = g();
}
Future<int> g() => Future.value(0);
class C {
  List<Future<void>>? x = [];
}
''');
  }

  test_functionCallInCascade_inSync() async {
    await assertNoDiagnostics(r'''
void foo() {
  C()..doAsync();
}
class C {
  Future<void> doAsync() async {}
}
''');
  }

  test_undefinedIdentifier() async {
    await assertDiagnostics(r'''
f() async {
  Duration d = Duration();
  Future.delayed(d, bar);
}
''', [
      // No lint
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 59, 3),
    ]);
  }
}
