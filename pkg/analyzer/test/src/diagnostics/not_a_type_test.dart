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
    defineReflectiveTests(NotATypeTest);
    defineReflectiveTests(NotATypeWithExtensionMethodsTest);
  });
}

@reflectiveTest
class NotATypeTest extends DriverResolutionTest {
  test_function() async {
    await assertErrorsInCode('''
f() {}
main() {
  f v = null;
}''', [
      error(StaticWarningCode.NOT_A_TYPE, 18, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 20, 1),
    ]);
  }
}

@reflectiveTest
class NotATypeWithExtensionMethodsTest extends NotATypeTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_extension() async {
    await assertErrorsInCode('''
extension E on int {}
E a;
''', [error(StaticWarningCode.NOT_A_TYPE, 22, 1)]);
    assertTypeDynamic(findNode.simple('E a;'));
  }
}
