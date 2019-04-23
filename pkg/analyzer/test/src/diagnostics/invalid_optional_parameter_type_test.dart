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
    defineReflectiveTests(MissingDefaultValueForParameterTest);
  });
}

@reflectiveTest
class MissingDefaultValueForParameterTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  test_typeParameter_potentiallyNonNullable_named_optional_noDefault() async {
    await assertErrorsInCode('''
class A<T extends Object?> {
  void f({T a}) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 41, 1),
    ]);
  }

  test_typeParameter_potentiallyNonNullable_positional_optional_noDefault() async {
    await assertErrorsInCode('''
class A<T extends Object?> {
  void f([T a]) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 41, 1),
    ]);
  }
}
