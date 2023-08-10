// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
        ExtensionTypeImplementsRepresentationNotSupertypeTest);
  });
}

@reflectiveTest
class ExtensionTypeImplementsRepresentationNotSupertypeTest
    extends PubPackageResolutionTest {
  test_notSupertype() async {
    await assertErrorsInCode('''
extension type A(String it) {}
extension type B(int it) implements A {}
''', [
      error(
          CompileTimeErrorCode
              .EXTENSION_TYPE_IMPLEMENTS_REPRESENTATION_NOT_SUPERTYPE,
          67,
          1),
    ]);
  }

  test_supertype() async {
    await assertNoErrorsInCode('''
extension type A(num it) {}
extension type B(int it) implements A {}
''');
  }

  test_supertype2() async {
    await assertNoErrorsInCode('''
extension type A(S1 it) {}
extension type B(S3 it) implements A {}
class S1 {}
class S2 extends S1 {}
class S3 extends S2 {}
''');
  }
}
