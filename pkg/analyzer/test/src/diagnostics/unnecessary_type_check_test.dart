// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryTypeCheckFalseTest);
    defineReflectiveTests(UnnecessaryTypeCheckFalseWithNnbdTest);
    defineReflectiveTests(UnnecessaryTypeCheckTrueTest);
    defineReflectiveTests(UnnecessaryTypeCheckTrueWithNnbdTest);
  });
}

@reflectiveTest
class UnnecessaryTypeCheckFalseTest extends DriverResolutionTest {
  test_null_not_Null() async {
    await assertErrorsInCode(r'''
var b = null is! Null;
''', [
      error(HintCode.UNNECESSARY_TYPE_CHECK_FALSE, 8, 13),
    ]);
  }

  test_type_not_dynamic() async {
    await assertErrorsInCode(r'''
void f<T>(T a) {
  a is! dynamic;
}
''', [
      error(HintCode.UNNECESSARY_TYPE_CHECK_FALSE, 19, 13),
    ]);
  }

  test_type_not_object() async {
    await assertErrorsInCode(r'''
void f<T>(T a) {
  a is! Object;
}
''', [
      error(HintCode.UNNECESSARY_TYPE_CHECK_FALSE, 19, 12),
    ]);
  }
}

@reflectiveTest
class UnnecessaryTypeCheckFalseWithNnbdTest
    extends UnnecessaryTypeCheckFalseTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  @override
  test_type_not_object() async {
    await assertNoErrorsInCode(r'''
void f<T>(T a) {
  a is! Object;
}
''');
  }

  test_type_not_objectQuestion() async {
    await assertErrorsInCode(r'''
void f<T>(T a) {
  a is! Object?;
}
''', [
      error(HintCode.UNNECESSARY_TYPE_CHECK_FALSE, 19, 13),
    ]);
  }
}

@reflectiveTest
class UnnecessaryTypeCheckTrueTest extends DriverResolutionTest {
  test_null_is_Null() async {
    await assertErrorsInCode(r'''
var b = null is Null;
''', [
      error(HintCode.UNNECESSARY_TYPE_CHECK_TRUE, 8, 12),
    ]);
  }

  test_type_is_dynamic() async {
    await assertErrorsInCode(r'''
void f<T>(T a) {
  a is dynamic;
}
''', [
      error(HintCode.UNNECESSARY_TYPE_CHECK_TRUE, 19, 12),
    ]);
  }

  test_type_is_object() async {
    await assertErrorsInCode(r'''
void f<T>(T a) {
  a is Object;
}
''', [
      error(HintCode.UNNECESSARY_TYPE_CHECK_TRUE, 19, 11),
    ]);
  }
}

@reflectiveTest
class UnnecessaryTypeCheckTrueWithNnbdTest
    extends UnnecessaryTypeCheckTrueTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  @override
  test_type_is_object() async {
    await assertNoErrorsInCode(r'''
void f<T>(T a) {
  a is Object;
}
''');
  }

  test_type_is_objectQuestion() async {
    await assertErrorsInCode(r'''
void f<T>(T a) {
  a is Object?;
}
''', [
      error(HintCode.UNNECESSARY_TYPE_CHECK_TRUE, 19, 12),
    ]);
  }
}
