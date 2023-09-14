// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseFunctionTypeSyntaxForParametersTest);
  });
}

@reflectiveTest
class UseFunctionTypeSyntaxForParametersTest extends LintRuleTest {
  @override
  String get lintRule => 'use_function_type_syntax_for_parameters';

  test_classicSyntax() async {
    await assertDiagnostics(r'''
void f1(bool f(int e)) {}
''', [
      lint(8, 13),
    ]);
  }

  test_functionTypeSyntax() async {
    await assertNoDiagnostics(r'''
void f2(bool Function(int e) f) {}
''');
  }
}
