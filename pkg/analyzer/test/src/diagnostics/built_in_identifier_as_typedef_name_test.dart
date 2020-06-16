// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsTypedefNameTest);
  });
}

@reflectiveTest
class BuiltInIdentifierAsTypedefNameTest extends DriverResolutionTest {
  test_classTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class as = A with B;
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 28, 2),
    ]);
  }

  test_typedef_classic() async {
    await assertErrorsInCode(r'''
typedef void as();
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 13, 2),
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 13, 2),
    ]);
  }

  test_typedef_generic() async {
    await assertErrorsInCode(r'''
typedef as = void Function();
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 8, 2),
      error(ParserErrorCode.MISSING_IDENTIFIER, 8, 2)
    ]);
  }
}
