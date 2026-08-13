// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/constant/has_type_parameter_reference.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HasTypeParameterReferenceTest);
  });
}

@reflectiveTest
class HasTypeParameterReferenceTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _checkFalse(parseType('dynamic'));
  }

  test_functionType() {
    _checkFalse(parseType('void Function()'));

    withTypeParameterScope('T', (scope) {
      _checkTrue(scope.parseType('T Function()'));
      _checkTrue(scope.parseType('void Function(T)'));
      _checkTrue(scope.parseType('void Function<S extends T>()'));
    });
  }

  test_interfaceType() {
    _checkFalse(parseType('int'));
    _checkFalse(parseType('int?'));

    withTypeParameterScope('T', (scope) {
      _checkTrue(scope.parseType('List<T>'));
      _checkTrue(scope.parseType('Map<T, int>'));
      _checkTrue(scope.parseType('Map<int, T>'));
    });
  }

  test_typeParameter() {
    withTypeParameterScope('T', (scope) {
      _checkTrue(scope.parseType('T'));
      _checkTrue(scope.parseType('T?'));
    });
  }

  test_void() {
    _checkFalse(parseType('void'));
  }

  void _checkFalse(DartType type) {
    expect(hasTypeParameterReference(type), isFalse);
  }

  void _checkTrue(DartType type) {
    expect(hasTypeParameterReference(type), isTrue);
  }
}
