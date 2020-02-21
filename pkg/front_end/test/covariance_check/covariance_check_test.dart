// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest:
          runTestFor(const CovarianceCheckDataComputer(), [defaultCfeConfig]));
}

class CovarianceCheckDataComputer extends DataComputer<String> {
  const CovarianceCheckDataComputer();

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  void computeLibraryData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Library library,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new CovarianceCheckDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    member.accept(new CovarianceCheckDataExtractor(compilerResult, actualMap));
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class CovarianceCheckDataExtractor extends CfeDataExtractor<String> {
  CovarianceCheckDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap)
      : super(compilerResult, actualMap);

  @override
  String computeNodeValue(Id id, TreeNode node) {
    if (node is AsExpression && node.isCovarianceCheck) {
      return typeToText(node.type);
    }
    return null;
  }
}
