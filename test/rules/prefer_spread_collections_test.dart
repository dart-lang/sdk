// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferSpreadCollectionsTest);
  });
}

@reflectiveTest
class PreferSpreadCollectionsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_spread_collections';

  test_constInitializedWithNonConstantValue() async {
    await assertDiagnostics(r'''
const thangs = [];
const cc = []..addAll(thangs);
''', [
      // No lint
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 30,
          18),
    ]);
  }
}
