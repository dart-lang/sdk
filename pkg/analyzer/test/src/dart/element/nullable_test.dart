// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
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
    isNotNonNullable(parseType('dynamic'));
  }

  test_function() {
    isNonNullable(parseType('void Function()'));

    isNotNonNullable(parseType('void Function()?'));
  }

  test_functionClass() {
    isNonNullable(parseType('Function'));
    isNotNonNullable(parseType('Function?'));
  }

  test_futureOr_noneArgument() {
    isNonNullable(parseType('FutureOr<int>'));

    isNotNonNullable(parseType('FutureOr<int>?'));
  }

  test_futureOr_questionArgument() {
    isNotNonNullable(parseType('FutureOr<int?>'));

    isNotNonNullable(parseType('FutureOr<int?>?'));
  }

  test_interface() {
    isNonNullable(parseType('int'));
    isNotNonNullable(parseType('int?'));
  }

  test_interface_extensionType2() {
    buildTestLibrary(
      extensionTypes: [
        ExtensionTypeSpec('extension type A(int it)'),
        ExtensionTypeSpec('extension type B(int it) implements int'),
      ],
    );
    isNotNonNullable(parseInterfaceType('A'));
    isNonNullable(parseInterfaceType('B'));
  }

  test_invalidType() {
    isNotNonNullable(parseType('InvalidType'));
  }

  test_never() {
    isNonNullable(parseType('Never'));
    isNotNonNullable(parseType('Never?'));
  }

  test_null() {
    isNotNonNullable(parseType('Null'));
  }

  test_typeParameter_boundNone() {
    withTypeParameterScope('T extends int', (scope) {
      isNonNullable(scope.parseType('T'));
      isNotNonNullable(scope.parseType('T?'));
    });
  }

  test_typeParameter_boundQuestion() {
    withTypeParameterScope('T extends int?', (scope) {
      isNotNonNullable(scope.parseType('T'));
      isNotNonNullable(scope.parseType('T?'));
    });
  }

  test_typeParameter_promotedBoundNone() {
    withTypeParameterScope('T', (scope) {
      isNonNullable(scope.parseType('T & int'));
      isNonNullable(scope.parseType('(T & int)?'));
    });
  }

  test_typeParameter_promotedBoundQuestion() {
    withTypeParameterScope('T', (scope) {
      isNotNonNullable(scope.parseType('T & int?'));
      isNotNonNullable(scope.parseType('(T & int?)?'));
    });
  }

  test_void() {
    isNotNonNullable(parseType('void'));
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
    isNullable(parseType('dynamic'));
  }

  test_function() {
    isNotNullable(parseType('void Function()'));

    isNullable(parseType('void Function()?'));
  }

  test_functionClass() {
    isNotNullable(parseType('Function'));
    isNullable(parseType('Function?'));
  }

  test_futureOr_noneArgument() {
    isNotNullable(parseType('FutureOr<int>'));

    isNullable(parseType('FutureOr<int>?'));
  }

  test_futureOr_questionArgument() {
    isNullable(parseType('FutureOr<int?>'));

    isNullable(parseType('FutureOr<int?>?'));
  }

  test_interface() {
    isNotNullable(parseType('int'));
    isNullable(parseType('int?'));
  }

  test_interface_extensionType2() {
    buildTestLibrary(
      extensionTypes: [
        ExtensionTypeSpec('extension type A(int it)'),
        ExtensionTypeSpec('extension type B(int it) implements int'),
      ],
    );
    isNotNullable(parseInterfaceType('A'));
    isNotNullable(parseInterfaceType('B'));
    isNullable(parseInterfaceType('B?'));
  }

  test_invalidType() {
    isNullable(parseType('InvalidType'));
  }

  test_never() {
    isNotNullable(parseType('Never'));
    isNullable(parseType('Never?'));
  }

  test_null() {
    isNullable(parseType('Null'));
  }

  test_typeParameter_boundNone() {
    withTypeParameterScope('T extends int', (scope) {
      isNotNullable(scope.parseType('T'));
      isNullable(scope.parseType('T?'));
    });
  }

  test_typeParameter_boundQuestion_none() {
    withTypeParameterScope('T extends int?', (scope) {
      isNotNullable(scope.parseType('T'));
      isNullable(scope.parseType('T?'));
    });
  }

  test_typeParameter_promotedBoundNone() {
    withTypeParameterScope('T', (scope) {
      isNotNullable(scope.parseType('T & int'));
      isNotNullable(scope.parseType('(T & int)?'));
    });
  }

  test_typeParameter_promotedBoundQuestion() {
    withTypeParameterScope('T', (scope) {
      isNullable(scope.parseType('T & int?'));
      isNullable(scope.parseType('(T & int?)?'));
    });
  }

  test_void() {
    isNullable(parseType('void'));
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
    isNotPotentiallyNonNullable(parseType('dynamic'));
  }

  test_futureOr() {
    isPotentiallyNonNullable(parseType('FutureOr<int>'));

    isNotPotentiallyNonNullable(parseType('FutureOr<int?>'));
  }

  test_interface() {
    isPotentiallyNonNullable(parseType('int'));
    isNotPotentiallyNonNullable(parseType('int?'));
  }

  test_interface_extensionType2() {
    buildTestLibrary(
      extensionTypes: [
        ExtensionTypeSpec('extension type A(int it)'),
        ExtensionTypeSpec('extension type B(int it) implements int'),
      ],
    );
    isPotentiallyNonNullable(parseInterfaceType('A'));
    isPotentiallyNonNullable(parseInterfaceType('B'));
  }

  test_invalidType() {
    isNotPotentiallyNonNullable(parseType('InvalidType'));
  }

  test_never() {
    isPotentiallyNonNullable(parseType('Never'));
  }

  test_null() {
    isNotPotentiallyNonNullable(parseType('Null'));
  }

  test_void() {
    isNotPotentiallyNonNullable(parseType('void'));
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
    isPotentiallyNullable(parseType('dynamic'));
  }

  test_futureOr() {
    isNotPotentiallyNullable(parseType('FutureOr<int>'));

    isPotentiallyNullable(parseType('FutureOr<int?>'));
  }

  test_interface() {
    isNotPotentiallyNullable(parseType('int'));
    isPotentiallyNullable(parseType('int?'));
  }

  test_interface_extensionType2() {
    buildTestLibrary(
      extensionTypes: [
        ExtensionTypeSpec('extension type A(int it)'),
        ExtensionTypeSpec('extension type B(int it) implements int'),
      ],
    );
    isPotentiallyNullable(parseInterfaceType('A?'));
    isPotentiallyNullable(parseInterfaceType('A'));
    isNotPotentiallyNullable(parseInterfaceType('B'));
  }

  test_invalidType() {
    isPotentiallyNullable(parseType('InvalidType'));
  }

  test_never() {
    isNotPotentiallyNullable(parseType('Never'));
  }

  test_null() {
    isPotentiallyNullable(parseType('Null'));
  }

  test_void() {
    isPotentiallyNullable(parseType('void'));
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
    isNotStrictlyNonNullable(parseType('dynamic'));
  }

  test_function() {
    isStrictlyNonNullable(parseType('void Function()'));

    isNotStrictlyNonNullable(parseType('void Function()?'));
  }

  test_functionClass() {
    isStrictlyNonNullable(parseType('Function'));
    isNotStrictlyNonNullable(parseType('Function?'));
  }

  test_futureOr_noneArgument() {
    isStrictlyNonNullable(parseType('FutureOr<int>'));

    isNotStrictlyNonNullable(parseType('FutureOr<int>?'));
  }

  test_futureOr_questionArgument() {
    isNotStrictlyNonNullable(parseType('FutureOr<int?>'));

    isNotStrictlyNonNullable(parseType('FutureOr<int?>?'));
  }

  test_interface() {
    isStrictlyNonNullable(parseType('int'));
    isNotStrictlyNonNullable(parseType('int?'));
  }

  test_interface_extensionType2() {
    buildTestLibrary(
      extensionTypes: [
        ExtensionTypeSpec('extension type A(int it)'),
        ExtensionTypeSpec('extension type B(int it) implements int'),
      ],
    );
    isNotStrictlyNonNullable(parseInterfaceType('A'));
    isStrictlyNonNullable(parseInterfaceType('B'));
  }

  test_invalidType() {
    isNotStrictlyNonNullable(parseType('InvalidType'));
  }

  test_never() {
    isStrictlyNonNullable(parseType('Never'));
    isNotStrictlyNonNullable(parseType('Never?'));
  }

  test_null() {
    isNotStrictlyNonNullable(parseType('Null'));
  }

  test_typeParameter_boundNone() {
    withTypeParameterScope('T extends int', (scope) {
      isStrictlyNonNullable(scope.parseType('T'));
      isNotStrictlyNonNullable(scope.parseType('T?'));
    });
  }

  test_typeParameter_boundQuestion() {
    withTypeParameterScope('T extends int?', (scope) {
      isNotStrictlyNonNullable(scope.parseType('T'));
      isNotStrictlyNonNullable(scope.parseType('T?'));
    });
  }

  test_void() {
    isNotStrictlyNonNullable(parseType('void'));
  }
}

