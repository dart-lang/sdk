// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DynamicBoundedTest);
    defineReflectiveTests(FunctionBoundedTest);
    defineReflectiveTests(InvalidBoundedTest);
  });
}

@reflectiveTest
class DynamicBoundedTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _assertDynamicBounded(dynamicType);
  }

  test_dynamic_typeParameter_hasBound_dynamic() {
    var T = typeParameter('T', bound: dynamicType);

    _assertDynamicBounded(
      typeParameterTypeNone(T),
    );
  }

  test_dynamic_typeParameter_hasBound_notDynamic() {
    var T = typeParameter('T', bound: intNone);

    _assertNotDynamicBounded(
      typeParameterTypeNone(T),
    );
  }

  test_dynamic_typeParameter_hasPromotedBound_dynamic() {
    var T = typeParameter('T');

    _assertDynamicBounded(
      typeParameterTypeNone(T, promotedBound: dynamicType),
    );
  }

  test_dynamic_typeParameter_hasPromotedBound_notDynamic() {
    var T = typeParameter('T');

    _assertNotDynamicBounded(
      typeParameterTypeNone(T, promotedBound: intNone),
    );
  }

  test_dynamic_typeParameter_noBound() {
    var T = typeParameter('T');

    _assertNotDynamicBounded(
      typeParameterTypeNone(T),
    );
  }

  test_functionType() {
    _assertNotDynamicBounded(
      functionTypeNone(returnType: voidNone),
    );

    _assertNotDynamicBounded(
      functionTypeNone(returnType: dynamicType),
    );
  }

  test_interfaceType() {
    _assertNotDynamicBounded(intNone);
    _assertNotDynamicBounded(intQuestion);
  }

  test_never() {
    _assertNotDynamicBounded(neverNone);
    _assertNotDynamicBounded(neverQuestion);
  }

  test_void() {
    _assertNotDynamicBounded(voidNone);
  }

  void _assertDynamicBounded(DartType type) {
    expect(typeSystem.isDynamicBounded(type), isTrue);
  }

  void _assertNotDynamicBounded(DartType type) {
    expect(typeSystem.isDynamicBounded(type), isFalse);
  }
}

@reflectiveTest
class FunctionBoundedTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _assertNotFunctionBounded(dynamicType);
  }

  test_dynamic_typeParameter_hasBound_functionType_none() {
    var T = typeParameter(
      'T',
      bound: functionTypeNone(returnType: voidNone),
    );

    _assertFunctionBounded(
      typeParameterTypeNone(T),
    );
  }

  test_dynamic_typeParameter_hasBound_functionType_question() {
    var T = typeParameter(
      'T',
      bound: functionTypeQuestion(returnType: voidNone),
    );

    _assertNotFunctionBounded(
      typeParameterTypeNone(T),
    );
  }

  test_dynamic_typeParameter_hasBound_notFunction() {
    var T = typeParameter('T', bound: intNone);

    _assertNotFunctionBounded(
      typeParameterTypeNone(T),
    );
  }

  test_dynamic_typeParameter_hasPromotedBound_functionType_none() {
    var T = typeParameter('T');

    _assertFunctionBounded(
      typeParameterTypeNone(
        T,
        promotedBound: functionTypeNone(
          returnType: voidNone,
        ),
      ),
    );
  }

  test_dynamic_typeParameter_hasPromotedBound_functionType_question() {
    var T = typeParameter('T');

    _assertNotFunctionBounded(
      typeParameterTypeNone(
        T,
        promotedBound: functionTypeQuestion(
          returnType: voidNone,
        ),
      ),
    );
  }

  test_dynamic_typeParameter_hasPromotedBound_notFunction() {
    var T = typeParameter('T');

    _assertNotFunctionBounded(
      typeParameterTypeNone(T, promotedBound: intNone),
    );
  }

  test_dynamic_typeParameter_noBound() {
    var T = typeParameter('T');

    _assertNotFunctionBounded(
      typeParameterTypeNone(T),
    );
  }

  test_functionType() {
    _assertFunctionBounded(
      functionTypeNone(returnType: voidNone),
    );
    _assertNotFunctionBounded(
      functionTypeQuestion(returnType: voidNone),
    );

    _assertFunctionBounded(
      functionTypeNone(returnType: dynamicType),
    );
  }

  test_interfaceType() {
    _assertNotFunctionBounded(intNone);
    _assertNotFunctionBounded(intQuestion);
  }

  test_never() {
    _assertNotFunctionBounded(neverNone);
    _assertNotFunctionBounded(neverQuestion);
  }

  test_void() {
    _assertNotFunctionBounded(voidNone);
  }

  void _assertFunctionBounded(DartType type) {
    expect(typeSystem.isFunctionBounded(type), isTrue);
  }

  void _assertNotFunctionBounded(DartType type) {
    expect(typeSystem.isFunctionBounded(type), isFalse);
  }
}

@reflectiveTest
class InvalidBoundedTest extends AbstractTypeSystemTest {
  test_dynamic_typeParameter_hasPromotedBound_notDynamic() {
    var T = typeParameter('T');

    _assertNotInvalidBounded(
      typeParameterTypeNone(T, promotedBound: intNone),
    );
  }

  test_functionType() {
    _assertNotInvalidBounded(
      functionTypeNone(returnType: voidNone),
    );

    _assertNotInvalidBounded(
      functionTypeNone(returnType: invalidType),
    );
  }

  test_interfaceType() {
    _assertNotInvalidBounded(intNone);
    _assertNotInvalidBounded(intQuestion);
  }

  test_invalid() {
    _assertInvalidBounded(invalidType);
  }

  test_never() {
    _assertNotInvalidBounded(neverNone);
    _assertNotInvalidBounded(neverQuestion);
  }

  test_typeParameter_hasBound_invalid() {
    var T = typeParameter('T', bound: invalidType);

    _assertInvalidBounded(
      typeParameterTypeNone(T),
    );
  }

  test_typeParameter_hasBound_notInvalid() {
    var T = typeParameter('T', bound: intNone);

    _assertNotInvalidBounded(
      typeParameterTypeNone(T),
    );
  }

  test_typeParameter_hasPromotedBound_invalidType() {
    var T = typeParameter('T');

    _assertInvalidBounded(
      typeParameterTypeNone(T, promotedBound: invalidType),
    );
  }

  test_typeParameter_noBound() {
    var T = typeParameter('T');

    _assertNotInvalidBounded(
      typeParameterTypeNone(T),
    );
  }

  test_void() {
    _assertNotInvalidBounded(voidNone);
  }

  void _assertInvalidBounded(DartType type) {
    expect(typeSystem.isInvalidBounded(type), isTrue);
  }

  void _assertNotInvalidBounded(DartType type) {
    expect(typeSystem.isInvalidBounded(type), isFalse);
  }
}
