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
    _assertDynamicBounded(parseType('dynamic'));
  }

  test_dynamic_typeParameter_hasBound_dynamic() {
    withTypeParameterScope('T extends dynamic', (scope) {
      _assertDynamicBounded(scope.parseType('T'));
    });
  }

  test_dynamic_typeParameter_hasBound_notDynamic() {
    withTypeParameterScope('T extends int', (scope) {
      _assertNotDynamicBounded(scope.parseType('T'));
    });
  }

  test_dynamic_typeParameter_hasPromotedBound_dynamic() {
    withTypeParameterScope('T', (scope) {
      _assertDynamicBounded(scope.parseType('T & dynamic'));
    });
  }

  test_dynamic_typeParameter_hasPromotedBound_notDynamic() {
    withTypeParameterScope('T', (scope) {
      _assertNotDynamicBounded(scope.parseType('T & int'));
    });
  }

  test_dynamic_typeParameter_noBound() {
    withTypeParameterScope('T', (scope) {
      _assertNotDynamicBounded(scope.parseType('T'));
    });
  }

  test_functionType() {
    _assertNotDynamicBounded(parseType('void Function()'));

    _assertNotDynamicBounded(parseType('dynamic Function()'));
  }

  test_interfaceType() {
    _assertNotDynamicBounded(parseType('int'));
    _assertNotDynamicBounded(parseType('int?'));
  }

  test_never() {
    _assertNotDynamicBounded(parseType('Never'));
    _assertNotDynamicBounded(parseType('Never?'));
  }

  test_void() {
    _assertNotDynamicBounded(parseType('void'));
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
    _assertNotFunctionBounded(parseType('dynamic'));
  }

  test_dynamic_typeParameter_hasBound_functionType_none() {
    withTypeParameterScope('T extends void Function()', (scope) {
      _assertFunctionBounded(scope.parseType('T'));
    });
  }

  test_dynamic_typeParameter_hasBound_functionType_question() {
    withTypeParameterScope('T extends void Function()?', (scope) {
      _assertNotFunctionBounded(scope.parseType('T'));
    });
  }

  test_dynamic_typeParameter_hasBound_notFunction() {
    withTypeParameterScope('T extends int', (scope) {
      _assertNotFunctionBounded(scope.parseType('T'));
    });
  }

  test_dynamic_typeParameter_hasPromotedBound_functionType_none() {
    withTypeParameterScope('T', (scope) {
      _assertFunctionBounded(scope.parseType('T & void Function()'));
    });
  }

  test_dynamic_typeParameter_hasPromotedBound_functionType_question() {
    withTypeParameterScope('T', (scope) {
      _assertNotFunctionBounded(scope.parseType('T & void Function()?'));
    });
  }

  test_dynamic_typeParameter_hasPromotedBound_notFunction() {
    withTypeParameterScope('T', (scope) {
      _assertNotFunctionBounded(scope.parseType('T & int'));
    });
  }

  test_dynamic_typeParameter_noBound() {
    withTypeParameterScope('T', (scope) {
      _assertNotFunctionBounded(scope.parseType('T'));
    });
  }

  test_functionType() {
    _assertFunctionBounded(parseType('void Function()'));
    _assertNotFunctionBounded(parseType('void Function()?'));

    _assertFunctionBounded(parseType('dynamic Function()'));
  }

  test_interfaceType() {
    _assertNotFunctionBounded(parseType('int'));
    _assertNotFunctionBounded(parseType('int?'));
  }

  test_never() {
    _assertNotFunctionBounded(parseType('Never'));
    _assertNotFunctionBounded(parseType('Never?'));
  }

  test_void() {
    _assertNotFunctionBounded(parseType('void'));
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
    withTypeParameterScope('T', (scope) {
      _assertNotInvalidBounded(scope.parseType('T & int'));
    });
  }

  test_functionType() {
    _assertNotInvalidBounded(parseType('void Function()'));

    _assertNotInvalidBounded(parseType('InvalidType Function()'));
  }

  test_interfaceType() {
    _assertNotInvalidBounded(parseType('int'));
    _assertNotInvalidBounded(parseType('int?'));
  }

  test_invalid() {
    _assertInvalidBounded(parseType('InvalidType'));
  }

  test_never() {
    _assertNotInvalidBounded(parseType('Never'));
    _assertNotInvalidBounded(parseType('Never?'));
  }

  test_typeParameter_hasBound_invalid() {
    withTypeParameterScope('T extends InvalidType', (scope) {
      _assertInvalidBounded(scope.parseType('T'));
    });
  }

  test_typeParameter_hasBound_notInvalid() {
    withTypeParameterScope('T extends int', (scope) {
      _assertNotInvalidBounded(scope.parseType('T'));
    });
  }

  test_typeParameter_hasPromotedBound_invalidType() {
    withTypeParameterScope('T', (scope) {
      _assertInvalidBounded(scope.parseType('T & InvalidType'));
    });
  }

  test_typeParameter_noBound() {
    withTypeParameterScope('T', (scope) {
      _assertNotInvalidBounded(scope.parseType('T'));
    });
  }

  test_void() {
    _assertNotInvalidBounded(parseType('void'));
  }

  void _assertInvalidBounded(DartType type) {
    expect(typeSystem.isInvalidBounded(type), isTrue);
  }

  void _assertNotInvalidBounded(DartType type) {
    expect(typeSystem.isInvalidBounded(type), isFalse);
  }
}
