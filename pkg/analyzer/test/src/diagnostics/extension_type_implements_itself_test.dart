// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeImplementsItselfTest);
  });
}

@reflectiveTest
class ExtensionTypeImplementsItselfTest extends PubPackageResolutionTest {
  test_hasCycle2() async {
    await assertErrorsInCode(
      '''
extension type A(int it) implements B {}
extension type B(int it) implements A {}
''',
      [
        error(CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_ITSELF, 15, 1),
        error(CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_ITSELF, 56, 1),
      ],
    );
  }

  test_hasCycle_self() async {
    await assertErrorsInCode(
      '''
extension type A(int it) implements A {}
''',
      [error(CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_ITSELF, 15, 1)],
    );
  }
}
