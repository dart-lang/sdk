// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LiteralOnlyBooleanExpressionsTest);
  });
}

@reflectiveTest
class LiteralOnlyBooleanExpressionsTest extends LintRuleTest {
  @override
  String get lintRule => 'literal_only_boolean_expressions';

  test_whileTrue() async {
    await assertNoDiagnostics(r'''
void f() {
  while (true) {
    print('!');
  }
}
''');
  }
}
