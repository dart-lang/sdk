// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexExpressionTest);
    defineReflectiveTests(IndexExpressionWithNnbdTest);
  });
}

@reflectiveTest
class IndexExpressionTest extends DriverResolutionTest {
  test_read() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator[](int index) => false;
}

main(A a) {
  a[0];
}
''');

    var indexElement = findElement.method('[]');

    var indexExpression = findNode.index('a[0]');
    assertIndexExpression(
      indexExpression,
      readElement: indexElement,
      writeElement: null,
      type: 'bool',
    );
    assertParameterElement(
      indexExpression.index,
      indexElement.parameters[0],
    );
  }

  test_read_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  T operator[](int index) => throw 42;
}

main(A<double> a) {
  a[0];
}
''');

    var indexElement = findElement.method('[]');

    var indexExpression = findNode.index('a[0]');
    assertIndexExpression(
      indexExpression,
      readElement: elementMatcher(
        indexElement,
        substitution: {'T': 'double'},
      ),
      writeElement: null,
      type: 'double',
    );
    assertParameterElement(
      indexExpression.index,
      indexElement.parameters[0],
    );
  }

  test_readWrite() async {
    await assertNoErrorsInCode(r'''
class A {
  num operator[](int index) => 0;
  void operator[]=(int index, num value) {}
}

main(A a) {
  a[0] += 1.2;
}
''');

    var indexElement = findElement.method('[]');
    var indexEqElement = findElement.method('[]=');
    var numPlusElement = numElement.getMethod('+');

    var indexExpression = findNode.index('a[0]');
    assertIndexExpression(
      indexExpression,
      readElement: indexElement,
      writeElement: indexEqElement,
      type: 'num',
    );
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      operatorElement: elementMatcher(
        numPlusElement,
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'num',
    );
    assertParameterElement(
      assignment.rightHandSide,
      numPlusElement.parameters[0],
    );
  }

  test_readWrite_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  T operator[](int index) => throw 42;
  void operator[]=(int index, T value) {}
}

main(A<double> a) {
  a[0] += 1.2;
}
''');

    var indexElement = findElement.method('[]');
    var indexEqElement = findElement.method('[]=');
    var doublePlusElement = doubleElement.getMethod('+');

    var indexExpression = findNode.index('a[0]');
    assertIndexExpression(
      indexExpression,
      readElement: elementMatcher(
        indexElement,
        substitution: {'T': 'double'},
      ),
      writeElement: elementMatcher(
        indexEqElement,
        substitution: {'T': 'double'},
      ),
      type: 'double',
    );
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      operatorElement: elementMatcher(
        doublePlusElement,
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'double',
    );
    assertParameterElement(
      assignment.rightHandSide,
      doublePlusElement.parameters[0],
    );
  }

  test_write() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator[]=(int index, num value) {}
}

main(A a) {
  a[0] = 1.2;
}
''');

    var indexEqElement = findElement.method('[]=');

    var indexExpression = findNode.index('a[0]');
    assertIndexExpression(
      indexExpression,
      readElement: null,
      writeElement: indexEqElement,
      type: null,
    );
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'double',
    );
    assertParameterElement(assignment.rightHandSide, null);
  }

  test_write_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  void operator[]=(int index, T value) {}
}

main(A<double> a) {
  a[0] = 1.2;
}
''');

    var indexEqElement = findElement.method('[]=');

    var indexExpression = findNode.index('a[0]');
    assertIndexExpression(
      indexExpression,
      readElement: null,
      writeElement: elementMatcher(
        indexEqElement,
        substitution: {'T': 'double'},
      ),
      type: null,
    );
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'double',
    );
    assertParameterElement(assignment.rightHandSide, null);
  }
}

@reflectiveTest
class IndexExpressionWithNnbdTest extends IndexExpressionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;

  test_read_cascade_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator[](int index) => false;
}

main(A? a) {
  a?..[0]..[1];
}
''');

    var indexElement = findElement.method('[]');

    assertIndexExpression(
      findNode.index('..[0]'),
      readElement: indexElement,
      writeElement: null,
      type: 'bool',
    );

    assertIndexExpression(
      findNode.index('..[1]'),
      readElement: indexElement,
      writeElement: null,
      type: 'bool',
    );

    assertType(findNode.cascade('a?'), 'A?');
  }

  test_read_nullable() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator[](int index) => false;
}

main(A? a) {
  a?[0];
}
''');

    var indexElement = findElement.method('[]');

    var indexExpression = findNode.index('a?[0]');
    assertIndexExpression(
      indexExpression,
      readElement: indexElement,
      writeElement: null,
      type: 'bool?',
    );
  }

  test_readWrite_nullable() async {
    await assertNoErrorsInCode(r'''
class A {
  num operator[](int index) => 0;
  void operator[]=(int index, num value) {}
}

main(A? a) {
  a?[0] += 1.2;
}
''');

    var indexElement = findElement.method('[]');
    var indexEqElement = findElement.method('[]=');
    var numPlusElement = numElement.getMethod('+');

    var indexExpression = findNode.index('a?[0]');
    assertIndexExpression(
      indexExpression,
      readElement: indexElement,
      writeElement: indexEqElement,
      type: 'num',
    );
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      operatorElement: numPlusElement,
      type: 'num?',
    );
    assertParameterElement(
      assignment.rightHandSide,
      numPlusElement.parameters[0],
    );
  }

  test_write_cascade_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator[]=(int index, A a) {}
}

main(A? a) {
  a?..[0] = a..[1] = a;
}
''');

    var indexEqElement = findElement.method('[]=');

    assertIndexExpression(
      findNode.index('..[0]'),
      readElement: null,
      writeElement: indexEqElement,
      type: null,
    );

    assertIndexExpression(
      findNode.index('..[1]'),
      readElement: null,
      writeElement: indexEqElement,
      type: null,
    );

    assertType(findNode.cascade('a?'), 'A?');
  }

  test_write_nullable() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator[]=(int index, num value) {}
}

main(A? a) {
  a?[0] = 1.2;
}
''');

    var indexEqElement = findElement.method('[]=');

    var indexExpression = findNode.index('a?[0]');
    assertIndexExpression(
      indexExpression,
      readElement: null,
      writeElement: indexEqElement,
      type: null,
    );
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      operatorElement: null,
      type: 'double?',
    );
    assertParameterElement(assignment.rightHandSide, null);
  }
}
