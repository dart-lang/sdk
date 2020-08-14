// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsSuperClassTest);
  });
}

@reflectiveTest
class ImplementsSuperClassTest extends PubPackageResolutionTest {
  test_implements_super_class() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A implements A {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 40, 1),
    ]);
  }

  test_Object() async {
    await assertErrorsInCode('''
class A implements Object {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 19, 6),
    ]);
  }

  test_Object_typeAlias() async {
    await assertErrorsInCode(r'''
class M {}
class A = Object with M implements Object;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 46, 6),
    ]);
  }

  test_typeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class B = A with M implements A;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 52, 1),
    ]);
  }
}
