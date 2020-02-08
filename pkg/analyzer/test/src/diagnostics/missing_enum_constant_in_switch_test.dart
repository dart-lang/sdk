// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingEnumConstantInSwitchTest);
    defineReflectiveTests(MissingEnumConstantInSwitchWithNnbdTest);
  });
}

@reflectiveTest
class MissingEnumConstantInSwitchTest extends DriverResolutionTest {
  test_default() async {
    await assertNoErrorsInCode('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case E.one:
      break;
    default:
      break;
  }
}
''');
  }

  test_first() async {
    await assertErrorsInCode('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case E.two:
    case E.three:
      break;
  }
}
''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 44, 10),
    ]);
  }

  test_last() async {
    await assertErrorsInCode('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case E.one:
    case E.two:
      break;
  }
}
''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 44, 10),
    ]);
  }

  test_middle() async {
    await assertErrorsInCode('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case E.one:
    case E.three:
      break;
  }
}
''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 44, 10),
    ]);
  }
}

@reflectiveTest
class MissingEnumConstantInSwitchWithNnbdTest
    extends MissingEnumConstantInSwitchTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.7.0', additionalFeatures: [Feature.non_nullable]);

  test_nullable() async {
    await assertErrorsInCode('''
enum E { one, two }

void f(E? e) {
  switch (e) {
    case E.one:
    case E.two:
      break;
  }
}
''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 38, 10),
    ]);
  }

  test_nullable_default() async {
    await assertNoErrorsInCode('''
enum E { one, two }

void f(E? e) {
  switch (e) {
    case E.one:
      break;
    default:
      break;
  }
}
''');
  }

  test_nullable_null() async {
    await assertNoErrorsInCode('''
enum E { one, two }

void f(E? e) {
  switch (e) {
    case E.one:
      break;
    case E.two:
      break;
    case null:
      break;
  }
}
''');
  }
}
