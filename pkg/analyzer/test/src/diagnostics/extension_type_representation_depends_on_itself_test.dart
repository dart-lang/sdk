// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeRepresentationDependsOnItselfTest);
  });
}

@reflectiveTest
class ExtensionTypeRepresentationDependsOnItselfTest
    extends PubPackageResolutionTest {
  test_depends_cycle2_direct() async {
    await assertErrorsInCode('''
extension type A(B it) {}

extension type B(A it) {}
''', [
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF,
          15,
          1),
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF,
          42,
          1),
    ]);
  }

  test_depends_cycle2_typeArgument() async {
    await assertErrorsInCode('''
extension type A(List<B> it) {}

extension type B(List<A> it) {}
''', [
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF,
          15,
          1),
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF,
          48,
          1),
    ]);
  }

  test_depends_self_direct() async {
    await assertErrorsInCode('''
extension type A(A it) {}
''', [
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF,
          15,
          1),
    ]);
  }

  test_depends_self_typeArgument() async {
    await assertErrorsInCode('''
extension type A(List<A> it) {}
''', [
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF,
          15,
          1),
    ]);
  }
}
