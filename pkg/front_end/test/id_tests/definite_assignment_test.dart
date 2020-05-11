// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/fasta/builder/member_builder.dart';
import 'package:front_end/src/fasta/source/source_loader.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart' hide Variance;

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve(
      '../../../_fe_analyzer_shared/test/flow_analysis/definite_assignment/'
      'data'));
  await runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const DefiniteAssignmentDataComputer(), [cfeNonNullableOnlyConfig]));
}

class DefiniteAssignmentDataComputer extends DataComputer<String> {
  const DefiniteAssignmentDataComputer();

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    MemberBuilderImpl memberBuilder =
        lookupMemberBuilder(compilerResult, member);
    member.accept(new DefiniteAssignmentDataExtractor(compilerResult, actualMap,
        memberBuilder.dataForTesting.inferenceData.flowAnalysisResult));
  }

  /// Errors are supported for testing erroneous code. The reported errors are
  /// not tested.
  @override
  bool get supportsErrors => true;
}

class DefiniteAssignmentDataExtractor extends CfeDataExtractor<String> {
  final SourceLoaderDataForTesting _sourceLoaderDataForTesting;
  final FlowAnalysisResult _flowResult;

  DefiniteAssignmentDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap, this._flowResult)
      : _sourceLoaderDataForTesting =
            compilerResult.kernelTargetForTesting.loader.dataForTesting,
        super(compilerResult, actualMap);

  @override
  String computeNodeValue(Id id, TreeNode node) {
    if (node is VariableGet) {
      TreeNode alias = _sourceLoaderDataForTesting.toOriginal(node);
      if (_flowResult.potentiallyUnassignedNodes.contains(alias)) {
        return 'unassigned';
      }
    }
    return null;
  }
}
