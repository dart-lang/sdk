// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMixinFunctionTest);
  });
}

@reflectiveTest
class DeprecatedMixinFunctionTest extends PubPackageResolutionTest {
  test_class_core() async {
    await assertErrorsInCode('''
class A extends Object with Function {}
''', [
      error(CompileTimeErrorCode.CLASS_USED_AS_MIXIN, 28, 8),
    ]);
  }

  test_class_core_language219() async {
    await assertErrorsInCode('''
// @dart = 2.19
class A extends Object with Function {}
''', [
      error(WarningCode.DEPRECATED_MIXIN_FUNCTION, 44, 8),
    ]);
  }

  test_class_core_language219_viaTypedef() async {
    await assertErrorsInCode('''
// @dart = 2.19
typedef F = Function;
class A extends Object with F {}
''', [
      error(WarningCode.DEPRECATED_MIXIN_FUNCTION, 66, 1),
    ]);
  }

  test_class_local() async {
    await assertErrorsInCode('''
mixin Function {}
class A extends Object with Function {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 6, 8),
    ]);
  }

  test_class_local_language219() async {
    await assertErrorsInCode('''
// @dart = 2.19
mixin Function {}
class A extends Object with Function {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 22, 8),
    ]);
  }

  test_classAlias_core_language219() async {
    await assertErrorsInCode('''
// @dart = 2.19
class A = Object with Function;
''', [
      error(WarningCode.DEPRECATED_MIXIN_FUNCTION, 38, 8),
    ]);
  }

  test_classAlias_core_language219_viaTypedef() async {
    await assertErrorsInCode('''
// @dart = 2.19
typedef F = Function;
class A = Object with F;
''', [
      error(WarningCode.DEPRECATED_MIXIN_FUNCTION, 60, 1),
    ]);
  }
}
