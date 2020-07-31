// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import '../core.dart';
import '../experiments.dart';
import '../sdk.dart';

class TestCommand extends DartdevCommand<int> {
  TestCommand() : super('test', 'Runs tests in this project.');

  @override
  final ArgParser argParser = ArgParser.allowAnything();

  @override
  void printUsage() {
    final command = sdk.pub;
    final args = ['run', 'test', '--help'];

    log.trace('$command ${args.join(' ')}');

    final result = Process.runSync(command, args);
    if (result.stderr.isNotEmpty) {
      stderr.write(result.stderr);
    }
    if (result.stdout.isNotEmpty) {
      stdout.write(result.stdout);
    }

    // "Could not find package "test". Did you forget to add a dependency?"
    if (result.exitCode == 65 && project.hasPackageConfigFile) {
      if (!project.packageConfig.hasDependency('test')) {
        _printPackageTestInstructions();
      }
    }
  }

  @override
  FutureOr<int> run() async {
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

    // Starting in ProcessStartMode.inheritStdio mode means the child process
    // can detect support for ansi chars.
    var process =
        await Process.start(command, args, mode: ProcessStartMode.inheritStdio);

    int exitCode = await process.exitCode;

    // "Could not find package "test". Did you forget to add a dependency?"
    if (exitCode == 65 && project.hasPackageConfigFile) {
      if (!project.packageConfig.hasDependency('test')) {
        _printPackageTestInstructions();
      }
    }

    return exitCode;
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
