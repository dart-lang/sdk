// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfNullValueTest);
  });
}

@reflectiveTest
class InvalidUseOfNullValueTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  test_as() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x as int; // ignore: unnecessary_cast
}
''');
  }

  test_await() async {
    await assertNoErrorsInCode(r'''
m() async {
  Null x;
  await x;
}
''');
  }

  test_cascade() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x..toString;
}
''');
  }

  test_eq() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x == null;
}
''');
  }

  test_forLoop() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  for (var y in x) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 27, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE, 32, 1),
      error(StaticWarningCode.INVALID_USE_OF_NULL_VALUE, 32, 1),
    ]);
  }

  test_is() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x is int;
}
''');
  }

  test_member() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x.runtimeType;
}
''');
  }

  test_method() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x.toString();
}
''');
  }

  test_notEq() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x != null;
}
''');
  }

  test_ternary_lhs() async {
    await assertNoErrorsInCode(r'''
m(bool cond) {
  Null x;
  cond ? x : 1;
}
''');
  }

  test_ternary_rhs() async {
    await assertNoErrorsInCode(r'''
m(bool cond) {
  Null x;
  cond ? 0 : x;
}
''');
  }
}
