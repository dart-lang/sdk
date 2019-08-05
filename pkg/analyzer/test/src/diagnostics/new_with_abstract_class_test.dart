// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_api/src/frontend/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewWithAbstractClassTest);
  });
}

@reflectiveTest
class NewWithAbstractClassTest extends DriverResolutionTest {
  test_generic() async {
    await assertErrorsInCode('''
abstract class A<E> {}
void f() {
  new A<int>();
}
''', [
      error(StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, 40, 6),
    ]);

    ClassDeclaration classA = result.unit.declarations[0];
    FunctionDeclaration f = result.unit.declarations[1];
    BlockFunctionBody body = f.functionExpression.body;
    ExpressionStatement s = body.block.statements[0];
    InstanceCreationExpression init = s.expression;
    expect(init.staticType,
        classA.declaredElement.type.instantiate([typeProvider.intType]));
  }

  test_nonGeneric() async {
    await assertErrorsInCode('''
abstract class A {}
void f() {
  new A();
}
''', [
      error(StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, 37, 1),
    ]);
  }
}
