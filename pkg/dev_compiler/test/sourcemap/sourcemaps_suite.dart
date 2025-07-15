// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dev_compiler/src/command/arguments.dart';
import 'package:dev_compiler/src/command/command.dart';
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:sourcemap_testing/src/stepping_helper.dart';
import 'package:testing/testing.dart';

import 'common.dart';
import 'ddc_common.dart';

Future<ChainContext> createContext(
  Chain suite,
  Map<String, String> environment,
) async {
  return SourceMapContext(environment);
}

class SourceMapContext extends ChainContextWithCleanupHelper
    implements WithCompilerState {
  final Map<String, String> environment;
  @override
  fe.InitializedCompilerState? compilerState;

  SourceMapContext(this.environment);

  List<Step>? _steps;

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
  final String moduleFormat;
  final bool canary;

  const DevCompilerRunner(
    this.context, {
    this.debugging = false,
    this.moduleFormat = 'es6',
    this.canary = false,
  });

  @override
  Future<Null> run(Uri inputFile, Uri outputFile, Uri outWrapperFile) async {
    Uri sdkJsFile;
    Uri? ddcModuleLoaderFile;
    if (moduleFormat == 'es6') {
      sdkJsFile = findInOutDir('gen/utils/ddc/stable/sdk/es6/dart_sdk.js').uri;
    } else {
      assert(moduleFormat == 'ddc' && canary);
      sdkJsFile = findInOutDir('gen/utils/ddc/canary/sdk/ddc/dart_sdk.js').uri;
      ddcModuleLoaderFile = findInOutDir(
        'dart-sdk/lib/dev_compiler/ddc/ddc_module_loader.js',
      ).uri;
    }

    var ddcSdkSummary = findInOutDir('ddc_outline.dill');
    var packageConfigPath = sdkRoot!.uri
        .resolve('.dart_tool/package_config.json')
        .toFilePath();
    var args = <String>[
      '--batch',
      '--packages=$packageConfigPath',
      '--modules=$moduleFormat',
      if (canary) '--canary',
      '--dart-sdk-summary=${ddcSdkSummary.path}',
      '-o',
      outputFile.toFilePath(),
      inputFile.toFilePath(),
    ];

    var succeeded = false;
    try {
      var result = await compile(
        ParsedArguments.from(args),
        compilerState: context.compilerState,
      );
      context.compilerState =
          result.compilerState as fe.InitializedCompilerState?;
      succeeded = result.success;
    } catch (e, s) {
      print('Unhandled exception:');
      print(e);
      print(s);
    }

    if (!succeeded) {
      var ddc = getDdcDir().uri.resolve('bin/dartdevc.dart');

      throw 'Error from ddc when executing with something like '
          '$dartExecutable ${ddc.toFilePath()} '
          "${args.reduce((value, element) => '$value "$element"')}";
    }

    var jsContent = File.fromUri(outputFile).readAsStringSync();
    File.fromUri(outputFile).writeAsStringSync(
      jsContent.replaceFirst(
        "from 'dart_sdk.js'",
        "from '${uriPathForwardSlashed(sdkJsFile)}'",
      ),
    );

    if (debugging) {
      createHtmlWrapper(
        inputFile: inputFile,
        sdkJsFile: sdkJsFile,
        outputFile: outputFile,
        jsContent: jsContent,
        outputFilename: outputFile.pathSegments.last,
        moduleFormat: moduleFormat,
        canary: canary,
      );
    }

    File.fromUri(outWrapperFile).writeAsStringSync(
      getWrapperContent(
        sdkJsFile: sdkJsFile,
        ddcModuleLoaderFile: ddcModuleLoaderFile,
        inputFile: inputFile,
        outputFile: outputFile,
        moduleFormat: moduleFormat,
        canary: canary,
      ),
    );
  }
}

void main(List<String> arguments) =>
    runMe(arguments, createContext, configurationPath: 'testing.json');
