// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
    await assertErrorsInCode(
      '''
void f(List<double> list) {
  switch (list) {
    case [double.nan]:
  }
}
''',
      [error(WarningCode.unnecessaryNanComparisonFalse, 56, 10)],
    );
  }

  test_equal() async {
    await assertErrorsInCode(
      '''
void f(double d) {
  d == double.nan;
}
''',
      [error(WarningCode.unnecessaryNanComparisonFalse, 23, 13)],
    );
  }

  test_equal_nanFirst() async {
    await assertErrorsInCode(
      '''
void f(double d) {
  double.nan == d;
}
''',
      [error(WarningCode.unnecessaryNanComparisonFalse, 21, 13)],
    );
  }

  test_notEqual() async {
    await assertErrorsInCode(
      '''
void f(double d) {
  d != double.nan;
}
''',
      [error(WarningCode.unnecessaryNanComparisonTrue, 23, 13)],
    );
  }

  test_notEqual_nanFirst() async {
    await assertErrorsInCode(
      '''
void f(double d) {
  double.nan != d;
}
''',
      [error(WarningCode.unnecessaryNanComparisonTrue, 21, 13)],
    );
  }
}
