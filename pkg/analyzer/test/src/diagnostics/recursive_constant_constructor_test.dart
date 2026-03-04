// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveConstantConstructorTest);
  });
}

@reflectiveTest
class RecursiveConstantConstructorTest extends PubPackageResolutionTest {
  test_newHead_named_redirectingConstructorInvocation() async {
    await assertErrorsInCode(
      '''
class A {
  const new named() : this.named();
}
''',
      [
        error(diag.recursiveConstantConstructor, 18, 9),
        error(diag.recursiveConstructorRedirect, 32, 12),
      ],
    );
  }

  test_newHead_unnamed_redirectingConstructorInvocation() async {
    await assertErrorsInCode(
      '''
class A {
  const new () : this();
}
''',
      [
        error(diag.recursiveConstantConstructor, 18, 3),
        error(diag.recursiveConstructorRedirect, 27, 6),
      ],
    );
  }

  test_typeName_field() async {
    await assertErrorsInCode(
      '''
class A {
  const A();
  final m = const A();
}
''',
      [error(diag.recursiveConstantConstructor, 18, 1)],
    );
  }

  test_typeName_initializer_after_toplevel_var() async {
    await assertErrorsInCode(
      '''
const y = const C();
class C {
  const C() : x = y;
  final x;
}
''',
      [
        error(diag.recursiveCompileTimeConstant, 6, 1),
        error(diag.recursiveConstantConstructor, 39, 1),
      ],
    );
  }

  test_typeName_initializer_field() async {
    await assertErrorsInCode(
      '''
class A {
  final A a;
  const A() : a = const A();
}
''',
      [error(diag.recursiveConstantConstructor, 31, 1)],
    );
  }

  test_typeName_initializer_field_multipleClasses() async {
    await assertErrorsInCode(
      '''
class B {
  final A a;
  const B() : a = const A();
}
class A {
  final B b;
  const A() : b = const B();
}
''',
      [
        error(diag.recursiveConstantConstructor, 31, 1),
        error(diag.recursiveConstantConstructor, 85, 1),
      ],
    );
  }
}
