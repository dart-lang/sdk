// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
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
  return SourceMapContext(
    environment: environment,
    moduleFormat: 'es6',
    canary: false,
  );
}

class SourceMapContext extends ChainContextWithCleanupHelper
    implements WithCompilerState {
  final Map<String, String> environment;
  @override
  fe.InitializedCompilerState? compilerState;

  final String moduleFormat;
  final bool canary;

  SourceMapContext({
    required this.environment,
    required this.moduleFormat,
    required this.canary,
  });

  List<Step>? _steps;

  @override
  List<Step> get steps {
    return _steps ??= <Step>[
      const Setup(),
      Compile(
        DevCompilerRunner(
          this,
          debugging: debugging(),
          moduleFormat: moduleFormat,
          canary: canary,
          chrome: true,
        ),
      ),
      const StepWithChrome(),
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

  /// Whether to prepare the output for `runChromeAndStep` (a `bootstrap.html`)
  /// instead of for d8 (a `wrapper.js`).
  final bool chrome;

  const DevCompilerRunner(
    this.context, {
    this.debugging = false,
    this.moduleFormat = 'es6',
    this.canary = false,
    this.chrome = false,
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
    // d8 loads the SDK straight from disk, while Chrome loads it from the
    // server started by `runChromeAndStep`.
    var sdkJsImport = chrome
        ? chromeUrlPathForSdkFile(sdkJsFile.toFilePath())
        : uriPathForwardSlashed(sdkJsFile);
    File.fromUri(outputFile).writeAsStringSync(
      jsContent.replaceFirst("from 'dart_sdk.js'", "from '$sdkJsImport'"),
    );

    if (chrome) {
      File.fromUri(outputFile.resolve('bootstrap.html')).writeAsStringSync(
        getBootstrapHtmlContent(
          sdkJsFile: sdkJsFile,
          ddcModuleLoaderFile: ddcModuleLoaderFile,
          inputFile: inputFile,
          outputFile: outputFile,
          moduleFormat: moduleFormat,
          canary: canary,
        ),
      );
      if (debugging) {
        // `http_server.dart` serves the same `/root_build/` and `/root_dart/`
        // paths that `runChromeAndStep` uses, so the page works as is.
        print(
          'To step through this test in a browser, run\n\n'
          '  dart ${sdkRoot!.path}/pkg/test_runner/bin/http_server.dart '
          '-p 39550 --network 127.0.0.1 '
          '--build-directory=${outputFile.resolve('.').toFilePath()}\n\n'
          'then open http://127.0.0.1:39550/root_build/bootstrap.html, set '
          'breakpoints in DevTools, and call scheduleMain() in the console.\n'
          'The directory is only kept if the test fails.',
        );
      }
    } else {
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
}

void main(List<String> arguments) =>
    runMe(arguments, createContext, configurationPath: 'testing.json');
