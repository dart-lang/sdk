// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart' hide Variance;

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/flow_analysis/type_promotion/'
          'data'));
  await runTests<DartType>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const TypePromotionDataComputer(), [cfeNonNullableOnlyConfig]));
}

class TypePromotionDataComputer extends DataComputer<DartType> {
  const TypePromotionDataComputer();

  @override
  DataInterpreter<DartType> get dataValidator =>
      const _TypePromotionDataInterpreter();

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<DartType>> actualMap,
      {bool verbose}) {
    member.accept(new TypePromotionDataExtractor(compilerResult, actualMap));
  }
}

class TypePromotionDataExtractor extends CfeDataExtractor<DartType> {
  TypePromotionDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<DartType>> actualMap)
      : super(compilerResult, actualMap);

  @override
  DartType computeNodeValue(Id id, TreeNode node) {
    if (node is VariableGet) {
      return node.promotedType;
    }
    return null;
  }
}

class _TypePromotionDataInterpreter implements DataInterpreter<DartType> {
  const _TypePromotionDataInterpreter();

  @override
  String getText(DartType actualData, [String indentation]) =>
      typeToText(actualData, TypeRepresentation.analyzerNonNullableByDefault);

  @override
  String isAsExpected(DartType actualData, String expectedData) {
    if (getText(actualData) == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualData';
    }
  }

  @override
  bool isEmpty(DartType actualData) => actualData == null;
}
