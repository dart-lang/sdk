// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferIsNotOperatorTest);
  });
}

@reflectiveTest
class PreferIsNotOperatorTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_is_not_operator';

  test_is_wrappedInNot() async {
    await assertDiagnostics(r'''
void f(Object p) {
  !(p is int);
}
''', [
      lint(21, 11),
    ]);
  }

  test_isNot() async {
    await assertNoDiagnostics(r'''
void f(Object p) {
  p is! int;
}
''');
  }
}
