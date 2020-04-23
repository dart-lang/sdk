// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidReferenceToThisTest);
    defineReflectiveTests(InvalidReferenceToThisTest_NNBD);
  });
}

@reflectiveTest
class InvalidReferenceToThisTest extends DriverResolutionTest {
  test_constructor_valid() async {
    await assertErrorsInCode(r'''
class A {
  A() {
    var v = this;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 1),
    ]);
  }

  test_factoryConstructor() async {
    await assertErrorsInCode(r'''
class A {
  factory A() { return this; }
}
''', [
      error(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, 33, 4),
    ]);
  }

  test_instanceMethod_valid() async {
    await assertErrorsInCode(r'''
class A {
  m() {
    var v = this;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 1),
    ]);
  }

  test_instanceVariableInitializer_inConstructor() async {
    await assertErrorsInCode(r'''
class A {
  var f;
  A() : f = this;
}
''', [
      error(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, 31, 4),
    ]);
  }

  test_instanceVariableInitializer_inDeclaration() async {
    await assertErrorsInCode(r'''
class A {
  var f = this;
}
''', [
      error(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, 20, 4),
    ]);
  }

  test_staticMethod() async {
    await assertErrorsInCode(r'''
class A {
  static m() { return this; }
}
''', [
      error(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, 32, 4),
    ]);
  }

  test_staticVariableInitializer() async {
    await assertErrorsInCode(r'''
class A {
  static A f = this;
}
''', [
      error(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, 25, 4),
    ]);
  }

  test_superInitializer() async {
    await assertErrorsInCode(r'''
class A {
  A(var x) {}
}
class B extends A {
  B() : super(this);
}
''', [
      error(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, 60, 4),
    ]);
  }

  test_topLevelFunction() async {
    await assertErrorsInCode('''
f() { return this; }
''', [
      error(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, 13, 4),
    ]);
  }

  test_variableInitializer() async {
    await assertErrorsInCode('''
int x = this;
''', [
      error(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, 8, 4),
    ]);
  }

  test_variableInitializer_inMethod_notLate() async {
    await assertErrorsInCode(r'''
class A {
  f() {
    var r = this;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 1),
    ]);
  }
}

@reflectiveTest
class InvalidReferenceToThisTest_NNBD extends InvalidReferenceToThisTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  test_instanceVariableInitializer_inDeclaration_late() async {
    await assertNoErrorsInCode(r'''
class A {
  late var f = this;
}
''');
  }

  test_mixinVariableInitializer_inDeclaration_late() async {
    await assertNoErrorsInCode(r'''
mixin A {
  late var f = this;
}
''');
  }

  test_variableInitializer_late() async {
    await assertErrorsInCode('''
late var x = this;
''', [
      error(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, 13, 4),
    ]);
  }
}
