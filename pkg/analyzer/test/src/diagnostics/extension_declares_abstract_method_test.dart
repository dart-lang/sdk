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
    defineReflectiveTests(ExtensionDeclaresAbstractMethodTest);
  });
}

@reflectiveTest
class ExtensionDeclaresAbstractMethodTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_getter() {
    assertErrorsInCode('''
extension E on String {
  bool get isPalindrome;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_DECLARES_ABSTRACT_METHOD, 35, 12),
    ]);
  }

  test_method() {
    assertErrorsInCode('''
extension E on String {
  String reversed();
}
''', [
      error(CompileTimeErrorCode.EXTENSION_DECLARES_ABSTRACT_METHOD, 33, 8),
    ]);
  }

  test_none() {
    assertNoErrorsInCode('''
extension E on String {}
''');
  }

  test_operator() {
    assertErrorsInCode('''
extension E on String {
  String operator -(String otherString);
}
''', [
      error(CompileTimeErrorCode.EXTENSION_DECLARES_ABSTRACT_METHOD, 42, 1),
    ]);
  }

  test_setter() {
    assertErrorsInCode('''
extension E on String {
  set length(int newLength);
}
''', [
      error(CompileTimeErrorCode.EXTENSION_DECLARES_ABSTRACT_METHOD, 30, 6),
    ]);
  }
}
