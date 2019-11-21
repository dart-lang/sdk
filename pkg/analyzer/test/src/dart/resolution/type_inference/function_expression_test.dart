// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionTest);
    defineReflectiveTests(FunctionExpressionWithNnbdTest);
  });
}

@reflectiveTest
class FunctionExpressionTest extends DriverResolutionTest {
  test_closure_returnType() async {
    await assertNoErrorsInCode('''
typedef ReturnsVoid = void Function(int a);

void setClosureContext(ReturnsVoid a) {}

void fail(String message) {
  throw message;
}

void main() {
  setClosureContext((a) {
    if (a == 42) return;
  });
}
''');
    var element = findNode.functionExpression('(a)').declaredElement;
    if (typeToStringWithNullability) {
      assertElementTypeString(element.returnType, 'Never');
    } else {
      assertElementTypeString(element.returnType, 'Null');
    }
  }

  test_return() async {
    await resolveTestCode('''
var f = (bool b) {
  if (b) {
    return 0;
  }
  return 1.2;
}
''');
    assertElementTypeString(
      findElement.topVar('f').type,
      'num Function(bool)',
    );
  }
}

@reflectiveTest
class FunctionExpressionWithNnbdTest extends FunctionExpressionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;
}
