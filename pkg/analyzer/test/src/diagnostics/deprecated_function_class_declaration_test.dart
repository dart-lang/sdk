// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedFunctionClassDeclarationTest);
  });
}

@reflectiveTest
class DeprecatedFunctionClassDeclarationTest extends PubPackageResolutionTest {
  test_declaration() async {
    await assertErrorsInCode('''
class Function {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 6, 8),
    ]);
  }

  test_typeparameter() async {
    await assertErrorsInCode('''
class Function {}
class C<Function> {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 6, 8),
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME, 26, 8),
    ]);
  }
}
