// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ThrowInFinallyTest);
  });
}

@reflectiveTest
class ThrowInFinallyTest extends LintRuleTest {
  @override
  String get lintRule => 'throw_in_finally';

  test_noThrow() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
  } catch (e) {
  } finally {
    print('');
  }
}
''');
  }

  test_throwInCatchInFinally() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
  } catch (e) {
  } finally {
    try {
    } catch (e) {
      throw C();
    }
  }
}

class C {}
''');
  }

  test_throwInFinally() async {
    await assertDiagnostics(r'''
  void f() {
  try {
  } catch (e) {
  } finally {
    if (1 > 0) {
      throw '';
    } else {
      print('should catch nested throws!');
    }
  }
}
''', [
      lint(74, 8),
    ]);
  }

  test_throwInInnerClosureInFinally() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    registrationGuard();
  } finally {
    registrationGuard = () {
      throw C();
    };
  }
}
Function registrationGuard = () {};

class C {}
''');
  }
}
