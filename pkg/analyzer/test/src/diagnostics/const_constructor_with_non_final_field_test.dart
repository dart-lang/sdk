// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorWithNonFinalFieldTest);
  });
}

@reflectiveTest
class ConstConstructorWithNonFinalFieldTest extends PubPackageResolutionTest {
  test_this_named() async {
    await assertErrorsInCode(r'''
class A {
  int x = 0;
  const A.a();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 31, 3),
    ]);
  }

  test_this_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  int x = 0;
  const A();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 31, 1),
    ]);
  }
}
