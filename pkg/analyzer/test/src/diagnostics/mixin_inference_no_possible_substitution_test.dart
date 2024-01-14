// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      MixinInferenceNoPossibleSubstitutionTest,
    );
  });
}

@reflectiveTest
class MixinInferenceNoPossibleSubstitutionTest
    extends PubPackageResolutionTest {
  test_valid_single() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

mixin M<T> on A<T> {}

class X extends A<int> with M {}
''');

    assertType(findNode.namedType('M {}'), 'M<int>');
  }
}
