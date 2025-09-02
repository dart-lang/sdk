// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalTypeBoolNumStringTest);
  });
}

@reflectiveTest
class ConstEvalTypeBoolNumStringTest extends PubPackageResolutionTest {
  test_equal_double_object_language219() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
const a = 0.1;
const b = a == Object();
''');
  }

  test_equal_userClass_int_language219() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
class A {
  const A();
}

const a = A();
const b = a == 0;
''',
      [error(CompileTimeErrorCode.constEvalTypeBoolNumString, 67, 6)],
    );
  }

  test_notEqual_double_object_language219() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
const a = 0.1;
const b = a != Object();
''');
  }

  test_notEqual_userClass_int_language219() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
class A {
  const A();
}

const a = A();
const b = a != 0;
''',
      [error(CompileTimeErrorCode.constEvalTypeBoolNumString, 67, 6)],
    );
  }

  test_stringInterpolation_list() async {
    await assertErrorsInCode(
      r'''
const x = '${const [2]}';
''',
      [error(CompileTimeErrorCode.constEvalTypeBoolNumString, 11, 12)],
    );
  }
}
