// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';
import 'package:front_end/src/testing/id.dart' show ActualData, Id;
import 'package:front_end/src/testing/id_testing.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve(
      '../../../front_end/test/flow_analysis/definite_assignment/data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: sharedMarkers,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const _DefiniteAssignmentDataComputer(), [analyzerNnbdConfig]));
}

class _DefiniteAssignmentDataComputer extends DataComputer<String> {
  const _DefiniteAssignmentDataComputer();

  @override
  DataInterpreter<String> get dataValidator =>
      const _DefiniteAssignmentDataInterpreter();

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<String>> actualMap) {
    var flowResult =
        testingData.uriToFlowAnalysisResult[unit.declaredElement.source.uri];
    _DefiniteAssignmentDataExtractor(
            unit.declaredElement.source.uri, actualMap, flowResult)
        .run(unit);
  }
}

class _DefiniteAssignmentDataExtractor extends AstDataExtractor<String> {
  final FlowAnalysisResult _flowResult;

  _DefiniteAssignmentDataExtractor(
      Uri uri, Map<Id, ActualData<String>> actualMap, this._flowResult)
      : super(uri, actualMap);

  @override
  String computeNodeValue(Id id, AstNode node) {
    if (node is SimpleIdentifier && node.inGetterContext()) {
      var element = node.staticElement;
      if (element is LocalVariableElement || element is ParameterElement) {
        if (_flowResult.unassignedNodes.contains(node)) {
          return 'unassigned';
        }
      }
    }
    return null;
  }
}

class _DefiniteAssignmentDataInterpreter implements DataInterpreter<String> {
  const _DefiniteAssignmentDataInterpreter();

  @override
  String getText(String actualData) => actualData;

  @override
  String isAsExpected(String actualData, String expectedData) {
    if (actualData == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualData';
    }
  }

  @override
  bool isEmpty(String actualData) => actualData == null;
}
