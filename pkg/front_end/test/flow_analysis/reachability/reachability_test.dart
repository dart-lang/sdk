// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;

import 'package:front_end/src/testing/id.dart' show ActualData, Id;
import 'package:front_end/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:front_end/src/testing/id_testing.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/builder/member_builder.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart' hide Variance;

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve(
      '../../../../_fe_analyzer_shared/test/flow_analysis/reachability/data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: sharedMarkers,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const ReachabilityDataComputer(), [
        new TestConfig(cfeMarker, 'cfe with nnbd',
            experimentalFlags: const {ExperimentalFlag.nonNullable: true})
      ]),
      skipList: [
        // TODO(dmitryas): Run all reachability tests.
        'assert.dart',
        'do.dart',
        'for.dart',
        'switch.dart',
        'try_catch.dart',
      ]);
}

class ReachabilityDataComputer
    extends DataComputer<Set<_ReachabilityAssertion>> {
  const ReachabilityDataComputer();

  @override
  DataInterpreter<Set<_ReachabilityAssertion>> get dataValidator =>
      const _ReachabilityDataInterpreter();

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  void computeMemberData(InternalCompilerResult compilerResult, Member member,
      Map<Id, ActualData<Set<_ReachabilityAssertion>>> actualMap,
      {bool verbose}) {
    MemberBuilderImpl memberBuilder =
        lookupMemberBuilder(compilerResult, member);
    member.accept(new ReachabilityDataExtractor(compilerResult, actualMap,
        memberBuilder.dataForTesting.inferenceData.flowAnalysisResult));
  }
}

class ReachabilityDataExtractor
    extends CfeDataExtractor<Set<_ReachabilityAssertion>> {
  final FlowAnalysisResult _flowResult;

  ReachabilityDataExtractor(
      InternalCompilerResult compilerResult,
      Map<Id, ActualData<Set<_ReachabilityAssertion>>> actualMap,
      this._flowResult)
      : super(compilerResult, actualMap);

  @override
  Set<_ReachabilityAssertion> computeMemberValue(Id id, Member member) {
    Set<_ReachabilityAssertion> result = {};
    if (member.function != null) {
      if (_flowResult.functionBodiesThatDontComplete
          .contains(member.function.body)) {
        result.add(_ReachabilityAssertion.doesNotComplete);
      }
    }
    return result.isEmpty ? null : result;
  }

  @override
  Set<_ReachabilityAssertion> computeNodeValue(Id id, TreeNode node) {
    Set<_ReachabilityAssertion> result = {};
    if (node is Expression && node.parent is ExpressionStatement) {
      // The reachability of an expression statement and the statement it
      // contains should always be the same.  We check this with an assert
      // statement, and only annotate the expression statement, to reduce the
      // amount of redundancy in the test files.
      assert(_flowResult.unreachableNodes.contains(node) ==
          _flowResult.unreachableNodes.contains(node.parent));
    } else if (_flowResult.unreachableNodes.contains(node)) {
      result.add(_ReachabilityAssertion.unreachable);
    }
    if (node is FunctionDeclaration) {
      Statement body = node.function.body;
      if (body != null &&
          _flowResult.functionBodiesThatDontComplete.contains(body)) {
        result.add(_ReachabilityAssertion.doesNotComplete);
      }
    }
    return result.isEmpty ? null : result;
  }
}

enum _ReachabilityAssertion {
  doesNotComplete,
  unreachable,
}

class _ReachabilityDataInterpreter
    implements DataInterpreter<Set<_ReachabilityAssertion>> {
  const _ReachabilityDataInterpreter();

  @override
  String getText(Set<_ReachabilityAssertion> actualData) =>
      _sortedRepresentation(_toStrings(actualData));

  @override
  String isAsExpected(
      Set<_ReachabilityAssertion> actualData, String expectedData) {
    var actualStrings = _toStrings(actualData);
    var actualSorted = _sortedRepresentation(actualStrings);
    var expectedSorted = _sortedRepresentation(expectedData?.split(','));
    if (actualSorted == expectedSorted) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualSorted';
    }
  }

  @override
  bool isEmpty(Set<_ReachabilityAssertion> actualData) => actualData.isEmpty;

  String _sortedRepresentation(Iterable<String> values) {
    var list = values == null || values.isEmpty ? ['none'] : values.toList();
    list.sort();
    return list.join(',');
  }

  List<String> _toStrings(Set<_ReachabilityAssertion> actualData) => actualData
      .map((flowAssertion) => flowAssertion.toString().split('.')[1])
      .toList();
}
