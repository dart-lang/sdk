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
  test_class_core() async {
    await assertErrorsInCode(
      '''
class A implements Function {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          19,
          8,
        ),
      ],
    );
  }

  test_class_core2() async {
    await assertErrorsInCode(
      '''
class A implements Function, Function {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          19,
          8,
        ),
        error(CompileTimeErrorCode.implementsRepeated, 29, 8),
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          29,
          8,
        ),
      ],
    );
  }

  test_class_core2_language219() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
class A implements Function, Function {}
''',
      [
        error(WarningCode.deprecatedImplementsFunction, 35, 8),
        error(CompileTimeErrorCode.implementsRepeated, 45, 8),
      ],
    );
  }

  test_class_core_language219() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
class A implements Function {}
''',
      [error(WarningCode.deprecatedImplementsFunction, 35, 8)],
    );
  }

  test_class_core_language219_viaTypedef() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
typedef F = Function;
class A implements F {}
''',
      [error(WarningCode.deprecatedImplementsFunction, 57, 1)],
    );
  }

  test_class_local() async {
    await assertErrorsInCode(
      '''
class Function {}
class A implements Function {}
''',
      [error(CompileTimeErrorCode.builtInIdentifierAsTypeName, 6, 8)],
    );
  }

  test_classAlias_core_language219() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
mixin M {}
class A = Object with M implements Function;
''',
      [error(WarningCode.deprecatedImplementsFunction, 62, 8)],
    );
  }

  test_classAlias_core_language219_viaTypedef() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
mixin M {}
typedef F = Function;
class A = Object with M implements F;
''',
      [error(WarningCode.deprecatedImplementsFunction, 84, 1)],
    );
  }
}
