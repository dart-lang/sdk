// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeParameterElementTest);
    defineReflectiveTests(TypeParameterTypeTest);
  });
}

@reflectiveTest
class TypeParameterElementTest extends AbstractTypeSystemTest {
  test_equal() {
    withTypeParameterScope('T', (scope1) {
      var T1 = scope1.typeParameter('T');
      scope1.withTypeParameterScope('T', (scope2) {
        var T2 = scope2.typeParameter('T');

        expect(T1 == T1, isTrue);
        expect(T2 == T2, isTrue);

        expect(T1 == T2, isFalse);
        expect(T2 == T1, isFalse);
      });
    });
  }
}

@reflectiveTest
class TypeParameterTypeTest extends AbstractTypeSystemTest {
  test_equal_differentElements() {
    withTypeParameterScope('T', (scope1) {
      var T1 = scope1.parseType('T');
      scope1.withTypeParameterScope('T', (scope2) {
        var T2 = scope2.parseType('T');
        _assertEqual(T1, T2, isFalse);
      });
    });
  }

  test_equal_sameElement() {
    withTypeParameterScope('T', (scope) {
      var T = scope.parseType('T');
      _assertEqual(T, T, isTrue);
      _assertEqual(T, scope.parseType('T?'), isFalse);
      _assertEqual(scope.parseType('T?'), T, isFalse);
      _assertEqual(scope.parseType('T?'), scope.parseType('T?'), isTrue);
    });
  }

  test_equal_sameElement_promotedBounds() {
    withTypeParameterScope('T', (scope) {
      var T = scope.parseType('T & int');
      _assertEqual(T, T, isTrue);
      _assertEqual(T, scope.parseType('T & double'), isFalse);
      _assertEqual(T, scope.parseType('T'), isFalse);
      _assertEqual(scope.parseType('T'), T, isFalse);
    });
  }

  void _assertEqual(DartType T1, DartType T2, matcher) {
    expect(T1 == T2, matcher);
  }
}
