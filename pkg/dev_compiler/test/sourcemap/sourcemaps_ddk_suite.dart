// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dev_compiler/src/kernel/command.dart';
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:sourcemap_testing/src/stepping_helper.dart';
import 'package:testing/testing.dart';

import 'common.dart';
import 'ddc_common.dart';

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new SourceMapContext(environment);
}

class SourceMapContext extends ChainContextWithCleanupHelper
    implements WithCompilerState {
  final Map<String, String> environment;
  fe.InitializedCompilerState compilerState;

  SourceMapContext(this.environment);

  List<Step> _steps;

  List<Step> get steps {
    return _steps ??= <Step>[
      const Setup(),
      new Compile(new DevCompilerRunner(this, debugging())),
      const StepWithD8(),
      new CheckSteps(debugging()),
    ];
  }

  bool debugging() => environment.containsKey("debug");
}

class DevCompilerRunner implements CompilerRunner {
  final WithCompilerState context;
  final bool debugging;

  const DevCompilerRunner(this.context, [this.debugging = false]);

  Future<Null> run(Uri inputFile, Uri outputFile, Uri outWrapperFile) async {
    Uri outDir = outputFile.resolve(".");
    String outputFilename = outputFile.pathSegments.last;

    File sdkJsFile = findInOutDir("gen/utils/dartdevc/js/es6/dart_sdk.js");
    var jsSdkPath = sdkJsFile.uri;

    File ddcSdkSummary = findInOutDir("gen/utils/dartdevc/kernel/ddc_sdk.dill");

    var ddc = getDdcDir().uri.resolve("bin/dartdevk.dart");

    List<String> args = <String>[
      "--packages=${sdkRoot.uri.resolve(".packages").toFilePath()}",
      "--modules=es6",
      "--dart-sdk-summary=${ddcSdkSummary.path}",
      "-o",
      outputFile.toFilePath(),
      inputFile.toFilePath()
    ];

    bool succeeded = false;
    try {
      var result = await compile(args, compilerState: context.compilerState);
      context.compilerState = result.compilerState;
      succeeded = result.success;
    } catch (e, s) {
      print('Unhandled exception:');
      print(e);
      print(s);
    }

    if (!succeeded) {
      throw "Error from ddc when executing with something like "
          "$dartExecutable ${ddc.toFilePath()} "
          "${args.reduce((value, element) => '$value "$element"')}";
    }

    var jsContent = new File.fromUri(outputFile).readAsStringSync();
    new File.fromUri(outputFile).writeAsStringSync(jsContent.replaceFirst(
        "from 'dart_sdk'", "from '${uriPathForwardSlashed(jsSdkPath)}'"));

    if (debugging) {
      createHtmlWrapper(
          sdkJsFile, outputFile, jsContent, outputFilename, outDir);
    }

    var inputFileName = inputFile.pathSegments.last;
    var inputFileNameNoExt =
        inputFileName.substring(0, inputFileName.lastIndexOf("."));
    new File.fromUri(outWrapperFile).writeAsStringSync(
        getWrapperContent(jsSdkPath, inputFileNameNoExt, outputFilename));
  }
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
