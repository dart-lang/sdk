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
    defineReflectiveTests(DefaultListConstructorMismatch);
  });
}

@reflectiveTest
class DefaultListConstructorMismatch extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  test_inferredType() async {
    await assertErrorsInCode('''
class C {}
List<C> v = List(5);
''', [
      error(CompileTimeErrorCode.DEFAULT_LIST_CONSTRUCTOR_MISMATCH, 23, 4),
    ]);
  }

  test_nonNullableType() async {
    await assertErrorsInCode('''
var l = new List<int>(3);
''', [
      error(CompileTimeErrorCode.DEFAULT_LIST_CONSTRUCTOR_MISMATCH, 12, 9),
    ]);
  }

  test_nullableType() async {
    await assertNoErrorsInCode('''
var l = new List<String?>(3);
''');
  }

  test_optOut() async {
    await assertNoErrorsInCode('''
// @dart = 2.2
var l = new List<int>(3);
''');
  }

  test_typeParameter() async {
    await assertErrorsInCode('''
class C<T> {
  var l = new List<T>(3);
}
''', [
      error(CompileTimeErrorCode.DEFAULT_LIST_CONSTRUCTOR_MISMATCH, 27, 7),
    ]);
  }
}
