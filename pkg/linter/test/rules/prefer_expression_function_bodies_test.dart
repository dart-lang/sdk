// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferExpressionFunctionBodiesTest);
  });
}

@reflectiveTest
class PreferExpressionFunctionBodiesTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_expression_function_bodies';

  /// https://github.com/dart-lang/linter/issues/4221
  test_voidReturn() async {
    await assertNoDiagnostics(r'''
class C {
  void f() {
    return;
  }
}
''');
  }
}
