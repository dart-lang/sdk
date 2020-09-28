// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerNotAssignableTest);
  });
}

@reflectiveTest
class FieldInitializerNotAssignableTest extends PubPackageResolutionTest {
  test_unrelated() async {
    await assertErrorsInCode('''
class A {
  int x;
  A() : x = '';
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, 31, 2),
    ]);
  }
}
