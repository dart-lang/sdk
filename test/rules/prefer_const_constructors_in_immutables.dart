// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConstConstructorsInImmutablesTest);
  });
}

@reflectiveTest
class PreferConstConstructorsInImmutablesTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_const_constructors_in_immutables';

  test_returnOfInvalidType() async {
    // Produces an return_of_invalid_type diagnostic.
    await assertNoLint(r'''
class F {
  factory F.fc() => null;
}
''');
  }
}
