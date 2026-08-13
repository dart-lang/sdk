// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TryPromoteToTest);
  });
}

@reflectiveTest
class TryPromoteToTest extends AbstractTypeSystemTest {
  void notPromotes(TypeImpl from, TypeImpl to) {
    var result = typeSystem.tryPromoteToType(to, from);
    expect(result, isNull);
  }

  void promotes(TypeImpl from, TypeImpl to) {
    var result = typeSystem.tryPromoteToType(to, from);
    expect(result, to);
  }

  test_interface() {
    promotes(parseType('int'), parseType('int'));
    promotes(parseType('int?'), parseType('int'));

    promotes(parseType('num'), parseType('int'));
    promotes(parseType('num?'), parseType('int'));

    notPromotes(parseType('int'), parseType('double'));
    notPromotes(parseType('int'), parseType('int?'));
  }

  test_typeParameter() {
    TypeParameterTypeImpl tryPromote(TypeImpl to, TypeParameterTypeImpl from) {
      return typeSystem.tryPromoteToType(to, from) as TypeParameterTypeImpl;
    }

    void check(TypeParameterTypeImpl type, String expected) {
      expect(type.getDisplayString(), expected);
    }

    withTypeParameterScope('T', (scope) {
      var T_none = scope.parseTypeParameterType('T');
      var T_question = scope.parseTypeParameterType('T?');

      check(tryPromote(parseType('num'), T_none), 'T & num');
      check(tryPromote(parseType('num?'), T_none), 'T & num?');

      check(tryPromote(parseType('num'), T_question), 'T & num');
      check(tryPromote(parseType('num?'), T_question), '(T & num?)?');
    });
  }

  test_typeParameter_twice() {
    TypeParameterTypeImpl tryPromote(TypeImpl to, TypeParameterTypeImpl from) {
      return typeSystem.tryPromoteToType(to, from) as TypeParameterTypeImpl;
    }

    void check(
      TypeParameterTypeImpl type,
      TypeParameterElement element,
      NullabilitySuffix nullability,
      DartType promotedBound,
    ) {
      expect(type.element, element);
      expect(type.nullabilitySuffix, nullability);
      expect(type.promotedBound, promotedBound);
    }

    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      var T_none = scope.parseTypeParameterType('T');

      var T1 = tryPromote(parseType('num'), T_none);
      check(T1, T, NullabilitySuffix.none, parseType('num'));

      var T2 = tryPromote(parseType('int'), T1);
      check(T2, T, NullabilitySuffix.none, parseType('int'));
    });
  }
}
