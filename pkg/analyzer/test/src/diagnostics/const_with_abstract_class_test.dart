// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_api/src/frontend/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithAbstractClassTest);
  });
}

@reflectiveTest
class ConstWithAbstractClassTest extends DriverResolutionTest {
  test_generic() async {
    await assertErrorsInCode('''
abstract class A<E> {
  const A();
}
void f() {
  var a = const A<int>();
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 1),
      error(StaticWarningCode.CONST_WITH_ABSTRACT_CLASS, 64, 6),
    ]);

    ClassDeclaration classA = result.unit.declarations[0];
    FunctionDeclaration f = result.unit.declarations[1];
    BlockFunctionBody body = f.functionExpression.body;
    VariableDeclarationStatement a = body.block.statements[0];
    InstanceCreationExpression init = a.variables.variables[0].initializer;
    expect(init.staticType,
        classA.declaredElement.type.instantiate([typeProvider.intType]));
  }

  test_simple() async {
    await assertErrorsInCode('''
abstract class A {
  const A();
}
void f() {
  A a = const A();
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 49, 1),
      error(StaticWarningCode.CONST_WITH_ABSTRACT_CLASS, 59, 1),
    ]);
  }
}
