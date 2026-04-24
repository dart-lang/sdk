// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart' as test;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FactorTypeTest);
  });
}

@reflectiveTest
class FactorTypeTest extends AbstractTypeSystemTest {
  void check(TypeImpl T, TypeImpl S, String expectedStr) {
    TypeImpl result = typeSystem.factor(T, S);
    String resultStr = result.getDisplayString();
    test.expect(resultStr, expectedStr);
  }

  void test_dynamic() {
    check(parseType('dynamic'), parseType('int'), 'dynamic');
  }

  void test_futureOr() {
    check(parseType('FutureOr<int>'), parseType('int'), 'Future<int>');
    check(parseType('FutureOr<int>'), parseType('Future<int>'), 'int');

    check(parseType('FutureOr<int?>'), parseType('int'), 'FutureOr<int?>');
    check(
      parseType('FutureOr<int?>'),
      parseType('Future<int>'),
      'FutureOr<int?>',
    );
    check(parseType('FutureOr<int?>'), parseType('int?'), 'Future<int?>');
    check(parseType('FutureOr<int?>'), parseType('Future<int?>'), 'int?');

    check(parseType('FutureOr<int>'), parseType('num'), 'Future<int>');
    check(parseType('FutureOr<int>'), parseType('Future<num>'), 'int');
  }

  void test_object() {
    check(parseType('Object'), parseType('Object'), 'Never');
    check(parseType('Object'), parseType('Object?'), 'Never');

    check(parseType('Object'), parseType('int'), 'Object');
    check(parseType('Object'), parseType('int?'), 'Object');

    check(parseType('Object?'), parseType('Object'), 'Never?');
    check(parseType('Object?'), parseType('Object?'), 'Never');

    check(parseType('Object?'), parseType('int'), 'Object?');
    check(parseType('Object?'), parseType('int?'), 'Object');
  }

  void test_subtype() {
    check(parseType('int'), parseType('int'), 'Never');
    check(parseType('int'), parseType('int?'), 'Never');

    check(parseType('int?'), parseType('int'), 'Never?');
    check(parseType('int?'), parseType('int?'), 'Never');

    check(parseType('int'), parseType('num'), 'Never');
    check(parseType('int'), parseType('num?'), 'Never');

    check(parseType('int?'), parseType('num'), 'Never?');
    check(parseType('int?'), parseType('num?'), 'Never');

    check(parseType('int'), parseType('Null'), 'int');
    check(parseType('int?'), parseType('Null'), 'int');

    check(parseType('int'), parseType('String'), 'int');
    check(parseType('int?'), parseType('String'), 'int?');

    check(parseType('int'), parseType('String?'), 'int');
    check(parseType('int?'), parseType('String?'), 'int');
  }

  void test_void() {
    check(parseType('void'), parseType('int'), 'void');
  }
}
