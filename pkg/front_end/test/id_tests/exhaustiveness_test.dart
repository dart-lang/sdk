// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/exhaustiveness/test_helper.dart';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart'
    show ActualData, Id, IdKind, NodeId;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, cfeMarker, runTests;
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/fasta/kernel/exhaustiveness.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:kernel/ast.dart' hide Variance;

Future<void> main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/exhaustiveness/data'));
  await runTests<Features>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor<Features>(const ExhaustivenessDataComputer(), [
        const TestConfig(cfeMarker, 'cfe with experiments',
            explicitExperimentalFlags: const {
              ExperimentalFlag.patterns: true,
              ExperimentalFlag.records: true,
              ExperimentalFlag.sealedClass: true
            })
      ]));
}

class ExhaustivenessDataComputer extends DataComputer<Features> {
  const ExhaustivenessDataComputer();

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(TestResultData testResultData, Member member,
      Map<Id, ActualData<Features>> actualMap,
      {bool? verbose}) {
    member.accept(new ExhaustivenessDataExtractor(
        testResultData.compilerResult, actualMap));
  }

  @override
  bool get supportsErrors => true;
}

class ExhaustivenessDataExtractor extends CfeDataExtractor<Features> {
  final ExhaustivenessDataForTesting _exhaustivenessData;

  ExhaustivenessDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<Features>> actualMap)
      : _exhaustivenessData = compilerResult
            .kernelTargetForTesting!.loader.dataForTesting!.exhaustivenessData,
        super(compilerResult, actualMap);

  Features? computeExhaustivenessData(TreeNode node) {
    ExhaustivenessResult? result = _exhaustivenessData.switchResults[node];
    if (result != null) {
      Features features = new Features();
      features[Tags.scrutineeType] = staticTypeToText(result.scrutineeType);
      String? subtypes = subtypesToText(result.scrutineeType);
      if (subtypes != null) {
        features[Tags.subtypes] = subtypes;
      }
      features[Tags.scrutineeFields] =
          fieldsToText(result.scrutineeType.fields);
      features[Tags.remaining] = spaceToText(result.remainingSpaces.last);
      Uri uri = node.location!.file;
      for (int i = 0; i < result.caseSpaces.length; i++) {
        int offset = result.caseOffsets[i];
        Features caseFeatures = new Features();
        caseFeatures[Tags.space] = spaceToText(result.caseSpaces[i]);
        caseFeatures[Tags.remaining] = spaceToText(result.remainingSpaces[i]);
        registerValue(
            uri, offset, new NodeId(offset, IdKind.node), caseFeatures, node);
      }
      return features;
    }
    return null;
  }

  @override
  Features? computeNodeValue(Id id, TreeNode node) {
    if (node is SwitchStatement || node is Block) {
      return computeExhaustivenessData(node);
    }
    return null;
  }
}
