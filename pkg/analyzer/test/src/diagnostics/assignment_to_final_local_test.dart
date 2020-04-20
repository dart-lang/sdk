// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToFinalLocalTest);
    defineReflectiveTests(AssignmentToFinalLocalWithNnbdTest);
  });
}

@reflectiveTest
class AssignmentToFinalLocalTest extends DriverResolutionTest {
  test_localVariable() async {
    await assertErrorsInCode('''
f() {
  final x = 0;
  x = 1;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL, 23, 1),
    ]);
  }

  test_localVariable_inForEach() async {
    await assertErrorsInCode('''
f() {
  final x = 0;
  for (x in <int>[1, 2]) {
    print(x);
  }
}''', [
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL, 28, 1),
    ]);
  }

  test_localVariable_plusEq() async {
    await assertErrorsInCode('''
f() {
  final x = 0;
  x += 1;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL, 23, 1),
    ]);
  }

  test_parameter() async {
    await assertErrorsInCode('''
f(final x) {
  x = 1;
}''', [
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL, 15, 1),
    ]);
  }

  test_postfixMinusMinus() async {
    await assertErrorsInCode('''
f() {
  final x = 0;
  x--;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL, 23, 1),
    ]);
  }

  test_postfixPlusPlus() async {
    await assertErrorsInCode('''
f() {
  final x = 0;
  x++;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL, 23, 1),
    ]);
  }

  test_prefixMinusMinus() async {
    await assertErrorsInCode('''
f() {
  final x = 0;
  --x;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL, 25, 1),
    ]);
  }

  test_prefixPlusPlus() async {
    await assertErrorsInCode('''
f() {
  final x = 0;
  ++x;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL, 25, 1),
    ]);
  }

  test_suffixMinusMinus() async {
    await assertErrorsInCode('''
f() {
  final x = 0;
  x--;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL, 23, 1),
    ]);
  }

  test_suffixPlusPlus() async {
    await assertErrorsInCode('''
f() {
  final x = 0;
  x++;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL, 23, 1),
    ]);
  }

  test_topLevelVariable() async {
    await assertErrorsInCode('''
final x = 0;
f() { x = 1; }''', [
      error(StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL, 19, 1),
    ]);
  }
}

@reflectiveTest
class AssignmentToFinalLocalWithNnbdTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  test_localVariable_late() async {
    await assertNoErrorsInCode('''
void f() {
  late final int a;
  a = 1;
  a;
}
''');
  }

  test_topLevelVariable_late() async {
    await assertNoErrorsInCode('''
late final int a;
late final int b = 0;
void f() {
  a = 1;
  b = 1;
}
''');
  }
}
