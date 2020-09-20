// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RuntimeTypeEqualityTypeTest);
  });
}

@reflectiveTest
class RuntimeTypeEqualityTypeTest with ElementsTypesMixin {
  @override
  TypeProvider typeProvider;

  TypeSystemImpl typeSystem;

  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting(
      additionalFeatures: [Feature.non_nullable],
    );
  }

  void setUp() {
    var analysisContext = TestAnalysisContext(
      featureSet: testFeatureSet,
    );
    typeProvider = analysisContext.typeProviderNonNullableByDefault;
    typeSystem = analysisContext.typeSystemNonNullableByDefault;
  }

  test_dynamic() {
    _equal(dynamicNone, dynamicNone);
    _notEqual(dynamicNone, voidNone);
    _notEqual(dynamicNone, intNone);

    _notEqual(dynamicNone, neverNone);
    _notEqual(dynamicNone, neverQuestion);
    _notEqual(dynamicNone, neverStar);
  }

  test_functionType_parameters() {
    void check(
      ParameterElement T1_parameter,
      ParameterElement T2_parameter,
      bool expected,
    ) {
      var T1 = functionTypeNone(
        returnType: voidNone,
        parameters: [T1_parameter],
      );
      var T2 = functionTypeNone(
        returnType: voidNone,
        parameters: [T2_parameter],
      );
      _check(T1, T2, expected);
    }

    {
      void checkRequiredParameter(
        DartType T1_type,
        DartType T2_type,
        bool expected,
      ) {
        check(
          requiredParameter(type: T1_type),
          requiredParameter(type: T2_type),
          expected,
        );
      }

      checkRequiredParameter(intNone, intNone, true);
      checkRequiredParameter(intNone, intQuestion, false);
      checkRequiredParameter(intNone, intStar, true);

      checkRequiredParameter(intQuestion, intNone, false);
      checkRequiredParameter(intQuestion, intQuestion, true);
      checkRequiredParameter(intQuestion, intStar, false);

      checkRequiredParameter(intStar, intNone, true);
      checkRequiredParameter(intStar, intQuestion, false);
      checkRequiredParameter(intStar, intStar, true);

      check(
        requiredParameter(type: intNone, name: 'a'),
        requiredParameter(type: intNone, name: 'b'),
        true,
      );

      check(
        requiredParameter(type: intNone),
        positionalParameter(type: intNone),
        false,
      );

      check(
        requiredParameter(type: intNone),
        namedParameter(type: intNone, name: 'a'),
        false,
      );

      check(
        requiredParameter(type: intNone),
        namedRequiredParameter(type: intNone, name: 'a'),
        false,
      );
    }

    {
      check(
        namedParameter(type: intNone, name: 'a'),
        namedParameter(type: intNone, name: 'a'),
        true,
      );

      check(
        namedParameter(type: intNone, name: 'a'),
        namedParameter(type: boolNone, name: 'a'),
        false,
      );

      check(
        namedParameter(type: intNone, name: 'a'),
        namedParameter(type: intNone, name: 'b'),
        false,
      );

      check(
        namedParameter(type: intNone, name: 'a'),
        namedRequiredParameter(type: intNone, name: 'a'),
        false,
      );
    }

    {
      check(
        namedRequiredParameter(type: intNone, name: 'a'),
        namedRequiredParameter(type: intNone, name: 'a'),
        true,
      );

      check(
        namedRequiredParameter(type: intNone, name: 'a'),
        namedRequiredParameter(type: boolNone, name: 'a'),
        false,
      );

      check(
        namedRequiredParameter(type: intNone, name: 'a'),
        namedRequiredParameter(type: intNone, name: 'b'),
        false,
      );

      check(
        namedRequiredParameter(type: intNone, name: 'a'),
        namedParameter(type: intNone, name: 'a'),
        false,
      );
    }
  }

  test_functionType_returnType() {
    void check(
      DartType T1_returnType,
      DartType T2_returnType,
      bool expected,
    ) {
      var T1 = functionTypeNone(
        returnType: T1_returnType,
      );
      var T2 = functionTypeNone(
        returnType: T2_returnType,
      );
      _check(T1, T2, expected);
    }

    check(intNone, intNone, true);
    check(intNone, intQuestion, false);
    check(intNone, intStar, true);
  }

  test_functionType_typeParameters() {
    {
      var T1_T = typeParameter('T', bound: numNone);
      _check(
        functionTypeNone(
          typeFormals: [T1_T],
          returnType: voidNone,
        ),
        functionTypeNone(
          returnType: voidNone,
        ),
        false,
      );
    }

    {
      var T1_T = typeParameter('T', bound: numNone);
      var T2_U = typeParameter('U');
      _check(
        functionTypeNone(
          typeFormals: [T1_T],
          returnType: voidNone,
        ),
        functionTypeNone(
          typeFormals: [T2_U],
          returnType: voidNone,
        ),
        false,
      );
    }

    {
      var T1_T = typeParameter('T');
      var T2_U = typeParameter('U');
      _check(
        functionTypeNone(
          typeFormals: [T1_T],
          returnType: typeParameterTypeNone(T1_T),
          parameters: [
            requiredParameter(
              type: typeParameterTypeNone(T1_T),
            )
          ],
        ),
        functionTypeNone(
          typeFormals: [T2_U],
          returnType: typeParameterTypeNone(T2_U),
          parameters: [
            requiredParameter(
              type: typeParameterTypeNone(T2_U),
            )
          ],
        ),
        true,
      );
    }
  }

  test_interfaceType() {
    _notEqual(intNone, boolNone);

    _equal(intNone, intNone);
    _notEqual(intNone, intQuestion);
    _equal(intNone, intStar);

    _notEqual(intQuestion, intNone);
    _equal(intQuestion, intQuestion);
    _notEqual(intQuestion, intStar);

    _equal(intStar, intNone);
    _notEqual(intStar, intQuestion);
    _equal(intStar, intStar);
  }

  test_interfaceType_typeArguments() {
    void _equal(DartType T1, DartType T2) {
      this._equal(listNone(T1), listNone(T2));
    }

    void _notEqual(DartType T1, DartType T2) {
      this._notEqual(listNone(T1), listNone(T2));
    }

    _notEqual(intNone, boolNone);

    _equal(intNone, intNone);
    _notEqual(intNone, intQuestion);
    _equal(intNone, intStar);

    _notEqual(intQuestion, intNone);
    _equal(intQuestion, intQuestion);
    _notEqual(intQuestion, intStar);

    _equal(intStar, intNone);
    _notEqual(intStar, intQuestion);
    _equal(intStar, intStar);
  }

  test_never() {
    _equal(neverNone, neverNone);
    _notEqual(neverNone, neverQuestion);
    _equal(neverNone, neverStar);
    _notEqual(neverNone, intNone);

    _notEqual(neverQuestion, neverNone);
    _equal(neverQuestion, neverQuestion);
    _notEqual(neverQuestion, neverStar);
    _notEqual(neverQuestion, intNone);
    _equal(neverQuestion, nullNone);

    _equal(neverStar, neverNone);
    _notEqual(neverStar, neverQuestion);
    _equal(neverStar, neverStar);
    _notEqual(neverStar, intNone);
  }

  test_norm() {
    _equal(futureOrNone(objectNone), objectNone);
    _equal(futureOrNone(neverNone), futureNone(neverNone));
    _equal(neverQuestion, nullNone);
  }

  test_void() {
    _equal(voidNone, voidNone);
    _notEqual(voidNone, dynamicNone);
    _notEqual(voidNone, intNone);

    _notEqual(voidNone, neverNone);
    _notEqual(voidNone, neverQuestion);
    _notEqual(voidNone, neverStar);
  }

  void _check(DartType T1, DartType T2, bool expected) {
    bool result;

    result = typeSystem.runtimeTypesEqual(T1, T2);
    if (result != expected) {
      fail('''
Expected ${expected ? 'equal' : 'not equal'}.
T1: ${_typeString(T1)}
T2: ${_typeString(T2)}
''');
    }

    result = typeSystem.runtimeTypesEqual(T2, T1);
    if (result != expected) {
      fail('''
Expected ${expected ? 'equal' : 'not equal'}.
T1: ${_typeString(T1)}
T2: ${_typeString(T2)}
''');
    }
  }

  void _equal(DartType T1, DartType T2) {
    _check(T1, T2, true);
  }

  void _notEqual(DartType T1, DartType T2) {
    _check(T1, T2, false);
  }

  String _typeString(TypeImpl type) {
    if (type == null) return null;
    return type.getDisplayString(withNullability: true);
  }
}
