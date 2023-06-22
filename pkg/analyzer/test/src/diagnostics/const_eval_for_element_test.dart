// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalForElementTest);
  });
}

@reflectiveTest
class ConstEvalForElementTest extends PubPackageResolutionTest {
  test_listLiteral() async {
    await assertErrorsInCode(r'''
const x = [for (int i = 0; i < 3; i++) i];
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 10,
          31),
      error(CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT, 11, 29),
    ]);
  }

  test_listLiteral_forIn() async {
    await assertErrorsInCode(r'''
const Set set = {};
const x = [for(final i in set) i];
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 30,
          23),
      error(CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT, 31, 21),
    ]);
  }

  test_mapLiteral_forIn() async {
    await assertErrorsInCode(r'''
const x = {for (final i in const []) i: null};
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 10,
          35),
      error(CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT, 11, 33),
    ]);
  }

  test_mapLiteral_forIn_nested() async {
    await assertErrorsInCode(r'''
const x = {if (true) for (final i in const []) i: null};
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 10,
          45),
      error(CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT, 21, 33),
    ]);
  }

  test_setLiteral_forIn() async {
    await assertErrorsInCode(r'''
const Set set = {};
const x = {for (final i in set) i};
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 30,
          24),
      error(CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT, 31, 22),
    ]);
  }
}
