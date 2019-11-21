// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullabilityEliminatorTest);
  });
}

@reflectiveTest
class NullabilityEliminatorTest with ElementsTypesMixin {
  @override
  TypeProvider typeProvider;

  void setUp() {
    var analysisContext = TestAnalysisContext(
      featureSet: FeatureSet.forTesting(
        sdkVersion: '2.6.0',
        additionalFeatures: [Feature.non_nullable],
      ),
    );
    typeProvider = analysisContext.typeProvider;
  }

  test_dynamicType() {
    _verifySame(typeProvider.dynamicType);
  }

  test_functionType() {
    _verify(
      functionTypeNone(returnType: voidNone),
      functionTypeStar(returnType: voidNone),
    );

    _verify(
      functionTypeQuestion(returnType: voidNone),
      functionTypeStar(returnType: voidNone),
    );

    _verifySame(
      functionTypeStar(returnType: voidNone),
    );
  }

  test_functionType_parameters() {
    _verify(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
    );

    _verify(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intQuestion),
        ],
        returnType: voidNone,
      ),
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
    );

    _verifySame(
      functionTypeStar(
        parameters: [
          requiredParameter(type: intStar),
        ],
        returnType: voidNone,
      ),
    );
  }

  test_functionType_returnType() {
    _verify(
      functionTypeStar(returnType: intNone),
      functionTypeStar(returnType: intStar),
    );

    _verify(
      functionTypeStar(returnType: intQuestion),
      functionTypeStar(returnType: intStar),
    );

    _verifySame(
      functionTypeStar(returnType: intStar),
    );
  }

  test_functionType_typeParameters() {
    var T = typeParameter('T');

    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeNone(T),
      ),
      'T Function<T>()',
      'T* Function<T>()*',
    );
    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeQuestion(T),
      ),
      'T? Function<T>()',
      'T* Function<T>()*',
    );
    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeStar(T),
      ),
      'T* Function<T>()',
      'T* Function<T>()*',
    );

    _verifySame(
      functionTypeStar(
        typeFormals: [T],
        returnType: typeParameterTypeStar(T),
      ),
    );
  }

  test_functionType_typeParameters_bound_none() {
    var T = typeParameter('T', bound: intNone);

    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeNone(T),
      ),
      'T Function<T extends int>()',
      'T* Function<T extends int*>()*',
    );
  }

  test_functionType_typeParameters_bound_question() {
    var T = typeParameter('T', bound: intQuestion);

    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeNone(T),
      ),
      'T Function<T extends int?>()',
      'T* Function<T extends int*>()*',
    );
  }

  test_functionType_typeParameters_bound_star() {
    var T = typeParameter('T', bound: intStar);

    _verifyStr(
      functionTypeNone(
        typeFormals: [T],
        returnType: typeParameterTypeNone(T),
      ),
      'T Function<T extends int*>()',
      'T* Function<T extends int*>()*',
    );

    _verifySame(
      functionTypeStar(
        typeFormals: [T],
        returnType: typeParameterTypeStar(T),
      ),
    );
  }

  test_interfaceType_int() {
    _verify(intNone, intStar);
    _verify(intQuestion, intStar);
    _verifySame(intStar);
  }

  test_interfaceType_list() {
    var expected = listStar(intStar);

    _verify(listNone(intNone), expected);
    _verify(listNone(intQuestion), expected);
    _verify(listNone(intStar), expected);

    _verify(listQuestion(intNone), expected);
    _verify(listQuestion(intQuestion), expected);
    _verify(listQuestion(intStar), expected);

    _verify(listStar(intNone), expected);
    _verify(listStar(intQuestion), expected);
    _verifySame(listStar(intStar));
  }

  test_neverType() {
    _verify(neverNone, neverStar);
    _verify(neverQuestion, neverStar);
    _verifySame(neverStar);
  }

  test_typeParameterType() {
    var T = typeParameter('T');
    _verify(
      typeParameterTypeNone(T),
      typeParameterTypeStar(T),
    );
    _verify(
      typeParameterTypeQuestion(T),
      typeParameterTypeStar(T),
    );
    _verifySame(
      typeParameterTypeStar(T),
    );
  }

  test_voidType() {
    _verifySame(typeProvider.voidType);
  }

  String _typeToString(TypeImpl type) {
    return type.toString(withNullability: true);
  }

  void _verify(DartType input, DartType expected) {
    var result = NullabilityEliminator.perform(input);
    expect(result, isNot(same(input)));
    expect(result, expected);
  }

  void _verifySame(DartType input) {
    var result = NullabilityEliminator.perform(input);
    expect(result, same(input));
  }

  void _verifyStr(DartType input, String inputStr, String expectedStr) {
    expect(_typeToString(input), inputStr);

    var result = NullabilityEliminator.perform(input);
    expect(result, isNot(same(input)));
    expect(_typeToString(result), expectedStr);
  }
}
