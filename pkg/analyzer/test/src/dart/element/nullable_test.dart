// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsNonNullableTest);
    defineReflectiveTests(IsNullableTest);
    defineReflectiveTests(IsPotentiallyNonNullableTest);
    defineReflectiveTests(IsPotentiallyNullableTest);
    defineReflectiveTests(IsStrictlyNonNullableTest);
    defineReflectiveTests(PromoteToNonNullTest);
  });
}

@reflectiveTest
class IsNonNullableTest extends AbstractTypeSystemTest {
  void isNonNullable(DartType type) {
    expect(typeSystem.isNonNullable(type), isTrue);
  }

  void isNotNonNullable(DartType type) {
    expect(typeSystem.isNonNullable(type), isFalse);
  }

  test_dynamic() {
    isNotNonNullable(dynamicType);
  }

  test_function() {
    isNonNullable(
      functionTypeNone(returnType: voidNone),
    );

    isNotNonNullable(
      functionTypeQuestion(returnType: voidNone),
    );
  }

  test_functionClass() {
    isNonNullable(functionNone);
    isNotNonNullable(functionQuestion);
  }

  test_futureOr_noneArgument() {
    isNonNullable(
      futureOrNone(intNone),
    );

    isNotNonNullable(
      futureOrQuestion(intNone),
    );
  }

  test_futureOr_questionArgument() {
    isNotNonNullable(
      futureOrNone(intQuestion),
    );

    isNotNonNullable(
      futureOrQuestion(intQuestion),
    );
  }

  test_interface() {
    isNonNullable(intNone);
    isNotNonNullable(intQuestion);
  }

  test_interface_extensionType() {
    isNotNonNullable(
      interfaceTypeNone(
        extensionType('A', representationType: intNone),
      ),
    );

    isNonNullable(
      interfaceTypeNone(
        extensionType('A', representationType: intNone, interfaces: [intNone]),
      ),
    );
  }

  test_invalidType() {
    isNotNonNullable(invalidType);
  }

  test_never() {
    isNonNullable(neverNone);
    isNotNonNullable(neverQuestion);
  }

  test_null() {
    isNotNonNullable(nullNone);
  }

  test_typeParameter_boundNone() {
    var T = typeParameter('T', bound: intNone);

    isNonNullable(
      typeParameterTypeNone(T),
    );

    isNotNonNullable(
      typeParameterTypeQuestion(T),
    );
  }

  test_typeParameter_boundQuestion() {
    var T = typeParameter('T', bound: intQuestion);

    isNotNonNullable(
      typeParameterTypeNone(T),
    );

    isNotNonNullable(
      typeParameterTypeQuestion(T),
    );
  }

  test_typeParameter_promotedBoundNone() {
    var T = typeParameter('T');

    isNonNullable(
      typeParameterTypeNone(T, promotedBound: intNone),
    );

    isNonNullable(
      typeParameterTypeQuestion(T, promotedBound: intNone),
    );
  }

  test_typeParameter_promotedBoundQuestion() {
    var T = typeParameter('T');

    isNotNonNullable(
      typeParameterTypeNone(T, promotedBound: intQuestion),
    );

    isNotNonNullable(
      typeParameterTypeQuestion(T, promotedBound: intQuestion),
    );
  }

  test_void() {
    isNotNonNullable(voidNone);
  }
}

@reflectiveTest
class IsNullableTest extends AbstractTypeSystemTest {
  void isNotNullable(DartType type) {
    expect(typeSystem.isNullable(type), isFalse);
  }

  void isNullable(DartType type) {
    expect(typeSystem.isNullable(type), isTrue);
  }

  test_dynamic() {
    isNullable(dynamicType);
  }

  test_function() {
    isNotNullable(
      functionTypeNone(returnType: voidNone),
    );

    isNullable(
      functionTypeQuestion(returnType: voidNone),
    );
  }

  test_functionClass() {
    isNotNullable(functionNone);
    isNullable(functionQuestion);
  }

