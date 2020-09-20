// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlattenTypeTest);
  });
}

@reflectiveTest
class FlattenTypeTest with ElementsTypesMixin {
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
    _check(dynamicNone, 'dynamic');
  }

  test_interfaceType_none() {
    _check(futureNone(intNone), 'int');
    _check(futureNone(intQuestion), 'int?');
    _check(futureNone(intStar), 'int*');

    // otherwise if T is FutureOr<S> then flatten(T) = S
    _check(futureOrNone(intNone), 'int');
    _check(futureOrNone(intQuestion), 'int?');
    _check(futureOrNone(intStar), 'int*');
  }

  test_interfaceType_question() {
    _check(futureQuestion(intNone), 'int?');
    _check(futureQuestion(intQuestion), 'int?');
    _check(futureQuestion(intStar), 'int?');

    _check(futureQuestion(listNone(intNone)), 'List<int>?');
    _check(futureQuestion(listQuestion(intNone)), 'List<int>?');
    _check(futureQuestion(listStar(intNone)), 'List<int>?');

    _check(futureOrQuestion(intNone), 'int?');
    _check(futureOrQuestion(intQuestion), 'int?');
    _check(futureOrQuestion(intStar), 'int?');
  }

  test_interfaceType_star() {
    _check(futureStar(intNone), 'int*');
    _check(futureStar(intQuestion), 'int*');
    _check(futureStar(intStar), 'int*');

    _check(futureStar(listNone(intNone)), 'List<int>*');
    _check(futureStar(listQuestion(intNone)), 'List<int>*');
    _check(futureStar(listStar(intNone)), 'List<int>*');

    _check(futureOrStar(intNone), 'int*');
    _check(futureOrStar(intQuestion), 'int*');
    _check(futureOrStar(intStar), 'int*');
  }

  test_unknownInferredType() {
    var type = UnknownInferredType.instance;
    expect(typeSystem.flatten(type), same(type));
  }

  void _check(DartType T, String expected) {
    var result = typeSystem.flatten(T);
    expect(
      result.getDisplayString(withNullability: true),
      expected,
    );
  }
}
