// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferContainsTest);
  });
}

@reflectiveTest
class PreferContainsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_contains';

  test_argumentTypeNotAssignable() async {
    // Produces an argument_type_not_assignable diagnostic.
    await assertNoLint(r'''
List<int> list = [];
condition() {
  var next;
  while ((next = list.indexOf('{')) != -1) {}
}
''');
  }

  test_unnecessaryCast() async {
    // Produces an unnecessary_cast diagnostic.
    await assertLint(r'''
bool le3 = ([].indexOf(1) as int) > -1;
''');
  }
}
