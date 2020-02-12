// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, StringDataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/fasta/messages.dart' show FormattedMessage;
import 'package:front_end/src/testing/id_testing_helper.dart'
    show
        CfeDataExtractor,
        DataComputer,
        InternalCompilerResult,
        TestConfig,
        createUriForFileName,
        onFailure,
        runTestFor;
import 'package:kernel/ast.dart' show Library;

main(List<String> args) async {
  // Fix default/max major and minor version so we can test it.
  // This config sets it to 2.8.
  TestConfigWithLanguageVersion cfeConfig =
      new TestConfigWithLanguageVersion(cfeMarker, "cfe");

  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<String>(dataDir,
      args: args,
      supportedMarkers: [cfeMarker],
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const LanguageVersioningDataComputer(), [cfeConfig]),
      skipList: [
        // Two language versions specified, the last one is ok and is used here.
        "package_default_version_is_wrong_2",
      ]);
}

class TestConfigWithLanguageVersion extends TestConfig {
  TestConfigWithLanguageVersion(String marker, String name)
      : super(marker, name);

  @override
  void customizeCompilerOptions(CompilerOptions options) {
    options.currentSdkVersion = "2.8";
  }
}

class LanguageVersioningDataComputer extends DataComputer<String> {
  const LanguageVersioningDataComputer();

  void computeLibraryData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Library library,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new LanguageVersioningDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  bool get supportsErrors => true;

  String computeErrorData(TestConfig config, InternalCompilerResult compiler,
      Id id, List<FormattedMessage> errors) {
    return errors.map((m) => m.code.name).join(',');
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class LanguageVersioningDataExtractor extends CfeDataExtractor<String> {
  LanguageVersioningDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap)
      : super(compilerResult, actualMap);

  @override
  String computeLibraryValue(Id id, Library library) {
    StringBuffer sb = new StringBuffer();
    sb.write('languageVersion='
        '${library.languageVersionMajor}.${library.languageVersionMinor}');
    return sb.toString();
  }
}
