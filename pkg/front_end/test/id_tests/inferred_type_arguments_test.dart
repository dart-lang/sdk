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
          'inference/inferred_type_arguments/data'));
  await runTests<List<DartType>>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const InferredTypeArgumentDataComputer(),
          [cfeNonNullableOnlyConfig]));
}

class InferredTypeArgumentDataComputer extends DataComputer<List<DartType>> {
  const InferredTypeArgumentDataComputer();

  @override
  DataInterpreter<List<DartType>> get dataValidator =>
      const _InferredTypeArgumentsDataInterpreter();

  @override
  bool get supportsErrors => true;

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(TestResultData testResultData, Member member,
      Map<Id, ActualData<List<DartType>>> actualMap,
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

class InferredTypeArgumentDataExtractor
    extends CfeDataExtractor<List<DartType>> {
  final TypeInferenceResultForTesting typeInferenceResult;

  InferredTypeArgumentDataExtractor(InternalCompilerResult compilerResult,
      this.typeInferenceResult, Map<Id, ActualData<List<DartType>>> actualMap)
      : super(compilerResult, actualMap);

  @override
  List<DartType>? computeNodeValue(Id id, TreeNode node) {
    if (node is Arguments ||
        node is ListLiteral ||
        node is SetLiteral ||
        node is MapLiteral) {
      return typeInferenceResult.inferredTypeArguments[node];
    }
    return null;
  }
}

class _InferredTypeArgumentsDataInterpreter
    implements DataInterpreter<List<DartType>> {
  const _InferredTypeArgumentsDataInterpreter();

  @override
  String getText(List<DartType> actualData, [String? indentation]) {
    StringBuffer sb = new StringBuffer();
    if (actualData.isNotEmpty) {
      sb.write('<');
      for (int i = 0; i < actualData.length; i++) {
        if (i > 0) {
          sb.write(',');
        }
        sb.write(typeToText(
            actualData[i], TypeRepresentation.analyzerNonNullableByDefault));
      }
      sb.write('>');
    }
    return sb.toString();
  }

  @override
  String? isAsExpected(List<DartType> actualData, String? expectedData) {
    if (getText(actualData) == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualData';
    }
  }

  @override
  bool isEmpty(List<DartType>? actualData) =>
      actualData == null || actualData.isEmpty;
}
