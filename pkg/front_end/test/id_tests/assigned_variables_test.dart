// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart'
    show ActualData, Id, IdKind;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/fasta/builder/member_builder.dart';
import 'package:front_end/src/fasta/source/source_loader.dart';

import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart' hide Variance;

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve(
      '../../../_fe_analyzer_shared/test/flow_analysis/assigned_variables/'
      'data'));
  await runTests<_Data>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor<_Data>(
          const AssignedVariablesDataComputer(), [cfeNonNullableOnlyConfig]));
}

class AssignedVariablesDataComputer extends DataComputer<_Data> {
  const AssignedVariablesDataComputer();

  @override
  DataInterpreter<_Data> get dataValidator =>
      const _AssignedVariablesDataInterpreter();

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<_Data>> actualMap,
      {bool verbose}) {
    MemberBuilderImpl memberBuilder =
        lookupMemberBuilder(compilerResult, member);
    AssignedVariablesForTesting<TreeNode, VariableDeclaration>
        assignedVariables = memberBuilder
            .dataForTesting.inferenceData.flowAnalysisResult.assignedVariables;
    if (assignedVariables == null) return;
    member.accept(new AssignedVariablesDataExtractor(
        compilerResult, actualMap, assignedVariables));
  }
}

class AssignedVariablesDataExtractor extends CfeDataExtractor<_Data> {
  final SourceLoaderDataForTesting _sourceLoaderDataForTesting;
  final AssignedVariablesForTesting<TreeNode, VariableDeclaration>
      _assignedVariables;

  AssignedVariablesDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<_Data>> actualMap, this._assignedVariables)
      : _sourceLoaderDataForTesting =
            compilerResult.kernelTargetForTesting.loader.dataForTesting,
        super(compilerResult, actualMap);

  @override
  _Data computeMemberValue(Id id, Member member) {
    return new _Data(
        _convertVars(_assignedVariables.declaredAtTopLevel),
        _convertVars(_assignedVariables.writtenAnywhere),
        _convertVars(_assignedVariables.capturedAnywhere));
  }

  Set<String> _convertVars(Iterable<VariableDeclaration> x) =>
      x.map((e) => e.name).toSet();

  @override
  _Data computeNodeValue(Id id, TreeNode node) {
    switch (id.kind) {
      case IdKind.iterator:
      case IdKind.current:
      case IdKind.moveNext:
        return null;
      default:
    }
    TreeNode alias = _sourceLoaderDataForTesting.toOriginal(node);
    if (!_assignedVariables.isTracked(alias)) return null;
    return new _Data(
        _convertVars(_assignedVariables.declaredInNode(alias)),
        _convertVars(_assignedVariables.writtenInNode(alias)),
        _convertVars(_assignedVariables.capturedInNode(alias)));
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
