// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:_fe_analyzer_shared/src/testing/metadata_helper.dart';
import 'package:front_end/src/base/common.dart';
import 'package:front_end/src/builder/member_builder.dart';
import 'package:front_end/src/source/source_member_builder.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart';
import 'package:front_end/src/builder/metadata_builder.dart';

Future<void> main(List<String> args) async {
  retainDataForTesting = true;
  computeSharedExpressionForTesting = true;

  Directory dataDir = new Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/metadata/data'));
  await runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const MetadataDataComputer(), [defaultCfeConfig]),
      preserveWhitespaceInAnnotations: true);
}

class MetadataDataComputer extends CfeDataComputer<String> {
  const MetadataDataComputer();

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();

  @override
  bool get supportsErrors => true;

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(CfeTestResultData testResultData, Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool? verbose}) {
    member.accept(
        new MetadataDataExtractor(testResultData.compilerResult, actualMap));
  }
}

class MetadataDataExtractor extends CfeDataExtractor<String> {
  MetadataDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap)
      : super(compilerResult, actualMap);

  @override
  String? computeMemberValue(Id id, Member member) {
    MemberBuilder? memberBuilder = lookupMemberBuilder(compilerResult, member);
    if (memberBuilder is SourceMemberBuilder) {
      Iterable<MetadataBuilder>? metadata = memberBuilder.metadataForTesting;
      if (metadata != null) {
        List<String> list = [];
        for (MetadataBuilder metadataBuilder in metadata) {
          list.add(expressionToText(unwrap(metadataBuilder.expression!)));
        }
        return '\n${list.join('\n')}';
      }
    }
    return null;
  }
}
