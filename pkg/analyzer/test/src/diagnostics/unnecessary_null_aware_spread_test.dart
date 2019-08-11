// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullAwareSpreadTest);
  });
}

@reflectiveTest
class UnnecessaryNullAwareSpreadTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_local_nonNullableSpread_nullableType() async {
    await assertNoErrorsInCode('''
f() {
  List x = [];
  [...x];
}
''');
  }

  test_local_nullableSpread_nonNullableType() async {
    await assertErrorsInCode('''
f() {
  List x = [];
  [...?x];
}
''', [
      error(StaticWarningCode.UNNECESSARY_NULL_AWARE_SPREAD, 24, 4),
    ]);
  }

  test_local_nullableSpread_nullableType() async {
    await assertNoErrorsInCode('''
f() {
  List? x;
  [...?x];
}
''');
  }
}
