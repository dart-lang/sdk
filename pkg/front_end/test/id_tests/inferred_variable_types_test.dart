// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:front_end/src/fasta/source/source_member_builder.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart' hide Variance;

Future<void> main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(
      Platform.script.resolve('../../../_fe_analyzer_shared/test/'
          'inference/inferred_variable_types/data'));
  await runTests<DartType>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const InferredVariableTypesDataComputer(),
          [cfeNonNullableOnlyConfig]));
}

class InferredVariableTypesDataComputer extends DataComputer<DartType> {
  const InferredVariableTypesDataComputer();

  @override
  DataInterpreter<DartType> get dataValidator =>
      const _InferredVariableTypesDataInterpreter();

  @override
  bool get supportsErrors => true;

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(TestResultData testResultData, Member member,
      Map<Id, ActualData<DartType>> actualMap,
      {bool? verbose}) {
    SourceMemberBuilder memberBuilder =
        lookupMemberBuilder(testResultData.compilerResult, member)
            as SourceMemberBuilder;
    member.accept(new InferredTypeArgumentDataExtractor(
        testResultData.compilerResult,
        memberBuilder.dataForTesting!.inferenceData.typeInferenceResult,
        actualMap));
  }
}

class InferredTypeArgumentDataExtractor extends CfeDataExtractor<DartType> {
  final TypeInferenceResultForTesting typeInferenceResult;

  InferredTypeArgumentDataExtractor(InternalCompilerResult compilerResult,
      this.typeInferenceResult, Map<Id, ActualData<DartType>> actualMap)
      : super(compilerResult, actualMap);

  @override
  DartType? computeNodeValue(Id id, TreeNode node) {
    if (node is VariableDeclaration || node is LocalFunction) {
      return typeInferenceResult.inferredVariableTypes[node];
    }
    return null;
  }
}

class _InferredVariableTypesDataInterpreter
    implements DataInterpreter<DartType> {
  const _InferredVariableTypesDataInterpreter();

  @override
  String getText(DartType actualData, [String? indentation]) {
    return typeToText(
        actualData, TypeRepresentation.analyzerNonNullableByDefault);
  }

  @override
  String? isAsExpected(DartType actualData, String? expectedData) {
    if (getText(actualData) == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualData';
    }
  }

  @override
  bool isEmpty(DartType? actualData) => actualData == null;
}
