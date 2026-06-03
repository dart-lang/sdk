// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveConstantConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecursiveConstantConstructorTest extends PubPackageResolutionTest {
  test_newHead_named_redirectingConstructorInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const new named() : this.named();
//      ^^^^^^^^^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
//                    ^^^^^^^^^^^^
// [diag.recursiveConstructorRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
''');
  }

  test_newHead_unnamed_redirectingConstructorInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const new () : this();
//      ^^^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
//               ^^^^^^
// [diag.recursiveConstructorRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
''');
  }

  test_typeName_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
//      ^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
  final m = const A();
}
''');
  }

  test_typeName_initializer_after_toplevel_var() async {
    await resolveTestCodeWithDiagnostics(r'''
const y = const C();
//    ^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
class C {
  const C() : x = y;
//      ^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
  final x;
}
''');
  }

  test_typeName_initializer_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final A a;
  const A() : a = const A();
//      ^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
}
''');
  }

  test_typeName_initializer_field_multipleClasses() async {
    await resolveTestCodeWithDiagnostics(r'''
class B {
  final A a;
  const B() : a = const A();
//      ^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
}
class A {
  final B b;
  const A() : b = const B();
//      ^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
}
''');
  }
}
