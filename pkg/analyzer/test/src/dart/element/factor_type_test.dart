// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeSystemImpl;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FactorTypeTest);
  });
}

@reflectiveTest
class FactorTypeTest with ElementsTypesMixin {
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

  void test_futureOr() {
    _check(futureOrNone(intNone), intNone, 'Future<int>');
    _check(futureOrNone(intNone), futureNone(intNone), 'int');

    _check(futureOrNone(intQuestion), intNone, 'FutureOr<int?>');
    _check(futureOrNone(intQuestion), futureNone(intNone), 'FutureOr<int?>');
    _check(futureOrNone(intQuestion), intQuestion, 'Future<int?>');
    _check(futureOrNone(intQuestion), futureNone(intQuestion), 'int?');
    _check(futureOrNone(intQuestion), intStar, 'Future<int?>');
    _check(futureOrNone(intQuestion), futureNone(intStar), 'int?');

    _check(futureOrNone(intNone), numNone, 'Future<int>');
    _check(futureOrNone(intNone), futureNone(numNone), 'int');
  }

  void test_object() {
    _check(objectNone, objectNone, 'Never');
    _check(objectNone, objectQuestion, 'Never');
    _check(objectNone, objectStar, 'Never');

    _check(objectNone, intNone, 'Object');
    _check(objectNone, intQuestion, 'Object');
    _check(objectNone, intStar, 'Object');

    _check(objectQuestion, objectNone, 'Never?');
    _check(objectQuestion, objectQuestion, 'Never');
    _check(objectQuestion, objectStar, 'Never');

    _check(objectQuestion, intNone, 'Object?');
    _check(objectQuestion, intQuestion, 'Object');
    _check(objectQuestion, intStar, 'Object');
  }

  test_subtype() {
    _check(intNone, intNone, 'Never');
    _check(intNone, intQuestion, 'Never');
    _check(intNone, intStar, 'Never');

    _check(intQuestion, intNone, 'Never?');
    _check(intQuestion, intQuestion, 'Never');
    _check(intQuestion, intStar, 'Never');

    _check(intStar, intNone, 'Never');
    _check(intStar, intQuestion, 'Never');
    _check(intStar, intStar, 'Never');

    _check(intNone, numNone, 'Never');
    _check(intNone, numQuestion, 'Never');
    _check(intNone, numStar, 'Never');

    _check(intQuestion, numNone, 'Never?');
    _check(intQuestion, numQuestion, 'Never');
    _check(intQuestion, numStar, 'Never');

    _check(intStar, numNone, 'Never');
    _check(intStar, numQuestion, 'Never');
    _check(intStar, numStar, 'Never');

    _check(intNone, nullNone, 'int');
    _check(intQuestion, nullNone, 'int');
    _check(intStar, nullNone, 'int');

    _check(intNone, stringNone, 'int');
    _check(intQuestion, stringNone, 'int?');
    _check(intStar, stringNone, 'int*');

    _check(intNone, stringQuestion, 'int');
    _check(intQuestion, stringQuestion, 'int');
    _check(intStar, stringQuestion, 'int');

    _check(intNone, stringStar, 'int');
    _check(intQuestion, stringStar, 'int');
    _check(intStar, stringStar, 'int');
  }

  void _check(DartType T, DartType S, String expectedStr) {
    var result = typeSystem.factor(T, S);
    var resultStr = _typeString(result);

    expect(resultStr, expectedStr);
  }

  String _typeString(TypeImpl type) {
    return type.getDisplayString(withNullability: true);
  }
}
