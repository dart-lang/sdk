// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeSystemImpl;
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/test_analysis_context.dart';

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
class IsNonNullableTest extends _NullableBase {
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

    isNonNullable(
      functionTypeStar(returnType: voidNone),
    );
  }

  test_functionClass() {
    isNonNullable(functionNone);
    isNotNonNullable(functionQuestion);
    isNonNullable(functionStar);
  }

  test_futureOr_noneArgument() {
    isNonNullable(
      futureOrNone(intNone),
    );

    isNotNonNullable(
      futureOrQuestion(intNone),
    );

    isNonNullable(
      futureOrStar(intNone),
    );
  }

  test_futureOr_questionArgument() {
    isNotNonNullable(
      futureOrNone(intQuestion),
    );

    isNotNonNullable(
      futureOrQuestion(intQuestion),
    );

    isNotNonNullable(
      futureOrStar(intQuestion),
    );
  }

  test_futureOr_starArgument() {
    isNonNullable(
      futureOrNone(intStar),
    );

    isNotNonNullable(
      futureOrStar(intQuestion),
    );

    isNonNullable(
      futureOrStar(intStar),
    );
  }

  test_interface() {
    isNonNullable(intNone);
    isNotNonNullable(intQuestion);
    isNonNullable(intStar);
  }

  test_never() {
    isNonNullable(neverNone);
    isNotNonNullable(neverQuestion);
    isNonNullable(neverStar);
  }

  test_null() {
    isNotNonNullable(nullStar);
  }

  test_typeParameter_noneBound() {
    var T = typeParameter('T', bound: intNone);

    isNonNullable(
      typeParameterTypeNone(T),
    );

    isNotNonNullable(
      typeParameterTypeQuestion(T),
    );
  }

  test_typeParameter_questionBound() {
    var T = typeParameter('T', bound: intQuestion);

    isNotNonNullable(
      typeParameterTypeNone(T),
    );

    isNotNonNullable(
      typeParameterTypeQuestion(T),
    );
  }

  test_typeParameter_starBound() {
    var T = typeParameter('T', bound: intStar);

    isNonNullable(
      typeParameterTypeStar(T),
    );
  }

  test_void() {
    isNotNonNullable(voidNone);
  }
}

@reflectiveTest
class IsNullableTest extends _NullableBase {
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

    isNotNullable(
      functionTypeStar(returnType: voidNone),
    );
  }

  test_functionClass() {
    isNotNullable(functionNone);
    isNullable(functionQuestion);
    isNotNullable(functionStar);
  }

  test_futureOr_noneArgument() {
    isNotNullable(
      futureOrNone(intNone),
    );

    isNullable(
      futureOrQuestion(intNone),
    );

    isNotNullable(
      futureOrStar(intNone),
    );
  }

  test_futureOr_questionArgument() {
    isNullable(
      futureOrNone(intQuestion),
    );

    isNullable(
      futureOrQuestion(intQuestion),
    );

    isNullable(
      futureOrStar(intQuestion),
    );
  }

  test_futureOr_starArgument() {
    isNotNullable(
      futureOrNone(intStar),
    );

    isNullable(
      futureOrQuestion(intStar),
    );

    isNotNullable(
      futureOrStar(intStar),
    );
  }

  test_interface() {
    isNotNullable(intNone);
    isNullable(intQuestion);
    isNotNullable(intStar);
  }

  test_never() {
    isNotNullable(neverNone);
    isNullable(neverQuestion);
    isNotNullable(neverStar);
  }

  test_null() {
    isNullable(nullStar);
  }

  test_typeParameter_noneBound() {
    var T = typeParameter('T', bound: intNone);

    isNotNullable(
      typeParameterTypeNone(T),
    );

    isNullable(
      typeParameterTypeQuestion(T),
    );
  }

  test_typeParameter_questionBound_none() {
    var T = typeParameter('T', bound: intQuestion);

    isNotNullable(
      typeParameterTypeNone(T),
    );

    isNullable(
      typeParameterTypeQuestion(T),
    );
  }

  test_typeParameter_starBound() {
    var T = typeParameter('T', bound: intStar);

    isNotNullable(
      typeParameterTypeStar(T),
    );
  }

  test_void() {
    isNullable(voidNone);
  }
}

@reflectiveTest
class IsPotentiallyNonNullableTest extends _NullableBase {
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

    isPotentiallyNonNullable(
      futureOrNone(intStar),
    );
  }

  test_interface() {
    isPotentiallyNonNullable(intNone);
    isNotPotentiallyNonNullable(intQuestion);
    isPotentiallyNonNullable(intStar);
  }

  test_never() {
    isPotentiallyNonNullable(neverNone);
  }

  test_null() {
    isNotPotentiallyNonNullable(nullStar);
  }

  test_void() {
    isNotPotentiallyNonNullable(voidNone);
  }
}

@reflectiveTest
class IsPotentiallyNullableTest extends _NullableBase {
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

    isNotPotentiallyNullable(
      futureOrNone(intStar),
    );
  }

  test_interface() {
    isNotPotentiallyNullable(intNone);
    isPotentiallyNullable(intQuestion);
    isNotPotentiallyNullable(intStar);
  }

  test_never() {
    isNotPotentiallyNullable(neverNone);
  }

  test_null() {
    isPotentiallyNullable(nullStar);
  }

  test_void() {
    isPotentiallyNullable(voidNone);
  }
}

@reflectiveTest
class IsStrictlyNonNullableTest extends _NullableBase {
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

