// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstantiateEnumTest);
  });
}

@reflectiveTest
class InstantiateEnumTest extends PubPackageResolutionTest
    with WithoutEnhancedEnumsMixin {
  test_const() async {
    await assertErrorsInCode(
      r'''
enum E { ONE }
E e(String name) {
  return const E();
}
''',
      [error(diag.instantiateEnum, 49, 1)],
    );
  }

  test_new() async {
    await assertErrorsInCode(
      r'''
enum E { ONE }
E e(String name) {
  return new E();
}
''',
      [error(diag.instantiateEnum, 47, 1)],
    );
  }
}
