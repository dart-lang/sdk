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
    defineReflectiveTests(MixinOfNonClassTest);
    defineReflectiveTests(MixinOfNonClassWithNnbdTest);
  });
}

@reflectiveTest
class MixinOfNonClassTest extends DriverResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
int A = 7;
class B extends Object with A {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 39, 1),
    ]);
  }

  test_enum() async {
    await assertErrorsInCode(r'''
enum E { ONE }
class A extends Object with E {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 43, 1),
    ]);
  }

  @failingTest
  test_non_class() async {
    // TODO(brianwilkerson) Compare with MIXIN_WITH_NON_CLASS_SUPERCLASS.
    // TODO(brianwilkerson) Fix the offset and length.
    await assertErrorsInCode(r'''
var A;
class B extends Object mixin A {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 0, 0),
    ]);
  }

  test_typeAlias() async {
    await assertErrorsInCode(r'''
class A {}
int B = 7;
class C = A with B;
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 39, 1),
    ]);
  }
}

@reflectiveTest
class MixinOfNonClassWithNnbdTest extends MixinOfNonClassTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  test_Never() async {
    await assertErrorsInCode('''
class A with Never {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 13, 5),
    ]);
  }
}
