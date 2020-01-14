// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionInvocationTest);
    defineReflectiveTests(FunctionExpressionInvocationWithNnbdTest);
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

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('(0)'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_dynamic_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
main() {
  (main as dynamic)<bool, int>(0);
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('(0)'),
      element: null,
      typeArgumentTypes: ['bool', 'int'],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }
}

@reflectiveTest
class FunctionExpressionInvocationWithNnbdTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.non_nullable]
    ..implicitCasts = false;

  @override
  bool get typeToStringWithNullability => true;

  test_call_infer_fromArguments() async {
    await assertNoErrorsInCode(r'''
class A {
  void call<T>(T t) {}
}

main(A a) {
  a(0);
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('a(0)'),
      element: findElement.method('call'),
      typeArgumentTypes: ['int'],
      invokeType: 'void Function(int)',
      type: 'void',
    );
  }

  test_call_infer_fromArguments_listLiteral() async {
    await resolveTestCode(r'''
class A {
  List<T> call<T>(List<T> _)  {
    throw 42;
  }
}

main(A a) {
  a([0]);
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('a(['),
      element: findElement.method('call'),
      typeArgumentTypes: ['int'],
      invokeType: 'List<int> Function(List<int>)',
      type: 'List<int>',
    );
  }

  test_call_infer_fromContext() async {
    await assertNoErrorsInCode(r'''
class A {
  T call<T>() {
    throw 42;
  }
}

main(A a, int context) {
  context = a();
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('a()'),
      element: findElement.method('call'),
      typeArgumentTypes: ['int'],
      invokeType: 'int Function()',
      type: 'int',
    );
  }

  test_call_typeArguments() async {
    await assertNoErrorsInCode(r'''
class A {
  T call<T>() {
    throw 42;
  }
}

main(A a) {
  a<int>();
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('a<int>()'),
      element: findElement.method('call'),
      typeArgumentTypes: ['int'],
      invokeType: 'int Function()',
      type: 'int',
    );
  }
}