  test_futureOr_noneArgument() {
    isNotNullable(
      futureOrNone(intNone),
    );

    isNullable(
      futureOrQuestion(intNone),
    );
  }

  test_futureOr_questionArgument() {
    isNullable(
      futureOrNone(intQuestion),
    );

    isNullable(
      futureOrQuestion(intQuestion),
    );
  }

  test_interface() {
    isNotNullable(intNone);
    isNullable(intQuestion);
  }

  test_interface_extensionType() {
    isNotNullable(
      interfaceTypeNone(
        extensionType('A', representationType: intNone),
      ),
    );

    isNotNullable(
      interfaceTypeNone(
        extensionType('A', representationType: intNone, interfaces: [intNone]),
      ),
    );

    isNullable(
      interfaceTypeQuestion(
        extensionType('A', representationType: intNone, interfaces: [intNone]),
      ),
    );
  }

  test_invalidType() {
    isNullable(invalidType);
  }

  test_never() {
    isNotNullable(neverNone);
    isNullable(neverQuestion);
  }

  test_null() {
    isNullable(nullNone);
  }

  test_typeParameter_boundNone() {
    var T = typeParameter('T', bound: intNone);

    isNotNullable(
      typeParameterTypeNone(T),
    );

    isNullable(
      typeParameterTypeQuestion(T),
    );
  }

  test_typeParameter_boundQuestion_none() {
    var T = typeParameter('T', bound: intQuestion);

    isNotNullable(
      typeParameterTypeNone(T),
    );

    isNullable(
      typeParameterTypeQuestion(T),
    );
  }

  test_typeParameter_promotedBoundNone() {
    var T = typeParameter('T');

    isNotNullable(
      typeParameterTypeNone(T, promotedBound: intNone),
    );

    isNotNullable(
      typeParameterTypeQuestion(T, promotedBound: intNone),
    );
  }

  test_typeParameter_promotedBoundQuestion() {
    var T = typeParameter('T');

    isNullable(
      typeParameterTypeNone(T, promotedBound: intQuestion),
    );

    isNullable(
      typeParameterTypeQuestion(T, promotedBound: intQuestion),
    );
  }

  test_void() {
    isNullable(voidNone);
  }
}

@reflectiveTest
class IsPotentiallyNonNullableTest extends AbstractTypeSystemTest {
  void isNotPotentiallyNonNullable(DartType type) {
    expect(typeSystem.isPotentiallyNonNullable(type), isFalse);
  }

  void isPotentiallyNonNullable(DartType type) {
    expect(typeSystem.isPotentiallyNonNullable(type), isTrue);
  }

  test_dynamic() {
    isNotPotentiallyNonNullable(dynamicType);
  }

  test_futureOr() {
    isPotentiallyNonNullable(
      futureOrNone(intNone),
    );

    isNotPotentiallyNonNullable(
      futureOrNone(intQuestion),
    );
  }

  test_interface() {
    isPotentiallyNonNullable(intNone);
    isNotPotentiallyNonNullable(intQuestion);
  }

  test_interface_extensionType() {
    isPotentiallyNonNullable(
      interfaceTypeNone(
        extensionType('A', representationType: intNone),
      ),
    );

    isPotentiallyNonNullable(
      interfaceTypeNone(
        extensionType('A', representationType: intNone, interfaces: [intNone]),
      ),
    );
  }

  test_invalidType() {
    isNotPotentiallyNonNullable(invalidType);
  }

  test_never() {
    isPotentiallyNonNullable(neverNone);
  }

  test_null() {
    isNotPotentiallyNonNullable(nullNone);
  }

  test_void() {
    isNotPotentiallyNonNullable(voidNone);
  }
}

@reflectiveTest
class IsPotentiallyNullableTest extends AbstractTypeSystemTest {
  void isNotPotentiallyNullable(DartType type) {
    expect(typeSystem.isPotentiallyNullable(type), isFalse);
  }

