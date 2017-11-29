// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:testing/testing.dart';

import 'common.dart';
import 'ddc_common.dart';

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new SourceMapContext(environment);
}

class SourceMapContext extends ChainContextWithCleanupHelper {
  final Map<String, String> environment;
  SourceMapContext(this.environment);

  List<Step> _steps;

  List<Step> get steps {
    return _steps ??= <Step>[
      const Setup(),
      new Compile(new RunDdc(environment.containsKey("debug"))),
      const StepWithD8(),
      new CheckSteps(environment.containsKey("debug")),
    ];
  }

  bool debugging() => environment.containsKey("debug");
}

class RunDdc implements DdcRunner {
  final bool debugging;

  const RunDdc([this.debugging = false]);

  ProcessResult runDDC(String ddcDir, String inputFile, String outputFile,
      String outWrapperPath) {
    var outDir = path.dirname(outWrapperPath);
    var outFileRelative = new File(path.relative(outputFile, from: outDir)).uri;

    File sdkJsFile = findInOutDir("gen/utils/dartdevc/js/es6/dart_sdk.js");
    var jsSdkPath = new File(path.relative(sdkJsFile.path, from: outDir)).uri;

    File ddcSdkSummary = findInOutDir("gen/utils/dartdevc/ddc_sdk.dill");

    var ddc = path.join(ddcDir, "bin/dartdevk.dart");
    if (!new File(ddc).existsSync()) throw "Couldn't find 'bin/dartdevk.dart'";

    var args = [
      ddc,
      "--modules=es6",
      "--dart-sdk-summary=${ddcSdkSummary.path}",
      "-o",
      "$outputFile",
      "$inputFile"
    ];
    ProcessResult runResult = Process.runSync(dartExecutable, args);
    if (runResult.exitCode != 0) {
      print(runResult.stderr);
      print(runResult.stdout);
      throw "Exit code: ${runResult.exitCode} from ddc when running "
          "$dartExecutable "
          "${args.reduce((value, element) => '$value "$element"')}";
    }

    var jsContent = new File(outputFile).readAsStringSync();
    new File(outputFile).writeAsStringSync(
        jsContent.replaceFirst("from 'dart_sdk'", "from '$jsSdkPath'"));

    if (debugging) {
      createHtmlWrapper(
          ddcDir, sdkJsFile, outputFile, jsContent, outFileRelative, outDir);
    }

    var inputFileName = path.basenameWithoutExtension(inputFile);
    new File(outWrapperPath).writeAsStringSync(
        getWrapperContent(jsSdkPath, inputFileName, outFileRelative));

    return runResult;
  }
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
