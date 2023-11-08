// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveConstantConstructorTest);
  });
}

@reflectiveTest
class RecursiveConstantConstructorTest extends PubPackageResolutionTest {
  test_field() async {
    await assertErrorsInCode('''
class A {
  const A();
  final m = const A();
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_CONSTANT_CONSTRUCTOR, 18, 1),
      error(CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, 31, 1),
    ]);
  }

  test_initializer_after_toplevel_var() async {
    await assertErrorsInCode('''
const y = const C();
class C {
  const C() : x = y;
  final x;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_CONSTANT_CONSTRUCTOR, 39, 1),
    ]);
  }

  test_initializer_field() async {
    await assertErrorsInCode('''
class A {
  final A a;
  const A() : a = const A();
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_CONSTANT_CONSTRUCTOR, 31, 1),
    ]);
  }

  test_initializer_field_multipleClasses() async {
    await assertErrorsInCode('''
class B {
  final A a;
  const B() : a = const A();
}
class A {
  final B b;
  const A() : b = const B();
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_CONSTANT_CONSTRUCTOR, 31, 1),
      error(CompileTimeErrorCode.RECURSIVE_CONSTANT_CONSTRUCTOR, 85, 1),
    ]);
  }
}
