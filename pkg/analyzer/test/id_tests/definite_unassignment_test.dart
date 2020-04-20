// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/null_safety_understanding_flag.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = Directory.fromUri(Platform.script.resolve(
      '../../../_fe_analyzer_shared/test/flow_analysis/definite_unassignment/'
      'data'));
  await NullSafetyUnderstandingFlag.enableNullSafetyTypes(() {
    return runTests<String>(dataDir,
        args: args,
        createUriForFileName: createUriForFileName,
        onFailure: onFailure,
        runTest: runTestFor(
            const _DefiniteAssignmentDataComputer(), [analyzerNnbdConfig]));
  });
}

class _DefiniteAssignmentDataComputer extends DataComputer<String> {
  const _DefiniteAssignmentDataComputer();

  @override
  DataInterpreter<String> get dataValidator =>
      const _DefiniteUnassignmentDataInterpreter();

  @override
  bool get supportsErrors => true;

  @override
  String computeErrorData(TestConfig config, TestingData testingData, Id id,
      List<AnalysisError> errors) {
    var errorCodes = errors.map((e) => e.errorCode).where((errorCode) =>
        errorCode !=
        CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE);
    return errorCodes.isNotEmpty ? errorCodes.join(',') : null;
  }

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<String>> actualMap) {
    var flowResult =
        testingData.uriToFlowAnalysisData[unit.declaredElement.source.uri];
    _DefiniteUnassignmentDataExtractor(
            unit.declaredElement.source.uri, actualMap, flowResult)
        .run(unit);
  }
}

class _DefiniteUnassignmentDataExtractor extends AstDataExtractor<String> {
  final FlowAnalysisDataForTesting _flowResult;

  _DefiniteUnassignmentDataExtractor(
      Uri uri, Map<Id, ActualData<String>> actualMap, this._flowResult)
      : super(uri, actualMap);

  @override
  String computeNodeValue(Id id, AstNode node) {
    if (node is SimpleIdentifier && node.inGetterContext()) {
      var element = node.staticElement;
      if (element is LocalVariableElement || element is ParameterElement) {
        if (_flowResult.definitelyUnassignedNodes.contains(node)) {
          return 'unassigned';
        }
      }
    }
    return null;
  }
}

class _DefiniteUnassignmentDataInterpreter implements DataInterpreter<String> {
  const _DefiniteUnassignmentDataInterpreter();

  @override
  String getText(String actualData, [String indentation]) => actualData;

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
