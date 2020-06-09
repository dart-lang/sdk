// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;
import 'package:front_end/src/base/nnbd_mode.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:kernel/ast.dart';

const String normalMarker = 'normal';
const String verboseMarker = 'verbose';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const TextRepresentationDataComputer(), [
        const TextRepresentationConfig(normalMarker, 'normal'),
        const TextRepresentationConfig(verboseMarker, 'verbose'),
      ]));
}

class TextRepresentationConfig extends TestConfig {
  const TextRepresentationConfig(String marker, String name)
      : super(marker, name,
            experimentalFlags: const {ExperimentalFlag.nonNullable: true},
            nnbdMode: NnbdMode.Strong);

  void customizeCompilerOptions(CompilerOptions options, TestData testData) {
    if (testData.name.endsWith('_opt_out.dart')) {
      options.nnbdMode = NnbdMode.Weak;
    }
  }
}

class TextRepresentationDataComputer extends DataComputer<String> {
  const TextRepresentationDataComputer();

  void computeLibraryData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Library library,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new TextRepresentationDataExtractor(
            compilerResult, actualMap, config.marker == verboseMarker)
        .computeForLibrary(library);
  }

  @override
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    member.accept(new TextRepresentationDataExtractor(
        compilerResult, actualMap, config.marker == verboseMarker));
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class TextRepresentationDataExtractor extends CfeDataExtractor<String> {
  final bool verbose;

  TextRepresentationDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap, this.verbose)
      : super(compilerResult, actualMap);

  @override
  String computeLibraryValue(Id id, Library node) {
    return 'nnbd=${node.isNonNullableByDefault}';
  }

  @override
  String computeNodeValue(Id id, TreeNode node) {
    if (node is ConstantExpression) {
      return node.constant.toConstantText(verbose: verbose);
    } else if (node is VariableDeclaration) {
      DartType type = node.type;
      if (type is FunctionType && type.typedefType != null) {
        return type.typedefType.toTypeText(verbose: verbose);
      } else {
        return type.toTypeText(verbose: verbose);
      }
    }
    return null;
  }
}
