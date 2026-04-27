// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResolveToBoundTest);
  });
}

@reflectiveTest
class ResolveToBoundTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _check(parseType('dynamic'), 'dynamic');
  }

  test_functionType() {
    _check(parseType('void Function()'), 'void Function()');
  }

  test_interfaceType() {
    _check(parseType('int'), 'int');
    _check(parseType('int?'), 'int?');
  }

  test_typeParameter_bound() {
    withTypeParameterScope('T extends int', (scope) {
      _check(scope.parseType('T'), 'int');
    });

    withTypeParameterScope('T extends int?', (scope) {
      _check(scope.parseType('T'), 'int?');
    });
  }

  test_typeParameter_bound_functionType() {
    withTypeParameterScope('T extends void Function()', (scope) {
      _check(scope.parseType('T'), 'void Function()');
    });
  }

  test_typeParameter_bound_nested_noBound() {
    withTypeParameterScope('T, U extends T', (scope) {
      _check(scope.parseType('U'), 'Object?');
    });
  }

  test_typeParameter_bound_nested_none() {
    withTypeParameterScope('T extends int, U extends T', (scope) {
      _check(scope.parseType('U'), 'int');
    });
  }

  test_typeParameter_bound_nested_none_outerNullable() {
    withTypeParameterScope('T extends int, U extends T?', (scope) {
      _check(scope.parseType('U'), 'int?');
    });
  }

  test_typeParameter_bound_nested_question() {
    withTypeParameterScope('T extends int?, U extends T', (scope) {
      _check(scope.parseType('U'), 'int?');
    });
  }

  test_typeParameter_bound_nullableInner() {
    withTypeParameterScope('T extends int?', (scope) {
      _check(scope.parseType('T'), 'int?');
    });
  }

  test_typeParameter_bound_nullableInnerOuter() {
    withTypeParameterScope('T extends int?', (scope) {
      _check(scope.parseType('T?'), 'int?');
    });
  }

  test_typeParameter_bound_nullableOuter() {
    withTypeParameterScope('T extends int', (scope) {
      _check(scope.parseType('T?'), 'int?');
    });
  }

  test_typeParameter_noBound() {
    withTypeParameterScope('T', (scope) {
      _check(scope.parseType('T'), 'Object?');
    });
  }

  test_typeParameter_promotedBound() {
    withTypeParameterScope('T extends num', (scope) {
      _check(scope.parseType('T & int'), 'int');
    });

    withTypeParameterScope('T extends num?', (scope) {
      _check(scope.parseType('T & int?'), 'int?');
    });
  }

  test_void() {
    _check(parseType('void'), 'void');
  }

  void _check(TypeImpl type, String expectedStr) {
    var result = typeSystem.resolveToBound(type);
    var resultStr = _typeString(result);
    expect(resultStr, expectedStr);
  }

  String _typeString(DartType type) {
    return type.getDisplayString();
  }
}
