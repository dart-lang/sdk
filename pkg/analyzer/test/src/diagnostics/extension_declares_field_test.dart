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
    defineReflectiveTests(ExtensionDeclaresFieldTest);
  });
}

@reflectiveTest
class ExtensionDeclaresFieldTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_multiple() {
    assertErrorsInCode('''
extension E on String {
  String one, two, three;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 33, 3),
      error(CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 38, 3),
      error(CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 43, 5)
    ]);
  }

  test_none() {
    assertNoErrorsInCode('''
extension E on String {}
''');
  }

  test_one() {
    assertErrorsInCode('''
extension E on String {
  String s;
}
''', [error(CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 33, 1)]);
  }

  test_static() {
    assertNoErrorsInCode('''
extension E on String {
  static String EMPTY = '';
}
''');
  }
}