@reflectiveTest
class PromoteToNonNullTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _check(parseType('dynamic'), parseType('dynamic'));
  }

  test_functionType() {
    // NonNull(T0 Function(...)) = T0 Function(...)
    _check(parseType('void Function()?'), parseType('void Function()'));
  }

  test_futureOr_question() {
    // NonNull(FutureOr<T>) = FutureOr<T>
    _check(parseType('FutureOr<String?>?'), parseType('FutureOr<String?>'));
  }

  test_interfaceType() {
    _check(parseType('int'), parseType('int'));
    _check(parseType('int?'), parseType('int'));

    // NonNull(C<T1, ... , Tn>) = C<T1, ... , Tn>
    _check(parseType('List<int?>?'), parseType('List<int?>'));
  }

  test_interfaceType_function() {
    _check(parseType('Function?'), parseType('Function'));
  }

  test_invalidType() {
    _check(parseType('InvalidType'), parseType('InvalidType'));
  }

  test_never() {
    _check(parseType('Never'), parseType('Never'));
    _check(parseType('Never?'), parseType('Never'));
  }

  test_null() {
    _check(parseType('Null'), parseType('Never'));
  }

  test_typeParameter_bound_dynamic() {
    withTypeParameterScope('T extends dynamic', (scope) {
      var element = scope.typeParameter('T');
      _checkTypeParameter(
        scope.parseTypeParameterType('T'),
        element: element,
        promotedBound: null,
      );
    });
  }

  test_typeParameter_bound_invalidType() {
    withTypeParameterScope('T extends InvalidType', (scope) {
      var element = scope.typeParameter('T');
      _checkTypeParameter(
        scope.parseTypeParameterType('T'),
        element: element,
        promotedBound: null,
      );
    });
  }

  test_typeParameter_bound_none() {
    withTypeParameterScope('T extends int', (scope) {
      var element = scope.typeParameter('T');
      _checkTypeParameter(
        scope.parseTypeParameterType('T'),
        element: element,
        promotedBound: null,
      );
      _checkTypeParameter(
        scope.parseTypeParameterType('T?'),
        element: element,
        promotedBound: null,
      );
    });
  }

  test_typeParameter_bound_null() {
    withTypeParameterScope('T', (scope) {
      var element = scope.typeParameter('T');
      _checkTypeParameter(
        scope.parseTypeParameterType('T'),
        element: element,
        promotedBound: parseType('Object'),
      );
    });
  }

  test_typeParameter_bound_question() {
    withTypeParameterScope('T extends int?', (scope) {
      var element = scope.typeParameter('T');
      _checkTypeParameter(
        scope.parseTypeParameterType('T'),
        element: element,
        promotedBound: parseType('int'),
      );
      _checkTypeParameter(
        scope.parseTypeParameterType('T?'),
        element: element,
        promotedBound: parseType('int'),
      );
    });
  }

  test_typeParameter_promotedBound_none() {
    withTypeParameterScope('T extends num?', (scope) {
      var element = scope.typeParameter('T');
      _checkTypeParameter(
        scope.parseTypeParameterType('T & int'),
        element: element,
        promotedBound: parseType('int'),
      );
      _checkTypeParameter(
        scope.parseTypeParameterType('(T & int)?'),
        element: element,
        promotedBound: parseType('int'),
      );
    });
  }

  test_typeParameter_promotedBound_question() {
    withTypeParameterScope('T extends num?', (scope) {
      var element = scope.typeParameter('T');
      _checkTypeParameter(
        scope.parseTypeParameterType('T & int?'),
        element: element,
        promotedBound: parseType('int'),
      );
      _checkTypeParameter(
        scope.parseTypeParameterType('(T & int?)?'),
        element: element,
        promotedBound: parseType('int'),
      );
    });
  }

  test_void() {
    _check(parseType('void'), parseType('void'));
  }

  void _check(TypeImpl type, TypeImpl expected) {
    var result = typeSystem.promoteToNonNull(type);
    expect(result, expected);
  }

  void _checkTypeParameter(
    TypeParameterTypeImpl type, {
    required TypeParameterElement element,
    required TypeImpl? promotedBound,
  }) {
    var actual = typeSystem.promoteToNonNull(type) as TypeParameterTypeImpl;
    expect(actual.element, same(element));
    expect(actual.promotedBound, promotedBound);
    expect(actual.nullabilitySuffix, NullabilitySuffix.none);
  }
}
