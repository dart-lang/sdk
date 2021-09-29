// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VoidChecksTest);
  });
}

@reflectiveTest
class VoidChecksTest extends LintRuleTest {
  @override
  String get lintRule => 'void_checks';

  test_extraPositionalArgument() async {
    // Produces an extra_positional_arguments diagnostic.
    await assertNoLint(r'''
missing_parameter_for_argument() {
  void foo() {}
  foo(0);
}
''');
  }

  test_returnOfInvalidType() async {
    // Produces a return_of_invalid_type diagnostic.
    await assertNoLint(r'''
void bug2813() {
  return 1;
}
''');
  }
}
