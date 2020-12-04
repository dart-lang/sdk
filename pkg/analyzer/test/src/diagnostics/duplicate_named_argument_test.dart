// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateNamedArgumentTest);
  });
}

@reflectiveTest
class DuplicateNamedArgumentTest extends PubPackageResolutionTest {
  test_duplicate_named_argument() async {
    await assertErrorsInCode(r'''
f({a, b}) {}
main() {
  f(a: 1, a: 2);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, 32, 1),
    ]);
  }
}
