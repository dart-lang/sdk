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
    defineReflectiveTests(ExtensionDeclaresConstructorTest);
  });
}

@reflectiveTest
class ExtensionDeclaresConstructorTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_named() {
    assertErrorsInCode('''
extension E on String {
  E.named() : super();
}
''', [error(CompileTimeErrorCode.EXTENSION_DECLARES_CONSTRUCTOR, 28, 5)]);
  }

  test_none() {
    assertNoErrorsInCode('''
extension E on String {}
''');
  }

  test_unnamed() {
    assertErrorsInCode('''
extension E on String {
  E() : super();
}
''', [error(CompileTimeErrorCode.EXTENSION_DECLARES_CONSTRUCTOR, 26, 1)]);
  }
}
