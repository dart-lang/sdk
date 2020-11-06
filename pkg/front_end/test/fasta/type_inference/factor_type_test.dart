// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/factory_type_test_helper.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/fasta/type_inference/factor_type.dart';
import 'package:front_end/src/kernel_generator_impl.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

import 'package:front_end/src/testing/compiler_common.dart';

class FactorTypeTest extends FactorTypeTestMixin<DartType> {
  final TypeEnvironment typeEnvironment;

  FactorTypeTest(this.typeEnvironment);

  CoreTypes get coreTypes => typeEnvironment.coreTypes;

  void run() {
    test_dynamic();
    test_futureOr();
    test_object();
    test_subtype();
    test_void();
  }

  @override
  void expect(
      DartType T, DartType S, String actualResult, String expectedResult) {
    Expect.equals(
        expectedResult, actualResult, "Unexpected result for factor($T, $S)");
  }

  @override
  DartType factor(DartType T, DartType S) {
    return factorType(typeEnvironment, T, S);
  }

  @override
  DartType futureNone(DartType type) =>
      new InterfaceType(coreTypes.futureClass, Nullability.nonNullable, [type]);

  @override
  DartType futureOrNone(DartType type) =>
      new FutureOrType(type, Nullability.nonNullable);

  @override
  DartType get dynamicType => const DynamicType();

  @override
  DartType get intNone => coreTypes.intNonNullableRawType;

  @override
  DartType get intQuestion => coreTypes.intNullableRawType;

  @override
  DartType get intStar => coreTypes.intLegacyRawType;

  @override
  DartType get nullNone => const NullType();

  @override
  DartType get numNone => coreTypes.numNonNullableRawType;

  @override
  DartType get numQuestion => coreTypes.numNullableRawType;

  @override
  DartType get numStar => coreTypes.numLegacyRawType;

  @override
  DartType get objectNone => coreTypes.objectNonNullableRawType;

  @override
  DartType get objectQuestion => coreTypes.objectNullableRawType;

  @override
  DartType get objectStar => coreTypes.objectLegacyRawType;

  @override
  DartType get stringNone => coreTypes.stringNonNullableRawType;

  @override
  DartType get stringQuestion => coreTypes.stringNullableRawType;

  @override
  DartType get stringStar => coreTypes.stringLegacyRawType;

  @override
  DartType get voidType => const VoidType();

  @override
  String typeString(DartType type) =>
      typeToText(type, TypeRepresentation.analyzerNonNullableByDefault);
}

main() async {
  CompilerOptions options = new CompilerOptions()
    ..explicitExperimentalFlags[ExperimentalFlag.nonNullable] = true;
  InternalCompilerResult result = await compileScript('',
      options: options, requireMain: false, retainDataForTesting: true);
  new FactorTypeTest(
          new TypeEnvironment(result.coreTypes, result.classHierarchy))
      .run();
}
