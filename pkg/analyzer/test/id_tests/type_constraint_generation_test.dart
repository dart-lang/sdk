// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) {
  Directory dataDir = Directory.fromUri(
    Platform.script.resolve(
      '../../../_fe_analyzer_shared/test/inference/'
      'type_constraint_generation/data',
    ),
  );
  return runTests<List<GeneratedTypeConstraint>>(
    dataDir,
    args: args,
    createUriForFileName: createUriForFileName,
    onFailure: onFailure,
    runTest: runTestFor(const _TypeConstraintGenerationDataComputer(), [
      analyzerDefaultConfig,
    ]),
  );
}

class _TypeConstraintGenerationDataComputer
    extends DataComputer<List<GeneratedTypeConstraint>> {
  const _TypeConstraintGenerationDataComputer();

  @override
  DataInterpreter<List<GeneratedTypeConstraint>> get dataValidator =>
      const _TypeConstraintGenerationDataInterpreter();

  @override
  bool get supportsErrors => true;

  @override
  void computeUnitData(
    TestingData testingData,
    CompilationUnit unit,
    Map<Id, ActualData<List<GeneratedTypeConstraint>>> actualMap,
  ) {
    _TypeConstraintGenerationDataExtractor(
      testingData.uriToTypeConstraintGenerationData[unit
          .declaredFragment
          ?.source
          .uri]!,
      unit.declaredFragment!.source.uri,
      actualMap,
    ).run(unit);
  }
}

class _TypeConstraintGenerationDataExtractor
    extends AstDataExtractor<List<GeneratedTypeConstraint>> {
  final TypeConstraintGenerationDataForTesting dataForTesting;

  _TypeConstraintGenerationDataExtractor(
    this.dataForTesting,
    super.uri,
    super.actualMap,
  );

  @override
  List<GeneratedTypeConstraint>? computeNodeValue(Id id, AstNode node) {
    return dataForTesting.generatedTypeConstraints[node];
  }
}

class _TypeConstraintGenerationDataInterpreter
    implements DataInterpreter<List<GeneratedTypeConstraint>> {
  const _TypeConstraintGenerationDataInterpreter();

  @override
  String getText(
    List<GeneratedTypeConstraint> actualData, [
    String? indentation,
  ]) {
    StringBuffer sb = StringBuffer();
    if (actualData.isNotEmpty) {
      for (int i = 0; i < actualData.length; i++) {
        if (i > 0) {
          sb.write(',');
        }
        var name = actualData[i].typeParameter
            .unwrapTypeParameterViewAsTypeParameterStructure<
              TypeParameterElementImpl
            >()
            .name;
        if (actualData[i].isUpper) {
          sb.write("$name <: ");
          sb.write(actualData[i].constraint.getDisplayString());
        } else {
          sb.write("$name :> ");
          sb.write(actualData[i].constraint.getDisplayString());
        }
      }
    }
    return sb.toString();
  }

  @override
  String? isAsExpected(
    List<GeneratedTypeConstraint> actualData,
    String? expectedData,
  ) {
    var actualDataText = getText(actualData);
    if (actualDataText == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualDataText';
    }
  }

  @override
  bool isEmpty(List<GeneratedTypeConstraint>? actualData) =>
      actualData == null || actualData.isEmpty;
}
