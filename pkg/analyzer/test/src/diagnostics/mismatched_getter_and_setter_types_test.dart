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
    defineReflectiveTests(MismatchedGetterAndSetterTypesTest);
    defineReflectiveTests(
        MismatchedGetterAndSetterTypesWithExtensionMethodsTest);
    defineReflectiveTests(MismatchedGetterAndSetterTypesWithNNBDTest);
  });
}

@reflectiveTest
class MismatchedGetterAndSetterTypesTest extends DriverResolutionTest {
  test_topLevel() async {
    await assertErrorsInCode('''
int get g { return 0; }
set g(String v) {}''', [
      error(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES, 0, 23),
    ]);
  }
}

@reflectiveTest
class MismatchedGetterAndSetterTypesWithExtensionMethodsTest
    extends MismatchedGetterAndSetterTypesTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_extensionMembers_instance() async {
    await assertErrorsInCode('''
extension E on Object {
  int get g { return 0; }
  set g(String v) {}
}
''', [
      error(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES, 34, 1),
    ]);
  }

  test_extensionMembers_static() async {
    await assertErrorsInCode('''
extension E on Object {
  static int get g { return 0; }
  static set g(String v) {}
}
''', [
      error(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES, 41, 1),
    ]);
  }
}

@reflectiveTest
class MismatchedGetterAndSetterTypesWithNNBDTest
    extends MismatchedGetterAndSetterTypesTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  test_classMembers_instance() async {
    await assertErrorsInCode('''
class C {
  num get g { return 0; }
  set g(int v) {}
}
''', [
      error(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES, 20, 1),
    ]);
  }

  @failingTest
  test_classMembers_static() async {
    await assertErrorsInCode('''
class C {
  static num get g { return 0; }
  static set g(int v) {}
}
''', [
      error(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES, 12, 30),
    ]);
  }
}
