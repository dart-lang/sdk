// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFunctionLiteralsInForeachCalls);
  });
}

@reflectiveTest
class AvoidFunctionLiteralsInForeachCalls extends LintRuleTest {
  @override
  String get lintRule => 'avoid_function_literals_in_foreach_calls';

  test_expectedIdentifier() async {
    await assertDiagnostics(r'''
void f(dynamic iter) => iter?.forEach(...);
''', [
      // No lint
      error(ParserErrorCode.MISSING_IDENTIFIER, 38, 3),
    ]);
  }
}
