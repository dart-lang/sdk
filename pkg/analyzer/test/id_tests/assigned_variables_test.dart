// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/null_safety_understanding_flag.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = Directory.fromUri(Platform.script.resolve(
      '../../../_fe_analyzer_shared/test/flow_analysis/assigned_variables/'
      'data'));
  await NullSafetyUnderstandingFlag.enableNullSafetyTypes(() {
    return runTests<_Data>(dataDir,
        args: args,
        createUriForFileName: createUriForFileName,
        onFailure: onFailure,
        runTest: runTestFor(
            const _AssignedVariablesDataComputer(), [analyzerNnbdConfig]));
  });
}

class _AssignedVariablesDataComputer extends DataComputer<_Data> {
  const _AssignedVariablesDataComputer();

  @override
  DataInterpreter<_Data> get dataValidator =>
      const _AssignedVariablesDataInterpreter();

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<_Data>> actualMap) {
    var flowResult =
        testingData.uriToFlowAnalysisData[unit.declaredElement.source.uri];
    _AssignedVariablesDataExtractor(
            unit.declaredElement.source.uri, actualMap, flowResult)
        .run(unit);
  }
}

class _AssignedVariablesDataExtractor extends AstDataExtractor<_Data> {
  final FlowAnalysisDataForTesting _flowResult;

  Declaration _currentDeclaration;

  AssignedVariablesForTesting<AstNode, PromotableElement>
      _currentAssignedVariables;

  _AssignedVariablesDataExtractor(
      Uri uri, Map<Id, ActualData<_Data>> actualMap, this._flowResult)
      : super(uri, actualMap);

  @override
  _Data computeNodeValue(Id id, AstNode node) {
    if (node is FunctionDeclarationStatement) {
      node = (node as FunctionDeclarationStatement).functionDeclaration;
    }
    if (_currentAssignedVariables == null) return null;
    if (node == _currentDeclaration) {
      return _Data(
          _convertVars(_currentAssignedVariables.declaredAtTopLevel),
          _convertVars(_currentAssignedVariables.writtenAnywhere),
          _convertVars(_currentAssignedVariables.capturedAnywhere));
    }
    if (!_currentAssignedVariables.isTracked(node)) return null;
    return _Data(
        _convertVars(_currentAssignedVariables.declaredInNode(node)),
        _convertVars(_currentAssignedVariables.writtenInNode(node)),
        _convertVars(_currentAssignedVariables.capturedInNode(node)));
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    _handlePossibleTopLevelDeclaration(
        node, () => super.visitConstructorDeclaration(node));
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _handlePossibleTopLevelDeclaration(
        node, () => super.visitFunctionDeclaration(node));
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _handlePossibleTopLevelDeclaration(
        node, () => super.visitVariableDeclaration(node));
  }

  Set<String> _convertVars(Iterable<PromotableElement> x) =>
      x.map((e) => e.name).toSet();

  void _handlePossibleTopLevelDeclaration(
      AstNode node, void Function() callback) {
    if (_currentDeclaration == null) {
      _currentDeclaration = node;
      _currentAssignedVariables = _flowResult.assignedVariables[node];
      callback();
      _currentDeclaration = null;
      _currentAssignedVariables = null;
    } else {
      callback();
    }
  }
}

class _AssignedVariablesDataInterpreter implements DataInterpreter<_Data> {
  const _AssignedVariablesDataInterpreter();

  @override
  String getText(_Data actualData, [String indentation]) {
    var parts = <String>[];
    if (actualData.declared.isNotEmpty) {
      parts.add('declared=${_setToString(actualData.declared)}');
    }
    if (actualData.assigned.isNotEmpty) {
      parts.add('assigned=${_setToString(actualData.assigned)}');
    }
    if (actualData.captured.isNotEmpty) {
      parts.add('captured=${_setToString(actualData.captured)}');
    }
    if (parts.isEmpty) return 'none';
    return parts.join(', ');
  }

  @override
  String isAsExpected(_Data actualData, String expectedData) {
    var actualDataText = getText(actualData);
    if (actualDataText == expectedData) {
      return null;
    } else {
      return 'Expected "$expectedData", got "$actualDataText"';
    }
  }

  @override
  bool isEmpty(_Data actualData) =>
      actualData.assigned.isEmpty && actualData.captured.isEmpty;

  String _setToString(Set<String> values) {
    List<String> sortedValues = values.toList()..sort();
    return '{${sortedValues.join(', ')}}';
  }
}

class _Data {
  final Set<String> declared;

  final Set<String> assigned;

  final Set<String> captured;

  _Data(this.declared, this.assigned, this.captured);
}
