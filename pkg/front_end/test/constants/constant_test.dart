// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:front_end/src/testing/id.dart' show ActualData, Id;
import 'package:front_end/src/testing/id_testing.dart'
    show DataInterpreter, StringDataInterpreter, runTests;
import 'package:front_end/src/testing/id_testing.dart';
import 'package:front_end/src/testing/id_testing_helper.dart'
    show
        CfeDataExtractor,
        InternalCompilerResult,
        DataComputer,
        FormattedMessage,
        createUriForFileName,
        defaultCfeConfig,
        onFailure,
        runTestFor;
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart' show Class, Member, TreeNode;
import 'package:kernel/ast.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: sharedMarkers,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const ConstantsDataComputer(), [defaultCfeConfig]));
}

class ConstantsDataComputer extends DataComputer<String> {
  const ConstantsDataComputer();

  @override
  void computeMemberData(InternalCompilerResult compilerResult, Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    member.accept(new ConstantsDataExtractor(compilerResult, actualMap));
  }

  @override
  void computeClassData(InternalCompilerResult compilerResult, Class cls,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new ConstantsDataExtractor(compilerResult, actualMap).computeForClass(cls);
  }

  @override
  bool get supportsErrors => true;

  /// Returns data corresponding to [error].
  String computeErrorData(
      InternalCompilerResult compiler, Id id, List<FormattedMessage> errors) {
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
  String computeNodeValue(Id id, TreeNode node) {
    if (node is ConstantExpression) {
      return constantToText(node.constant);
    }
    return null;
  }
}
