// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidFieldNameTest);
  });
}

@reflectiveTest
class InvalidFieldNameTest extends PubPackageResolutionTest {
  void test_fromObject() async {
    await assertErrorsInCode(r'''
var r = (hashCode: 1, noSuchMethod: 2, runtimeType: 3, toString: 4);
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 9, 8),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 22, 12),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 39, 11),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 55, 8),
    ]);
  }

  void test_positional() async {
    await assertErrorsInCode(r'''
var r = (a: 1, $12: 2);
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, 15, 3),
    ]);
  }

  void test_private() async {
    await assertErrorsInCode(r'''
var r = (_a: 1, b: 2);
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 9, 2),
    ]);
  }
}
