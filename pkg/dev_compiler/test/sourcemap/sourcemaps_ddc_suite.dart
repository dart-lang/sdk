// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dev_compiler/src/analyzer/command.dart';
import 'package:testing/testing.dart';

import 'common.dart';
import 'ddc_common.dart';

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return SourceMapContext(environment);
}

class SourceMapContext extends ChainContextWithCleanupHelper {
  final Map<String, String> environment;
  SourceMapContext(this.environment);

  List<Step> _steps;

  List<Step> get steps => _steps ??= <Step>[
        const Setup(),
        Compile(DevCompilerRunner(environment.containsKey("debug"))),
        const StepWithD8(),
        CheckSteps(environment.containsKey("debug")),
      ];

  bool debugging() => environment.containsKey("debug");
}

class DevCompilerRunner implements CompilerRunner {
  final bool debugging;

  const DevCompilerRunner([this.debugging = false]);

  Future<Null> run(Uri inputFile, Uri outputFile, Uri outWrapperFile) async {
    Uri outDir = outputFile.resolve(".");
    String outputFilename = outputFile.pathSegments.last;

    File sdkJsFile = findInOutDir("gen/utils/dartdevc/js/es6/dart_sdk.js");
    var jsSdkPath = sdkJsFile.uri;

    File ddcSdkSummary = findInOutDir("gen/utils/dartdevc/ddc_sdk.sum");

    var ddc = getDdcDir().uri.resolve("bin/dartdevc.dart");

    List<String> args = <String>[
      "--modules=es6",
      "--dart-sdk-summary=${ddcSdkSummary.path}",
      "--library-root",
      outDir.toFilePath(),
      "--module-root",
      outDir.toFilePath(),
      "-o",
      outputFile.toFilePath(),
      inputFile.toFilePath()
    ];

    var exitCode = compile(args);
    if (exitCode != 0) {
      throw "Exit code: $exitCode from ddc when running something like "
          "$dartExecutable ${ddc.toFilePath()} "
          "${args.reduce((value, element) => '$value "$element"')}";
    }

    var jsContent = File.fromUri(outputFile).readAsStringSync();
    File.fromUri(outputFile).writeAsStringSync(jsContent.replaceFirst(
        "from 'dart_sdk'", "from '${uriPathForwardSlashed(jsSdkPath)}'"));

    if (debugging) {
      createHtmlWrapper(
          sdkJsFile, outputFile, jsContent, outputFilename, outDir);
    }

    var inputFileName = inputFile.pathSegments.last;
    var inputFileNameNoExt =
        inputFileName.substring(0, inputFileName.lastIndexOf("."));
    File.fromUri(outWrapperFile).writeAsStringSync(
        getWrapperContent(jsSdkPath, inputFileNameNoExt, outputFilename));
  }
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
