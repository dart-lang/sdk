// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';
import 'string_types.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NormalizeTypeTest);
  });
}

@reflectiveTest
class NormalizeTypeTest extends AbstractTypeSystemTest with StringTypes {
  test_functionType_parameter() {
    _check(
      parseType('void Function(FutureOr<Object>)'),
      parseType('void Function(Object)'),
    );

    _check(
      parseType('void Function({FutureOr<Object> a})'),
      parseType('void Function({Object a})'),
    );

    _check(
      parseType('void Function({required FutureOr<Object> a})'),
      parseType('void Function({required Object a})'),
    );

    _check(
      parseType('void Function([FutureOr<Object>])'),
      parseType('void Function([Object])'),
    );
  }

  test_functionType_parameter_covariant() {
    _check(
      parseType('void Function(covariant FutureOr<Object>)'),
      parseType('void Function(covariant Object)'),
    );
  }

  test_functionType_parameter_typeParameter() {
    _check(
      parseType('void Function<T extends Never>(T)'),
      parseType('void Function<T2 extends Never>(Never)'),
    );

    _check(
      parseType('void Function<T extends Iterable<FutureOr<dynamic>>>(T)'),
      parseType('void Function<T2 extends Iterable<dynamic>>(T2)'),
    );
  }

  test_functionType_returnType() {
    _check(
      parseType('FutureOr<Object> Function()'),
      parseType('Object Function()'),
    );

    _check(parseType('int Function()'), parseType('int Function()'));
  }

  test_functionType_typeParameter_bound_normalized() {
    _check(
      parseType('void Function<T extends FutureOr<Object>>()'),
      parseType('void Function<T extends Object>()'),
    );
  }

  test_functionType_typeParameter_bound_unchanged() {
    _check(
      parseType('int Function<T extends num>()'),
      parseType('int Function<T extends num>()'),
    );
  }

  test_functionType_typeParameter_fresh() {
    _check(parseType('T Function<T>(T)'), parseType('U Function<U>(U)'));
  }

  test_functionType_typeParameter_fresh_bound() {
    _check(
      parseType('T Function<T, S extends T>(T, S)'),
      parseType('U Function<U, V extends U>(U, V)'),
    );
  }

  /// `NORM(FutureOr<T>)`
  /// * let S be NORM(T)
  test_futureOr() {
    void check(TypeImpl T, TypeImpl expected) {
      var input = typeProvider.futureOrElement.instantiateImpl(
        typeArguments: [T],
        nullabilitySuffix: NullabilitySuffix.none,
      );
      _check(input, expected);
    }

    // * if S is a top type then S
    check(parseType('dynamic'), parseType('dynamic'));
    check(parseType('InvalidType'), parseType('InvalidType'));
    check(parseType('void'), parseType('void'));
    check(parseType('Object?'), parseType('Object?'));

    // * if S is Object then S
    check(parseType('Object'), parseType('Object'));

    // * if S is Never then Future<Never>
    check(parseType('Never'), parseType('Future<Never>'));

    // * if S is Null then Future<Null>?
    check(parseType('Null'), parseType('Future<Null>?'));

    // * else FutureOr<S>
    check(parseType('int'), parseType('FutureOr<int>'));
  }

  test_interfaceType() {
    _check(parseType('List<int>'), parseType('List<int>'));

    _check(parseType('List<FutureOr<Object>>'), parseType('List<Object>'));
  }

  test_primitive() {
    _check(parseType('dynamic'), parseType('dynamic'));
    _check(parseType('Never'), parseType('Never'));
    _check(parseType('void'), parseType('void'));
    _check(parseType('int'), parseType('int'));
  }

