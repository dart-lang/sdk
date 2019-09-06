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
    defineReflectiveTests(UndefinedMethodTest);
    defineReflectiveTests(UndefinedMethodWithExtensionMethodsTest);
  });
}

@reflectiveTest
class UndefinedMethodTest extends DriverResolutionTest {}

@reflectiveTest
class UndefinedMethodWithExtensionMethodsTest extends UndefinedMethodTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_withExtension() async {
    await assertErrorsInCode(r'''
class C {}

extension E on C {
  void a() {}
}

f(C c) {
  c.c();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 61, 1),
    ]);
  }

  test_definedInPrivateExtension() async {
    newFile('/test/lib/lib.dart', content: '''
class B {}

extension _ on B {
  void a() {}
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';

f(B b) {
  b.a();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 33, 1),
    ]);
  }

  test_definedInUnnamedExtension() async {
    newFile('/test/lib/lib.dart', content: '''
class C {}

extension on C {
  void a() {}
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';

f(C c) {
  c.a();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 33, 1),
    ]);
  }
}
