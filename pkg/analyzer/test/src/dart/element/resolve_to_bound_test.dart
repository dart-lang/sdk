// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResolveToBoundTest);
  });
}

@reflectiveTest
class ResolveToBoundTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _check(dynamicType, 'dynamic');
  }

  test_functionType() {
    _check(functionTypeNone(returnType: voidNone), 'void Function()');
  }

  test_interfaceType() {
    _check(intNone, 'int');
    _check(intQuestion, 'int?');
  }

  test_typeParameter_bound() {
    _check(typeParameterTypeNone(typeParameter('T', bound: intNone)), 'int');

    _check(
      typeParameterTypeNone(typeParameter('T', bound: intQuestion)),
      'int?',
    );
  }

  test_typeParameter_bound_functionType() {
    _check(
      typeParameterTypeNone(
        typeParameter('T', bound: functionTypeNone(returnType: voidNone)),
      ),
      'void Function()',
    );
  }

  test_typeParameter_bound_nested_noBound() {
    var T = typeParameter('T');
    var U = typeParameter('U', bound: typeParameterTypeNone(T));
    _check(typeParameterTypeNone(U), 'Object?');
  }

  test_typeParameter_bound_nested_none() {
    var T = typeParameter('T', bound: intNone);
    var U = typeParameter('U', bound: typeParameterTypeNone(T));
    _check(typeParameterTypeNone(U), 'int');
  }

  test_typeParameter_bound_nested_none_outerNullable() {
    var T = typeParameter('T', bound: intNone);
    var U = typeParameter('U', bound: typeParameterTypeQuestion(T));
    _check(typeParameterTypeNone(U), 'int?');
  }

  test_typeParameter_bound_nested_question() {
    var T = typeParameter('T', bound: intQuestion);
    var U = typeParameter('U', bound: typeParameterTypeNone(T));
    _check(typeParameterTypeNone(U), 'int?');
  }

  test_typeParameter_bound_nullableInner() {
    _check(
      typeParameterTypeNone(typeParameter('T', bound: intQuestion)),
      'int?',
    );
  }

  test_typeParameter_bound_nullableInnerOuter() {
    _check(
      typeParameterTypeQuestion(typeParameter('T', bound: intQuestion)),
      'int?',
    );
  }

  test_typeParameter_bound_nullableOuter() {
    _check(
      typeParameterTypeQuestion(typeParameter('T', bound: intNone)),
      'int?',
    );
  }

  test_typeParameter_noBound() {
    _check(typeParameterTypeNone(typeParameter('T')), 'Object?');
  }

  test_typeParameter_promotedBound() {
    _check(
      typeParameterTypeNone(
        typeParameter('T', bound: numNone),
        promotedBound: intNone,
      ),
      'int',
    );

    _check(
      typeParameterTypeNone(
        typeParameter('T', bound: numQuestion),
        promotedBound: intQuestion,
      ),
      'int?',
    );
  }

  test_void() {
    _check(voidNone, 'void');
  }

  void _check(TypeImpl type, String expectedStr) {
    var result = typeSystem.resolveToBound(type);
    var resultStr = _typeString(result);
    expect(resultStr, expectedStr);
  }

  String _typeString(DartType type) {
    return type.getDisplayString();
  }
}
