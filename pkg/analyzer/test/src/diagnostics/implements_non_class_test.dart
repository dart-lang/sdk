// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsNonClassTest);
  });
}

@reflectiveTest
class ImplementsNonClassTest extends PubPackageResolutionTest {
  test_inClass_dynamic() async {
    await assertErrorsInCode(
      '''
class A implements dynamic {}
''',
      [error(CompileTimeErrorCode.implementsNonClass, 19, 7)],
    );
  }

  test_inClass_enum() async {
    await assertErrorsInCode(
      r'''
enum E { ONE }
class A implements E {}
''',
      [error(CompileTimeErrorCode.implementsNonClass, 34, 1)],
    );
  }

  test_inClass_extensionType() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}
class B implements A {}
''',
      [error(CompileTimeErrorCode.implementsNonClass, 47, 1)],
    );
  }

  test_inClass_topLevelVariable() async {
    await assertErrorsInCode(
      r'''
int A = 7;
class B implements A {}
''',
      [error(CompileTimeErrorCode.implementsNonClass, 30, 1)],
    );
  }

  test_inClassTypeAlias() async {
    await assertErrorsInCode(
      r'''
class A {}
mixin M {}
int B = 7;
class C = A with M implements B;
''',
      [error(CompileTimeErrorCode.implementsNonClass, 63, 1)],
    );
  }

  test_inEnum_topLevelVariable() async {
    await assertErrorsInCode(
      r'''
int A = 7;
enum E implements A {
  v
}
''',
      [error(CompileTimeErrorCode.implementsNonClass, 29, 1)],
    );
  }

  test_inMixin_dynamic() async {
    await assertErrorsInCode(
      r'''
mixin M implements dynamic {}
''',
      [error(CompileTimeErrorCode.implementsNonClass, 19, 7)],
    );
  }

  test_inMixin_extensionType() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}
mixin M implements A {}
''',
      [error(CompileTimeErrorCode.implementsNonClass, 47, 1)],
    );
  }

  test_Never() async {
    await assertErrorsInCode(
      '''
class A implements Never {}
''',
      [error(CompileTimeErrorCode.implementsNonClass, 19, 5)],
    );
  }
}
