// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidCastNewExprTest);
  });
}

@reflectiveTest
class InvalidCastNewExprTest extends PubPackageResolutionTest {
  test_listLiteral_const() async {
    await assertErrorsInCode(r'''
const c = <B>[A()];
class A {
  const A();
}
class B extends A {
  const B();
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 14, 3),
      error(CompileTimeErrorCode.INVALID_CAST_NEW_EXPR, 14, 3),
    ]);
  }

  test_listLiteral_nonConst() async {
    await assertErrorsInCode(r'''
var c = <B>[A()];
class A {
  const A();
}
class B extends A {
  const B();
}
''', [
      error(CompileTimeErrorCode.INVALID_CAST_NEW_EXPR, 12, 3),
    ]);
  }

  test_setLiteral_const() async {
    await assertErrorsInCode(r'''
const c = <B>{A()};
class A {
  const A();
}
class B extends A {
  const B();
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 14, 3),
      error(CompileTimeErrorCode.INVALID_CAST_NEW_EXPR, 14, 3),
    ]);
  }

  test_setLiteral_nonConst() async {
    await assertErrorsInCode(r'''
var c = <B>{A()};
class A {
  const A();
}
class B extends A {
  const B();
}
''', [
      error(CompileTimeErrorCode.INVALID_CAST_NEW_EXPR, 12, 3),
    ]);
  }
}
