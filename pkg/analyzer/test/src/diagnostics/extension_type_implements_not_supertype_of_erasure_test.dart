// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeImplementsDisallowedTypeTest);
  });
}

@reflectiveTest
class ExtensionTypeImplementsDisallowedTypeTest
    extends PubPackageResolutionTest {
  test_notSupertype() async {
    await assertErrorsInCode('''
extension type A(int it) implements String {}
''', [
      error(
          CompileTimeErrorCode
              .EXTENSION_TYPE_IMPLEMENTS_NOT_SUPERTYPE_OF_ERASURE,
          36,
          6),
    ]);
  }

  test_supertype2() async {
    await assertNoErrorsInCode('''
extension type A(S3 it) implements S1 {}
class S1 {}
class S2 extends S1 {}
class S3 extends S2 {}
''');
  }

  test_supertype_erasure() async {
    await assertNoErrorsInCode('''
extension type A(int it) {}
extension type B(A it) implements num {}
''');
  }

  test_supertype_interfaceType() async {
    await assertNoErrorsInCode('''
extension type A(int it) implements num {}
''');
  }
}
