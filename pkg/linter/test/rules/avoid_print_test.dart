// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidPrintTest);
  });
}

@reflectiveTest
class AvoidPrintTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'avoid_print';

  test_directCall() async {
    await assertDiagnostics(r'''
void f() {
  print('ha');
}
''', [
      lint(13, 5),
    ]);
  }

  test_kDebugMode_blockStatement() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
void f() {
  if (kDebugMode) {
    print('');
  }
}
''');
  }

  test_kDebugMode_sigleStatement() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
void f() {
  if (kDebugMode) print('');
}
''');
  }

  test_methodOfClass() async {
    await assertNoDiagnostics(r'''
class A {
  print() {}
}
void f(A a) {
  a.print();
}
''');
  }

  test_tearoff() async {
    await assertDiagnostics(r'''
void f() {
  [1,2,3].forEach(print);
}
''', [
      lint(29, 5),
    ]);
  }

  test_tearoff2() async {
    await assertDiagnostics(r'''
void f() {
  Future.value('hello').then(print);
}
''', [
      lint(40, 5),
    ]);
  }

  test_tearoff_assigned_thenCalled() async {
    await assertNoDiagnostics(r'''
var x = print;
void f() {
  x('ha');
}
''');
  }

  test_tearoff_assigned_thenTornOff() async {
    await assertNoDiagnostics(r'''
var x = print;
void f() {
  [1,2,3].forEach(x);
}
''');
  }
}