  void isPotentiallyNullable(DartType type) {
    expect(typeSystem.isPotentiallyNullable(type), isTrue);
  }

  test_dynamic() {
    isPotentiallyNullable(dynamicType);
  }

  test_futureOr() {
    isNotPotentiallyNullable(
      futureOrNone(intNone),
    );

    isPotentiallyNullable(
      futureOrNone(intQuestion),
    );
  }

  test_interface() {
    isNotPotentiallyNullable(intNone);
    isPotentiallyNullable(intQuestion);
  }

  test_interface_extensionType() {
    isPotentiallyNullable(
      interfaceTypeQuestion(
        extensionType('A', representationType: intNone),
      ),
    );

    isPotentiallyNullable(
      interfaceTypeNone(
        extensionType('A', representationType: intNone),
      ),
    );

    isNotPotentiallyNullable(
      interfaceTypeNone(
        extensionType('A', representationType: intNone, interfaces: [intNone]),
      ),
    );
  }

  test_invalidType() {
    isPotentiallyNullable(invalidType);
  }

  test_never() {
    isNotPotentiallyNullable(neverNone);
  }

  test_null() {
    isPotentiallyNullable(nullNone);
  }

  test_void() {
    isPotentiallyNullable(voidNone);
  }
}

@reflectiveTest
class IsStrictlyNonNullableTest extends AbstractTypeSystemTest {
  void isNotStrictlyNonNullable(DartType type) {
    expect(typeSystem.isStrictlyNonNullable(type), isFalse);
  }

  void isStrictlyNonNullable(DartType type) {
    expect(typeSystem.isStrictlyNonNullable(type), isTrue);
  }

  test_dynamic() {
    isNotStrictlyNonNullable(dynamicType);
  }

  test_function() {
    isStrictlyNonNullable(
      functionTypeNone(returnType: voidNone),
    );

    isNotStrictlyNonNullable(
      functionTypeQuestion(returnType: voidNone),
    );
  }

  test_functionClass() {
    isStrictlyNonNullable(functionNone);
    isNotStrictlyNonNullable(functionQuestion);
  }

  test_futureOr_noneArgument() {
    isStrictlyNonNullable(
      futureOrNone(intNone),
    );

    isNotStrictlyNonNullable(
      futureOrQuestion(intNone),
    );
  }

  test_futureOr_questionArgument() {
    isNotStrictlyNonNullable(
      futureOrNone(intQuestion),
    );

    isNotStrictlyNonNullable(
      futureOrQuestion(intQuestion),
    );
  }

  test_interface() {
    isStrictlyNonNullable(intNone);
    isNotStrictlyNonNullable(intQuestion);
  }

  test_interface_extensionType() {
    isNotStrictlyNonNullable(
      interfaceTypeNone(
        extensionType('A', representationType: intNone),
      ),
    );

    isStrictlyNonNullable(
      interfaceTypeNone(
        extensionType('A', representationType: intNone, interfaces: [intNone]),
      ),
    );
  }

  test_invalidType() {
    isNotStrictlyNonNullable(invalidType);
  }

  test_never() {
    isStrictlyNonNullable(neverNone);
    isNotStrictlyNonNullable(neverQuestion);
  }

  test_null() {
    isNotStrictlyNonNullable(nullNone);
    isNotStrictlyNonNullable(nullQuestion);
  }

  test_typeParameter_boundNone() {
    var T = typeParameter('T', bound: intNone);

    isStrictlyNonNullable(
      typeParameterTypeNone(T),
    );

    isNotStrictlyNonNullable(
      typeParameterTypeQuestion(T),
    );
  }

  test_typeParameter_boundQuestion() {
    var T = typeParameter('T', bound: intQuestion);

    isNotStrictlyNonNullable(
      typeParameterTypeNone(T),
    );

    isNotStrictlyNonNullable(
      typeParameterTypeQuestion(T),
    );
  }

