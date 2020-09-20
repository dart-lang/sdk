// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvocationOfNonFunctionExpressionTest);
  });
}

@reflectiveTest
class InvocationOfNonFunctionExpressionTest extends PubPackageResolutionTest {
  test_invocationOfNonFunctionExpression_literal() async {
    await assertErrorsInCode(r'''
f() {
  3(5);
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 8, 1),
    ]);
  }
}
