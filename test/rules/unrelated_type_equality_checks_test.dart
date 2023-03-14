// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnrelatedTypeEqualityChecksTestLanguage300);
  });
}

@reflectiveTest
class UnrelatedTypeEqualityChecksTestLanguage300 extends LintRuleTest
    with LanguageVersion300Mixin {
  @override
  bool get dumpAstOnFailures => true;

  @override
  String get lintRule => 'unrelated_type_equality_checks';

  test_switchExpression() async {
    await assertDiagnostics(r'''    
const space = 32;

String f(int char) {
  return switch (char) {
    == 'space' => 'space',
  };
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 49, 6),
      lint(69, 10),
    ]);
  }

  test_switchExpression_lessEq_ok() async {
    await assertDiagnostics(r'''
String f(String char) {
  return switch (char) {
    <= 1 => 'space',
  };
}
''', [
      // No lint.
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 33, 6),
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 53, 2),
    ]);
  }

  test_switchExpression_notEq() async {
    await assertDiagnostics(r'''    
const space = 32;

String f(int char) {
  return switch (char) {
    != 'space' => 'space',
  };
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 49, 6),
      lint(69, 10),
    ]);
  }

  test_switchExpression_ok() async {
    await assertDiagnostics(r'''
String f(String char) {
  return switch (char) {
    == 'space' => 'space',
  };
}
''', [
      // No lint.
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 33, 6),
    ]);
  }
}
