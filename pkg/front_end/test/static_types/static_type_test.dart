// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:front_end/src/fasta/kernel/kernel_api.dart';
import 'package:front_end/src/testing/id.dart' show ActualData, Id;
import 'package:front_end/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:front_end/src/testing/id_testing.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: sharedMarkers,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const StaticTypeDataComputer(), [defaultCfeConfig]));
}

class StaticTypeDataComputer extends DataComputer<String> {
  const StaticTypeDataComputer();

  @override
  void computeMemberData(InternalCompilerResult compilerResult, Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    member.accept(new StaticTypeDataExtractor(compilerResult, actualMap));
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class StaticTypeDataExtractor extends CfeDataExtractor<String> {
  final TypeEnvironment _environment;

  StaticTypeDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap)
      : _environment = new TypeEnvironment(
            new CoreTypes(compilerResult.component),
            new ClassHierarchy(compilerResult.component)),
        super(compilerResult, actualMap);

  @override
  String computeNodeValue(Id id, TreeNode node) {
    if (node is Expression) {
      DartType type = node.getStaticType(_environment);
      return typeToText(type);
    } else if (node is Arguments) {
      if (node.types.isNotEmpty) {
        return '<${node.types.map(typeToText).join(',')}>';
      }
    }
    return null;
  }

  ActualData<String> mergeData(
      ActualData<String> value1, ActualData<String> value2) {
    if (value1.object is NullLiteral && value2.object is! NullLiteral) {
      // Skip `null` literals from null-aware operations.
      return value2;
    } else if (value1.object is! NullLiteral && value2.object is NullLiteral) {
      // Skip `null` literals from null-aware operations.
      return value1;
    }
    return null;
  }
}
