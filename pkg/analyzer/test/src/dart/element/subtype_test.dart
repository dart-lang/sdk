// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeTest);
    defineReflectiveTests(NonNullableSubtypingCompoundTest);
    defineReflectiveTests(SubtypingCompoundTest);
  });
}

@reflectiveTest
class NonNullableSubtypingCompoundTest extends _SubtypingCompoundTestBase {
  @override
  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting(
      additionalFeatures: [Feature.non_nullable],
    );
  }

  test_dynamic() {
    var equivalents = <DartType>[
      voidNone,
      objectQuestion,
      objectStar,
    ];

    var subtypes = <DartType>[
      bottomNone,
      nullNone,
      objectNone,
    ];

    _checkGroups(
      dynamicNone,
      equivalents: equivalents,
      subtypes: subtypes,
    );
  }

  test_futureOr_topTypes() {
    var futureOrObject = futureOrNone(objectNone);
    var futureOrObjectStar = futureOrNone(objectStar);
    var futureOrObjectQuestion = futureOrNone(objectQuestion);

    var futureOrStarObject = futureOrStar(objectNone);
    var futureOrStarObjectStar = futureOrStar(objectStar);
    var futureOrStarObjectQuestion = futureOrStar(objectQuestion);

    var futureOrQuestionObject = futureOrQuestion(objectNone);
    var futureOrQuestionObjectStar = futureOrQuestion(objectStar);
    var futureOrQuestionObjectQuestion = futureOrQuestion(objectQuestion);

    //FutureOr<Object> <: FutureOr*<Object?>
    _checkGroups(
      futureOrObject,
      equivalents: [
        objectStar,
        futureOrObjectStar,
        futureOrStarObject,
        futureOrStarObjectStar,
        objectNone,
      ],
      subtypes: [],
      supertypes: [
        objectQuestion,
        futureOrQuestionObject,
        futureOrObjectQuestion,
        futureOrQuestionObject,
        futureOrQuestionObjectStar,
        futureOrStarObjectQuestion,
        futureOrQuestionObjectQuestion,
      ],
    );
  }

  test_intNone() {
    var equivalents = <DartType>[
      intNone,
      intStar,
    ];

    var subtypes = <DartType>[
      bottomNone,
    ];

    var supertypes = <DartType>[
      intQuestion,
      objectNone,
      objectQuestion,
    ];

    var unrelated = <DartType>[
      doubleNone,
      nullNone,
      nullStar,
      nullQuestion,
      bottomQuestion,
    ];

    _checkGroups(
      intNone,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_intQuestion() {
    var equivalents = <DartType>[
      intQuestion,
      intStar,
    ];

    var subtypes = <DartType>[
      intNone,
      nullNone,
      nullQuestion,
      nullStar,
      bottomNone,
      bottomQuestion,
      bottomStar,
    ];

    var supertypes = <DartType>[
      numQuestion,
      numStar,
      objectQuestion,
      objectStar,
    ];

    var unrelated = <DartType>[
      doubleNone,
      numNone,
      objectNone,
    ];

    _checkGroups(
      intQuestion,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_intStar() {
    var equivalents = <DartType>[
      intNone,
      intQuestion,
      intStar,
    ];

    var subtypes = <DartType>[
      nullNone,
      nullStar,
      nullQuestion,
      bottomNone,
      bottomStar,
      bottomQuestion,
    ];

    var supertypes = <DartType>[
      numNone,
      numQuestion,
      numStar,
      objectNone,
      objectQuestion,
    ];

    var unrelated = <DartType>[
      doubleStar,
    ];

    _checkGroups(
      intStar,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_null() {
    var equivalents = <DartType>[
      nullNone,
      nullQuestion,
      nullStar,
      bottomQuestion,
    ];

    var supertypes = <DartType>[
      intQuestion,
      intStar,
      objectQuestion,
      objectStar,
      dynamicNone,
      voidNone,
    ];

    var subtypes = <DartType>[
      bottomNone,
    ];

    var unrelated = <DartType>[
      doubleNone,
      intNone,
      numNone,
      objectNone,
    ];

    for (final formOfNull in equivalents) {
      _checkGroups(
        formOfNull,
        equivalents: equivalents,
        supertypes: supertypes,
        unrelated: unrelated,
        subtypes: subtypes,
      );
    }
  }

  test_object() {
    var equivalents = <DartType>[
      objectStar,
    ];

    var supertypes = <DartType>[
      objectQuestion,
      dynamicType,
      voidNone,
    ];

    var subtypes = <DartType>[
      bottomNone,
    ];

    var unrelated = <DartType>[
      doubleQuestion,
      numQuestion,
      intQuestion,
      nullNone,
    ];

    _checkGroups(
      objectNone,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }
}

@reflectiveTest
class SubtypeTest extends _SubtypingTestBase {
  void assertExpectedString(TypeImpl type, String expectedString) {
    if (expectedString != null) {
      var typeStr = type.toString(withNullability: true);

      var typeParameterCollector = _TypeParameterCollector();
      DartTypeVisitor.visit(type, typeParameterCollector);
      for (var typeParameter in typeParameterCollector.typeParameters) {
        if (typeParameter is TypeParameterMember) {
          var boundTypeImpl = typeParameter.bound as TypeImpl;
          var boundTypeStr = boundTypeImpl.toString(withNullability: true);
          typeStr += ', ${typeParameter.name} & ' + boundTypeStr;
        }
      }

      expect(typeStr, expectedString);
    }
  }

  InterfaceType comparableStar(DartType type) {
    return comparableElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  void isNotSubtype(
    DartType T0,
    DartType T1, {
    String strT0,
    String strT1,
  }) {
    assertExpectedString(T0, strT0);
    assertExpectedString(T1, strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isFalse);
  }

  void isSubtype(
    DartType T0,
    DartType T1, {
    String strT0,
    String strT1,
  }) {
    assertExpectedString(T0, strT0);
    assertExpectedString(T1, strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isTrue);
  }

  InterfaceType iterableStar(DartType type) {
    return typeProvider.iterableElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType listQuestion(DartType type) {
    return typeProvider.listElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType listStar(DartType type) {
    return typeProvider.listElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  TypeParameterMember promoteTypeParameter(
    TypeParameterElement element,
    DartType bound,
  ) {
    assert(element is! TypeParameterMember);
    return TypeParameterMember(element, null, bound);
  }

  test_functionType_01() {
    var E0 = typeParameter('E0');
    var E1 = typeParameter('E1', bound: numStar);

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: numStar),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0 Function<E0>(E0, num*)*',
      strT1: 'E1* Function<E1 extends num*>(E1*, E1*)*',
    );
  }

  test_functionType_02() {
    var E0 = typeParameter('E0', bound: numStar);
    var E1 = typeParameter('E1', bound: intStar);

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function<E0 extends num*>(E0*)*',
      strT1: 'int* Function<E1 extends int*>(E1*)*',
    );
  }

  test_functionType_03() {
    var E0 = typeParameter('E0', bound: numStar);
    var E1 = typeParameter('E1', bound: intStar);

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0* Function<E0 extends num*>(E0*)*',
      strT1: 'E1* Function<E1 extends int*>(E1*)*',
    );
  }

  test_functionType_04() {
    var E0 = typeParameter('E0', bound: numStar);
    var E1 = typeParameter('E1', bound: intStar);

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0* Function<E0 extends num*>(int*)*',
      strT1: 'E1* Function<E1 extends int*>(int*)*',
    );
  }

  test_functionType_05() {
    var E0 = typeParameter('E0', bound: numStar);
    var E1 = typeParameter('E1', bound: numStar);

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: numStar,
      ),
      strT0: 'E0* Function<E0 extends num*>(E0*)*',
      strT1: 'num* Function<E1 extends num*>(E1*)*',
    );
  }

  test_functionType_06() {
    var E0 = typeParameter('E0', bound: intStar);
    var E1 = typeParameter('E1', bound: intStar);

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: numStar,
      ),
      strT0: 'E0* Function<E0 extends int*>(E0*)*',
      strT1: 'num* Function<E1 extends int*>(E1*)*',
    );
  }

  test_functionType_07() {
    var E0 = typeParameter('E0', bound: intStar);
    var E1 = typeParameter('E1', bound: intStar);

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: intStar,
      ),
      strT0: 'E0* Function<E0 extends int*>(E0*)*',
      strT1: 'int* Function<E1 extends int*>(E1*)*',
    );
  }

  test_functionType_08() {
    var E0 = typeParameter('E0');

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function<E0>(int*)*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_functionType_09() {
    var E0 = typeParameter('E0');
    var F0 = typeParameter('F0');
    var E1 = typeParameter('E1');

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0, F0],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function<E0,F0>(int*)*',
      strT1: 'int* Function<E1>(int*)*',
    );
  }

  test_functionType_10() {
    var E0 = typeParameter('E0');
    E0.bound = listStar(
      typeParameterTypeStar(E0),
    );

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0* Function<E0 extends List<E0*>*>(E0*)*',
      strT1: 'E1* Function<E1 extends List<E1*>*>(E1*)*',
    );
  }

  test_functionType_11() {
    var E0 = typeParameter('E0');
    E0.bound = iterableStar(
      typeParameterTypeStar(E0),
    );

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E0)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0* Function<E0 extends Iterable<E0*>*>(E0*)*',
      strT1: 'E1* Function<E1 extends List<E1*>*>(E1*)*',
    );
  }

  test_functionType_12() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listStar(objectStar)),
        ],
        returnType: typeParameterTypeStar(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'E0* Function<E0>(E0, List<Object*>*)*',
      strT1: 'E1* Function<E1 extends List<E1*>*>(E1*, E1*)*',
    );
  }

  test_functionType_13() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listStar(objectStar)),
        ],
        returnType: listStar(
          typeParameterTypeNone(E0),
        ),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'List<E0>* Function<E0>(E0, List<Object*>*)*',
      strT1: 'E1* Function<E1 extends List<E1*>*>(E1*, E1*)*',
    );
  }

  test_functionType_14() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listStar(objectStar)),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: typeParameterTypeStar(E1),
      ),
      strT0: 'int* Function<E0>(E0, List<Object*>*)*',
      strT1: 'E1* Function<E1 extends List<E1*>*>(E1*, E1*)*',
    );
  }

  test_functionType_15() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listStar(
      typeParameterTypeStar(E1),
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listStar(objectStar)),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeStar(E1)),
          requiredParameter(type: typeParameterTypeStar(E1)),
        ],
        returnType: voidNone,
      ),
      strT0: 'E0 Function<E0>(E0, List<Object*>*)*',
      strT1: 'void Function<E1 extends List<E1*>*>(E1*, E1*)*',
    );
  }

  test_functionType_16() {
    isSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionStar,
      strT0: 'int* Function()*',
      strT1: 'Function*',
    );
  }

  test_functionType_17() {
    isNotSubtype(
      functionStar,
      functionTypeStar(
        returnType: intStar,
      ),
      strT0: 'Function*',
      strT1: 'int* Function()*',
    );
  }

  test_functionType_18() {
    isSubtype(
      functionTypeStar(
        returnType: dynamicNone,
      ),
      functionTypeStar(
        returnType: dynamicNone,
      ),
      strT0: 'dynamic Function()*',
      strT1: 'dynamic Function()*',
    );
  }

  test_functionType_19() {
    isSubtype(
      functionTypeStar(
        returnType: dynamicNone,
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'dynamic Function()*',
      strT1: 'void Function()*',
    );
  }

  test_functionType_20() {
    isSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      functionTypeStar(
        returnType: dynamicNone,
      ),
      strT0: 'void Function()*',
      strT1: 'dynamic Function()*',
    );
  }

  test_functionType_21() {
    isSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'int* Function()*',
      strT1: 'void Function()*',
    );
  }

  test_functionType_22() {
    isNotSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      functionTypeStar(
        returnType: intStar,
      ),
      strT0: 'void Function()*',
      strT1: 'int* Function()*',
    );
  }

  test_functionType_23() {
    isSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'void Function()*',
      strT1: 'void Function()*',
    );
  }

  test_functionType_24() {
    isSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        returnType: intStar,
      ),
      strT0: 'int* Function()*',
      strT1: 'int* Function()*',
    );
  }

  test_functionType_25() {
    isSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        returnType: objectStar,
      ),
      strT0: 'int* Function()*',
      strT1: 'Object* Function()*',
    );
  }

  test_functionType_26() {
    isNotSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        returnType: doubleStar,
      ),
      strT0: 'int* Function()*',
      strT1: 'double* Function()*',
    );
  }

  test_functionType_27() {
    isNotSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'int* Function()*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_28() {
    isNotSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'void Function()*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_functionType_29() {
    isNotSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function()*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_30() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function(int*)*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_functionType_31() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: objectStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: objectStar,
      ),
      strT0: 'int* Function(Object*)*',
      strT1: 'Object* Function(int*)*',
    );
  }

  test_functionType_32() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: doubleStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function(int*)*',
      strT1: 'int* Function(double*)*',
    );
  }

  test_functionType_33() {
    isNotSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function()*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_functionType_34() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function(int*)*',
      strT1: 'int* Function(int*, int*)*',
    );
  }

  test_functionType_35() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'int* Function(int*, int*)*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_functionType_36() {
    var f = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    var g = functionTypeStar(
      parameters: [
        requiredParameter(
          type: functionTypeStar(
            parameters: [
              requiredParameter(type: intStar),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );

    isNotSubtype(
      f,
      g,
      strT0: 'void Function(void Function()*)*',
      strT1: 'void Function(void Function(int*)*)*',
    );

    isNotSubtype(
      g,
      f,
      strT0: 'void Function(void Function(int*)*)*',
      strT1: 'void Function(void Function()*)*',
    );
  }

  test_functionType_37() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function()*',
    );
  }

  test_functionType_38() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_39() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int*)*',
      strT1: 'void Function([int*])*',
    );
  }

  test_functionType_40() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function([int*])*',
    );
  }

  test_functionType_41() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: objectStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([Object*])*',
      strT1: 'void Function([int*])*',
    );
  }

  test_functionType_42() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: objectStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function([Object*])*',
    );
  }

  test_functionType_43() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int*, [int*])*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_44() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int*, [int*])*',
      strT1: 'void Function(int*, [int*])*',
    );
  }

  test_functionType_45() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*, int*])*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_46() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*, int*])*',
      strT1: 'void Function(int*, [int*])*',
    );
  }

  test_functionType_47() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*, int*])*',
      strT1: 'void Function(int*, [int*, int*])*',
    );
  }

  test_functionType_48() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*, int*, int*])*',
      strT1: 'void Function(int*, [int*, int*])*',
    );
  }

  test_functionType_49() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: doubleStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function(double*)*',
    );
  }

  test_functionType_50() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*])*',
      strT1: 'void Function([int*, int*])*',
    );
  }

  test_functionType_51() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int*, int*])*',
      strT1: 'void Function([int*])*',
    );
  }

  test_functionType_52() {
    isSubtype(
      functionTypeStar(
        parameters: [
          positionalParameter(type: objectStar),
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          positionalParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([Object*, int*])*',
      strT1: 'void Function([int*])*',
    );
  }

  test_functionType_53() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'void Function({a: int*})*',
      strT1: 'void Function()*',
    );
  }

  test_functionType_54() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({a: int*})*',
      strT1: 'void Function(int*)*',
    );
  }

  test_functionType_55() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int*)*',
      strT1: 'void Function({a: int*})*',
    );
  }

  test_functionType_56() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({a: int*})*',
      strT1: 'void Function({a: int*})*',
    );
  }

  test_functionType_57() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'b', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({a: int*})*',
      strT1: 'void Function({b: int*})*',
    );
  }

  test_functionType_58() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: objectStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({a: Object*})*',
      strT1: 'void Function({a: int*})*',
    );
  }

  test_functionType_59() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: objectStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({a: int*})*',
      strT1: 'void Function({a: Object*})*',
    );
  }

  test_functionType_60() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int*, {a: int*})*',
      strT1: 'void Function(int*, {a: int*})*',
    );
  }

  test_functionType_61() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: doubleStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({a: int*})*',
      strT1: 'void Function({a: double*})*',
    );
  }

  test_functionType_62() {
    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'b', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({a: int*})*',
      strT1: 'void Function({a: int*, b: int*})*',
    );
  }

  test_functionType_63() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'b', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({a: int*, b: int*})*',
      strT1: 'void Function({a: int*})*',
    );
  }

  test_functionType_64() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({a: int*, b: int*, c: int*})*',
      strT1: 'void Function({a: int*, c: int*})*',
    );
  }

  test_functionType_65() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'c', type: intStar),
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({c: int*, b: int*, a: int*})*',
      strT1: 'void Function({a: int*, c: int*})*',
    );
  }

  test_functionType_66() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({a: int*, b: int*, c: int*})*',
      strT1: 'void Function({b: int*, c: int*})*',
    );
  }

  test_functionType_67() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'c', type: intStar),
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({c: int*, b: int*, a: int*})*',
      strT1: 'void Function({b: int*, c: int*})*',
    );
  }

  test_functionType_68() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'a', type: intStar),
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({a: int*, b: int*, c: int*})*',
      strT1: 'void Function({c: int*})*',
    );
  }

  test_functionType_69() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'c', type: intStar),
          namedParameter(name: 'b', type: intStar),
          namedParameter(name: 'a', type: intStar),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'c', type: intStar),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({c: int*, b: int*, a: int*})*',
      strT1: 'void Function({c: int*})*',
    );
  }

  test_functionType_generic_nested() {
    var E0 = typeParameter('E0');
    var F0 = typeParameter('F0');
    var E1 = typeParameter('E1');
    var F1 = typeParameter('F1');

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(E0)),
          ],
          returnType: typeParameterTypeNone(E0),
        ),
      ),
      functionTypeStar(
        typeFormals: [F1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(F1)),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F1)),
          ],
          returnType: typeParameterTypeNone(F1),
        ),
      ),
      strT0: 'E0 Function(E0)* Function<E0>(E0)*',
      strT1: 'F1 Function(F1)* Function<F1>(F1)*',
    );

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(
            type: functionTypeStar(
              parameters: [
                requiredParameter(type: intStar),
                requiredParameter(type: typeParameterTypeNone(E0)),
              ],
              returnType: typeParameterTypeNone(E0),
            ),
          ),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(
            type: functionTypeStar(
              parameters: [
                requiredParameter(type: numStar),
                requiredParameter(type: typeParameterTypeNone(E1)),
              ],
              returnType: typeParameterTypeNone(E1),
            ),
          ),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E0 Function<E0>(E0, E0 Function(int*, E0)*)*',
      strT1: 'E1 Function<E1>(E1, E1 Function(num*, E1)*)*',
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0, F0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F0)),
          ],
          returnType: typeParameterTypeNone(E0),
        ),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: functionTypeStar(
          typeFormals: [F1],
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F1)),
          ],
          returnType: typeParameterTypeNone(E1),
        ),
      ),
      strT0: 'E0 Function(F0)* Function<E0,F0>(E0)*',
      strT1: 'E1 Function<F1>(F1)* Function<E1>(E1)*',
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0, F0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F0)),
          ],
          returnType: typeParameterTypeNone(E0),
        ),
      ),
      functionTypeStar(
        typeFormals: [F1, E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F1)),
          ],
          returnType: typeParameterTypeNone(E1),
        ),
      ),
      strT0: 'E0 Function(F0)* Function<E0,F0>(E0)*',
      strT1: 'E1 Function(F1)* Function<F1,E1>(E1)*',
    );
  }

  test_functionType_generic_required() {
    var E0 = typeParameter('E');
    var E1 = typeParameter('E');

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function<E>(E)*',
      strT1: 'num* Function<E>(E)*',
    );

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E Function<E>(num*)*',
      strT1: 'E Function<E>(int*)*',
    );

    isSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: numStar),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(type: intStar),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E Function<E>(E, num*)*',
      strT1: 'E Function<E>(E, int*)*',
    );

    isNotSubtype(
      functionTypeStar(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: numStar),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeStar(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E Function<E>(E, num*)*',
      strT1: 'E Function<E>(E, E)*',
    );
  }

  test_functionType_notGeneric_functionReturnType() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: numStar),
          ],
          returnType: numStar,
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: intStar),
          ],
          returnType: numStar,
        ),
      ),
      strT0: 'num* Function(num*)* Function(num*)*',
      strT1: 'num* Function(int*)* Function(num*)*',
    );

    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: intStar),
          ],
          returnType: intStar,
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: functionTypeStar(
          parameters: [
            requiredParameter(type: numStar),
          ],
          returnType: numStar,
        ),
      ),
      strT0: 'int* Function(int*)* Function(int*)*',
      strT1: 'num* Function(num*)* Function(num*)*',
    );
  }

  test_functionType_notGeneric_named() {
    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: numStar),
        ],
        returnType: numStar,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: intStar),
        ],
        returnType: numStar,
      ),
      strT0: 'num* Function({x: num*})*',
      strT1: 'num* Function({x: int*})*',
    );

    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
          namedParameter(name: 'x', type: numStar),
        ],
        returnType: numStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
          namedParameter(name: 'x', type: intStar),
        ],
        returnType: numStar,
      ),
      strT0: 'num* Function(num*, {x: num*})*',
      strT1: 'num* Function(int*, {x: int*})*',
    );

    isSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: numStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: numStar),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function({x: num*})*',
      strT1: 'num* Function({x: num*})*',
    );

    isNotSubtype(
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          namedParameter(name: 'x', type: numStar),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function({x: int*})*',
      strT1: 'num* Function({x: num*})*',
    );
  }

  test_functionType_notGeneric_required() {
    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: numStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: numStar,
      ),
      strT0: 'num* Function(num*)*',
      strT1: 'num* Function(int*)*',
    );

    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function(num*)*',
      strT1: 'num* Function(num*)*',
    );

    isSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function(num*)*',
      strT1: 'num* Function(int*)*',
    );

    isNotSubtype(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: numStar),
        ],
        returnType: numStar,
      ),
      strT0: 'int* Function(int*)*',
      strT1: 'num* Function(num*)*',
    );

    isSubtype(
      nullQuestion,
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: numStar,
      ),
      strT0: 'Null?',
      strT1: 'num* Function(int*)*',
    );
  }

  test_futureOr_01() {
    isSubtype(
      intStar,
      futureOrStar(intStar),
      strT0: 'int*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_02() {
    isSubtype(
      intStar,
      futureOrStar(numStar),
      strT0: 'int*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_03() {
    isSubtype(
      futureStar(intStar),
      futureOrStar(intStar),
      strT0: 'Future<int*>*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_04() {
    isSubtype(
      futureStar(intStar),
      futureOrStar(numStar),
      strT0: 'Future<int*>*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_05() {
    isSubtype(
      futureStar(intStar),
      futureOrStar(objectStar),
      strT0: 'Future<int*>*',
      strT1: 'FutureOr<Object*>*',
    );
  }

  test_futureOr_06() {
    isSubtype(
      futureOrStar(intStar),
      futureOrStar(intStar),
      strT0: 'FutureOr<int*>*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_07() {
    isSubtype(
      futureOrStar(intStar),
      futureOrStar(numStar),
      strT0: 'FutureOr<int*>*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_08() {
    isSubtype(
      futureOrStar(intStar),
      objectStar,
      strT0: 'FutureOr<int*>*',
      strT1: 'Object*',
    );
  }

  test_futureOr_09() {
    isNotSubtype(
      intStar,
      futureOrStar(doubleStar),
      strT0: 'int*',
      strT1: 'FutureOr<double*>*',
    );
  }

  test_futureOr_10() {
    isNotSubtype(
      futureOrStar(doubleStar),
      intStar,
      strT0: 'FutureOr<double*>*',
      strT1: 'int*',
    );
  }

  test_futureOr_11() {
    isNotSubtype(
      futureOrStar(intStar),
      futureStar(numStar),
      strT0: 'FutureOr<int*>*',
      strT1: 'Future<num*>*',
    );
  }

  test_futureOr_12() {
    isNotSubtype(
      futureOrStar(intStar),
      numStar,
      strT0: 'FutureOr<int*>*',
      strT1: 'num*',
    );
  }

  test_futureOr_13() {
    isSubtype(
      nullQuestion,
      futureOrStar(intStar),
      strT0: 'Null?',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_14() {
    isSubtype(
      nullQuestion,
      futureStar(intStar),
      strT0: 'Null?',
      strT1: 'Future<int*>*',
    );
  }

  test_futureOr_15() {
    isSubtype(
      dynamicNone,
      futureOrStar(dynamicNone),
      strT0: 'dynamic',
      strT1: 'FutureOr<dynamic>*',
    );
  }

  test_futureOr_16() {
    isNotSubtype(
      dynamicNone,
      futureOrStar(stringStar),
      strT0: 'dynamic',
      strT1: 'FutureOr<String*>*',
    );
  }

  test_futureOr_17() {
    isSubtype(
      voidNone,
      futureOrStar(voidNone),
      strT0: 'void',
      strT1: 'FutureOr<void>*',
    );
  }

  test_futureOr_18() {
    isNotSubtype(
      voidNone,
      futureOrStar(stringStar),
      strT0: 'void',
      strT1: 'FutureOr<String*>*',
    );
  }

  test_futureOr_19() {
    var E = typeParameter('E');

    isSubtype(
      typeParameterTypeNone(E),
      futureOrStar(
        typeParameterTypeNone(E),
      ),
      strT0: 'E',
      strT1: 'FutureOr<E>*',
    );
  }

  test_futureOr_20() {
    var E = typeParameter('E');

    isNotSubtype(
      typeParameterTypeNone(E),
      futureOrStar(stringStar),
      strT0: 'E',
      strT1: 'FutureOr<String*>*',
    );
  }

  test_futureOr_21() {
    isSubtype(
      functionTypeStar(
        parameters: [],
        returnType: stringStar,
      ),
      futureOrStar(
        functionTypeStar(
          parameters: [],
          returnType: voidNone,
        ),
      ),
      strT0: 'String* Function()*',
      strT1: 'FutureOr<void Function()*>*',
    );
  }

  test_futureOr_22() {
    isNotSubtype(
      functionTypeStar(
        parameters: [],
        returnType: voidNone,
      ),
      futureOrStar(
        functionTypeStar(
          parameters: [],
          returnType: stringStar,
        ),
      ),
      strT0: 'void Function()*',
      strT1: 'FutureOr<String* Function()*>*',
    );
  }

  test_futureOr_23() {
    isNotSubtype(
      futureOrStar(numStar),
      futureOrStar(intStar),
      strT0: 'FutureOr<num*>*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_24() {
    var T = typeParameter('T');
    var Tp = promoteTypeParameter(T, intStar);

    isSubtype(
      typeParameterTypeNone(Tp),
      futureOrStar(numStar),
      strT0: 'T, T & int*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_25() {
    var T = typeParameter('T');
    var Tp = promoteTypeParameter(T, futureStar(numStar));

    isSubtype(
      typeParameterTypeNone(Tp),
      futureOrStar(numStar),
      strT0: 'T, T & Future<num*>*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_26() {
    var T = typeParameter('T');
    var Tp = promoteTypeParameter(T, futureStar(intStar));

    isSubtype(
      typeParameterTypeNone(Tp),
      futureOrStar(numStar),
      strT0: 'T, T & Future<int*>*',
      strT1: 'FutureOr<num*>*',
    );
  }

  test_futureOr_27() {
    var T = typeParameter('T');
    var Tp = promoteTypeParameter(T, numStar);

    isNotSubtype(
      typeParameterTypeNone(Tp),
      futureOrStar(intStar),
      strT0: 'T, T & num*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_28() {
    var T = typeParameter('T');
    var Tp = promoteTypeParameter(T, futureStar(numStar));

    isNotSubtype(
      typeParameterTypeNone(Tp),
      futureOrStar(intStar),
      strT0: 'T, T & Future<num*>*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_29() {
    var T = typeParameter('T');
    var Tp = promoteTypeParameter(T, futureOrStar(numStar));

    isNotSubtype(
      typeParameterTypeNone(Tp),
      futureOrStar(intStar),
      strT0: 'T, T & FutureOr<num*>*',
      strT1: 'FutureOr<int*>*',
    );
  }

  test_futureOr_30() {
    isSubtype(
      futureOrStar(objectStar),
      futureOrStar(
        futureOrStar(objectStar),
      ),
      strT0: 'FutureOr<Object*>*',
      strT1: 'FutureOr<FutureOr<Object*>*>*',
    );
  }

  test_interfaceType_01() {
    isSubtype(intStar, intStar, strT0: 'int*', strT1: 'int*');
  }

  test_interfaceType_02() {
    isSubtype(intStar, numStar, strT0: 'int*', strT1: 'num*');
  }

  test_interfaceType_03() {
    isSubtype(
      intStar,
      comparableStar(numStar),
      strT0: 'int*',
      strT1: 'Comparable<num*>*',
    );
  }

  test_interfaceType_04() {
    isSubtype(intStar, objectStar, strT0: 'int*', strT1: 'Object*');
  }

  test_interfaceType_05() {
    isSubtype(doubleStar, numStar, strT0: 'double*', strT1: 'num*');
  }

  test_interfaceType_06() {
    isNotSubtype(intStar, doubleStar, strT0: 'int*', strT1: 'double*');
  }

  test_interfaceType_07() {
    isNotSubtype(
      intStar,
      comparableStar(intStar),
      strT0: 'int*',
      strT1: 'Comparable<int*>*',
    );
  }

  test_interfaceType_08() {
    isNotSubtype(
      intStar,
      iterableStar(intStar),
      strT0: 'int*',
      strT1: 'Iterable<int*>*',
    );
  }

  test_interfaceType_09() {
    isNotSubtype(
      comparableStar(intStar),
      iterableStar(intStar),
      strT0: 'Comparable<int*>*',
      strT1: 'Iterable<int*>*',
    );
  }

  test_interfaceType_10() {
    isSubtype(
      listStar(intStar),
      listStar(intStar),
      strT0: 'List<int*>*',
      strT1: 'List<int*>*',
    );
  }

  test_interfaceType_11() {
    isSubtype(
      listStar(intStar),
      iterableStar(intStar),
      strT0: 'List<int*>*',
      strT1: 'Iterable<int*>*',
    );
  }

  test_interfaceType_12() {
    isSubtype(
      listStar(intStar),
      listStar(numStar),
      strT0: 'List<int*>*',
      strT1: 'List<num*>*',
    );
  }

  test_interfaceType_13() {
    isSubtype(
      listStar(intStar),
      iterableStar(numStar),
      strT0: 'List<int*>*',
      strT1: 'Iterable<num*>*',
    );
  }

  test_interfaceType_14() {
    isSubtype(
      listStar(intStar),
      listStar(objectStar),
      strT0: 'List<int*>*',
      strT1: 'List<Object*>*',
    );
  }

  test_interfaceType_15() {
    isSubtype(
      listStar(intStar),
      iterableStar(objectStar),
      strT0: 'List<int*>*',
      strT1: 'Iterable<Object*>*',
    );
  }

  test_interfaceType_16() {
    isSubtype(
      listStar(intStar),
      objectStar,
      strT0: 'List<int*>*',
      strT1: 'Object*',
    );
  }

  test_interfaceType_17() {
    isSubtype(
      listStar(intStar),
      listStar(
        comparableStar(objectStar),
      ),
      strT0: 'List<int*>*',
      strT1: 'List<Comparable<Object*>*>*',
    );
  }

  test_interfaceType_18() {
    isSubtype(
      listStar(intStar),
      listStar(
        comparableStar(numStar),
      ),
      strT0: 'List<int*>*',
      strT1: 'List<Comparable<num*>*>*',
    );
  }

  test_interfaceType_19() {
    isSubtype(
      listStar(intStar),
      listStar(
        comparableStar(
          comparableStar(numStar),
        ),
      ),
      strT0: 'List<int*>*',
      strT1: 'List<Comparable<Comparable<num*>*>*>*',
    );
  }

  test_interfaceType_20() {
    isNotSubtype(
      listStar(intStar),
      listStar(doubleStar),
      strT0: 'List<int*>*',
      strT1: 'List<double*>*',
    );
  }

  test_interfaceType_21() {
    isNotSubtype(
      listStar(intStar),
      iterableStar(doubleStar),
      strT0: 'List<int*>*',
      strT1: 'Iterable<double*>*',
    );
  }

  test_interfaceType_22() {
    isNotSubtype(
      listStar(intStar),
      comparableStar(intStar),
      strT0: 'List<int*>*',
      strT1: 'Comparable<int*>*',
    );
  }

  test_interfaceType_23() {
    isNotSubtype(
      listStar(intStar),
      listStar(
        comparableStar(intStar),
      ),
      strT0: 'List<int*>*',
      strT1: 'List<Comparable<int*>*>*',
    );
  }

  test_interfaceType_24() {
    isNotSubtype(
      listStar(intStar),
      listStar(
        comparableStar(
          comparableStar(intStar),
        ),
      ),
      strT0: 'List<int*>*',
      strT1: 'List<Comparable<Comparable<int*>*>*>*',
    );
  }

  test_interfaceType_25_interfaces() {
    var A = class_(name: 'A');
    var I = class_(name: 'I');

    A.interfaces = [
      I.instantiate(
        typeArguments: const [],
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    ];

    var A_none = A.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var I_none = I.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_none, I_none, strT0: 'A', strT1: 'I');
    isNotSubtype(I_none, A_none, strT0: 'I', strT1: 'A');
  }

  test_interfaceType_26_mixins() {
    var A = class_(name: 'A');
    var M = class_(name: 'M');

    A.mixins = [
      M.instantiate(
        typeArguments: const [],
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    ];

    var A_none = A.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var M_none = M.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_none, M_none, strT0: 'A', strT1: 'M');
    isNotSubtype(M_none, A_none, strT0: 'M', strT1: 'A');
  }

  test_never_01() {
    isSubtype(
      neverNone,
      neverNone,
      strT0: 'Never',
      strT1: 'Never',
    );
  }

  test_null_01() {
    isNotSubtype(
      nullQuestion,
      neverNone,
      strT0: 'Null?',
      strT1: 'Never',
    );
  }

  test_null_02() {
    isSubtype(
      nullQuestion,
      objectStar,
      strT0: 'Null?',
      strT1: 'Object*',
    );
  }

  test_null_03() {
    isSubtype(
      nullQuestion,
      voidNone,
      strT0: 'Null?',
      strT1: 'void',
    );
  }

  test_null_04() {
    isSubtype(
      nullQuestion,
      dynamicNone,
      strT0: 'Null?',
      strT1: 'dynamic',
    );
  }

  test_null_05() {
    isSubtype(
      nullQuestion,
      doubleStar,
      strT0: 'Null?',
      strT1: 'double*',
    );
  }

  test_null_06() {
    isSubtype(
      nullQuestion,
      comparableStar(objectStar),
      strT0: 'Null?',
      strT1: 'Comparable<Object*>*',
    );
  }

  test_null_07() {
    var T = typeParameter('T', bound: objectStar);

    isNotSubtype(
      nullQuestion,
      typeParameterTypeNone(T),
      strT0: 'Null?',
      strT1: 'T',
    );
  }

  test_null_08() {
    isSubtype(
      nullQuestion,
      nullQuestion,
      strT0: 'Null?',
      strT1: 'Null?',
    );
  }

  test_nullabilitySuffix_01() {
    isSubtype(intNone, intNone, strT0: 'int', strT1: 'int');
    isSubtype(intNone, intQuestion, strT0: 'int', strT1: 'int?');
    isSubtype(intNone, intStar, strT0: 'int', strT1: 'int*');

    isNotSubtype(intQuestion, intNone, strT0: 'int?', strT1: 'int');
    isSubtype(intQuestion, intQuestion, strT0: 'int?', strT1: 'int?');
    isSubtype(intQuestion, intStar, strT0: 'int?', strT1: 'int*');

    isSubtype(intStar, intNone, strT0: 'int*', strT1: 'int');
    isSubtype(intStar, intQuestion, strT0: 'int*', strT1: 'int?');
    isSubtype(intStar, intStar, strT0: 'int*', strT1: 'int*');
  }

  test_nullabilitySuffix_05() {
    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      objectNone,
      strT0: 'void Function(int)',
      strT1: 'Object',
    );
  }

  test_nullabilitySuffix_11() {
    isSubtype(
      intQuestion,
      intQuestion,
      strT0: 'int?',
      strT1: 'int?',
    );
  }

  test_nullabilitySuffix_12() {
    isSubtype(
      intStar,
      intStar,
      strT0: 'int*',
      strT1: 'int*',
    );
  }

  test_nullabilitySuffix_13() {
    var f = functionTypeQuestion(
      parameters: [
        requiredParameter(type: intNone),
      ],
      returnType: intNone,
    );
    isSubtype(
      f,
      f,
      strT0: 'int Function(int)?',
      strT1: 'int Function(int)?',
    );
  }

  test_nullabilitySuffix_14() {
    var f = functionTypeStar(
      parameters: [
        requiredParameter(type: intNone),
      ],
      returnType: intNone,
    );
    isSubtype(
      f,
      f,
      strT0: 'int Function(int)*',
      strT1: 'int Function(int)*',
    );
  }

  test_nullabilitySuffix_15() {
    var f = functionTypeNone(
      parameters: [
        requiredParameter(type: intNone),
        requiredParameter(type: intStar),
        requiredParameter(type: intQuestion),
      ],
      returnType: intQuestion,
    );
    isSubtype(
      f,
      f,
      strT0: 'int? Function(int, int*, int?)',
      strT1: 'int? Function(int, int*, int?)',
    );
  }

  test_nullabilitySuffix_16() {
    var type = listQuestion(intNone);
    isSubtype(
      type,
      type,
      strT0: 'List<int>?',
      strT1: 'List<int>?',
    );
  }

  test_nullabilitySuffix_17() {
    var type = listQuestion(intQuestion);
    isSubtype(
      type,
      type,
      strT0: 'List<int?>?',
      strT1: 'List<int?>?',
    );
  }

  test_nullabilitySuffix_18() {
    var T = typeParameter('T', bound: objectStar);
    var type = typeParameterTypeNone(
      promoteTypeParameter(T, intQuestion),
    );
    isSubtype(
      type,
      type,
      strT0: 'T, T & int?',
      strT1: 'T, T & int?',
    );
  }

  test_nullabilitySuffix_19() {
    var T = typeParameter('T', bound: objectNone);
    var type = typeParameterTypeQuestion(
      promoteTypeParameter(T, intQuestion),
    );
    isSubtype(
      type,
      type,
      strT0: 'T?, T & int?',
      strT1: 'T?, T & int?',
    );
  }

  test_special_01() {
    isNotSubtype(
      dynamicNone,
      intStar,
      strT0: 'dynamic',
      strT1: 'int*',
    );
  }

  test_special_02() {
    isNotSubtype(
      voidNone,
      intStar,
      strT0: 'void',
      strT1: 'int*',
    );
  }

  test_special_03() {
    isNotSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      intStar,
      strT0: 'int* Function()*',
      strT1: 'int*',
    );
  }

  test_special_04() {
    isNotSubtype(
      intStar,
      functionTypeStar(
        returnType: intStar,
      ),
      strT0: 'int*',
      strT1: 'int* Function()*',
    );
  }

  test_special_05() {
    isSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      functionStar,
      strT0: 'int* Function()*',
      strT1: 'Function*',
    );
  }

  test_special_06() {
    isSubtype(
      functionTypeStar(
        returnType: intStar,
      ),
      objectStar,
      strT0: 'int* Function()*',
      strT1: 'Object*',
    );
  }

  test_special_07() {
    isSubtype(
      objectStar,
      objectStar,
      strT0: 'Object*',
      strT1: 'Object*',
    );
  }

  test_special_08() {
    isSubtype(
      objectStar,
      dynamicNone,
      strT0: 'Object*',
      strT1: 'dynamic',
    );
  }

  test_special_09() {
    isSubtype(
      objectStar,
      voidNone,
      strT0: 'Object*',
      strT1: 'void',
    );
  }

  test_special_10() {
    isSubtype(
      dynamicNone,
      objectStar,
      strT0: 'dynamic',
      strT1: 'Object*',
    );
  }

  test_special_11() {
    isSubtype(
      dynamicNone,
      dynamicNone,
      strT0: 'dynamic',
      strT1: 'dynamic',
    );
  }

  test_special_12() {
    isSubtype(
      dynamicNone,
      voidNone,
      strT0: 'dynamic',
      strT1: 'void',
    );
  }

  test_special_13() {
    isSubtype(
      voidNone,
      objectStar,
      strT0: 'void',
      strT1: 'Object*',
    );
  }

  test_special_14() {
    isSubtype(
      voidNone,
      dynamicNone,
      strT0: 'void',
      strT1: 'dynamic',
    );
  }

  test_special_15() {
    isSubtype(
      voidNone,
      voidNone,
      strT0: 'void',
      strT1: 'void',
    );
  }

  test_top_01() {
    var S = typeParameter('S', bound: objectStar);
    var T = typeParameter('T', bound: voidNone);
    var U = typeParameter('U', bound: dynamicNone);
    var V = typeParameter('V', bound: objectStar);

    isSubtype(
      functionTypeStar(
        typeFormals: [S, T],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(S)),
          requiredParameter(type: typeParameterTypeNone(T)),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        typeFormals: [U, V],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(U)),
          requiredParameter(type: typeParameterTypeNone(V)),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function<S extends Object*,T extends void>(S, T)*',
      strT1: 'void Function<U extends dynamic,V extends Object*>(U, V)*',
    );
  }

  test_top_02() {
    var T0 = typeParameter('T0', bound: dynamicNone);
    var T1 = typeParameter('T1', bound: objectStar);

    var f = functionTypeStar(
      typeFormals: [T0],
      returnType: typeParameterTypeNone(T0),
    );

    var g = functionTypeStar(
      typeFormals: [T1],
      returnType: typeParameterTypeStar(T1),
    );

    isSubtype(
      f,
      g,
      strT0: 'T0 Function<T0 extends dynamic>()*',
      strT1: 'T1* Function<T1 extends Object*>()*',
    );

    isSubtype(
      g,
      f,
      strT0: 'T1* Function<T1 extends Object*>()*',
      strT1: 'T0 Function<T0 extends dynamic>()*',
    );
  }

  test_top_03() {
    var T0 = typeParameter('T0', bound: dynamicNone);
    var T1 = typeParameter('T1', bound: objectStar);
    var T2 = typeParameter('T2', bound: voidNone);

    var h = functionTypeStar(
      typeFormals: [T0],
      returnType: typeParameterTypeStar(T0),
    );

    var i = functionTypeStar(
      typeFormals: [T1],
      returnType: typeParameterTypeStar(T1),
    );

    var j = functionTypeStar(
      typeFormals: [T2],
      returnType: typeParameterTypeStar(T2),
    );

    isSubtype(h, i);
    isSubtype(h, j);
    isSubtype(i, h);
    isSubtype(i, j);
    isSubtype(j, h);
    isSubtype(h, i);
  }

  test_top_04() {
    isNotSubtype(
      dynamicNone,
      functionTypeStar(
        returnType: dynamicNone,
      ),
      strT0: 'dynamic',
      strT1: 'dynamic Function()*',
    );
  }

  test_top_05() {
    isNotSubtype(
      futureOrStar(
        functionTypeStar(
          returnType: voidNone,
        ),
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'FutureOr<void Function()*>*',
      strT1: 'void Function()*',
    );
  }

  test_top_06() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(
          T,
          functionTypeStar(
            returnType: voidNone,
          ),
        ),
      ),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'T, T & void Function()*',
      strT1: 'void Function()*',
    );
  }

  test_top_07() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(
          T,
          functionTypeStar(
            returnType: voidNone,
          ),
        ),
      ),
      functionTypeStar(
        returnType: dynamicNone,
      ),
      strT0: 'T, T & void Function()*',
      strT1: 'dynamic Function()*',
    );
  }

  test_top_08() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(
          T,
          functionTypeStar(
            returnType: voidNone,
          ),
        ),
      ),
      functionTypeStar(
        returnType: objectStar,
      ),
      strT0: 'T, T & void Function()*',
      strT1: 'Object* Function()*',
    );
  }

  test_top_09() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(
          T,
          functionTypeStar(
            parameters: [
              requiredParameter(type: voidNone),
            ],
            returnType: voidNone,
          ),
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: voidNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'T, T & void Function(void)*',
      strT1: 'void Function(void)*',
    );
  }

  test_top_10() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(
          T,
          functionTypeStar(
            parameters: [
              requiredParameter(type: voidNone),
            ],
            returnType: voidNone,
          ),
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: dynamicNone),
        ],
        returnType: dynamicNone,
      ),
      strT0: 'T, T & void Function(void)*',
      strT1: 'dynamic Function(dynamic)*',
    );
  }

  test_top_11() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(
          T,
          functionTypeStar(
            parameters: [
              requiredParameter(type: voidNone),
            ],
            returnType: voidNone,
          ),
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: objectStar),
        ],
        returnType: objectStar,
      ),
      strT0: 'T, T & void Function(void)*',
      strT1: 'Object* Function(Object*)*',
    );
  }

  test_top_12() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(
          T,
          functionTypeStar(
            parameters: [
              requiredParameter(type: voidNone),
            ],
            returnType: voidNone,
          ),
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: iterableStar(intStar)),
        ],
        returnType: dynamicNone,
      ),
      strT0: 'T, T & void Function(void)*',
      strT1: 'dynamic Function(Iterable<int*>*)*',
    );
  }

  test_top_13() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(
          T,
          functionTypeStar(
            parameters: [
              requiredParameter(type: voidNone),
            ],
            returnType: voidNone,
          ),
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: objectStar,
      ),
      strT0: 'T, T & void Function(void)*',
      strT1: 'Object* Function(int*)*',
    );
  }

  test_top_14() {
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(
          T,
          functionTypeStar(
            parameters: [
              requiredParameter(type: voidNone),
            ],
            returnType: voidNone,
          ),
        ),
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: intStar,
      ),
      strT0: 'T, T & void Function(void)*',
      strT1: 'int* Function(int*)*',
    );
  }

  test_top_15() {
    var T = typeParameter(
      'T',
      bound: functionTypeStar(
        returnType: voidNone,
      ),
    );

    isSubtype(
      typeParameterTypeStar(T),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'T*',
      strT1: 'void Function()*',
    );
  }

  test_top_16() {
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(T),
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'T',
      strT1: 'void Function()*',
    );
  }

  test_top_17() {
    isNotSubtype(
      voidNone,
      functionTypeStar(
        returnType: voidNone,
      ),
      strT0: 'void',
      strT1: 'void Function()*',
    );
  }

  test_top_18() {
    var T = typeParameter('T');

    isNotSubtype(
      dynamicNone,
      typeParameterTypeNone(T),
      strT0: 'dynamic',
      strT1: 'T',
    );
  }

  test_top_19() {
    var T = typeParameter('T');

    isNotSubtype(
      iterableStar(
        typeParameterTypeNone(T),
      ),
      typeParameterTypeNone(T),
      strT0: 'Iterable<T>*',
      strT1: 'T',
    );
  }

  test_top_21() {
    var T = typeParameter('T');

    isNotSubtype(
      functionTypeStar(
        returnType: voidNone,
      ),
      typeParameterTypeNone(T),
      strT0: 'void Function()*',
      strT1: 'T',
    );
  }

  test_top_22() {
    var T = typeParameter('T');

    isNotSubtype(
      futureOrStar(
        typeParameterTypeNone(T),
      ),
      typeParameterTypeNone(T),
      strT0: 'FutureOr<T>*',
      strT1: 'T',
    );
  }

  test_top_23() {
    var T = typeParameter('T');

    isNotSubtype(
      voidNone,
      typeParameterTypeNone(T),
      strT0: 'void',
      strT1: 'T',
    );
  }

  test_top_24() {
    var T = typeParameter('T');

    isNotSubtype(
      voidNone,
      typeParameterTypeNone(
        promoteTypeParameter(T, voidNone),
      ),
      strT0: 'void',
      strT1: 'T, T & void',
    );
  }

  test_top_25() {
    var T = typeParameter('T', bound: voidNone);

    isNotSubtype(
      voidNone,
      typeParameterTypeNone(
        promoteTypeParameter(T, voidNone),
      ),
      strT0: 'void',
      strT1: 'T, T & void',
    );
  }

  test_typeParameter_01() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(T, intStar),
      ),
      typeParameterTypeNone(
        promoteTypeParameter(T, intStar),
      ),
      strT0: 'T, T & int*',
      strT1: 'T, T & int*',
    );
  }

  test_typeParameter_02() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(T, intStar),
      ),
      typeParameterTypeNone(
        promoteTypeParameter(T, numStar),
      ),
      strT0: 'T, T & int*',
      strT1: 'T, T & num*',
    );
  }

  test_typeParameter_03() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(T, numStar),
      ),
      typeParameterTypeNone(
        promoteTypeParameter(T, numStar),
      ),
      strT0: 'T, T & num*',
      strT1: 'T, T & num*',
    );
  }

  test_typeParameter_04() {
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(T, numStar),
      ),
      typeParameterTypeNone(
        promoteTypeParameter(T, intStar),
      ),
      strT0: 'T, T & num*',
      strT1: 'T, T & int*',
    );
  }

  test_typeParameter_05() {
    var T = typeParameter('T');

    isNotSubtype(
      nullQuestion,
      typeParameterTypeNone(
        promoteTypeParameter(T, numStar),
      ),
      strT0: 'Null?',
      strT1: 'T, T & num*',
    );
  }

  test_typeParameter_06() {
    var T = typeParameter('T', bound: intStar);

    isSubtype(
      typeParameterTypeStar(
        promoteTypeParameter(T, intStar),
      ),
      typeParameterTypeStar(T),
      strT0: 'T*, T & int*',
      strT1: 'T*',
    );
  }

  test_typeParameter_07() {
    var T = typeParameter('T', bound: numStar);

    isSubtype(
      typeParameterTypeStar(
        promoteTypeParameter(T, intStar),
      ),
      typeParameterTypeStar(T),
      strT0: 'T*, T & int*',
      strT1: 'T*',
    );
  }

  test_typeParameter_08() {
    var T = typeParameter('T', bound: numStar);

    isSubtype(
      typeParameterTypeStar(
        promoteTypeParameter(T, numStar),
      ),
      typeParameterTypeStar(T),
      strT0: 'T*, T & num*',
      strT1: 'T*',
    );
  }

  test_typeParameter_09() {
    var T = typeParameter('T', bound: intStar);

    isSubtype(
      typeParameterTypeStar(T),
      typeParameterTypeStar(
        promoteTypeParameter(T, intStar),
      ),
      strT0: 'T*',
      strT1: 'T*, T & int*',
    );
  }

  test_typeParameter_10() {
    var T = typeParameter('T', bound: intStar);

    isSubtype(
      typeParameterTypeStar(T),
      typeParameterTypeStar(
        promoteTypeParameter(T, numStar),
      ),
      strT0: 'T*',
      strT1: 'T*, T & num*',
    );
  }

  test_typeParameter_11() {
    var T = typeParameter('T', bound: numStar);

    isNotSubtype(
      typeParameterTypeStar(T),
      typeParameterTypeStar(
        promoteTypeParameter(T, intStar),
      ),
      strT0: 'T*',
      strT1: 'T*, T & int*',
    );
  }

  test_typeParameter_12() {
    var T = typeParameter('T', bound: numStar);

    isSubtype(
      typeParameterTypeStar(T),
      typeParameterTypeStar(T),
      strT0: 'T*',
      strT1: 'T*',
    );
  }

  test_typeParameter_13() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
      strT0: 'T',
      strT1: 'T',
    );
  }

  test_typeParameter_14() {
    var S = typeParameter('S');
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S',
      strT1: 'T',
    );
  }

  test_typeParameter_15() {
    var T = typeParameter('T', bound: objectStar);

    isSubtype(
      typeParameterTypeStar(T),
      typeParameterTypeStar(T),
      strT0: 'T*',
      strT1: 'T*',
    );
  }

  test_typeParameter_16() {
    var S = typeParameter('S', bound: objectStar);
    var T = typeParameter('T', bound: objectStar);

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S',
      strT1: 'T',
    );
  }

  test_typeParameter_17() {
    var T = typeParameter('T', bound: dynamicNone);

    isSubtype(
      typeParameterTypeStar(T),
      typeParameterTypeStar(T),
      strT0: 'T*',
      strT1: 'T*',
    );
  }

  test_typeParameter_18() {
    var S = typeParameter('S', bound: dynamicNone);
    var T = typeParameter('T', bound: dynamicNone);

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S',
      strT1: 'T',
    );
  }

  test_typeParameter_19() {
    var S = typeParameter('S');
    var T = typeParameter('T', bound: typeParameterTypeNone(S));

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S',
      strT1: 'T',
    );

    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(S),
      strT0: 'T',
      strT1: 'S',
    );
  }

  test_typeParameter_20() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(T, intStar),
      ),
      intStar,
      strT0: 'T, T & int*',
      strT1: 'int*',
    );
  }

  test_typeParameter_21() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(T, intStar),
      ),
      numStar,
      strT0: 'T, T & int*',
      strT1: 'num*',
    );
  }

  test_typeParameter_22() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(T, numStar),
      ),
      numStar,
      strT0: 'T, T & num*',
      strT1: 'num*',
    );
  }

  test_typeParameter_23() {
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(T, numStar),
      ),
      intStar,
      strT0: 'T, T & num*',
      strT1: 'int*',
    );
  }

  test_typeParameter_24() {
    var S = typeParameter('S');
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(S, numStar),
      ),
      typeParameterTypeNone(T),
      strT0: 'S, S & num*',
      strT1: 'T',
    );
  }

  test_typeParameter_25() {
    var S = typeParameter('S');
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(
        promoteTypeParameter(S, numStar),
      ),
      typeParameterTypeNone(
        promoteTypeParameter(T, numStar),
      ),
      strT0: 'S, S & num*',
      strT1: 'T, T & num*',
    );
  }

  test_typeParameter_26() {
    var S = typeParameter('S', bound: intStar);

    isSubtype(
      typeParameterTypeStar(S),
      intStar,
      strT0: 'S*',
      strT1: 'int*',
    );
  }

  test_typeParameter_27() {
    var S = typeParameter('S', bound: intStar);

    isSubtype(
      typeParameterTypeStar(S),
      numStar,
      strT0: 'S*',
      strT1: 'num*',
    );
  }

  test_typeParameter_28() {
    var S = typeParameter('S', bound: numStar);

    isSubtype(
      typeParameterTypeStar(S),
      numStar,
      strT0: 'S*',
      strT1: 'num*',
    );
  }

  test_typeParameter_29() {
    var S = typeParameter('S', bound: numStar);

    isNotSubtype(
      typeParameterTypeStar(S),
      intStar,
      strT0: 'S*',
      strT1: 'int*',
    );
  }

  test_typeParameter_30() {
    var S = typeParameter('S', bound: numStar);
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeStar(S),
      typeParameterTypeNone(T),
      strT0: 'S*',
      strT1: 'T',
    );
  }

  test_typeParameter_31() {
    var S = typeParameter('S', bound: numStar);
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeStar(S),
      typeParameterTypeNone(
        promoteTypeParameter(T, numStar),
      ),
      strT0: 'S*',
      strT1: 'T, T & num*',
    );
  }

  test_typeParameter_32() {
    var T = typeParameter('T', bound: dynamicNone);

    isNotSubtype(
      dynamicNone,
      typeParameterTypeNone(
        promoteTypeParameter(T, dynamicNone),
      ),
      strT0: 'dynamic',
      strT1: 'T, T & dynamic',
    );
  }

  test_typeParameter_33() {
    var T = typeParameter('T');

    isNotSubtype(
      functionTypeStar(
        returnType: typeParameterTypeNone(T),
      ),
      typeParameterTypeNone(
        promoteTypeParameter(
          T,
          functionTypeStar(
            returnType: typeParameterTypeNone(T),
          ),
        ),
      ),
      strT0: 'T Function()*',
      strT1: 'T, T & T Function()*',
    );
  }

  test_typeParameter_34() {
    var T = typeParameter('T');

    isNotSubtype(
      futureOrStar(
        typeParameterTypeNone(
          promoteTypeParameter(T, stringStar),
        ),
      ),
      typeParameterTypeNone(
        promoteTypeParameter(T, stringStar),
      ),
      strT0: 'FutureOr<T>*, T & String*',
      strT1: 'T, T & String*',
    );
  }

  test_typeParameter_35() {
    var T = typeParameter('T');

    isSubtype(
      nullStar,
      typeParameterTypeStar(T),
      strT0: 'Null*',
      strT1: 'T*',
    );
  }

  TypeParameterTypeImpl typeParameterTypeNone(TypeParameterElement element) {
    return element.instantiate(nullabilitySuffix: NullabilitySuffix.none);
  }

  TypeParameterTypeImpl typeParameterTypeQuestion(
      TypeParameterElement element) {
    return element.instantiate(nullabilitySuffix: NullabilitySuffix.question);
  }

  TypeParameterTypeImpl typeParameterTypeStar(TypeParameterElement element) {
    return element.instantiate(nullabilitySuffix: NullabilitySuffix.star);
  }
}

