// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForEachElementTest);
    defineReflectiveTests(ForEachElementWithNnbdTest);
    defineReflectiveTests(ForLoopElementTest);
  });
}

@reflectiveTest
class ForEachElementTest extends DriverResolutionTest {
  test_withDeclaration_scope() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i in [1, 2, 3]) i]; // 1
  <double>[for (var i in [1.1, 2.2, 3.3]) i]; // 2
}
''');

    assertElement(
      findNode.simple('i]; // 1'),
      findNode.simple('i in [1, 2').staticElement,
    );
    assertElement(
      findNode.simple('i]; // 2'),
      findNode.simple('i in [1.1').staticElement,
    );
  }

  test_withIdentifier_topLevelVariable() async {
    await assertNoErrorsInCode(r'''
int v = 0;
main() {
  <int>[for (v in [1, 2, 3]) v];
}
''');
    assertElement(
      findNode.simple('v];'),
      findElement.topGet('v'),
    );
  }
}

@reflectiveTest
class ForEachElementWithNnbdTest extends ForEachElementTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.6.0', additionalFeatures: [Feature.non_nullable]);

  test_optIn_fromOptOut() async {
    newFile('/test/lib/a.dart', content: r'''
class A implements Iterable<int> {
  Iterator<int> iterator => throw 0;
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

main(A a) {
  for (var v in a) {
    v;
  }
}
''');
  }
}

@reflectiveTest
class ForLoopElementTest extends DriverResolutionTest {
  test_condition_rewrite() async {
    await assertNoErrorsInCode(r'''
main(bool Function() b) {
  <int>[for (; b(); ) 0];
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

  test_declaredVariableScope() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i = 1; i < 10; i += 3) i]; // 1
  <double>[for (var i = 1.1; i < 10; i += 5) i]; // 2
}
''');

    assertElement(
      findNode.simple('i]; // 1'),
      findNode.simple('i = 1;').staticElement,
    );
    assertElement(
      findNode.simple('i]; // 2'),
      findNode.simple('i = 1.1;').staticElement,
    );
  }
}
