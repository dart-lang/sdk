// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
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
    defineReflectiveTests(RuntimeTypeEqualityTypeTest);
  });
}

@reflectiveTest
class RuntimeTypeEqualityTypeTest extends AbstractTypeSystemTest
    with StringTypes {
  @override
  void setUp() {
    super.setUp();
    defineStringTypes();
  }

  test_dynamic() {
    _equal(parseType('dynamic'), parseType('dynamic'));
    _notEqual(parseType('dynamic'), parseType('void'));
    _notEqual(parseType('dynamic'), parseType('int'));

    _notEqual(parseType('dynamic'), parseType('Never'));
    _notEqual(parseType('dynamic'), parseType('Never?'));
  }

  test_functionType_parameters() {
    void check(String T1, String T2, bool expected) {
      _check(parseFunctionType(T1), parseFunctionType(T2), expected);
    }

    {
      void checkRequiredParameter(String T1, String T2, bool expected) {
        check('void Function($T1)', 'void Function($T2)', expected);
      }

      checkRequiredParameter('int', 'int', true);
      checkRequiredParameter('int', 'int?', false);

      checkRequiredParameter('int?', 'int', false);
      checkRequiredParameter('int?', 'int?', true);

      check('void Function(int a)', 'void Function(int b)', true);

      check('void Function(int)', 'void Function([int])', false);

      check('void Function(int)', 'void Function({int a})', false);

      check('void Function(int)', 'void Function({required int a})', false);
    }

    {
      check('void Function({int a})', 'void Function({int a})', true);

      check('void Function({int a})', 'void Function({bool a})', false);

      check('void Function({int a})', 'void Function({int b})', false);

      check('void Function({int a})', 'void Function({required int a})', false);
    }

    {
      check(
        'void Function({required int a})',
        'void Function({required int a})',
        true,
      );

      check(
        'void Function({required int a})',
        'void Function({required bool a})',
        false,
      );

      check(
        'void Function({required int a})',
        'void Function({required int b})',
        false,
      );

      check('void Function({required int a})', 'void Function({int a})', false);
    }
  }

  test_functionType_returnType() {
    void check(String T1, String T2, bool expected) {
      _check(parseFunctionType(T1), parseFunctionType(T2), expected);
    }

    check('int Function()', 'int Function()', true);
    check('int Function()', 'int? Function()', false);
  }

  test_functionType_typeParameters() {
    {
      _check(
        parseType('void Function<T extends num>()'),
        parseType('void Function()'),
        false,
      );
    }

    {
      _check(
        parseType('void Function<T extends num>()'),
        parseType('void Function<U>()'),
        false,
      );
    }

    {
      _check(
        parseType('T Function<T>(T)'),
        parseType('U Function<U>(U)'),
        true,
      );
    }
  }

  test_interfaceType() {
    _notEqual(parseType('int'), parseType('bool'));

    _equal(parseType('int'), parseType('int'));
    _notEqual(parseType('int'), parseType('int?'));

    _notEqual(parseType('int?'), parseType('int'));
    _equal(parseType('int?'), parseType('int?'));
  }

  test_interfaceType_typeArguments() {
    void equal(TypeImpl T1, TypeImpl T2) {
      _equal(
        typeProvider.listElement.instantiateImpl(
          typeArguments: [T1],
          nullabilitySuffix: NullabilitySuffix.none,
        ),
        typeProvider.listElement.instantiateImpl(
          typeArguments: [T2],
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      );
    }

    void notEqual(TypeImpl T1, TypeImpl T2) {
      _notEqual(
        typeProvider.listElement.instantiateImpl(
          typeArguments: [T1],
          nullabilitySuffix: NullabilitySuffix.none,
        ),
        typeProvider.listElement.instantiateImpl(
          typeArguments: [T2],
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      );
    }

    notEqual(parseType('int'), parseType('bool'));

    equal(parseType('int'), parseType('int'));
    notEqual(parseType('int'), parseType('int?'));

    notEqual(parseType('int?'), parseType('int'));
    equal(parseType('int?'), parseType('int?'));
  }

  test_never() {
    _equal(parseType('Never'), parseType('Never'));
    _notEqual(parseType('Never'), parseType('Never?'));
    _notEqual(parseType('Never'), parseType('int'));

    _notEqual(parseType('Never?'), parseType('Never'));
    _equal(parseType('Never?'), parseType('Never?'));
    _notEqual(parseType('Never?'), parseType('int'));
    _equal(parseType('Never?'), parseType('Null'));
  }

  test_norm() {
    _equal(parseType('FutureOr<Object>'), parseType('Object'));
    _equal(parseType('FutureOr<Never>'), parseType('Future<Never>'));
    _equal(parseType('Never?'), parseType('Null'));
  }

  test_recordType_andNot() {
    _notEqual2('(int,)', 'dynamic');
    _notEqual2('(int,)', 'int');
    _notEqual2('(int,)', 'void');
  }

  test_recordType_differentShape() {
    _notEqual2('(int,)', '(int, int)');
    _notEqual2('(int,)', '({int f1})');
    _notEqual2('({int f1})', '({int f2})');
    _notEqual2('({int f1})', '({int f1, int f2})');
  }

  test_recordType_sameShape_named() {
    _equal2('({int f1})', '({int f1})');
    _notEqual2('({int f1})', '({int? f1})');

    _notEqual2('({int f1})', '({double f1})');
  }

  test_recordType_sameShape_positional() {
    _equal2('(int,)', '(int,)');
    _notEqual2('(int,)', '(int?,)');

    _notEqual2('(int,)', '(double,)');
  }

  test_void() {
    _equal(parseType('void'), parseType('void'));
    _notEqual(parseType('void'), parseType('dynamic'));
    _notEqual(parseType('void'), parseType('int'));

    _notEqual(parseType('void'), parseType('Never'));
    _notEqual(parseType('void'), parseType('Never?'));
  }

  void _check(TypeImpl T1, TypeImpl T2, bool expected) {
    bool result;

    result = typeSystem.runtimeTypesEqual(T1, T2);
    if (result != expected) {
      fail('''
Expected ${expected ? 'equal' : 'not equal'}.
T1: ${typeString(T1)}
T2: ${typeString(T2)}
''');
    }

    result = typeSystem.runtimeTypesEqual(T2, T1);
    if (result != expected) {
      fail('''
Expected ${expected ? 'equal' : 'not equal'}.
T1: ${typeString(T1)}
T2: ${typeString(T2)}
''');
    }
  }

  void _equal(TypeImpl T1, TypeImpl T2) {
    _check(T1, T2, true);
  }

  void _equal2(String T1, String T2) {
    _equal(typeOfString(T1), typeOfString(T2));
  }

  void _notEqual(TypeImpl T1, TypeImpl T2) {
    _check(T1, T2, false);
  }

  void _notEqual2(String T1, String T2) {
    _notEqual(typeOfString(T1), typeOfString(T2));
  }
}
