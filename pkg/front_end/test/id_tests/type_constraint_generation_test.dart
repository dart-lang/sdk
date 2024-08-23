// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:front_end/src/source/source_member_builder.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:front_end/src/type_inference/type_inference_engine.dart';
import 'package:front_end/src/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';

Future<void> main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(
      Platform.script.resolve('../../../_fe_analyzer_shared/test/'
          'inference/type_constraint_generation/data'));
  await runTests<List<GeneratedTypeConstraint>>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const InferredTypeArgumentDataComputer(), [defaultCfeConfig]));
}

class InferredTypeArgumentDataComputer
    extends CfeDataComputer<List<GeneratedTypeConstraint>> {
  const InferredTypeArgumentDataComputer();

  @override
  DataInterpreter<List<GeneratedTypeConstraint>> get dataValidator =>
      const _InferredTypeArgumentsDataInterpreter();

  @override
  bool get supportsErrors => true;

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(CfeTestResultData testResultData, Member member,
      Map<Id, ActualData<List<GeneratedTypeConstraint>>> actualMap,
      {bool? verbose}) {
    SourceMemberBuilder memberBuilder =
        lookupMemberBuilder(testResultData.compilerResult, member)
            as SourceMemberBuilder;
    member.accept(new TypeConstraintGenerationDataExtractor(
        testResultData.compilerResult,
        memberBuilder.dataForTesting!.inferenceData.typeInferenceResult,
        actualMap));
  }
}

class TypeConstraintGenerationDataExtractor
    extends CfeDataExtractor<List<GeneratedTypeConstraint>> {
  final TypeInferenceResultForTesting typeInferenceResult;

  TypeConstraintGenerationDataExtractor(
      InternalCompilerResult compilerResult,
      this.typeInferenceResult,
      Map<Id, ActualData<List<GeneratedTypeConstraint>>> actualMap)
      : super(compilerResult, actualMap);

  @override
  List<GeneratedTypeConstraint>? computeNodeValue(Id id, TreeNode node) {
    if (node is Arguments ||
        node is ListLiteral ||
        node is SetLiteral ||
        node is MapLiteral) {
      return typeInferenceResult.generatedTypeConstraints[node];
    }
    return null;
  }
}

class _InferredTypeArgumentsDataInterpreter
    implements DataInterpreter<List<GeneratedTypeConstraint>> {
  const _InferredTypeArgumentsDataInterpreter();

  @override
  String getText(List<GeneratedTypeConstraint> actualData,
      [String? indentation]) {
    StringBuffer sb = new StringBuffer();
    if (actualData.isNotEmpty) {
      for (int i = 0; i < actualData.length; i++) {
        if (i > 0) {
          sb.write(',');
        }
        if (actualData[i].isUpper) {
          sb.write("${actualData[i].typeParameter.name} <: ");
          sb.write(typeToText(actualData[i].constraint.unwrapTypeSchemaView(),
              TypeRepresentation.analyzerNonNullableByDefault));
        } else {
          sb.write("${actualData[i].typeParameter.name} :> ");
          sb.write(typeToText(actualData[i].constraint.unwrapTypeSchemaView(),
              TypeRepresentation.analyzerNonNullableByDefault));
        }
      }
    }
    return sb.toString();
  }

  @override
  String? isAsExpected(
      List<GeneratedTypeConstraint> actualData, String? expectedData) {
    if (getText(actualData) == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualData';
    }
  }

  @override
  bool isEmpty(List<GeneratedTypeConstraint>? actualData) =>
      actualData == null || actualData.isEmpty;
}
