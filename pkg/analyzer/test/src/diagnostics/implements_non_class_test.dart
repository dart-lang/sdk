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
//    defineReflectiveTests(ImplementsNonClassTest);
    defineReflectiveTests(ImplementsNonClassWithNnbdTest);
  });
}

@reflectiveTest
class ImplementsNonClassTest extends DriverResolutionTest {}

@reflectiveTest
class ImplementsNonClassWithNnbdTest extends ImplementsNonClassTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  test_Never() async {
    await assertErrorsInCode('''
class A implements Never {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, 19, 5),
    ]);
  }
}
