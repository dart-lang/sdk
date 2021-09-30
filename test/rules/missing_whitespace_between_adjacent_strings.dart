// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingWhitespaceBetweenAdjacentStringsTest);
  });
}

@reflectiveTest
class MissingWhitespaceBetweenAdjacentStringsTest extends LintRuleTest {
  @override
  String get lintRule => 'missing_whitespace_between_adjacent_strings';

  test_extraPositionalArgument() async {
    await assertDiagnostics(r'''
void f() {
  new Unresolved('aaa' 'bbb');
}
''', [
      // No lint
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 17, 10),
    ]);
  }
}
