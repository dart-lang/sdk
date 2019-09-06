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
    defineReflectiveTests(InstanceAccessToStaticMemberTest);
    defineReflectiveTests(InstanceAccessToStaticMemberWithExtensionMethodsTest);
  });
}

@reflectiveTest
class InstanceAccessToStaticMemberTest extends DriverResolutionTest {}

@reflectiveTest
class InstanceAccessToStaticMemberWithExtensionMethodsTest
    extends InstanceAccessToStaticMemberTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_getter() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static int get a => 0;
}

C g(C c) => null;
f(C c) {
  g(c).a;
}
''', [
      error(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 93, 1),
    ]);
    assertElement(
      findNode.simple('a;'),
      findElement.getter('a'),
    );
  }

  test_method() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static void a() {}
}

f(C c) {
  c.a();
}
''', [
      error(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 68, 1),
    ]);
    assertElement(
      findNode.methodInvocation('a();'),
      findElement.method('a'),
    );
  }

  test_setter() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static set a(v) {}
}

f(C c) {
  c.a = 2;
}
''', [
      error(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 68, 1),
    ]);
    assertElement(
      findNode.simple('a = 2;'),
      findElement.setter('a'),
    );
  }
}
