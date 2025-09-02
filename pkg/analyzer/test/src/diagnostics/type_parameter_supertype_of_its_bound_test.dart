// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeParameterSupertypeOfItsBoundTest);
  });
}

@reflectiveTest
class TypeParameterSupertypeOfItsBoundTest extends PubPackageResolutionTest {
  test_1of1() async {
    await assertErrorsInCode(
      r'''
class A<T extends T> {
}
''',
      [error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 8, 1)],
    );
  }

  test_1of1_local() async {
    await assertErrorsInCode(
      r'''
void m() {
  void local<T extends T>() {}
  local;
}
''',
      [error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 24, 1)],
    );
  }

  test_1of1_local_viaExtensionType() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(T it) {}

void m() {
  void local<U extends A<U>>() {}
  local;
}
''',
      [error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 54, 1)],
    );
  }

  test_1of1_used() async {
    await assertErrorsInCode(
      '''
class A<T extends T> {
  void foo(x) {
    x is T;
  }
}
''',
      [error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 8, 1)],
    );
  }

  test_1of1_viaExtensionType() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(T it) {}

class B<U extends A<U>> {}
''',
      [error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 38, 1)],
    );
  }

  test_2of2_local_viaExtensionType() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(T it) {}

void m() {
  void local<T1 extends A<T2>, T2 extends T1>() {}
  local;
}
''',
      [
        error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 54, 2),
        error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 72, 2),
      ],
    );
  }

  test_2of2_viaExtensionType() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(T it) {}

class B<T1 extends A<T2>, T2 extends T1> {}
''',
      [
        error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 38, 2),
        error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 56, 2),
      ],
    );
  }

  test_2of3() async {
    await assertErrorsInCode(
      r'''
class A<T1 extends T3, T2, T3 extends T1> {
}
''',
      [
        error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 8, 2),
        error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 27, 2),
      ],
    );
  }

  test_local_2of3() async {
    await assertErrorsInCode(
      r'''
void m() {
  void local<T1 extends T3, T2, T3 extends T1>() {}
  local;
}
''',
      [
        error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 24, 2),
        error(CompileTimeErrorCode.typeParameterSupertypeOfItsBound, 43, 2),
      ],
    );
  }
}
