// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FutureOrBaseTest);
  });
}

@reflectiveTest
class FutureOrBaseTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _check(parseType('dynamic'), 'dynamic');
  }

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

  test_other() {
    _check(parseType('int'), 'int');
    _check(parseType('int?'), 'int?');

    _check(parseType('Object'), 'Object');
    _check(parseType('Object?'), 'Object?');
  }

  /// futureValueType(`void`) = `void`.
  test_void() {
    _check(parseType('void'), 'void');
  }

  void _check(TypeImpl T, String expected) {
    var result = typeSystem.futureOrBase(T);
    expect(result.getDisplayString(), expected);
  }
}
