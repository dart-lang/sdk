// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseOfVoidResultTest);
    defineReflectiveTests(UseOfVoidResultTest_NonNullable);
  });
}

@reflectiveTest
class UseOfVoidResultTest extends DriverResolutionTest {
  test_implicitReturnValue() async {
    await assertNoErrorsInCode(r'''
f() {}
class A {
  n() {
    var a = f();
  }
}
''');
  }

  test_nonVoidReturnValue() async {
    await assertNoErrorsInCode(r'''
int f() => 1;
g() {
  var a = f();
}
''');
  }
}

@reflectiveTest
class UseOfVoidResultTest_NonNullable extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_bang_nonVoid() async {
    await assertNoErrorsInCode(r'''
int? f() => 1;
g() {
  f()!;
}
''');
  }

  test_bang_void() async {
    await assertErrorsInCode(r'''
void f() => 1;
g() {
  f()!;
}
''', [ExpectedError(StaticWarningCode.USE_OF_VOID_RESULT, 23, 4)]);
  }
}