  /// NORM(T?)
  /// * let S be NORM(T)
  test_question() {
    void check(TypeImpl T, TypeImpl expected) {
      _assertNullabilityQuestion(T);
      _check(T, expected);
    }

    // * if S is a top type then S
    check(parseType('FutureOr<dynamic>?'), parseType('dynamic'));
    check(parseType('FutureOr<void>?'), parseType('void'));
    check(parseType('FutureOr<Object?>?'), parseType('Object?'));

    // * if S is Never then Null
    check(parseType('Never?'), parseType('Null'));

    // * if S is Never* then Null
    // Analyzer: impossible, we have only one suffix

    // * if S is Null then Null
    // Analyzer: impossible; `Null?` is always represented as `Null`.

    // * if S is FutureOr<R> and R is nullable then S
    check(parseType('FutureOr<int?>?'), parseType('FutureOr<int?>'));

    // * if S is FutureOr<R>* and R is nullable then FutureOr<R>
    // Analyzer: impossible, we have only one suffix

    // * if S is R? then R?
    // * if S is R* then R?
    // * else S?
    check(parseType('int?'), parseType('int?'));
    check(parseType('Object?'), parseType('Object?'));
    check(parseType('FutureOr<Object>?'), parseType('Object?'));
  }

  test_recordType() {
    _check(parseRecordType('(int,)'), parseRecordType('(int,)'));

    _check(
      parseRecordType('(FutureOr<Object>,)'),
      parseRecordType('(Object,)'),
    );

    _check(
      parseRecordType('({FutureOr<Object> foo})'),
      parseRecordType('({Object foo})'),
    );
  }

  /// NORM(X & T)
  /// * let S be NORM(T)
  test_typeParameter_bound() {
    // * if S is Never then Never
    withTypeParameterScope('T extends Never', (scope) {
      _check(scope.parseType('T'), parseType('Never'));
    });

    // * else X
    withTypeParameterScope('T', (scope) {
      _check(scope.parseType('T'), scope.parseType('T'));
    });

    // * else X
    withTypeParameterScope('T extends FutureOr<Object>', (scope) {
      _check(scope.parseType('T'), scope.parseType('T'));
    });
  }

  test_typeParameter_bound_recursive() {
    withTypeParameterScope('T extends Iterable<T>', (scope) {
      _check(scope.parseType('T'), scope.parseType('T'));
    });
  }

  test_typeParameter_promoted() {
    withTypeParameterScope('T', (scope) {
      // * if S is Never then Never
      _check(scope.parseType('T & Never'), parseType('Never'));

      // * if S is a top type then X
      _check(scope.parseType('T & Object?'), scope.parseType('T'));
      _check(scope.parseType('T & FutureOr<Object>?'), scope.parseType('T'));

      // * if S is X then X
      _check(scope.parseType('T & T'), scope.parseType('T'));

      // else X & S
      _check(
        scope.parseType('T & FutureOr<Never>'),
        scope.parseType('T & Future<Never>'),
      );
    });

    // * if S is Object and NORM(B) is Object where B is the bound of X then X
    withTypeParameterScope('T extends Object', (scope) {
      _check(scope.parseType('T & FutureOr<Object>'), scope.parseType('T'));
    });
  }

  void _assertNullability(TypeImpl type, NullabilitySuffix expected) {
    if (type.nullabilitySuffix != expected) {
      fail('Expected $expected in ${typeString(type)}');
    }
  }

  void _assertNullabilityQuestion(TypeImpl type) {
    _assertNullability(type, NullabilitySuffix.question);
  }

  void _check(TypeImpl T, TypeImpl expected) {
    var expectedStr = typeString(expected);

    var result = typeSystem.normalize(T);
    var resultStr = typeString(result);
    expect(
      result,
      expected,
      reason:
          '''
expected: $expectedStr
actual: $resultStr
''',
    );
    _checkFormalParametersIsCovariant(result, expected);
  }

  void _checkFormalParametersIsCovariant(TypeImpl T1, TypeImpl T2) {
    if (T1 is FunctionTypeImpl && T2 is FunctionTypeImpl) {
      var parameters1 = T1.formalParameters;
      var parameters2 = T2.formalParameters;
      expect(parameters1, hasLength(parameters2.length));
      for (var i = 0; i < parameters1.length; i++) {
        var parameter1 = parameters1[i];
        var parameter2 = parameters2[i];
        if (parameter1.isCovariant != parameter2.isCovariant) {
          fail('''
parameter1: $parameter1, isCovariant: ${parameter1.isCovariant}
parameter2: $parameter2, isCovariant: ${parameter2.isCovariant}
T1: ${typeString(T1)}
T2: ${typeString(T2)}
''');
        }
        _checkFormalParametersIsCovariant(parameter1.type, parameter2.type);
      }
    }
  }
}
