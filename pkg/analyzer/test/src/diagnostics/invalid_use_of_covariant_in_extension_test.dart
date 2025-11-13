// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfCovariantInExtensionTest);
  });
}

@reflectiveTest
class InvalidUseOfCovariantInExtensionTest extends PubPackageResolutionTest {
  test_optional_named() async {
    await assertErrorsInCode(
      '''
extension E on String {
  void foo({covariant int a = 0}) {}
}
''',
      [error(diag.invalidUseOfCovariantInExtension, 36, 9)],
    );
  }

  test_optional_positional() async {
    await assertErrorsInCode(
      '''
extension E on String {
  void foo([covariant int a = 0]) {}
}
''',
      [error(diag.invalidUseOfCovariantInExtension, 36, 9)],
    );
  }

  test_required_positional() async {
    await assertErrorsInCode(
      '''
extension E on String {
  void foo(covariant int a) {}
}
''',
      [error(diag.invalidUseOfCovariantInExtension, 35, 9)],
    );
  }
}
