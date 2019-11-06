// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'element_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeParameterElementTest);
    defineReflectiveTests(TypeParameterTypeTest);
  });
}

@reflectiveTest
class TypeParameterElementTest extends _TypeParameterElementBase {
  test_equal_elementElement_sameLocation() {
    var T1 = typeParameter('T');
    var T2 = typeParameter('T');
    var U = typeParameter('U');

    _setEnclosingElement(T1);
    _setEnclosingElement(T2);
    _setEnclosingElement(U);

    expect(T1 == T1, isTrue);
    expect(T2 == T2, isTrue);
    expect(U == U, isTrue);

    expect(T1 == T2, isTrue);
    expect(T2 == T1, isTrue);

    expect(U == T1, isFalse);
    expect(T1 == U, isFalse);
  }

  test_equal_elementElement_synthetic() {
    var T1 = typeParameter('T');
    var T2 = typeParameter('T');
    expect(T1 == T1, isTrue);
    expect(T2 == T2, isTrue);
    expect(T1 == T2, isFalse);
    expect(T2 == T1, isFalse);
  }

  test_equal_elementMember_sameBase_differentBounds() {
    var T = typeParameter('T');
    _setEnclosingElement(T);

    var M = TypeParameterMember(T, null, typeProvider.intType);

    expect(_equal(T, M), isTrue);
    expect(_equal(M, T), isTrue);
  }

  test_equal_elementMember_sameBase_equalBounds() {
    var T = typeParameter('T', bound: typeProvider.intType);
    _setEnclosingElement(T);

    var M = TypeParameterMember(T, null, typeProvider.intType);

    expect(_equal(T, M), isTrue);
    expect(_equal(M, T), isTrue);
  }

  test_equal_memberMember_differentBase() {
    var T1 = typeParameter('T1');
    var T2 = typeParameter('T2');

    _setEnclosingElement(T1);
    _setEnclosingElement(T2);

    var M1 = TypeParameterMember(T1, null, typeProvider.numType);
    var M2 = TypeParameterMember(T2, null, typeProvider.numType);

    expect(M1 == M2, isFalse);
  }

  test_equal_memberMember_sameBase_differentBounds() {
    var T = typeParameter('T');
    _setEnclosingElement(T);

    var M1 = TypeParameterMember(T, null, typeProvider.intType);
    var M2 = TypeParameterMember(T, null, typeProvider.doubleType);

    expect(M1 == M2, isTrue);
  }

  test_equal_memberMember_sameBase_equalBounds() {
    var T = typeParameter('T');
    _setEnclosingElement(T);

    var M1 = TypeParameterMember(T, null, typeProvider.numType);
    var M2 = TypeParameterMember(T, null, typeProvider.numType);

    expect(M1 == M2, isTrue);
    expect(M2 == M1, isTrue);
  }

  /// We use this method to work around the lint for using `==` for values
  /// that are not of the same type.
  static bool _equal(a, b) {
    return a == b;
  }
}

@reflectiveTest
class TypeParameterTypeTest extends _TypeParameterElementBase {
  test_equal_equalElements() {
    var T1 = typeParameter('T');
    var T2 = typeParameter('T');

    _setEnclosingElement(T1);
    _setEnclosingElement(T2);

    expect(typeParameterTypeNone(T1) == typeParameterTypeNone(T2), isTrue);
    expect(typeParameterTypeNone(T2) == typeParameterTypeNone(T1), isTrue);

    expect(typeParameterTypeNone(T1) == typeParameterTypeStar(T2), isFalse);
    expect(typeParameterTypeStar(T1) == typeParameterTypeNone(T2), isFalse);
  }

  test_equal_sameElement_differentBounds() {
    var T = typeParameter('T');
    _setEnclosingElement(T);

    var T1 = TypeParameterMember(T, null, typeProvider.intType);
    var T2 = TypeParameterMember(T, null, typeProvider.doubleType);

    expect(typeParameterTypeNone(T1) == typeParameterTypeNone(T1), isTrue);

    expect(typeParameterTypeNone(T1) == typeParameterTypeNone(T2), isFalse);
    expect(typeParameterTypeNone(T2) == typeParameterTypeNone(T1), isFalse);

    expect(typeParameterTypeNone(T1) == typeParameterTypeNone(T), isFalse);
    expect(typeParameterTypeNone(T) == typeParameterTypeNone(T1), isFalse);
  }

  test_equal_sameElements() {
    var T = typeParameter('T');

    expect(typeParameterTypeNone(T) == typeParameterTypeNone(T), isTrue);
    expect(typeParameterTypeNone(T) == typeParameterTypeStar(T), isFalse);
    expect(typeParameterTypeNone(T) == typeParameterTypeQuestion(T), isFalse);

    expect(typeParameterTypeStar(T) == typeParameterTypeNone(T), isFalse);
    expect(typeParameterTypeStar(T) == typeParameterTypeStar(T), isTrue);
    expect(typeParameterTypeNone(T) == typeParameterTypeQuestion(T), isFalse);

    expect(
      typeParameterTypeQuestion(T) == typeParameterTypeNone(T),
      isFalse,
    );
    expect(
      typeParameterTypeQuestion(T) == typeParameterTypeStar(T),
      isFalse,
    );
    expect(
      typeParameterTypeQuestion(T) == typeParameterTypeQuestion(T),
      isTrue,
    );
  }
}

class _TypeParameterElementBase extends AbstractTypeTest {
  /// Ensure that the [element] has a location.
  void _setEnclosingElement(TypeParameterElementImpl element) {
    element.enclosingElement = method('foo', typeProvider.voidType);
  }
}
