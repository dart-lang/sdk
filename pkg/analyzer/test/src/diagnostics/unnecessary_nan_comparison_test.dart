// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNanComparisonTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnnecessaryNanComparisonTest extends PubPackageResolutionTest {
  test_constantPattern() async {
    await resolveTestCodeWithDiagnostics('''
void f(List<double> list) {
  switch (list) {
    case [double.nan]:
//        ^^^^^^^^^^
// [diag.unnecessaryNanComparisonFalse] A double can't equal 'double.nan', so the condition is always 'false'.
  }
}
''');
  }

  test_equal() async {
    await resolveTestCodeWithDiagnostics('''
void f(double d) {
  d == double.nan;
//  ^^^^^^^^^^^^^
// [diag.unnecessaryNanComparisonFalse] A double can't equal 'double.nan', so the condition is always 'false'.
}
''');
  }

  test_equal_nanFirst() async {
    await resolveTestCodeWithDiagnostics('''
void f(double d) {
  double.nan == d;
//^^^^^^^^^^^^^
// [diag.unnecessaryNanComparisonFalse] A double can't equal 'double.nan', so the condition is always 'false'.
}
''');
  }

  test_notEqual() async {
    await resolveTestCodeWithDiagnostics('''
void f(double d) {
  d != double.nan;
//  ^^^^^^^^^^^^^
// [diag.unnecessaryNanComparisonTrue] A double can't equal 'double.nan', so the condition is always 'true'.
}
''');
  }

  test_notEqual_nanFirst() async {
    await resolveTestCodeWithDiagnostics('''
void f(double d) {
  double.nan != d;
//^^^^^^^^^^^^^
// [diag.unnecessaryNanComparisonTrue] A double can't equal 'double.nan', so the condition is always 'true'.
}
''');
  }
}
