// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import '../core.dart';
import '../sdk.dart';

class RunCommand extends DartdevCommand<int> {
  final ArgParser argParser = ArgParser.allowAnything();

  RunCommand({bool verbose = false}) : super('run', '''
Run a Dart app or package.

dart run <file path>   run the specified Dart file
dart run package:foo   run the Dart file specified by some <package>:<executable>''');

  @override
  String get invocation => '${super.invocation} <dart file | package target>';

  @override
  void printUsage() {
    // Override [printUsage] for invocations of 'dart help run' which won't
    // execute [run] below.  Without this, the 'dart help run' reports the
    // command pub with no commands or flags.
    final command = sdk.dart;
    final args = ['--help'];

    log.trace('$command ${args.first}');

    // Call 'dart --help'
    // Process.runSync(..) is used since [printUsage] is not an async method,
    // and we want to guarantee that the result (the help text for the console)
    // is printed before command exits.
    final result = Process.runSync(command, args);
    stderr.write(result.stderr);
    stdout.write(result.stdout);
  }

  @override
  FutureOr<int> run() async {
    // the command line arguments after 'run'
    final args = argResults.arguments;

    // TODO(jwren) Implement support for pubspec executables, see
    //  https://dart.dev/tools/pub/pubspec#executables

    // Starting in ProcessStartMode.inheritStdio mode means the child process
    // can detect support for ansi chars.
    var process = await Process.start(sdk.dart, args,
        mode: ProcessStartMode.inheritStdio);
    return process.exitCode;
  }
}
