// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopMergeTest);
  });
}

@reflectiveTest
class TopMergeTest extends AbstractTypeSystemTest {
  test_differentStructure() {
    _checkThrows(parseType('int'), parseType('void Function()'));

    withTypeParameterScope('T', (scope) {
      _checkThrows(parseType('int'), scope.parseType('T'));
      _checkThrows(parseType('void Function()'), scope.parseType('T'));
    });
  }

  test_dynamic() {
    // NNBD_TOP_MERGE(dynamic, dynamic) = dynamic
    _check(parseType('dynamic'), parseType('dynamic'), parseType('dynamic'));
  }

  test_function_formalParameters_differentCount() {
    _checkThrows(
      parseFunctionType('void Function()'),
      parseFunctionType('void Function(int)'),
    );
  }

  test_function_parameters_covariant() {
    _check(
      parseFunctionType('void Function(covariant Object?)'),
      parseFunctionType('void Function(dynamic)'),
      parseFunctionType('void Function(covariant Object?)'),
    );

    _check(
      parseFunctionType('void Function(covariant int)'),
      parseFunctionType('void Function(num)'),
      parseFunctionType('void Function(covariant num)'),
    );
  }

  test_function_parameters_kind_optionalPositional_optionalPositional() {
    _check(
      parseFunctionType('void Function([int])'),
      parseFunctionType('void Function([int])'),
      parseFunctionType('void Function([int])'),
    );
  }

  test_function_parameters_kind_requiredNamed_optionalNamed() {
    _checkThrows(
      parseFunctionType('void Function({required int a})'),
      parseFunctionType('void Function({int a})'),
    );
  }

  test_function_parameters_kind_requiredPositional_optionalPositional() {
    _checkThrows(
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function([int])'),
    );

    _checkThrows(
      parseFunctionType('void Function({int a})'),
      parseFunctionType('void Function({int b})'),
    );
  }

  test_function_parameters_mismatch() {
    _check(
      parseFunctionType('void Function(int a)'),
      parseFunctionType('void Function(int b)'),
      parseFunctionType('void Function(int a)'),
    );
  }

  test_function_parameters_type() {
    _check(
      parseFunctionType('void Function(Object? a)'),
      parseFunctionType('void Function(dynamic a)'),
      parseFunctionType('void Function(Object? a)'),
    );
  }

  test_function_returnType() {
    _check(
      parseFunctionType('void Function()'),
      parseFunctionType('Object? Function()'),
      parseFunctionType('Object? Function()'),
    );
  }

  test_function_typeParameters_boundsMerge() {
    _check(
      parseFunctionType('T Function<T extends dynamic>()'),
      parseFunctionType('T Function<T extends Object?>()'),
      parseFunctionType('T Function<T extends Object?>()'),
    );
  }

  test_function_typeParameters_boundsMismatch() {
    _checkThrows(
      parseFunctionType('T Function<T extends int>()'),
      parseFunctionType('T Function<T>()'),
    );
  }

  test_function_typeParameters_differentCount() {
    _checkThrows(
      parseFunctionType('void Function()'),
      parseFunctionType('void Function<T, S>()'),
    );
  }

  test_interface() {
    _check(
      parseType('List<dynamic>'),
      parseType('List<Object?>'),
      parseType('List<Object?>'),
    );

    _check(
      parseType('List<void>'),
      parseType('List<Object?>'),
      parseType('List<Object?>'),
    );

    _checkThrows(parseType('Iterable<int>'), parseType('List<int>'));
  }

  test_invalid() {
    _check(
      parseType('InvalidType'),
      parseType('int'),
      parseType('InvalidType'),
    );
    _check(
      parseType('int'),
      parseType('InvalidType'),
      parseType('InvalidType'),
    );
  }

  test_never() {
    _check(parseType('Never'), parseType('Never'), parseType('Never'));
  }

  test_nullability() {
    // NNBD_TOP_MERGE(T?, S?) = NNBD_TOP_MERGE(T, S)?
    _check(parseType('int?'), parseType('int?'), parseType('int?'));
  }

  test_nullability_mismatch() {
    _checkThrows(parseType('int?'), parseType('int'));
  }

  test_objectQuestion() {
    // NNBD_TOP_MERGE(Object?, Object?) = Object?
    _check(parseType('Object?'), parseType('Object?'), parseType('Object?'));

    // NNBD_TOP_MERGE(Object?, void) = Object?
    // NNBD_TOP_MERGE(void, Object?) = Object?
    _check(parseType('Object?'), parseType('void'), parseType('Object?'));

    // NNBD_TOP_MERGE(Object?, dynamic) = Object?
    // NNBD_TOP_MERGE(dynamic, Object?) = Object?
    _check(parseType('Object?'), parseType('dynamic'), parseType('Object?'));
  }

  test_record() {
    _check(
      parseRecordType('(dynamic,)'),
      parseRecordType('(Object?,)'),
      parseRecordType('(Object?,)'),
    );

    _check(
      parseRecordType('(void,)'),
      parseRecordType('(Object?,)'),
      parseRecordType('(Object?,)'),
    );

    _check(
      parseRecordType('({dynamic f})'),
      parseRecordType('({Object? f})'),
      parseRecordType('({Object? f})'),
    );

    _check(
      parseRecordType('(dynamic, {void f})'),
      parseRecordType('(Object?, {Object? f})'),
      parseRecordType('(Object?, {Object? f})'),
    );
  }

  test_record_namedFields_differentCount() {
    _checkThrows(
      parseRecordType('({int a})'),
      parseRecordType('({int a, int b})'),
    );
  }

  test_record_namedFields_differentNames() {
    _checkThrows(parseRecordType('({int a})'), parseRecordType('({int b})'));
  }

  test_record_positionalFields_differentCount() {
    _checkThrows(parseRecordType('(int,)'), parseRecordType('(int, int)'));
  }

  test_typeParameter() {
    withTypeParameterScope('T', (scope1) {
      _check(
        scope1.parseType('T'),
        scope1.parseType('T'),
        scope1.parseType('T'),
      );

      withTypeParameterScope('T', (scope2) {
        _checkThrows(scope1.parseType('T'), scope2.parseType('T'));
        _checkThrows(scope2.parseType('T'), scope1.parseType('T'));
      });
    });
  }

  test_void() {
    // NNBD_TOP_MERGE(void, void) = void
    _check(parseType('void'), parseType('void'), parseType('void'));

    // NNBD_TOP_MERGE(void, dynamic) = Object?
    // NNBD_TOP_MERGE(dynamic, void) = Object?
    _check(parseType('void'), parseType('dynamic'), parseType('Object?'));
  }

  void _check(TypeImpl T, TypeImpl S, TypeImpl expected) {
    var result = typeSystem.topMerge(T, S);
    if (result != expected) {
      var expectedStr = expected.getDisplayString();
      var resultStr = result.getDisplayString();
      fail('Expected: $expectedStr, actual: $resultStr');
    }

    result = typeSystem.topMerge(S, T);
    if (result != expected) {
      var expectedStr = expected.getDisplayString();
      var resultStr = result.getDisplayString();
      fail('Expected: $expectedStr, actual: $resultStr');
    }
  }

  void _checkThrows(TypeImpl T, TypeImpl S) {
    expect(() {
      return typeSystem.topMerge(T, S);
    }, throwsA(anything));

    expect(() {
      return typeSystem.topMerge(S, T);
    }, throwsA(anything));
  }
}
