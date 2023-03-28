// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedImplementsFunctionTest);
  });
}

@reflectiveTest
class DeprecatedImplementsFunctionTest extends PubPackageResolutionTest {
  test_core() async {
    await assertErrorsInCode('''
class A implements Function {}
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 19,
          8),
    ]);
  }

  test_core2() async {
    await assertErrorsInCode('''
class A implements Function, Function {}
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 19,
          8),
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 29, 8),
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 29,
          8),
    ]);
  }

  test_core2_language219() async {
    await assertErrorsInCode('''
// @dart = 2.19
class A implements Function, Function {}
''', [
      error(WarningCode.DEPRECATED_IMPLEMENTS_FUNCTION, 35, 8),
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 45, 8),
    ]);
  }

  test_core_language219() async {
    await assertErrorsInCode('''
// @dart = 2.19
class A implements Function {}
''', [
      error(WarningCode.DEPRECATED_IMPLEMENTS_FUNCTION, 35, 8),
    ]);
  }

  test_local() async {
    await assertErrorsInCode('''
class Function {}
class A implements Function {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 6, 8),
    ]);
  }
}
