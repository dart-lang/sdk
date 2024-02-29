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
  void notPromotes(DartType from, DartType to) {
    var result = typeSystem.tryPromoteToType(to, from);
    expect(result, isNull);
  }

  void promotes(DartType from, DartType to) {
    var result = typeSystem.tryPromoteToType(to, from);
    expect(result, to);
  }

  test_interface() {
    promotes(intNone, intNone);
    promotes(intQuestion, intNone);

    promotes(numNone, intNone);
    promotes(numQuestion, intNone);

    notPromotes(intNone, doubleNone);
    notPromotes(intNone, intQuestion);
  }

  test_typeParameter() {
    TypeParameterTypeImpl tryPromote(DartType to, TypeParameterTypeImpl from) {
      return typeSystem.tryPromoteToType(to, from) as TypeParameterTypeImpl;
    }

    void check(TypeParameterTypeImpl type, String expected) {
      expect(type.getDisplayString(), expected);
    }

    var T = typeParameter('T');
    var T_none = typeParameterTypeNone(T);
    var T_question = typeParameterTypeQuestion(T);

    check(tryPromote(numNone, T_none), 'T & num');
    check(tryPromote(numQuestion, T_none), 'T & num?');

    check(tryPromote(numNone, T_question), 'T & num');
    check(tryPromote(numQuestion, T_question), '(T & num?)?');
  }

  test_typeParameter_twice() {
    TypeParameterTypeImpl tryPromote(DartType to, TypeParameterTypeImpl from) {
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

    var T = typeParameter('T');
    var T_none = typeParameterTypeNone(T);

    var T1 = tryPromote(numNone, T_none);
    check(T1, T, NullabilitySuffix.none, numNone);

    var T2 = tryPromote(intNone, T1);
    check(T2, T, NullabilitySuffix.none, intNone);
  }
}
