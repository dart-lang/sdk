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
    defineReflectiveTests(NullableTypeInCatchClauseTest);
  });
}

@reflectiveTest
class NullableTypeInCatchClauseTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  test_noOnClause() async {
    await assertNoErrorsInCode('''
f() {
  try {
  } catch (e) {
  }
}
''');
  }

  test_on_class_nonNullable() async {
    await assertErrorsInCode('''
class A {}
f() {
  try {
  } on A catch (e) {
  }
}
''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 41, 1),
    ]);
  }

  test_on_class_nullable() async {
    await assertErrorsInCode('''
class A {}
f() {
  try {
  } on A? {
  }
}
''', [
      error(CompileTimeErrorCode.NULLABLE_TYPE_IN_CATCH_CLAUSE, 32, 2),
    ]);
  }

  test_on_typeParameter() async {
    await assertErrorsInCode('''
class A<B> {
  m() {
    try {
    } on B {
    }
  }
}
''', [
      error(CompileTimeErrorCode.NULLABLE_TYPE_IN_CATCH_CLAUSE, 40, 1),
    ]);
  }

  test_on_typeParameter_nonNullable() async {
    await assertNoErrorsInCode('''
class A<B extends Object> {
  m() {
    try {
    } on B {
    }
  }
}
''');
  }

  test_optOut() async {
    await assertNoErrorsInCode('''
// @dart = 2.7

void f() {
  try {
  } on dynamic {
  }
}
''');
  }
}
