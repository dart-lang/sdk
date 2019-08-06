// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:front_end/src/fasta/messages.dart' show FormattedMessage;
import 'package:front_end/src/testing/id.dart' show ActualData, Id;
import 'package:front_end/src/testing/id_testing.dart'
    show DataInterpreter, StringDataInterpreter, runTests;
import 'package:front_end/src/testing/id_testing.dart';
import 'package:front_end/src/testing/id_testing_helper.dart'
    show
        CfeDataExtractor,
        CompilerResult,
        DataComputer,
        defaultCfeConfig,
        createUriForFileName,
        onFailure,
        runTestFor;
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart' show Library;

main(List<String> args) async {
  // Fix default/max major and minor version so we can test it.
  Library.defaultLangaugeVersionMajor = 2;
  Library.defaultLangaugeVersionMinor = 4;

  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: [cfeMarker],
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const LanguageVersioningDataComputer(), [defaultCfeConfig]));
}

class LanguageVersioningDataComputer extends DataComputer<String> {
  const LanguageVersioningDataComputer();

  void computeLibraryData(CompilerResult compilerResult, Library library,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new LanguageVersioningDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library, useFileUri: true);
  }

  @override
  bool get supportsErrors => true;

  String computeErrorData(
      CompilerResult compiler, Id id, List<FormattedMessage> errors) {
    return errorsToText(errors);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class LanguageVersioningDataExtractor extends CfeDataExtractor<String> {
  LanguageVersioningDataExtractor(
      CompilerResult compilerResult, Map<Id, ActualData<String>> actualMap)
      : super(compilerResult, actualMap);

  @override
  String computeLibraryValue(Id id, Library library) {
    StringBuffer sb = new StringBuffer();
    sb.write('languageVersion='
        '${library.languageVersionMajor}.${library.languageVersionMinor}');
    return sb.toString();
  }
}
