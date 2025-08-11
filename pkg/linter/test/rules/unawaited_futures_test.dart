// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnawaitedFuturesTest);
  });
}

@reflectiveTest
class UnawaitedFuturesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.unawaited_futures;

  test_binaryExpression_unawaited() async {
    await assertDiagnostics(
      r'''
void f(C a, C b) async {
  a + b;
}
class C {
  Future<int> operator +(C other) async => 7;
}
''',
      [lint(27, 5)],
    );
  }

  test_binaryExpression_unawaited_awaitNotRequired() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f(C a, C b) async {
  a + b;
}
class C {
  @awaitNotRequired
  Future<int> operator +(C other) async => 7;
}
''');
  }

  test_boundToFuture_unawaited() async {
    // This behavior was not necessarily designed, but this test documents the
    // current behavior.
    await assertNoDiagnostics(r'''
void f<T extends Future<void>>(T p) async {
  p;
}
''');
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

  test_functionCall_classImplementsFuture() async {
    // https://github.com/dart-lang/linter/issues/2211
    await assertDiagnostics(
      r'''
void f(Future2 p) async {
  g(p);
}
Future2 g(Future2 p) => p;
abstract class Future2 implements Future {}
''',
      [lint(28, 1)],
    );
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
    await assertDiagnostics(
      r'''
void f() async {
  '${g()}';
}
Future<int> g() => Future.value(0);
''',
      [lint(22, 1)],
    );
  }

  test_functionCall_interpolated_unawaited_awaitNotRequired() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f() async {
  '${g()}';
}
@awaitNotRequired
Future<int> g() => Future.value(0);
''');
  }

  test_functionCall_interpolated_unawaited_classImplementsFuture() async {
    await assertDiagnostics(
      r'''
void f() async {
  '${g()}';
}
Future2<int> g() => f2;
abstract class Future2<T> implements Future<T> {}
external Future2<int> f2;
''',
      [lint(22, 1)],
    );
  }

  test_functionCall_nullableFuture_unawaited() async {
    await assertDiagnostics(
      r'''
void f() async {
  g();
}
Future<int>? g() => Future.value(0);
''',
      [lint(19, 1)],
    );
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
    await assertDiagnostics(
      r'''
void f() async {
  g();
}
Future<int> g() => Future.value(0);
''',
      [lint(19, 1)],
    );
  }

  test_functionCall_unawaited_awaitNotRequired() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f() async {
  g();
}
@awaitNotRequired
Future<int> g() => Future.value(0);
''');
  }

  test_functionCallInCascade() async {
    await assertDiagnostics(
      r'''
void f() async {
  C()..doAsync();
}
class C {
  Future<void> doAsync() async {}
}
''',
      [lint(24, 7)],
    );
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

  test_functionCallInCascade_awaitNotRequired() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f() async {
  C()..m();
}
class C {
  @awaitNotRequired
  Future<void> m() async {}
}
''');
  }

  test_functionCallInCascade_awaitNotRequiredInherited() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f() async {
  C()..m();
}
class C {
  @awaitNotRequired
  Future<void> m() async {}
}
class D {
  Future<void> m() => Future.value();
}
''');
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

  test_instanceProperty_unawaited() async {
    await assertDiagnostics(
      r'''
void f(C c) async {
  c.p;
}
abstract class C {
  Future<int> get p;
}
''',
      [lint(24, 1)],
    );
  }

  test_instanceProperty_unawaited_awaitNotRequired() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f(C c) async {
  c.p;
}
abstract class C {
  @awaitNotRequired
  Future<int> get p;
}
''');
  }

  test_instanceProperty_unawaited_awaitNotRequiredInherited() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f(D d) async {
  d.p;
}
abstract class C {
  @awaitNotRequired
  Future<int> get p;
}
class D extends C {
  Future<int> p = Future.value(7);
}
''');
  }

  test_parameter_unawaited() async {
    await assertDiagnostics(
      r'''
void f(Future<int> p) async {
  p;
}
''',
      [lint(32, 1)],
    );
  }

  test_prefixExpression_unawaited() async {
    await assertDiagnostics(
      r'''
void f(C a) async {
  -a;
}
class C {
  Future<int> operator -() async => 7;
}
''',
      [lint(22, 2)],
    );
  }

  test_prefixExpression_unawaited_awaitNotRequired() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f(C a) async {
  -a;
}
class C {
  @awaitNotRequired
  Future<int> operator -() async => 7;
}
''');
  }

  test_undefinedIdentifier() async {
    await assertDiagnostics(
      r'''
f() async {
  Duration d = Duration();
  Future.delayed(d, bar);
}
''',
      [
        // No lint
        error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 59, 3),
      ],
    );
  }
}
