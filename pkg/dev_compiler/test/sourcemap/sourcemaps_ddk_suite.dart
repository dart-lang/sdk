// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

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
  return SourceMapContext(environment);
}

class SourceMapContext extends ChainContextWithCleanupHelper
    implements WithCompilerState {
  final Map<String, String> environment;
  @override
  fe.InitializedCompilerState compilerState;

  SourceMapContext(this.environment);

  List<Step> _steps;

  @override
  List<Step> get steps {
    return _steps ??= <Step>[
      const Setup(),
      Compile(DevCompilerRunner(this, debugging: debugging())),
      const StepWithD8(),
      CheckSteps(debugging()),
    ];
  }

  @override
  bool debugging() => environment.containsKey('debug');
}

class DevCompilerRunner implements CompilerRunner {
  final WithCompilerState context;
  final bool debugging;

  const DevCompilerRunner(this.context, {this.debugging = false});

  @override
  Future<Null> run(Uri inputFile, Uri outputFile, Uri outWrapperFile) async {
    var outDir = outputFile.resolve('.');
    var outputFilename = outputFile.pathSegments.last;

    var sdkJsFile = findInOutDir('gen/utils/dartdevc/kernel/es6/dart_sdk.js');
    var jsSdkPath = sdkJsFile.uri;

    var ddcSdkSummary = findInOutDir('ddc_outline.dill');

    var args = <String>[
      "--packages=${sdkRoot.uri.resolve(".packages").toFilePath()}",
      '--modules=es6',
      '--dart-sdk-summary=${ddcSdkSummary.path}',
      '-o',
      outputFile.toFilePath(),
      inputFile.toFilePath()
    ];

    var succeeded = false;
    try {
      var result = await compile(args, compilerState: context.compilerState);
      context.compilerState =
          result.compilerState as fe.InitializedCompilerState;
      succeeded = result.success;
    } catch (e, s) {
      print('Unhandled exception:');
      print(e);
      print(s);
    }

    if (!succeeded) {
      var ddc = getDdcDir().uri.resolve('bin/dartdevc.dart');

      throw 'Error from ddc when executing with something like '
          '$dartExecutable ${ddc.toFilePath()} --kernel '
          "${args.reduce((value, element) => '$value "$element"')}";
    }

    var jsContent = File.fromUri(outputFile).readAsStringSync();
    File.fromUri(outputFile).writeAsStringSync(jsContent.replaceFirst(
        "from 'dart_sdk.js'", "from '${uriPathForwardSlashed(jsSdkPath)}'"));

    if (debugging) {
      createHtmlWrapper(
          sdkJsFile, outputFile, jsContent, outputFilename, outDir);
    }

    var inputPath = inputFile.path;
    inputPath = inputPath.substring(0, inputPath.lastIndexOf('.'));
    var inputFileNameNoExt = pathToJSIdentifier(inputPath);
    File.fromUri(outWrapperFile).writeAsStringSync(
        getWrapperContent(jsSdkPath, inputFileNameNoExt, outputFilename));
  }
}

void main(List<String> arguments) =>
    runMe(arguments, createContext, configurationPath: 'testing.json');
