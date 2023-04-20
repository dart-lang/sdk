// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/key.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/test_helper.dart';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/generated/exhaustiveness.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/exhaustiveness/data'));
  return runTests<Features>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const _ExhaustivenessDataComputer(), [
        TestConfig(analyzerMarker, 'analyzer with experiments',
            featureSet: FeatureSet.fromEnableFlags2(
                sdkLanguageVersion: ExperimentStatus.currentVersion,
                flags: ['patterns', 'records', 'sealed-class']))
      ]));
}

class _ExhaustivenessDataComputer extends DataComputer<Features> {
  const _ExhaustivenessDataComputer();

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();

  @override
  bool get supportsErrors => true;

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<Features>> actualMap) {
    var unitElement = unit.declaredElement!;
    var exhaustivenessData =
        testingData.uriToExhaustivenessData[unitElement.source.uri]!;
    _ExhaustivenessDataExtractor(
            unitElement.source.uri, actualMap, exhaustivenessData)
        .run(unit);
  }
}

class _ExhaustivenessDataExtractor extends AstDataExtractor<Features> {
  final ExhaustivenessDataForTesting _exhaustivenessData;

  _ExhaustivenessDataExtractor(
      super.uri, super.actualMap, this._exhaustivenessData);

  @override
  Features? computeNodeValue(Id id, AstNode node) {
    Features features = Features();
    if (node is SwitchStatement || node is SwitchExpression) {
      StaticType? scrutineeType = _exhaustivenessData.switchScrutineeType[node];
      List<Space>? caseSpaces = _exhaustivenessData.switchCases[node];
      if (scrutineeType != null && caseSpaces != null) {
        Set<Key> fieldsOfInterest = {};
        Set<Key> keysOfInterest = {};
        for (Space caseSpace in caseSpaces) {
          for (SingleSpace singleSpace in caseSpace.singleSpaces) {
            fieldsOfInterest.addAll(singleSpace.properties.keys);
            keysOfInterest.addAll(singleSpace.additionalProperties.keys);
          }
        }
        features[Tags.scrutineeType] = staticTypeToText(scrutineeType);
        if (fieldsOfInterest.isNotEmpty) {
          features[Tags.scrutineeFields] = fieldsToText(scrutineeType,
              _exhaustivenessData.objectFieldLookup, fieldsOfInterest);
        }
        String? subtypes =
            typesToText(scrutineeType.getSubtypes(keysOfInterest));
        if (subtypes != null) {
          features[Tags.subtypes] = subtypes;
        }
        if (scrutineeType.isSealed) {
          String? expandedSubtypes =
              typesToText(expandSealedSubtypes(scrutineeType, keysOfInterest));
          if (subtypes != expandedSubtypes && expandedSubtypes != null) {
            features[Tags.expandedSubtypes] = expandedSubtypes;
          }
          String? order =
              typesToText(checkingOrder(scrutineeType, keysOfInterest));
          if (order != null) {
            features[Tags.checkingOrder] = order;
          }
        }
      }
      ExhaustivenessError? error = _exhaustivenessData.errors[node];
      if (error != null) {
        features[Tags.error] = errorToText(error);
      }
    } else if (node is SwitchMember || node is SwitchExpressionCase) {
      Space? caseSpace = _exhaustivenessData.caseSpaces[node];
      if (caseSpace != null) {
        features[Tags.space] = spacesToText(caseSpace);
      }
      ExhaustivenessError? error = _exhaustivenessData.errors[node];
      if (error != null) {
        features[Tags.error] = errorToText(error);
      }
    }
    return features.isNotEmpty ? features : null;
  }
}
