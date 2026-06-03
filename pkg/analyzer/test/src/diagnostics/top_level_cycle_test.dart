// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelCycleTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TopLevelCycleTest extends PubPackageResolutionTest {
  test_cycle_fields() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static final x = y + 1;
//             ^
// [diag.topLevelCycle] The type of 'x' can't be inferred because it depends on itself through the cycle: x, y.
  static final y = x + 1;
//             ^
// [diag.topLevelCycle] The type of 'y' can't be inferred because it depends on itself through the cycle: x, y.
}
''');
  }

  test_cycle_fields_chain() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static final a = b.c;
//             ^
// [diag.topLevelCycle] The type of 'a' can't be inferred because it depends on itself through the cycle: a, c.
  static final b = A();
  final c = a;
//      ^
// [diag.topLevelCycle] The type of 'c' can't be inferred because it depends on itself through the cycle: a, c.
}
''');
  }

  test_cycle_topLevelVariables() async {
    await resolveTestCodeWithDiagnostics(r'''
var x = y + 1;
//  ^
// [diag.topLevelCycle] The type of 'x' can't be inferred because it depends on itself through the cycle: x, y.
var y = x + 1;
//  ^
// [diag.topLevelCycle] The type of 'y' can't be inferred because it depends on itself through the cycle: x, y.
''');
  }

  test_singleVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
var x = x;
//  ^
// [diag.topLevelCycle] The type of 'x' can't be inferred because it depends on itself through the cycle: x.
''');
  }

  test_singleVariable_fromList() async {
    await resolveTestCodeWithDiagnostics(r'''
var elems = [
//  ^^^^^
// [diag.topLevelCycle] The type of 'elems' can't be inferred because it depends on itself through the cycle: elems.
  [
    1, elems, 3,
  ],
];
''');
  }
}
