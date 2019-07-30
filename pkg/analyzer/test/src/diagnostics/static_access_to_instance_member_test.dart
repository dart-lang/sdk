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
//    defineReflectiveTests(StaticAccessToInstanceMemberTest);
    defineReflectiveTests(StaticAccessToInstanceMemberWithExtensionMethodsTest);
  });
}

@reflectiveTest
class StaticAccessToInstanceMemberTest extends DriverResolutionTest {}

@reflectiveTest
class StaticAccessToInstanceMemberWithExtensionMethodsTest
    extends StaticAccessToInstanceMemberTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_getter() async {
    assertErrorsInCode('''
extension E on int {
  int get g => 0;
}
f() {
  E.g;
}
''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 51, 1),
    ]);
  }

  test_method() async {
    assertErrorsInCode('''
extension E on int {
  void m() {}
}
f() {
  E.m();
}
''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 47, 1),
    ]);
  }

  test_setter() async {
    assertErrorsInCode('''
extension E on int {
  void set s(int i) {}
}
f() {
  E.s = 2;
}
''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 56, 1),
    ]);
  }
}
