// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, StringDataInterpreter, cfeMarker, runTests;
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/testing/id_testing_helper.dart'
    show
        CfeDataComputer,
        CfeDataExtractor,
        CfeTestConfig,
        CfeTestResultData,
        FormattedMessage,
        InternalCompilerResult,
        createUriForFileName,
        onFailure,
        runTestFor;
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart';

Future<void> main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/constants/data'));
  await runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const ConstantsDataComputer(), [
        const CfeTestConfig(
          cfeMarker,
          'cfe with experiments',
          explicitExperimentalFlags: const {
            ExperimentalFlag.digitSeparators: true,
          },
        )
      ]));
}

class ConstantsDataComputer extends CfeDataComputer<String> {
  const ConstantsDataComputer();

  @override
  void computeMemberData(CfeTestResultData testResultData, Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool? verbose}) {
    member.accept(
        new ConstantsDataExtractor(testResultData.compilerResult, actualMap));
  }

  @override
  void computeClassData(CfeTestResultData testResultData, Class cls,
      Map<Id, ActualData<String>> actualMap,
      {bool? verbose}) {
    new ConstantsDataExtractor(testResultData.compilerResult, actualMap)
        .computeForClass(cls);
  }

  @override
  bool get supportsErrors => true;

  /// Returns data corresponding to [error].
  @override
  String computeErrorData(
      CfeTestResultData testResultData, Id id, List<FormattedMessage> errors) {
    return errorsToText(errors);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class ConstantsDataExtractor extends CfeDataExtractor<String> {
  ConstantsDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap)
      : super(compilerResult, actualMap);

  @override
  String? computeNodeValue(Id id, TreeNode node) {
    if (node is ConstantExpression) {
      return constantToText(node.constant);
    }
    return null;
  }
}
