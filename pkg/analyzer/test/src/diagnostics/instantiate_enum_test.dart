// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstantiateEnumTest);
  });
}

@reflectiveTest
class InstantiateEnumTest extends PubPackageResolutionTest {
  test_const() async {
    await assertErrorsInCode(r'''
enum E { ONE }
E e(String name) {
  return const E();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 43, 9),
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 43, 9),
      error(CompileTimeErrorCode.INSTANTIATE_ENUM, 49, 1),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 50, 2),
    ]);
  }

  test_new() async {
    await assertErrorsInCode(r'''
enum E { ONE }
E e(String name) {
  return new E();
}
''', [
      error(CompileTimeErrorCode.INSTANTIATE_ENUM, 47, 1),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 48, 2),
    ]);
  }
}
