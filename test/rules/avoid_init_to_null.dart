// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidInitToNullTest);
  });
}

@reflectiveTest
class AvoidInitToNullTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_init_to_null';

  test_invalidAssignment_field() async {
    // Produces an invalid_assignment compilation error.
    await assertNoLint(r'''
class X {
  int x = null;
}
''');
  }

  test_invalidAssignment_namedParameter() async {
    // Produces an invalid_assignment compilation error.
    await assertNoLint(r'''
class X {
  X({int a: null});
}
''');
  }

  test_invalidAssignment_namedParameter_fieldFormal() async {
    // Produces an invalid_assignment compilation error.
    await assertNoLint(r'''
class X {
  int x;
  X({this.x: null});
}
''');
  }

  test_invalidAssignment_topLevelVariable() async {
    // Produces an invalid_assignment compilation error.
    await assertNoLint(r'''
int i = null;
''');
  }

  test_nullable_topLevelVariable() async {
    await assertLint(r'''
int? ii = null;
''');
  }
}
