// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';
import 'package:analyzer/src/error/codes.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToFinalTest);
    defineReflectiveTests(AssignmentToFinalWithNnbdTest);
  });
}

@reflectiveTest
class AssignmentToFinalTest extends DriverResolutionTest {
  test_instanceVariable() async {
    await assertErrorsInCode('''
class A {
  final v = 0;
}
f() {
  A a = new A();
  a.v = 1;
}''', [
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL, 54, 1),
    ]);
  }

  test_instanceVariable_plusEq() async {
    await assertErrorsInCode('''
class A {
  final v = 0;
}
f() {
  A a = new A();
  a.v += 1;
}''', [
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL, 54, 1),
    ]);
  }
}

@reflectiveTest
class AssignmentToFinalWithNnbdTest extends AssignmentToFinalTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  @failingTest
  test_field_late() async {
    await assertNoErrorsInCode('''
class A {
  final a;
  void m() {
    a = 1;
  }
}
''');
  }

  @failingTest
  test_localVariable_late() async {
    await assertNoErrorsInCode('''
void f() {
  final a;
  a = 1;
}
''');
  }
}
