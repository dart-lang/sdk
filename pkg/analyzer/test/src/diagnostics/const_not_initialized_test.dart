// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstNotInitializedTest);
  });
}

@reflectiveTest
class ConstNotInitializedTest extends PubPackageResolutionTest {
  test_class_static() async {
    await assertErrorsInCode(
      r'''
class A {
  static const F;
}
''',
      [error(diag.constNotInitialized, 25, 1)],
    );
  }

  test_enum_static() async {
    await assertErrorsInCode(
      '''
enum E {
  v;
  static const F;
}
''',
      [error(diag.constNotInitialized, 29, 1)],
    );
  }

  test_extension_static() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static const F;
}
''',
      [error(diag.constNotInitialized, 39, 1)],
    );
  }

  test_local() async {
    await assertErrorsInCode(
      r'''
f() {
  const int x;
}
''',
      [
        error(diag.unusedLocalVariable, 18, 1),
        error(diag.constNotInitialized, 18, 1),
      ],
    );
  }

  test_topLevel() async {
    await assertErrorsInCode(
      '''
const F;
''',
      [error(diag.constNotInitialized, 6, 1)],
    );
  }
}
