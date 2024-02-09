// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
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

  void isAssignable(DartType from, DartType to) {
    expect(
        typeSystem.isAssignableTo(from, to, strictCasts: strictCasts), isTrue);
  }

  void isNotAssignable(DartType from, DartType to) {
    expect(
        typeSystem.isAssignableTo(from, to, strictCasts: strictCasts), isFalse);
  }

  test_dynamicType() {
    isAssignable(dynamicType, dynamicType);
    isAssignable(dynamicType, invalidType);
    isAssignable(dynamicType, intNone);
  }

  test_interfaceType() {
    isAssignable(intNone, numNone);
    isAssignable(doubleNone, numNone);

    isNotAssignable(numNone, intNone);
  }

  test_invalidType() {
    isAssignable(invalidType, invalidType);
    isAssignable(invalidType, dynamicType);
    isAssignable(invalidType, intNone);
  }
}
