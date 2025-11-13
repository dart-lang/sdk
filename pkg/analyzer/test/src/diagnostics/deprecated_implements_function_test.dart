// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
      [error(diag.finalClassImplementedOutsideOfLibrary, 19, 8)],
    );
  }

  test_class_core2() async {
    await assertErrorsInCode(
      '''
class A implements Function, Function {}
''',
      [
        error(diag.finalClassImplementedOutsideOfLibrary, 19, 8),
        error(diag.implementsRepeated, 29, 8),
        error(diag.finalClassImplementedOutsideOfLibrary, 29, 8),
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
        error(diag.deprecatedImplementsFunction, 35, 8),
        error(diag.implementsRepeated, 45, 8),
      ],
    );
  }

  test_class_core_language219() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
class A implements Function {}
''',
      [error(diag.deprecatedImplementsFunction, 35, 8)],
    );
  }

  test_class_core_language219_viaTypedef() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
typedef F = Function;
class A implements F {}
''',
      [error(diag.deprecatedImplementsFunction, 57, 1)],
    );
  }

  test_class_local() async {
    await assertErrorsInCode(
      '''
class Function {}
class A implements Function {}
''',
      [error(diag.builtInIdentifierAsTypeName, 6, 8)],
    );
  }

  test_classAlias_core_language219() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
mixin M {}
class A = Object with M implements Function;
''',
      [error(diag.deprecatedImplementsFunction, 62, 8)],
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
      [error(diag.deprecatedImplementsFunction, 84, 1)],
    );
  }
}
