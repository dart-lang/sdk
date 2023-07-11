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
  test_equal_double_object() async {
    await assertNoErrorsInCode(r'''
const a = 0.1;
const b = a == Object();
''');
  }

  test_equal_double_object_language219() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
const a = 0.1;
const b = a == Object();
''');
  }

  test_equal_int_object() async {
    await assertNoErrorsInCode(r'''
const a = 0;
const b = a == Object();
''');
  }

  test_equal_int_userClass() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

const a = 0;
const b = a == A();
''');
  }

  test_equal_null_object() async {
    await assertNoErrorsInCode(r'''
const a = null;
const b = a == Object();
''');
  }

  test_equal_string_object() async {
    await assertNoErrorsInCode(r'''
const a = 'foo';
const b = a == Object();
''');
  }

  test_equal_userClass_int_hasEqEq() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  bool operator ==(other) => false;
}

const a = A();
const b = a == 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 87, 6),
    ]);
  }

  test_equal_userClass_int_hasHashCode() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  int get hashCode => 0;
}

const a = A();
const b = a == 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 76, 6),
    ]);
  }

  test_equal_userClass_int_hasPrimitiveEquality() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

const a = A();
const b = a == 0;
''');
  }

  test_equal_userClass_int_language219() async {
    await assertErrorsInCode(r'''
// @dart = 2.19
class A {
  const A();
}

const a = A();
const b = a == 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 67, 6),
    ]);
  }

  test_notEqual_double_object() async {
    await assertNoErrorsInCode(r'''
const a = 0.1;
const b = a != Object();
''');
  }

  test_notEqual_double_object_language219() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
const a = 0.1;
const b = a != Object();
''');
  }

  test_notEqual_int_object() async {
    await assertNoErrorsInCode(r'''
const a = 0;
const b = a != Object();
''');
  }

  test_notEqual_int_userClass() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

const a = 0;
const b = a != A();
''');
  }

  test_notEqual_null_object() async {
    await assertNoErrorsInCode(r'''
const a = null;
const b = a != Object();
''');
  }

  test_notEqual_string_object() async {
    await assertNoErrorsInCode(r'''
const a = 'foo';
const b = a != Object();
''');
  }

  test_notEqual_userClass_int_hasEqEq() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  bool operator ==(other) => false;
}

const a = A();
const b = a != 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 87, 6),
    ]);
  }

  test_notEqual_userClass_int_hasHashCode() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  int get hashCode => 0;
}

const a = A();
const b = a != 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 76, 6),
    ]);
  }

  test_notEqual_userClass_int_hasPrimitiveEquality() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

const a = A();
const b = a != 0;
''');
  }

  test_notEqual_userClass_int_language219() async {
    await assertErrorsInCode(r'''
// @dart = 2.19
class A {
  const A();
}

const a = A();
const b = a != 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 67, 6),
    ]);
  }

  test_stringInterpolation_list() async {
    await assertErrorsInCode(r'''
const x = '${const [2]}';
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 11, 12),
    ]);
  }
}
