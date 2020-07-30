// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';

import '../core.dart';
import '../experiments.dart';
import '../sdk.dart';
import '../vm_interop_handler.dart';

class TestCommand extends DartdevCommand<int> {
  TestCommand() : super('test', 'Runs tests in this project.');

  @override
  final ArgParser argParser = ArgParser.allowAnything();

  @override
  void printUsage() {
    if (!Sdk.checkArtifactExists(sdk.pub)) {
      return;
    }
    if ((project.packageConfig != null) &&
        !project.packageConfig.hasDependency('test')) {
      _printPackageTestInstructions();
    }
    final command = sdk.pub;
    final args = ['run', 'test', '--help'];

    log.trace('$command ${args.join(' ')}');
    VmInteropHandler.run(command, args);
  }

  @override
  FutureOr<int> run() async {
    if (!Sdk.checkArtifactExists(sdk.pub)) {
      return 255;
    }
    // "Could not find package "test". Did you forget to add a dependency?"
    if (project.hasPackageConfigFile) {
      if ((project.packageConfig != null) &&
          !project.packageConfig.hasDependency('test')) {
        _printPackageTestInstructions();
        return 65;
      }
    }

    final command = sdk.pub;
    final testArgs = argResults.arguments.toList();

    final args = [
      'run',
      if (wereExperimentsSpecified)
        '--$experimentFlagName=${specifiedExperiments.join(',')}',
      'test',
      ...testArgs,
    ];

    log.trace('$command ${args.join(' ')}');
    VmInteropHandler.run(command, args);
    return 0;
  }

  void _printPackageTestInstructions() {
    log.stdout('');

    final ansi = log.ansi;

    log.stdout('''
In order to run tests, you need to add a dependency on package:test in your
pubspec.yaml file:

${ansi.emphasized('dev_dependencies:\n  test: ^1.0.0')}

See https://pub.dev/packages/test#-installing-tab- for more information on
adding package:test, and https://dart.dev/guides/testing for general
information on testing.''');
  }
}
