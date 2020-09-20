// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializerForStaticFieldTest);
  });
}

@reflectiveTest
class InitializerForStaticFieldTest extends PubPackageResolutionTest {
  test_static() async {
    await assertErrorsInCode(r'''
class A {
  static int x;
  A() : x = 0 {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD, 34, 5),
    ]);
  }
}
