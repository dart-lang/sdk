// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedExtendsFunctionTest);
  });
}

@reflectiveTest
class DeprecatedExtendsFunctionTest extends PubPackageResolutionTest {
  test_core() async {
    await assertErrorsInCode(
      '''
class A extends Function {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 16, 8)],
    );
  }

  test_core_language219() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
class A extends Function {}
''',
      [error(WarningCode.deprecatedExtendsFunction, 32, 8)],
    );
  }

  test_core_language219_viaTypedef() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
typedef F = Function;
class A extends F {}
''',
      [error(WarningCode.deprecatedExtendsFunction, 54, 1)],
    );
  }

  test_local_language219() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
class Function {}
class A extends Function {}
''',
      [error(CompileTimeErrorCode.builtInIdentifierAsTypeName, 22, 8)],
    );
  }
}
