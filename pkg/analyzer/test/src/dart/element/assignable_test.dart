// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsAssignableToTest);
  });
}

@reflectiveTest
class IsAssignableToTest extends AbstractTypeSystemTest {
  bool get strictCasts => analysisContext.analysisOptions.strictCasts;

  void isAssignable(TypeImpl from, TypeImpl to) {
    expect(
      typeSystem.isAssignableTo(from, to, strictCasts: strictCasts),
      isTrue,
    );
  }

  void isNotAssignable(TypeImpl from, TypeImpl to) {
    expect(
      typeSystem.isAssignableTo(from, to, strictCasts: strictCasts),
      isFalse,
    );
  }

  test_dynamicType() {
    isAssignable(parseType('dynamic'), parseType('dynamic'));
    isAssignable(parseType('dynamic'), parseType('InvalidType'));
    isAssignable(parseType('dynamic'), parseType('int'));
  }

  test_interfaceType() {
    isAssignable(parseType('int'), parseType('num'));
    isAssignable(parseType('double'), parseType('num'));

    isNotAssignable(parseType('num'), parseType('int'));
  }

  test_invalidType() {
    isAssignable(parseType('InvalidType'), parseType('InvalidType'));
    isAssignable(parseType('InvalidType'), parseType('dynamic'));
    isAssignable(parseType('InvalidType'), parseType('int'));
  }
}
