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
    var T1 = typeParameter('T');
    var T2 = typeParameter('T');

    expect(T1 == T1, isTrue);
    expect(T2 == T2, isTrue);

    expect(T1 == T2, isFalse);
    expect(T2 == T1, isFalse);
  }
}

@reflectiveTest
class TypeParameterTypeTest extends AbstractTypeSystemTest {
  test_equal_differentElements() {
    var T1 = typeParameter('T');
    var T2 = typeParameter('T');

    _assertEqual(typeParameterTypeNone(T1), typeParameterTypeNone(T2), isFalse);
  }

  test_equal_sameElement() {
    var T = typeParameter('T');

    _assertEqual(typeParameterTypeNone(T), typeParameterTypeNone(T), isTrue);

    _assertEqual(
      typeParameterTypeNone(T),
      typeParameterTypeQuestion(T),
      isFalse,
    );

    _assertEqual(
      typeParameterTypeQuestion(T),
      typeParameterTypeNone(T),
      isFalse,
    );

    _assertEqual(
      typeParameterTypeQuestion(T),
      typeParameterTypeQuestion(T),
      isTrue,
    );
  }

  test_equal_sameElement_promotedBounds() {
    var T = typeParameter('T');

    _assertEqual(
      promotedTypeParameterTypeNone(T, intNone),
      promotedTypeParameterTypeNone(T, intNone),
      isTrue,
    );

    _assertEqual(
      promotedTypeParameterTypeNone(T, intNone),
      promotedTypeParameterTypeNone(T, doubleNone),
      isFalse,
    );

    _assertEqual(
      promotedTypeParameterTypeNone(T, intNone),
      typeParameterTypeNone(T),
      isFalse,
    );

    _assertEqual(
      typeParameterTypeNone(T),
      promotedTypeParameterTypeNone(T, intNone),
      isFalse,
    );
  }

  void _assertEqual(DartType T1, DartType T2, matcher) {
    expect(T1 == T2, matcher);
  }
}