  test_void() {
    isNotStrictlyNonNullable(voidNone);
  }
}

@reflectiveTest
class PromoteToNonNullTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _check(dynamicType, dynamicType);
  }

  test_functionType() {
    // NonNull(T0 Function(...)) = T0 Function(...)
    _check(
      functionTypeQuestion(returnType: voidNone),
      functionTypeNone(returnType: voidNone),
    );
  }

  test_futureOr_question() {
    // NonNull(FutureOr<T>) = FutureOr<T>
    _check(
      futureOrQuestion(stringQuestion),
      futureOrNone(stringQuestion),
    );
  }

  test_interfaceType() {
    _check(intNone, intNone);
    _check(intQuestion, intNone);

    // NonNull(C<T1, ... , Tn>) = C<T1, ... , Tn>
    _check(
      listQuestion(intQuestion),
      listNone(intQuestion),
    );
  }

  test_interfaceType_function() {
    _check(functionQuestion, functionNone);
  }

  test_invalidType() {
    _check(invalidType, invalidType);
  }

  test_never() {
    _check(neverNone, neverNone);
  }

  test_null() {
    _check(nullNone, neverNone);
  }

  test_typeParameter_bound_dynamic() {
    var element = typeParameter('T', bound: dynamicType);

    _checkTypeParameter(
      typeParameterTypeNone(element),
      element: element,
      promotedBound: null,
    );
  }

  test_typeParameter_bound_invalidType() {
    var element = typeParameter('T', bound: invalidType);

    _checkTypeParameter(
      typeParameterTypeNone(element),
      element: element,
      promotedBound: null,
    );
  }

  test_typeParameter_bound_none() {
    var element = typeParameter('T', bound: intNone);

    _checkTypeParameter(
      typeParameterTypeNone(element),
      element: element,
      promotedBound: null,
    );

    _checkTypeParameter(
      typeParameterTypeQuestion(element),
      element: element,
      promotedBound: null,
    );
  }

  test_typeParameter_bound_null() {
    var element = typeParameter('T');
    _checkTypeParameter(
      typeParameterTypeNone(element),
      element: element,
      promotedBound: objectNone,
    );
  }

  test_typeParameter_bound_question() {
    var element = typeParameter('T', bound: intQuestion);

    _checkTypeParameter(
      typeParameterTypeNone(element),
      element: element,
      promotedBound: intNone,
    );

    _checkTypeParameter(
      typeParameterTypeQuestion(element),
      element: element,
      promotedBound: intNone,
    );
  }

  test_typeParameter_promotedBound_none() {
    var element = typeParameter('T', bound: numQuestion);

    _checkTypeParameter(
      promotedTypeParameterTypeNone(element, intNone),
      element: element,
      promotedBound: intNone,
    );

    _checkTypeParameter(
      promotedTypeParameterTypeQuestion(element, intNone),
      element: element,
      promotedBound: intNone,
    );
  }

  test_typeParameter_promotedBound_question() {
    var element = typeParameter('T', bound: numQuestion);

    _checkTypeParameter(
      promotedTypeParameterTypeNone(element, intQuestion),
      element: element,
      promotedBound: intNone,
    );

    _checkTypeParameter(
      promotedTypeParameterTypeQuestion(element, intQuestion),
      element: element,
      promotedBound: intNone,
    );
  }

  test_void() {
    _check(voidNone, voidNone);
  }

  void _check(DartType type, DartType expected) {
    var result = typeSystem.promoteToNonNull(type);
    expect(result, expected);
  }

  void _checkTypeParameter(
    TypeParameterType type, {
    required TypeParameterElement element,
    required DartType? promotedBound,
  }) {
    var actual = typeSystem.promoteToNonNull(type) as TypeParameterTypeImpl;
    expect(actual.element, same(element));
    expect(actual.promotedBound, promotedBound);
    expect(actual.nullabilitySuffix, NullabilitySuffix.none);
  }
}
