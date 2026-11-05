// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FutureSyncValueTest);
  });
}

@reflectiveTest
class FutureSyncValueTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.future_sync_value;

  Future<void> test_dotShorthands() async {
    await assertDiagnosticsFromMarkup('''
Future<int> f() => .[!value!](1);
''');
  }

  Future<void> test_dynamic() async {
    await assertNoDiagnostics('''
Future<int> f(p) => Future.value(p);
''');
  }

  Future<void> test_FutureInt() async {
    await assertNoDiagnostics('''
Future<int> f(Future<int> f) => Future.value(f);
''');
  }

  Future<void> test_futureOr() async {
    await assertNoDiagnostics('''
import 'dart:async';
Future<FutureOr> f(FutureOr f) => Future.value(f);
''');
  }

  Future<void> test_FutureOrInt() async {
    await assertNoDiagnostics('''
import 'dart:async';

Future<int> f(FutureOr<int> f) => Future.value(f);
''');
  }

  Future<void> test_int() async {
    await assertDiagnosticsFromMarkup('''
Future<int> f() => Future.[!value!](1);
''');
  }

  Future<void> test_int_pre_valueSync() async {
    await assertNoDiagnostics('''
// @dart = 3.9
Future<int> f() => Future.value(1);
''');
  }

  Future<void> test_object() async {
    await assertDiagnosticsFromMarkup('''
Future<Object> f(Object o) => Future.[!value!](o);
''');
  }
}
