// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

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
class AwaitExpressionResolutionWithNullSafetyTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  @override
  bool get typeToStringWithNullability => true;

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
