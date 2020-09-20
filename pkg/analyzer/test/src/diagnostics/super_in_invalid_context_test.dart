// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInInvalidContextTest);
  });
}

@reflectiveTest
class SuperInInvalidContextTest extends PubPackageResolutionTest {
  test_binaryExpression() async {
    await assertErrorsInCode('''
var v = super + 0;
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 8, 5),
    ]);
  }

  test_constructorFieldInitializer() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
}
class B extends A {
  var f;
  B() : f = super.m();
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 62, 5),
    ]);
  }

  test_factoryConstructor() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
}
class B extends A {
  factory B() {
    super.m();
    return null;
  }
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 61, 5),
    ]);
  }

  test_instanceVariableInitializer() async {
    await assertErrorsInCode(r'''
class A {
  var a;
}
class B extends A {
 var b = super.a;
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 50, 5),
    ]);
  }

  test_staticMethod() async {
    await assertErrorsInCode(r'''
class A {
  static m() {}
}
class B extends A {
  static n() { return super.m(); }
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 70, 5),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('super.m()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_staticVariableInitializer() async {
    await assertErrorsInCode(r'''
class A {
  static int a = 0;
}
class B extends A {
  static int b = super.a;
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 69, 5),
    ]);

    assertPropertyAccess2(
      findNode.propertyAccess('super.a'),
      element: null,
      type: 'dynamic',
    );
  }

  test_topLevelFunction() async {
    await assertErrorsInCode(r'''
f() {
  super.f();
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 8, 5),
    ]);
  }

  test_topLevelVariableInitializer() async {
    await assertErrorsInCode('''
var v = super.y;
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 8, 5),
    ]);
  }

  test_valid() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
}
class B extends A {
  B() {
    var v = super.m();
  }
  n() {
    var v = super.m();
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 57, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 92, 1),
    ]);
  }
}
