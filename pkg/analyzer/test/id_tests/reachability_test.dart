// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';
import 'package:front_end/src/testing/id.dart' show ActualData, Id;
import 'package:front_end/src/testing/id_testing.dart';
import 'package:test/test.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script
      .resolve('../../../front_end/test/flow_analysis/reachability/data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: sharedMarkers,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest:
          runTestFor(const _ReachabilityDataComputer(), [analyzerNnbdConfig]));
}

class FlowTestBase {
  FlowAnalysisResult flowResult;

  /// Resolve the given [code] and track nullability in the unit.
  Future<void> trackCode(String code) async {
    if (await checkTests(
        code,
        const _ReachabilityDataComputer(),
        FeatureSet.forTesting(
            sdkVersion: '2.2.2', additionalFeatures: [Feature.non_nullable]))) {
      fail('Failure(s)');
    }
  }
}

enum _ReachabilityAssertion {
  doesNotComplete,
  unreachable,
}

class _ReachabilityDataComputer
    extends DataComputer<Set<_ReachabilityAssertion>> {
  const _ReachabilityDataComputer();

  @override
  DataInterpreter<Set<_ReachabilityAssertion>> get dataValidator =>
      const _ReachabilityDataInterpreter();

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<Set<_ReachabilityAssertion>>> actualMap) {
    var flowResult =
        testingData.uriToFlowAnalysisResult[unit.declaredElement.source.uri];
    _ReachabilityDataExtractor(
            unit.declaredElement.source.uri, actualMap, flowResult)
        .run(unit);
  }
}

class _ReachabilityDataExtractor
    extends AstDataExtractor<Set<_ReachabilityAssertion>> {
  final FlowAnalysisResult _flowResult;

  _ReachabilityDataExtractor(
      Uri uri,
      Map<Id, ActualData<Set<_ReachabilityAssertion>>> actualMap,
      this._flowResult)
      : super(uri, actualMap);

  @override
  Set<_ReachabilityAssertion> computeNodeValue(Id id, AstNode node) {
    Set<_ReachabilityAssertion> result = {};
    if (_flowResult.unreachableNodes.contains(node)) {
      result.add(_ReachabilityAssertion.unreachable);
    }
    if (node is FunctionDeclaration) {
      var body = node.functionExpression.body;
      if (body != null &&
          _flowResult.functionBodiesThatDontComplete.contains(body)) {
        result.add(_ReachabilityAssertion.doesNotComplete);
      }
    }
    return result.isEmpty ? null : result;
  }
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
