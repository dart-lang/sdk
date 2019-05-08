// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplicitThisReferenceInInitializerTest);
  });
}

@reflectiveTest
class ImplicitThisReferenceInInitializerTest extends DriverResolutionTest {
  test_implicitThisReferenceInInitializer_constructorName() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named() {}
}
class B {
  var v;
  B() : v = new A.named();
}
''');
  }

  test_implicitThisReferenceInInitializer_field() async {
    await assertErrorsInCode(r'''
class A {
  var v;
  A() : v = f;
  var f;
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 31, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_field2() async {
    await assertErrorsInCode(r'''
class A {
  final x = 0;
  final y = x;
}
''', [
      error(StrongModeCode.TOP_LEVEL_INSTANCE_GETTER, 37, 1),
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 37, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_invocation() async {
    await assertErrorsInCode(r'''
class A {
  var v;
  A() : v = f();
  f() {}
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 31, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_invocationInStatic() async {
    await assertErrorsInCode(r'''
class A {
  static var F = m();
  int m() => 0;
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 27, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_prefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
class A {
  var f;
}
class B {
  var v;
  B(A a) : v = a.f;
}
''');
  }

  test_implicitThisReferenceInInitializer_qualifiedMethodInvocation() async {
    await assertNoErrorsInCode(r'''
class A {
  f() {}
}
class B {
  var v;
  B() : v = new A().f();
}
''');
  }

  test_implicitThisReferenceInInitializer_qualifiedPropertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  var f;
}
class B {
  var v;
  B() : v = new A().f;
}
''');
  }

  test_implicitThisReferenceInInitializer_redirectingConstructorInvocation() async {
    await assertErrorsInCode(r'''
class A {
  A(p) {}
  A.named() : this(f);
  var f;
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 39, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_staticField_thisClass() async {
    await assertNoErrorsInCode(r'''
class A {
  var v;
  A() : v = f;
  static var f;
}
''');
  }

  test_implicitThisReferenceInInitializer_staticGetter() async {
    await assertNoErrorsInCode(r'''
class A {
  var v;
  A() : v = f;
  static get f => 42;
}
''');
  }

  test_implicitThisReferenceInInitializer_staticMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  var v;
  A() : v = f();
  static f() => 42;
}
''');
  }

  test_implicitThisReferenceInInitializer_superConstructorInvocation() async {
    await assertErrorsInCode(r'''
class A {
  A(p) {}
}
class B extends A {
  B() : super(f);
  var f;
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 56, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_topLevelField() async {
    await assertNoErrorsInCode(r'''
class A {
  var v;
  A() : v = f;
}
var f = 42;
''');
  }

  test_implicitThisReferenceInInitializer_topLevelFunction() async {
    await assertNoErrorsInCode(r'''
class A {
  var v;
  A() : v = f();
}
f() => 42;
''');
  }

  test_implicitThisReferenceInInitializer_topLevelGetter() async {
    await assertNoErrorsInCode(r'''
class A {
  var v;
  A() : v = f;
}
get f => 42;
''');
  }

  test_implicitThisReferenceInInitializer_typeParameter() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  var v;
  A(p) : v = (p is T);
}
''');
  }

  test_isInInstanceVariableInitializer_restored() async {
    // If ErrorVerifier._isInInstanceVariableInitializer is not properly
    // restored on exit from visitVariableDeclaration, the error at (1)
    // won't be detected.
    await assertErrorsInCode(r'''
class Foo {
  var bar;
  Map foo = {
    'bar': () {
        var _bar;
    },
    'bop': _foo // (1)
  };
  _foo() {
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 65, 4),
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 89, 4),
    ]);
  }
}
