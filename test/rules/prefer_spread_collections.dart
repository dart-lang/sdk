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
    // Produces a const_initialized_with_non_constant_value diagnostic.
    await assertNoLint(r'''
const thangs = [];
const cc = []..addAll(thangs);
''');
  }
}
