// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OnlyThrowErrorsTest);
  });
}

@reflectiveTest
class OnlyThrowErrorsTest extends LintRuleTest {
  @override
  String get lintRule => 'only_throw_errors';

  @override
  setUp() {
    super.setUp();
    noSoundNullSafety = false;
  }

  tearDown() {
    noSoundNullSafety = true;
  }

  test_argumentError() async {
    await assertNoDiagnostics(r'''
void f() {
  throw ArgumentError('hello');
}
''');
  }

  test_error() async {
    await assertNoDiagnostics(r'''
void f() {
  throw Error();
}
''');
  }

  test_exception() async {
    await assertNoDiagnostics(r'''
void f() {
  throw ArgumentError('hello');
}
''');
  }

  test_exceptionGeneric() async {
    await assertNoDiagnostics(r'''
void f<E extends Exception>(E error) {
  throw error;
}
''');
  }

  test_exceptionGenericUnboundedAndPromoted() async {
    await assertNoDiagnostics(r'''
void f<E>(E error) {
  if (error is Error) {
    throw error;
  }
}
''');
  }

  test_exceptionMixedIn() async {
    await assertNoDiagnostics(r'''
// @dart=2.19
class Err extends Object with Exception {}

void f() {
  throw Err();
}
''');
  }

  test_int() async {
    await assertDiagnostics(r'''
void f() {
  throw 7;
}
''', [
      lint(19, 1),
    ]);
  }

  test_never() async {
    await assertNoDiagnostics(r'''
void f() {
  throw e();
}

Never e() => throw Exception();
''');
  }

  test_nullInPreNullSafe() async {
    await assertDiagnostics(r'''
// @dart=2.9
void f() {
  throw null;
}
''', [
      lint(32, 4),
    ]);
  }

  test_object() async {
    await assertDiagnostics(r'''
void f() {
  throw Object();
}
''', [
      lint(19, 8),
    ]);
  }

  test_string() async {
    await assertDiagnostics(r'''
void f() {
  throw 'hello';
}
''', [
      lint(19, 7),
    ]);
  }
}
