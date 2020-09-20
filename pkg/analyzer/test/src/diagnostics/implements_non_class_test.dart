// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsNonClassTest);
    defineReflectiveTests(ImplementsNonClassWithNullSafetyTest);
  });
}

@reflectiveTest
class ImplementsNonClassTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
int A = 7;
class B implements A {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, 30, 1),
    ]);
  }

  test_dynamic() async {
    await assertErrorsInCode('''
class A implements dynamic {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, 19, 7),
    ]);
  }

  test_enum() async {
    await assertErrorsInCode(r'''
enum E { ONE }
class A implements E {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, 34, 1),
    ]);
  }

  test_typeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
int B = 7;
class C = A with M implements B;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, 63, 1),
    ]);
  }
}

@reflectiveTest
class ImplementsNonClassWithNullSafetyTest extends ImplementsNonClassTest
    with WithNullSafetyMixin {
  test_Never() async {
    await assertErrorsInCode('''
class A implements Never {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, 19, 5),
    ]);
  }
}
