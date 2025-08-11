// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryUnawaitedTest);
  });
}

@reflectiveTest
class UnnecessaryUnawaitedTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.unnecessary_unawaited;

  test_binaryOperator_annotated() async {
    await assertDiagnostics(
      r'''
import 'dart:async';
import 'package:meta/meta.dart';
void f(C c) {
  unawaited(c + c);
}
class C {
  @awaitNotRequired
  Future<void> operator +(C c) => Future.value();
}
''',
      [lint(70, 9)],
    );
  }

  test_binaryOperator_notAnnotated() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(C c) {
  unawaited(c + c);
}
class C {
  Future<void> operator +(C c) => Future.value();
}
''');
  }

  test_function_annotated() async {
    await assertDiagnostics(
      r'''
import 'dart:async';
import 'package:meta/meta.dart';
void f() {
  unawaited(f2());
}
@awaitNotRequired
Future<void> f2() => Future.value();
''',
      [lint(67, 9)],
    );
  }

  test_function_notAnnotated() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f() {
  unawaited(f2());
}
Future<void> f2() => Future.value();
''');
  }

  test_method_annotated() async {
    await assertDiagnostics(
      r'''
import 'dart:async';
import 'package:meta/meta.dart';
void f(C c) {
  unawaited(c.m());
}
class C {
  @awaitNotRequired
  Future<void> m() => Future.value();
}
''',
      [lint(70, 9)],
    );
  }

  test_method_notAnnotated() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(C c) {
  unawaited(c.m());
}
class C {
  Future<void> m() => Future.value();
}
''');
  }

  test_topLevelVariable_annotated() async {
    await assertDiagnostics(
      r'''
import 'dart:async';
import 'package:meta/meta.dart';
void f() {
  unawaited(f2);
}
@awaitNotRequired
Future<void> f2 = Future.value();
''',
      [lint(67, 9)],
    );
  }

  test_topLevelVariable_notAnnotated() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f() {
  unawaited(f2);
}
Future<void> f2 = Future.value();
''');
  }

  test_unaryOperator_annotated() async {
    await assertDiagnostics(
      r'''
import 'dart:async';
import 'package:meta/meta.dart';
void f(C c) {
  unawaited(-c);
}
class C {
  @awaitNotRequired
  Future<void> operator -() => Future.value();
}
''',
      [lint(70, 9)],
    );
  }

  test_unaryOperator_notAnnotated() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(C c) {
  unawaited(-c);
}
class C {
  Future<void> operator -() => Future.value();
}
''');
  }
}
