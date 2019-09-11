// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';
import 'undefined_getter_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSetterTest);
    defineReflectiveTests(UndefinedSetterWithExtensionMethodsTest);
  });
}

@reflectiveTest
class UndefinedSetterTest extends DriverResolutionTest {
  test_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  set b(x) {}
}
f(var a) {
  if (a is A) {
    a.b = 0;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 80, 1),
    ]);
  }

  test_inType() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if(a is A) {
    a.m = 0;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 43, 1),
    ]);
  }

  test_static_definedInSuperclass() async {
    await assertErrorsInCode('''
class S {
  static set s(int i) {}
}
class C extends S {}
f(var p) {
  f(C.s = 1);
}''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 75, 1),
    ]);
  }
}

@reflectiveTest
class UndefinedSetterWithExtensionMethodsTest extends UndefinedGetterTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_withExtension() async {
    await assertErrorsInCode(r'''
class C {}

extension E on C {}

f(C c) {
  c.a = 1;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 46, 1),
    ]);
  }
}
