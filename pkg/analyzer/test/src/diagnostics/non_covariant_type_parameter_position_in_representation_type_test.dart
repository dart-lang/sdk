// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
        NonCovariantTypeParameterPositionInRepresentationTypeTest);
  });
}

@reflectiveTest
class NonCovariantTypeParameterPositionInRepresentationTypeTest
    extends PubPackageResolutionTest {
  test_contravariant() async {
    await assertErrorsInCode(r'''
extension type A<T>(void Function(T) it) {}
''', [
      error(
          CompileTimeErrorCode
              .NON_COVARIANT_TYPE_PARAMETER_POSITION_IN_REPRESENTATION_TYPE,
          17,
          1),
    ]);
  }

  test_covariant() async {
    await assertNoErrorsInCode(r'''
extension type A<T>(T Function() it) {}
''');
  }

  test_invariant() async {
    await assertErrorsInCode(r'''
extension type A<T>(T Function(T) it) {}
''', [
      error(
          CompileTimeErrorCode
              .NON_COVARIANT_TYPE_PARAMETER_POSITION_IN_REPRESENTATION_TYPE,
          17,
          1),
    ]);
  }
}
