// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
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
  test_core() async {
    await assertErrorsInCode('''
class A extends Object with Function {}
''', [
      error(HintCode.DEPRECATED_MIXIN_FUNCTION, 28, 8),
    ]);
  }

  test_local() async {
    await assertErrorsInCode('''
class Function {}
class A extends Object with Function {}
''', [
      error(CompileTimeErrorCode.FUNCTION_CLASS_DECLARATION, 6, 8),
      error(HintCode.DEPRECATED_MIXIN_FUNCTION, 46, 8),
    ]);
  }

  test_mixin() async {
    await assertErrorsInCode('''
mixin Function {}
mixin M<Function> implements List<Function> {}    
''', [
      error(CompileTimeErrorCode.FUNCTION_MIXIN_DECLARATION, 6, 8),
      error(CompileTimeErrorCode.FUNCTION_AS_TYPE_PARAMETER, 26, 8),
    ]);
  }

  test_mixin_onclause() async {
    await assertErrorsInCode('''
mixin A on Function {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 11, 8),
    ]);
  }
}
