// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidReturningThisTest);
  });
}

@reflectiveTest
class AvoidReturningThisTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_returning_this';

  /// https://github.com/dart-lang/linter/issues/3853
  test_conditionalReturn() async {
    await assertNoDiagnostics(r'''
class C {
  C getInstance(C? c) {
    if (c == null) return this;
    return c;
  }
}
''');
  }

  test_conditionalReturn_expression_ternary() async {
    await assertNoDiagnostics(r'''
class C {
  C getInstance(C? c) => c == null ? this : c;
}
''');
  }

  test_conditionalReturn_ternary() async {
    await assertNoDiagnostics(r'''
class C {
  C getInstance(C? c) {
    return c == null ? this : c;
  }
}
''');
  }

  test_method() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  A aa() => this;
}
''', [
      lint(22, 2),
    ]);
  }
}
