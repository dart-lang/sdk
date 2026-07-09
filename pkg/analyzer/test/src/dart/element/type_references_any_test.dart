// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeReferencesAnyTest);
  });
}

@reflectiveTest
class TypeReferencesAnyTest extends AbstractTypeSystemTest {
  test_false() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      void checkFalse(TypeImpl type) {
        var actual = type.referencesAny({T});
        expect(actual, isFalse);
      }

      checkFalse(parseType('dynamic'));
      checkFalse(parseType('int'));
      checkFalse(parseType('Never'));
      checkFalse(parseType('void'));
      checkFalse(parseType('List<int>'));
    });
  }

  test_true() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      void checkTrue(TypeImpl type) {
        var actual = type.referencesAny({T});
        expect(actual, isTrue);
      }

      checkTrue(scope.parseType('T'));
      checkTrue(scope.parseType('List<T>'));
      checkTrue(scope.parseType('Map<T, int>'));
      checkTrue(scope.parseType('Map<int, T>'));
      checkTrue(scope.parseType('T Function()'));
      checkTrue(scope.parseType('void Function(T)'));
      checkTrue(scope.parseType('void Function<U extends T>()'));
    });
  }
}
