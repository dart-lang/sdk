// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNanComparisonTest);
  });
}

@reflectiveTest
class UnnecessaryNanComparisonTest extends PubPackageResolutionTest {
  test_constantPattern() async {
    await assertErrorsInCode('''
void f(List<double> list) {
  switch (list) {
    case [double.nan]:
  }
}
''', [
      error(WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE, 56, 10),
    ]);
  }

  test_equal() async {
    await assertErrorsInCode('''
void f(double d) {
  d == double.nan;
}
''', [
      error(WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE, 23, 13),
    ]);
  }

  test_equal_nanFirst() async {
    await assertErrorsInCode('''
void f(double d) {
  double.nan == d;
}
''', [
      error(WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE, 21, 13),
    ]);
  }

  test_notEqual() async {
    await assertErrorsInCode('''
void f(double d) {
  d != double.nan;
}
''', [
      error(WarningCode.UNNECESSARY_NAN_COMPARISON_TRUE, 23, 13),
    ]);
  }

  test_notEqual_nanFirst() async {
    await assertErrorsInCode('''
void f(double d) {
  double.nan != d;
}
''', [
      error(WarningCode.UNNECESSARY_NAN_COMPARISON_TRUE, 21, 13),
    ]);
  }
}
