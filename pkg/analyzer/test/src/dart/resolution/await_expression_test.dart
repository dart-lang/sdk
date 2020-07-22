// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'with_null_safety_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitExpressionResolutionTest);
    defineReflectiveTests(AwaitExpressionResolutionWithNullSafetyTest);
  });
}

@reflectiveTest
class AwaitExpressionResolutionTest extends DriverResolutionTest {
  test_future() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

f(Future<int> a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int');
  }

  test_futureOr() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

f(FutureOr<int> a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int');
  }
}

@reflectiveTest
class AwaitExpressionResolutionWithNullSafetyTest extends DriverResolutionTest
    with WithNullSafetyMixin {
  test_futureOrQ() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

f(FutureOr<int>? a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int?');
  }

  test_futureQ() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

f(Future<int>? a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int?');
  }
}
