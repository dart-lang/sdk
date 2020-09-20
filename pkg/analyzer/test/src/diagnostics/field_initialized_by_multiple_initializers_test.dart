// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalInitializedByMultipleInitializersTest);
  });
}

@reflectiveTest
class FinalInitializedByMultipleInitializersTest
    extends PubPackageResolutionTest {
  static const _errorCode =
      CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS;

  test_more_than_two_initializers() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A() : x = 0, x = 1, x = 2 {}
}
''', [
      error(_errorCode, 34, 1),
      error(_errorCode, 41, 1),
    ]);
  }

  test_multiple_names() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  int y;
  A() : x = 0, x = 1, y = 0, y = 1 {}
}
''', [
      error(_errorCode, 43, 1),
      error(_errorCode, 57, 1),
    ]);
  }

  test_one_initializer() async {
    await assertNoErrorsInCode(r'''
class A {
  int x;
  int y;
  A() : x = 0, y = 0 {}
}
''');
  }

  test_two_initializers() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A() : x = 0, x = 1 {}
}
''', [
      error(_errorCode, 34, 1),
    ]);
  }
}
