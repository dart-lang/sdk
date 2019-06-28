// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalVariableResolutionTest);
    defineReflectiveTests(LocalVariableResolutionTest_NNBD);
  });
}

@reflectiveTest
class LocalVariableResolutionTest extends DriverResolutionTest {
  test_element() async {
    await assertNoErrorsInCode(r'''
void f() {
  int x = 0;
}
''');

    var x = findElement.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_const() async {
    await assertNoErrorsInCode(r'''
void f() {
  const int x = 0;
}
''');

    var x = findElement.localVar('x');
    expect(x.isConst, isTrue);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }

  test_element_final() async {
    await assertNoErrorsInCode(r'''
void f() {
  final int x = 0;
}
''');

    var x = findElement.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isTrue);
    expect(x.isLate, isFalse);
    expect(x.isStatic, isFalse);
  }
}

@reflectiveTest
class LocalVariableResolutionTest_NNBD extends LocalVariableResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_element_late() async {
    await assertNoErrorsInCode(r'''
void f() {
  late int x = 0;
}
''');

    var x = findElement.localVar('x');
    expect(x.isConst, isFalse);
    expect(x.isFinal, isFalse);
    expect(x.isLate, isTrue);
    expect(x.isStatic, isFalse);
  }
}