@reflectiveTest
class SubtypingCompoundTest extends _SubtypingCompoundTestBase {
  test_bottom_isBottom() {
    var equivalents = <DartType>[bottomStar];

    var supertypes = <DartType>[
      dynamicNone,
      objectStar,
      intStar,
      doubleStar,
      numStar,
      stringStar,
      functionStar,
    ];

    _checkGroups(
      bottomStar,
      equivalents: equivalents,
      supertypes: supertypes,
    );
  }

  test_double() {
    var equivalents = <DartType>[doubleStar];
    var supertypes = <DartType>[numStar];
    var unrelated = <DartType>[intStar];
    _checkGroups(
      doubleStar,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
    );
  }

  test_dynamic_isTop() {
    var equivalents = <DartType>[
      dynamicNone,
      objectStar,
      voidNone,
    ];

    var subtypes = <DartType>[
      intStar,
      doubleStar,
      numStar,
      stringStar,
      functionStar,
      bottomStar,
    ];

    _checkGroups(
      dynamicType,
      equivalents: equivalents,
      subtypes: subtypes,
    );
  }

  test_int() {
    var equivalents = <DartType>[intStar];
    var supertypes = <DartType>[numStar];
    var unrelated = <DartType>[doubleStar];
    _checkGroups(
      intStar,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
    );
  }

