// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferAssertsInInitializerListsTest);
  });
}

@reflectiveTest
class PreferAssertsInInitializerListsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_asserts_in_initializer_lists';

  test_nonBoolExpression() async {
    // Produces an non_bool_expression diagnostic.
    await assertNoLint(r'''
class A {
  bool? f;
  A() {
    assert(()
    {
      f = true;
      return false;
    });
  }
}
''');
  }
}
