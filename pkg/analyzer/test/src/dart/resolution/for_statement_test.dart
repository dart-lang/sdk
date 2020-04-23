// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForEachStatementResolutionTest);
    defineReflectiveTests(ForLoopStatementResolutionTest);
  });
}

@reflectiveTest
class ForEachStatementResolutionTest extends DriverResolutionTest {
  test_importPrefix_asIterable() async {
    // TODO(scheglov) Remove this test (already tested as import prefix).
    // TODO(scheglov) Move other for-in tests here.
    await assertErrorsInCode(r'''
import 'dart:async' as p;

main() {
  for (var x in p) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 52, 1),
    ]);

    var xRef = findNode.simple('x in');
    expect(xRef.staticElement, isNotNull);

    var pRef = findNode.simple('p) {}');
    assertElement(pRef, findElement.prefix('p'));
    assertTypeDynamic(pRef);
  }
}

@reflectiveTest
class ForLoopStatementResolutionTest extends DriverResolutionTest {
  test_condition_rewrite() async {
    await assertNoErrorsInCode(r'''
main(bool Function() b) {
  for (; b(); ) {
    print(0);
  }
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('b()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'bool Function()',
      type: 'bool',
    );
  }
}
