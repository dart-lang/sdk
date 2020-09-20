// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/null_safety_understanding_flag.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceTopBottomLegacyTest);
    defineReflectiveTests(ReplaceTopBottomNullSafetyTest);
  });
}

@reflectiveTest
class ReplaceTopBottomLegacyTest extends AbstractTypeSystemTest {
  test_contravariant_bottom() {
    // Not contravariant.
    _check(nullStar, 'Null*');

    _check(
      functionTypeStar(returnType: intStar, parameters: [
        requiredParameter(type: nullStar),
      ]),
      'int* Function(dynamic)*',
    );
  }

  test_covariant_top() {
    _check(objectStar, 'Null*');
    _check(dynamicNone, 'Null*');
    _check(voidNone, 'Null*');

    _check(futureOrStar(objectStar), 'Null*');
    _check(futureOrStar(dynamicNone), 'Null*');
    _check(futureOrStar(voidNone), 'Null*');
    _check(futureOrStar(futureOrStar(voidNone)), 'Null*');

    _check(
      functionTypeStar(returnType: intStar, parameters: [
        requiredParameter(
          type: functionTypeStar(returnType: intStar, parameters: [
            requiredParameter(type: objectStar),
          ]),
        ),
      ]),
      'int* Function(int* Function(Null*)*)*',
      typeStr: 'int* Function(int* Function(Object*)*)*',
    );

    _check(listStar(intStar), 'List<int*>*');
  }

  void _check(DartType type, String expectedStr, {String typeStr}) {
    NullSafetyUnderstandingFlag.enableNullSafetyTypes(() {
      if (typeStr != null) {
        expect(_typeString(type), typeStr);
      }

      var result = typeSystem.replaceTopAndBottom(type);
      var resultStr = _typeString(result);
      expect(resultStr, expectedStr);
    });
  }

  String _typeString(TypeImpl type) {
    return type.getDisplayString(withNullability: true);
  }
}

@reflectiveTest
class ReplaceTopBottomNullSafetyTest extends AbstractTypeSystemNullSafetyTest {
  test_contravariant_bottom() {
    // Not contravariant.
    _check(neverNone, 'Never');

    void checkContravariant(DartType type, String expectedStr) {
      _check(
        functionTypeNone(returnType: intNone, parameters: [
          requiredParameter(type: type),
        ]),
        'int Function($expectedStr)',
      );
    }

    checkContravariant(neverNone, 'Object?');

    checkContravariant(
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
      'Object?',
    );
  }

  test_covariant_top() {
    _check(objectQuestion, 'Never');
    _check(objectStar, 'Never');
    _check(dynamicNone, 'Never');
    _check(voidNone, 'Never');

    _check(futureOrNone(objectQuestion), 'Never');
    _check(futureOrNone(objectStar), 'Never');
    _check(futureOrNone(dynamicNone), 'Never');
    _check(futureOrNone(voidNone), 'Never');
    _check(futureOrNone(futureOrNone(voidNone)), 'Never');

    _check(
      functionTypeNone(returnType: intNone, parameters: [
        requiredParameter(
          type: functionTypeNone(returnType: intNone, parameters: [
            requiredParameter(type: objectQuestion),
          ]),
        ),
      ]),
      'int Function(int Function(Never))',
      typeStr: 'int Function(int Function(Object?))',
    );

    _check(listNone(intNone), 'List<int>');
    _check(listNone(intQuestion), 'List<int?>');
    _check(listQuestion(intNone), 'List<int>?');
    _check(listQuestion(intQuestion), 'List<int?>?');
  }

  void _check(DartType type, String expectedStr, {String typeStr}) {
    NullSafetyUnderstandingFlag.enableNullSafetyTypes(() {
      if (typeStr != null) {
        expect(_typeString(type), typeStr);
      }

      var result = typeSystem.replaceTopAndBottom(type);
      var resultStr = _typeString(result);
      expect(resultStr, expectedStr);
    });
  }

  String _typeString(TypeImpl type) {
    return type.getDisplayString(withNullability: true);
  }
}
