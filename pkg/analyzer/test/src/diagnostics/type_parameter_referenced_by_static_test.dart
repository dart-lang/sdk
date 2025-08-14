// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeParameterReferencedByStaticTest);
  });
}

@reflectiveTest
class TypeParameterReferencedByStaticTest extends PubPackageResolutionTest {
  test_class_field() async {
    await assertErrorsInCode(
      '''
class A<T> {
  static T? foo;
}
''',
      [error(CompileTimeErrorCode.typeParameterReferencedByStatic, 22, 1)],
    );
  }

  test_class_getter() async {
    await assertErrorsInCode(
      '''
class A<T> {
  static T? get foo => null;
}
''',
      [error(CompileTimeErrorCode.typeParameterReferencedByStatic, 22, 1)],
    );
  }

  test_class_method_bodyReference() async {
    await assertErrorsInCode(
      '''
class A<T> {
  static foo() {
    // ignore:unused_local_variable
    T v;
  }
}
''',
      [error(CompileTimeErrorCode.typeParameterReferencedByStatic, 70, 1)],
    );
  }

  test_class_method_closure() async {
    await assertErrorsInCode(
      '''
class A<T> {
  static Object foo() {
    return (T a) {};
  }
}
''',
      [error(CompileTimeErrorCode.typeParameterReferencedByStatic, 49, 1)],
    );
  }

  test_class_method_parameter() async {
    await assertErrorsInCode(
      '''
class A<T> {
  static foo(T a) {}
}
''',
      [error(CompileTimeErrorCode.typeParameterReferencedByStatic, 26, 1)],
    );
  }

  test_class_method_return() async {
    await assertErrorsInCode(
      '''
class A<T> {
  static T foo() {
    throw 0;
  }
}
''',
      [error(CompileTimeErrorCode.typeParameterReferencedByStatic, 22, 1)],
    );
  }

  test_class_setter() async {
    await assertErrorsInCode(
      '''
class A<T> {
  static set foo(T _) {}
}
''',
      [error(CompileTimeErrorCode.typeParameterReferencedByStatic, 30, 1)],
    );
  }

  test_expression_method() async {
    await assertErrorsInCode(
      '''
class A<T> {
  static foo() {
    T;
  }
}
''',
      [error(CompileTimeErrorCode.typeParameterReferencedByStatic, 34, 1)],
    );
  }

  test_extension_field() async {
    await assertErrorsInCode(
      '''
extension E<T> on int {
  static T? foo;
}
''',
      [error(CompileTimeErrorCode.typeParameterReferencedByStatic, 33, 1)],
    );
  }

  test_extension_method_return() async {
    await assertErrorsInCode(
      '''
extension E<T> on int {
  static T foo() => throw 0;
}
''',
      [error(CompileTimeErrorCode.typeParameterReferencedByStatic, 33, 1)],
    );
  }

  test_mixin_field() async {
    await assertErrorsInCode(
      '''
mixin A<T> {
  static T? foo;
}
''',
      [error(CompileTimeErrorCode.typeParameterReferencedByStatic, 22, 1)],
    );
  }
}
