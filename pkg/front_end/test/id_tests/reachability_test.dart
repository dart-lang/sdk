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
      '../../../_fe_analyzer_shared/test/flow_analysis/reachability/data'));
  await runTests<Set<_ReachabilityAssertion>>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const ReachabilityDataComputer(), [cfeNonNullableOnlyConfig]));
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
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<Set<_ReachabilityAssertion>>> actualMap,
      {bool verbose}) {
    MemberBuilderImpl memberBuilder =
        lookupMemberBuilder(compilerResult, member);
    member.accept(new ReachabilityDataExtractor(compilerResult, actualMap,
        memberBuilder.dataForTesting.inferenceData.flowAnalysisResult));
  }

  /// Errors are supported for testing erroneous code. The reported errors are
  /// not tested.
  @override
  bool get supportsErrors => true;
}

class ReachabilityDataExtractor
    extends CfeDataExtractor<Set<_ReachabilityAssertion>> {
  final SourceLoaderDataForTesting _sourceLoaderDataForTesting;
  final FlowAnalysisResult _flowResult;

  ReachabilityDataExtractor(
      InternalCompilerResult compilerResult,
      Map<Id, ActualData<Set<_ReachabilityAssertion>>> actualMap,
      this._flowResult)
      : _sourceLoaderDataForTesting =
            compilerResult.kernelTargetForTesting.loader.dataForTesting,
        super(compilerResult, actualMap);

  @override
  Set<_ReachabilityAssertion> computeMemberValue(Id id, Member member) {
    Set<_ReachabilityAssertion> result = {};
    if (member.function != null) {
      TreeNode alias =
          _sourceLoaderDataForTesting.toOriginal(member.function.body);
      if (_flowResult.functionBodiesThatDontComplete.contains(alias)) {
        result.add(_ReachabilityAssertion.doesNotComplete);
      }
    }
    return result.isEmpty ? null : result;
  }

  @override
  Set<_ReachabilityAssertion> computeNodeValue(Id id, TreeNode node) {
    Set<_ReachabilityAssertion> result = {};
    TreeNode alias = _sourceLoaderDataForTesting.toOriginal(node);
    if (node is Expression && node.parent is ExpressionStatement) {
      // The reachability of an expression statement and the statement it
      // contains should always be the same.  We check this with an assert
      // statement, and only annotate the expression statement, to reduce the
      // amount of redundancy in the test files.
      assert(_flowResult.unreachableNodes.contains(alias) ==
          _flowResult.unreachableNodes
              .contains(_sourceLoaderDataForTesting.toOriginal(node.parent)));
    } else if (_flowResult.unreachableNodes.contains(alias)) {
      result.add(_ReachabilityAssertion.unreachable);
    }
    if (node is FunctionDeclaration) {
      Statement body = node.function.body;
      if (body != null &&
          _flowResult.functionBodiesThatDontComplete
              .contains(_sourceLoaderDataForTesting.toOriginal(body))) {
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
  String getText(Set<_ReachabilityAssertion> actualData,
          [String indentation]) =>
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