  test_num() {
    var equivalents = <DartType>[numStar];
    var supertypes = <DartType>[objectStar];
    var unrelated = <DartType>[stringStar];
    var subtypes = <DartType>[intStar, doubleStar];
    _checkGroups(
      numStar,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_void_isTop() {
    var equivalents = <DartType>[
      dynamicNone,
      objectStar,
      voidNone,
    ];

    var subtypes = <DartType>[
      intStar,
      doubleStar,
      numStar,
      stringStar,
      functionStar,
      bottomStar,
    ];

    _checkGroups(
      voidNone,
      equivalents: equivalents,
      subtypes: subtypes,
    );
  }
}

class _SubtypingCompoundTestBase extends _SubtypingTestBase {
  void _checkEquivalent(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsSubtypeOf(type2, type1);
  }

  void _checkGroups(DartType t1,
      {List<DartType> equivalents,
      List<DartType> unrelated,
      List<DartType> subtypes,
      List<DartType> supertypes}) {
    if (equivalents != null) {
      for (DartType t2 in equivalents) {
        _checkEquivalent(t1, t2);
      }
    }
    if (unrelated != null) {
      for (DartType t2 in unrelated) {
        _checkUnrelated(t1, t2);
      }
    }
    if (subtypes != null) {
      for (DartType t2 in subtypes) {
        _checkIsStrictSubtypeOf(t2, t1);
      }
    }
    if (supertypes != null) {
      for (DartType t2 in supertypes) {
        _checkIsStrictSubtypeOf(t1, t2);
      }
    }
  }

  void _checkIsNotSubtypeOf(DartType type1, DartType type2) {
    var strType1 = _typeStr(type1);
    var strType2 = _typeStr(type2);
    expect(typeSystem.isSubtypeOf(type1, type2), false,
        reason: '$strType1 was not supposed to be a subtype of $strType2');
  }

  void _checkIsStrictSubtypeOf(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  void _checkIsSubtypeOf(DartType type1, DartType type2) {
    var strType1 = _typeStr(type1);
    var strType2 = _typeStr(type2);
    expect(typeSystem.isSubtypeOf(type1, type2), true,
        reason: '$strType1 is not a subtype of $strType2');
  }

  void _checkUnrelated(DartType type1, DartType type2) {
    _checkIsNotSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  static String _typeStr(DartType type) {
    return (type as TypeImpl).toString(withNullability: true);
  }
}

@reflectiveTest
class _SubtypingTestBase with ElementsTypesMixin {
  TypeProvider typeProvider;

  Dart2TypeSystem typeSystem;

  ClassElement _comparableElement;

  BottomTypeImpl get bottomNone => BottomTypeImpl.instance;

  BottomTypeImpl get bottomQuestion => BottomTypeImpl.instanceNullable;

  BottomTypeImpl get bottomStar => BottomTypeImpl.instanceLegacy;

  ClassElement get comparableElement {
    return _comparableElement ??=
        typeProvider.intType.element.library.getType('Comparable');
  }

  InterfaceType get doubleNone {
    var element = typeProvider.doubleType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get doubleQuestion {
    var element = typeProvider.doubleType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get doubleStar {
    var element = typeProvider.doubleType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  DartType get dynamicNone => typeProvider.dynamicType;

  InterfaceType get functionStar {
    var element = typeProvider.functionType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType get intNone {
    var element = typeProvider.intType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get intQuestion {
    var element = typeProvider.intType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get intStar {
    var element = typeProvider.intType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  BottomTypeImpl get neverNone => BottomTypeImpl.instance;

  InterfaceType get nullNone {
    var element = typeProvider.nullType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get nullQuestion {
    var element = typeProvider.nullType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get nullStar {
    var element = typeProvider.nullType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType get numNone {
    var element = typeProvider.numType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get numQuestion {
    var element = typeProvider.numType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get numStar {
    var element = typeProvider.numType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType get objectNone {
    var element = typeProvider.objectType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get objectQuestion {
    var element = typeProvider.objectType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get objectStar {
    var element = typeProvider.objectType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType get stringStar {
    var element = typeProvider.stringType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting();
  }

  VoidType get voidNone => typeProvider.voidType;

  InterfaceTypeImpl futureNone(DartType type) {
    return typeProvider.futureElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl futureOrNone(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl futureOrQuestion(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl futureOrStar(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceTypeImpl futureStar(DartType type) {
    return typeProvider.futureElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  void setUp() {
    var analysisContext = TestAnalysisContext(
      featureSet: testFeatureSet,
    );
    typeProvider = analysisContext.typeProvider;
    typeSystem = analysisContext.typeSystem;
  }
}

class _TypeParameterCollector extends DartTypeVisitor<void> {
  final Set<TypeParameterElement> typeParameters = Set();

  @override
  void defaultDartType(DartType type) {
    throw UnimplementedError('(${type.runtimeType}) $type');
  }

  @override
  void visitBottomType(BottomTypeImpl type) {}

  @override
  void visitDynamicType(DynamicTypeImpl type) {}

  @override
  void visitFunctionType(FunctionType type) {
    for (var typeParameter in type.typeFormals) {
      var bound = typeParameter.bound;
      if (bound != null) {
        DartTypeVisitor.visit(bound, this);
      }
    }
    for (var parameter in type.parameters) {
      DartTypeVisitor.visit(parameter.type, this);
    }
    DartTypeVisitor.visit(type.returnType, this);
  }

  @override
  void visitInterfaceType(InterfaceType type) {
    for (var typeArgument in type.typeArguments) {
      DartTypeVisitor.visit(typeArgument, this);
    }
  }

  @override
  void visitTypeParameterType(TypeParameterType type) {
    typeParameters.add(type.element);
  }

  @override
  void visitVoidType(VoidType type) {}
}
