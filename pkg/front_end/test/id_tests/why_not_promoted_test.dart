// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
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
import 'package:kernel/ast.dart' hide Variance, MapLiteralEntry;

Future<void> main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(
      Platform.script.resolve('../../../_fe_analyzer_shared/test/flow_analysis/'
          'why_not_promoted/data'));
  await runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const WhyNotPromotedDataComputer(), [cfeNonNullableOnlyConfig]));
}

class WhyNotPromotedDataComputer extends DataComputer<String> {
  const WhyNotPromotedDataComputer();

  @override
  DataInterpreter<String> get dataValidator =>
      const _WhyNotPromotedDataInterpreter();

  /// Errors are supported for testing erroneous code. The reported errors are
  /// not tested.
  @override
  bool get supportsErrors => true;

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(TestResultData testResultData, Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool? verbose}) {
    SourceMemberBuilder memberBuilder =
        lookupMemberBuilder(testResultData.compilerResult, member)
            as SourceMemberBuilder;
    member.accept(new WhyNotPromotedDataExtractor(
        testResultData.compilerResult,
        actualMap,
        memberBuilder.dataForTesting!.inferenceData.flowAnalysisResult));
  }
}

class WhyNotPromotedDataExtractor extends CfeDataExtractor<String> {
  final FlowAnalysisResult _flowResult;

  WhyNotPromotedDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap, this._flowResult)
      : super(compilerResult, actualMap);

  @override
  String? computeNodeValue(Id id, TreeNode node) {
    String? nonPromotionReason = _flowResult.nonPromotionReasons[node];
    if (nonPromotionReason != null) {
      return 'notPromoted($nonPromotionReason)';
    }
    return _flowResult.nonPromotionReasonTargets[node];
  }
}

class _WhyNotPromotedDataInterpreter implements DataInterpreter<String> {
  const _WhyNotPromotedDataInterpreter();

  @override
  String getText(String actualData, [String? indentation]) => actualData;

  @override
  String? isAsExpected(String actualData, String? expectedData) {
    if (actualData == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualData';
    }
  }

  @override
  bool isEmpty(String? actualData) => actualData == null;
}
