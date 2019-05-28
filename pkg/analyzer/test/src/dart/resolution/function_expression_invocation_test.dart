// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionInvocationTest);
  });
}

@reflectiveTest
class FunctionExpressionInvocationTest extends DriverResolutionTest {
  test_dynamic_withoutTypeArguments() async {
    await assertNoErrorsInCode(r'''
main() {
  (main as dynamic)(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('(0)');
    assertTypeDynamic(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeArgumentTypes(invocation, []);
  }

  test_dynamic_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
main() {
  (main as dynamic)<bool, int>(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('(0)');
    assertTypeDynamic(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeArgumentTypes(invocation, ['bool', 'int']);
  }

  test_generic() async {
    await assertNoErrorsInCode(r'''
main() {
  (f)(0);
}

bool f<T>(T a) => true;
''');

    var invocation = findNode.functionExpressionInvocation('(0)');
    assertType(invocation, 'bool');
    assertInvokeType(invocation, 'bool Function(int)');
    assertTypeArgumentTypes(invocation, ['int']);
  }
}
