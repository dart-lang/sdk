// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedMethodTest);
  });
}

@reflectiveTest
class UndefinedMethodTest extends PubPackageResolutionTest {
  test_constructor_defined() async {
    await assertNoErrorsInCode(r'''
class C {
  C.m();
}
C c = C.m();
''');
  }

  test_definedInPrivateExtension() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class B {}

extension _ on B {
  void a() {}
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';

f(B b) {
  b.a();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 33, 1),
    ]);
  }

  test_definedInUnnamedExtension() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class C {}

extension on C {
  void a() {}
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';

f(C c) {
  c.a();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 33, 1),
    ]);
  }

  test_functionExpression_callMethod_defined() async {
    await assertNoErrorsInCode(r'''
main() {
  (() => null).call();
}
''');
  }

  test_functionExpression_directCall_defined() async {
    await assertNoErrorsInCode(r'''
main() {
  (() => null)();
}
''');
  }

  test_ignoreTypePropagation() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  m() {}
}
class C {
  f() {
    A a = new B();
    a.m();
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 85, 1),
    ]);
  }

  test_leastUpperBoundWithNull() async {
    await assertErrorsInCode('''
f(bool b, int i) => (b ? null : i).foo();
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 35, 3),
    ]);
  }

  test_method_undefined() async {
    await assertErrorsInCode(r'''
class C {
  f() {
    abs();
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 22, 3),
    ]);
  }

  test_method_undefined_cascade() async {
    await assertErrorsInCode(r'''
class C {}
f(C c) {
  c..abs();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 3),
    ]);
  }

  test_method_undefined_enum() async {
    await assertErrorsInCode(r'''
enum E { A }
f() => E.abs();
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 22, 3),
    ]);
  }

  test_method_undefined_mixin() async {
    await assertErrorsInCode(r'''
mixin M {}
f(M m) {
  m.abs();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 24, 3),
    ]);
  }

  test_method_undefined_mixin_cascade() async {
    await assertErrorsInCode(r'''
mixin M {}
f(M m) {
  m..abs();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 3),
    ]);
  }

  test_method_undefined_onNull() async {
    await assertErrorsInCode(r'''
Null f(int x) => null;
main() {
  f(42).abs();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 40, 3),
    ]);
  }

  test_static_conditionalAccess_defined() async {
    // The conditional access operator '?.' can be used to access static
    // methods.
    await assertNoErrorsInCode('''
class A {
  static void m() {}
}
f() { A?.m(); }
''');
  }

  test_static_mixinApplication_superConstructorIsFactory() async {
    await assertErrorsInCode(r'''
mixin M {}

class A {
  A();
  factory A.named() = A;
}

class B = A with M;

void main() {
  B.named();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 96, 5),
    ]);
  }

  test_withExtension() async {
    await assertErrorsInCode(r'''
class C {}

extension E on C {
  void a() {}
}

f(C c) {
  c.c();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 61, 1),
    ]);
  }
}
