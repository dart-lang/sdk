// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;

import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/builder/member_builder.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart' hide Variance;

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve(
      '../../../../_fe_analyzer_shared/test/flow_analysis/definite_assignment/'
      'data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: sharedMarkers,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const DefiniteAssignmentDataComputer(), [
        new TestConfig(cfeMarker, 'cfe with nnbd',
            experimentalFlags: const {ExperimentalFlag.nonNullable: true})
      ]),
      skipList: [
        // TODO(dmitryas): Run all definite assignment tests.
        'assert.dart',
        'assignment.dart',
        'binary_expression.dart',
        'conditional_expression.dart',
        'do.dart',
        'for.dart',
        'for_each.dart',
        'function_expression.dart',
        'if.dart',
        'initialization.dart',
        'switch.dart',
        'try.dart',
        'while.dart',
      ]);
}

class DefiniteAssignmentDataComputer extends DataComputer<String> {
  const DefiniteAssignmentDataComputer();

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  void computeMemberData(InternalCompilerResult compilerResult, Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    MemberBuilderImpl memberBuilder =
        lookupMemberBuilder(compilerResult, member);
    member.accept(new DefiniteAssignmentDataExtractor(compilerResult, actualMap,
        memberBuilder.dataForTesting.inferenceData.flowAnalysisResult));
  }
}

class DefiniteAssignmentDataExtractor extends CfeDataExtractor<String> {
  final FlowAnalysisResult _flowResult;

  DefiniteAssignmentDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap, this._flowResult)
      : super(compilerResult, actualMap);

  @override
  String computeNodeValue(Id id, TreeNode node) {
    if (node is VariableGet) {
      if (_flowResult.unassignedNodes.contains(node.variable)) {
        return 'unassigned';
      }
    }
    return null;
  }
}
