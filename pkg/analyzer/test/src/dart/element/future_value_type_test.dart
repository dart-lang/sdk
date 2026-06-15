// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FutureValueTypeTest);
  });
}

@reflectiveTest
class FutureValueTypeTest extends AbstractTypeSystemTest {
  /// futureValueType(`dynamic`) = `dynamic`.
  test_dynamic() {
    _check(parseType('dynamic'), 'dynamic');
  }

  /// futureValueType(Future<`S`>) = `S`, for all `S`.
  test_future() {
    _check(parseType('Future<int>'), 'int');
    _check(parseType('Future<int?>'), 'int?');

    _check(parseType('Future<dynamic>'), 'dynamic');
    _check(parseType('Future<void>'), 'void');

    _check(parseType('Future<Never>'), 'Never');
    _check(parseType('Future<Never?>'), 'Never?');

    _check(parseType('Future<Object>'), 'Object');
    _check(parseType('Future<Object?>'), 'Object?');
  }

  /// futureValueType(FutureOr<`S`>) = `S`, for all `S`.
  test_futureOr() {
    _check(parseType('FutureOr<int>'), 'int');
    _check(parseType('FutureOr<int?>'), 'int?');

    _check(parseType('FutureOr<dynamic>'), 'dynamic');
    _check(parseType('FutureOr<void>'), 'void');

    _check(parseType('FutureOr<Never>'), 'Never');
    _check(parseType('FutureOr<Never?>'), 'Never?');

    _check(parseType('FutureOr<Object>'), 'Object');
    _check(parseType('FutureOr<Object?>'), 'Object?');
  }

  /// Otherwise, for all `S`, futureValueType(`S`) = `Object?`.
  test_other() {
    _check(parseType('Object'), 'Object?');
    _check(parseType('int'), 'Object?');
  }

  /// futureValueType(`S?`) = futureValueType(`S`), for all `S`.
  test_suffix_question() {
    _check(parseType('int?'), 'Object?');

    _check(parseType('Future<int>?'), 'int');
    _check(parseType('Future<int?>?'), 'int?');

    _check(parseType('FutureOr<int>?'), 'int');
    _check(parseType('FutureOr<int?>?'), 'int?');

    _check(parseType('Future<Object>?'), 'Object');
    _check(parseType('Future<Object?>?'), 'Object?');

    _check(parseType('Future<dynamic>?'), 'dynamic');
    _check(parseType('Future<void>?'), 'void');
  }

  /// futureValueType(`void`) = `void`.
  test_void() {
    _check(parseType('void'), 'void');
  }

  void _check(TypeImpl T, String expected) {
    var result = typeSystem.futureValueType(T);
    expect(result.getDisplayString(), expected);
  }
}
