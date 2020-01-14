// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultValueInFunctionTypedParameterTest);
  });
}

@reflectiveTest
class DefaultValueInFunctionTypedParameterTest extends DriverResolutionTest {
  test_named() async {
    await assertErrorsInCode('''
f(g({p: null})) {}
''', [
      error(
          CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER, 5, 7),
      error(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 6, 1),
    ]);
  }

  test_positional() async {
    await assertErrorsInCode('''
f(g([p = null])) {}
''', [
      error(
          CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER, 5, 8),
      error(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 7, 1),
    ]);
  }
}
