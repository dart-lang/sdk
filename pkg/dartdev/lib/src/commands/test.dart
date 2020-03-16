// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import '../core.dart';
import '../sdk.dart';

class TestCommand extends DartdevCommand<int> {
  TestCommand({bool verbose = false}) : super('test', 'todo: .');

  final ArgParser argParser = ArgParser.allowAnything();

  @override
  FutureOr<int> run() async {
    final command = sdk.pub;
    final args = argResults.arguments.toList();

    args.insertAll(0, ['run', 'test']);

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

${ansi.emphasized('dev_dependencies:\n  test: any')}

See https://pub.dev/packages/test#-installing-tab- for more information on
adding package:test, and https://dart.dev/guides/testing for general
information on testing.''');
  }
}
