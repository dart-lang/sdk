// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelCycleTest);
  });
}

@reflectiveTest
class TopLevelCycleTest extends PubPackageResolutionTest {
  test_cycle_fields() async {
    await assertErrorsInCode(
      r'''
class A {
  static final x = y + 1;
  static final y = x + 1;
}
''',
      [error(diag.topLevelCycle, 25, 1), error(diag.topLevelCycle, 51, 1)],
    );
  }

  test_cycle_fields_chain() async {
    await assertErrorsInCode(
      r'''
class A {
  static final a = b.c;
  static final b = A();
  final c = a;
}
''',
      [error(diag.topLevelCycle, 25, 1), error(diag.topLevelCycle, 66, 1)],
    );
  }

  test_cycle_topLevelVariables() async {
    await assertErrorsInCode(
      r'''
var x = y + 1;
var y = x + 1;
''',
      [error(diag.topLevelCycle, 4, 1), error(diag.topLevelCycle, 19, 1)],
    );
  }

  test_singleVariable() async {
    await assertErrorsInCode(
      r'''
var x = x;
''',
      [error(diag.topLevelCycle, 4, 1)],
    );
  }

  test_singleVariable_fromList() async {
    await assertErrorsInCode(
      r'''
var elems = [
  [
    1, elems, 3,
  ],
];
''',
      [error(diag.topLevelCycle, 4, 5)],
    );
  }
}
