// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) {
  Directory dataDir = Directory.fromUri(
    Platform.script.resolve(
      '../../../_fe_analyzer_shared/test/flow_analysis/definite_assignment/'
      'data',
    ),
  );
  return runTests<String>(
    dataDir,
    args: args,
    createUriForFileName: createUriForFileName,
    onFailure: onFailure,
    runTest: runTestFor(const _DefiniteAssignmentDataComputer(), [
      analyzerDefaultConfig,
    ]),
  );
}

class _DefiniteAssignmentDataComputer extends DataComputer<String> {
  const _DefiniteAssignmentDataComputer();

  @override
  DataInterpreter<String> get dataValidator =>
      const _DefiniteAssignmentDataInterpreter();

  @override
  bool get supportsErrors => true;

  @override
  String? computeErrorData(
    TestConfig config,
    TestingData testingData,
    Id id,
    List<Diagnostic> diagnostics,
  ) {
    var diagnosticCodes = diagnostics
        .map((e) => e.diagnosticCode)
        .where(
          (c) =>
              c != CompileTimeErrorCode.definitelyUnassignedLateLocalVariable,
        );
    return diagnosticCodes.isNotEmpty ? diagnosticCodes.join(',') : null;
  }

  @override
  void computeUnitData(
    TestingData testingData,
    CompilationUnit unit,
    Map<Id, ActualData<String>> actualMap,
  ) {
    var unitUri = unit.declaredFragment!.source.uri;
    var flowResult = testingData.uriToFlowAnalysisData[unitUri]!;
    _DefiniteAssignmentDataExtractor(unitUri, actualMap, flowResult).run(unit);
  }
}

class _DefiniteAssignmentDataExtractor extends AstDataExtractor<String> {
  final FlowAnalysisDataForTesting _flowResult;

  _DefiniteAssignmentDataExtractor(
    super.uri,
    super.actualMap,
    this._flowResult,
  );

  @override
  String? computeNodeValue(Id id, AstNode node) {
    if (node is SimpleIdentifier && node.inGetterContext()) {
      var element = node.element;
      if (element is LocalVariableElement ||
          element is FormalParameterElement) {
        if (_flowResult.notDefinitelyAssigned.contains(node)) {
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