    isNotStrictlyNonNullable(
      functionTypeStar(returnType: voidNone),
    );
  }

  test_functionClass() {
    isStrictlyNonNullable(functionNone);
    isNotStrictlyNonNullable(functionQuestion);
    isNotStrictlyNonNullable(functionStar);
  }

  test_futureOr_noneArgument() {
    isStrictlyNonNullable(
      futureOrNone(intNone),
    );

    isNotStrictlyNonNullable(
      futureOrQuestion(intNone),
    );

    isNotStrictlyNonNullable(
      futureOrStar(intNone),
    );
  }

  test_futureOr_questionArgument() {
    isNotStrictlyNonNullable(
      futureOrNone(intQuestion),
    );

    isNotStrictlyNonNullable(
      futureOrQuestion(intQuestion),
    );

    isNotStrictlyNonNullable(
      futureOrStar(intQuestion),
    );
  }

  test_futureOr_starArgument() {
    isNotStrictlyNonNullable(
      futureOrNone(intStar),
    );

    isNotStrictlyNonNullable(
      futureOrStar(intQuestion),
    );

    isNotStrictlyNonNullable(
      futureOrStar(intStar),
    );
  }

  test_interface() {
    isStrictlyNonNullable(intNone);
    isNotStrictlyNonNullable(intQuestion);
    isNotStrictlyNonNullable(intStar);
  }

  test_never() {
    isStrictlyNonNullable(neverNone);
    isNotStrictlyNonNullable(neverQuestion);
    isNotStrictlyNonNullable(neverStar);
  }

  test_null() {
    isNotStrictlyNonNullable(nullNone);
    isNotStrictlyNonNullable(nullQuestion);
    isNotStrictlyNonNullable(nullStar);
  }

  test_typeParameter_noneBound() {
    var T = typeParameter('T', bound: intNone);

    isStrictlyNonNullable(
      typeParameterTypeNone(T),
    );

    isNotStrictlyNonNullable(
      typeParameterTypeQuestion(T),
    );

    isNotStrictlyNonNullable(
      typeParameterTypeStar(T),
    );
  }

  test_typeParameter_questionBound() {
    var T = typeParameter('T', bound: intQuestion);

    isNotStrictlyNonNullable(
      typeParameterTypeNone(T),
    );

    isNotStrictlyNonNullable(
      typeParameterTypeQuestion(T),
    );

    isNotStrictlyNonNullable(
      typeParameterTypeStar(T),
    );
  }

  test_typeParameter_starBound() {
    var T = typeParameter('T', bound: intStar);

    isNotStrictlyNonNullable(
      typeParameterTypeNone(T),
    );

    isNotStrictlyNonNullable(
      typeParameterTypeQuestion(T),
    );

    isNotStrictlyNonNullable(
      typeParameterTypeStar(T),
    );
  }

  test_void() {
    isNotStrictlyNonNullable(voidNone);
  }
}

@reflectiveTest
class PromoteToNonNullTest extends _NullableBase {
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
    _check(intStar, intNone);

    // NonNull(C<T1, ... , Tn>) = C<T1, ... , Tn>
    _check(
      listQuestion(intQuestion),
      listNone(intQuestion),
    );
  }

  test_interfaceType_function() {
    _check(functionQuestion, functionNone);
  }

  test_never() {
    _check(neverNone, neverNone);
  }

  test_null() {
    _check(nullStar, neverNone);
  }

  test_typeParameter_noneBound() {
    var element = typeParameter('T', bound: intNone);

    _checkTypeParameter(
      typeParameterTypeNone(element),
      baseElement: element,
    );

    _checkTypeParameter(
      typeParameterTypeQuestion(element),
      baseElement: element,
    );
  }

  test_typeParameter_nullBound() {
    var element = typeParameter('T', bound: null);
    _checkTypeParameter(
      typeParameterTypeNone(element),
      baseElement: element,
      expectedBound: objectNone,
    );
  }

  test_typeParameter_questionBound() {
    var element = typeParameter('T', bound: intQuestion);

    _checkTypeParameter(
      typeParameterTypeNone(element),
      baseElement: element,
      expectedBound: intNone,
    );

    _checkTypeParameter(
      typeParameterTypeQuestion(element),
      baseElement: element,
      expectedBound: intNone,
    );

    _checkTypeParameter(
      typeParameterTypeStar(element),
      baseElement: element,
      expectedBound: intNone,
    );
  }

  test_typeParameter_starBound() {
    var element = typeParameter('T', bound: intStar);

    _checkTypeParameter(
      typeParameterTypeNone(element),
      baseElement: element,
      expectedBound: intNone,
    );
  }

  test_void() {
    _check(voidNone, voidNone);
  }

  void _check(DartType type, DartType expected) {
    var result = typeSystem.promoteToNonNull(type);
    expect(result, expected);
  }

  /// If [expectedBound] is `null`, the element of the result must be the same
  /// as the [baseElement].  Otherwise the element of the result must be a
  /// [TypeParameterMember] with the [baseElement] and the [expectedBound].
  void _checkTypeParameter(
    TypeParameterType type, {
    @required TypeParameterElement baseElement,
    DartType expectedBound,
  }) {
    var actual = typeSystem.promoteToNonNull(type);
    if (expectedBound != null) {
      var actualMember = actual.element as TypeParameterMember;
      expect(actualMember.declaration, same(baseElement));
      expect(actualMember.bound, expectedBound);
    } else {
      expect(actual.element, same(baseElement));
    }
    expect(actual.nullabilitySuffix, NullabilitySuffix.none);
  }
}

abstract class _NullableBase with ElementsTypesMixin {
  @override
  TypeProvider typeProvider;

  TypeSystemImpl typeSystem;

  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting();
  }

  void setUp() {
    var analysisContext = TestAnalysisContext(
      featureSet: testFeatureSet,
    );
    typeProvider = analysisContext.typeProviderLegacy;
    typeSystem = analysisContext.typeSystemLegacy;
  }
}
