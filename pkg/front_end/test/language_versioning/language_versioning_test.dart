// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, StringDataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/language_version.dart' as lv;
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

import 'package:kernel/ast.dart' show Component, Library;

main(List<String> args) async {
  // Fix default/max major and minor version so we can test it.
  // This config sets it to 2.8.
  TestConfigWithLanguageVersion cfeConfig =
      new TestConfigWithLanguageVersion(cfeMarker, "cfe");

  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const LanguageVersioningDataComputer(), [cfeConfig]),
      skipList: [
        // Two language versions specified, the last one is ok and is used here.
        "package_default_version_is_wrong_2",
      ]);
}

// Ugly hack.
CompilerOptions stashedOptions;

class TestConfigWithLanguageVersion extends TestConfig {
  TestConfigWithLanguageVersion(String marker, String name)
      : super(marker, name);

  @override
  void customizeCompilerOptions(CompilerOptions options, TestData testData) {
    stashedOptions = options;
    options.currentSdkVersion = "2.8";

    File f = new File.fromUri(testData.testFileUri.resolve("test.options"));
    if (f.existsSync()) {
      List<String> lines = f.readAsStringSync().split("\n");
      for (String line in lines) {
        const String packages = "--packages=";
        if (line == "" || line.startsWith("#")) continue;
        if (line.startsWith(packages)) {
          String value = line.substring(packages.length);
          options.packagesFileUri = testData.entryPoint.resolve(value);
          print("Setting package file uri to ${options.packagesFileUri}");
        } else {
          throw "Unsupported: $line";
        }
      }
    }
  }
}

class LanguageVersioningDataComputer extends DataComputer<String> {
  const LanguageVersioningDataComputer();

  Future<void> inspectComponent(Component component) async {
    for (Library library in component.libraries) {
      if (library.importUri.scheme == "dart") continue;
      lv.LanguageVersionForUri lvFile =
          await lv.languageVersionForUri(library.fileUri, stashedOptions);
      lv.LanguageVersionForUri lvImportUri =
          await lv.languageVersionForUri(library.importUri, stashedOptions);
      if ((lvFile.major != lvImportUri.major ||
              lvFile.major != library.languageVersionMajor) ||
          (lvFile.minor != lvImportUri.minor ||
              lvFile.minor != library.languageVersionMinor)) {
        throw """
Language version disagreement:
Library: ${library.languageVersionMajor}.${library.languageVersionMinor}
Language version API (file URI): ${lvFile.major}.${lvFile.minor}
Language version API (import URI): ${lvImportUri.major}.${lvImportUri.minor}
""";
      }
    }
  }

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
    return "languageVersion="
        "${library.languageVersionMajor}"
        "."
        "${library.languageVersionMinor}";
  }
}
