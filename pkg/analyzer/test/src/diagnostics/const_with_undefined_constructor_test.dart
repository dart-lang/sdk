// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithUndefinedConstructorTest);
  });
}

@reflectiveTest
class ConstWithUndefinedConstructorTest extends PubPackageResolutionTest {
  test_named() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
f() {
  return const A.noSuchConstructor();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR, 48, 17),
    ]);
  }

  test_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  const A.name();
}
f() {
  return const A();
}
''', [
      error(
          CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, 51, 1),
    ]);
  }
}
