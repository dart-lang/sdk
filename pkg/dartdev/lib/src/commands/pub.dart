// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import '../core.dart';
import '../sdk.dart';

class PubCommand extends DartdevCommand<int> {
  PubCommand({bool verbose = false}) : super('pub', 'Work with packages.');

  final ArgParser argParser = ArgParser.allowAnything();

  /// Override [printUsage] for invocations of 'dart help pub' which won't
  /// execute [run] below.  Without this, the 'dart help pub' reports the
  /// command pub with no commands or flags.
  @override
  void printUsage() {
    final command = sdk.pub;
    final args = ['help'];

    log.trace('$command ${args.first}');

    // Call 'pub help'
    // Process.runSync(..) is used since [printUsage] is not an async method,
    // and we want to guarantee that the result (the help text for the console)
    // is printed before command exits.
    final result = Process.runSync(command, args);
    stderr.write(result.stderr);
    stdout.write(result.stdout);
  }

  @override
  FutureOr<int> run() async {
    final command = sdk.pub;
    final args = argResults.arguments;

    log.trace('$command ${args.join(' ')}');

    // Starting in ProcessStartMode.inheritStdio mode means the child process
    // can detect support for ansi chars.
    var process =
        await Process.start(command, args, mode: ProcessStartMode.inheritStdio);

    return process.exitCode;
  }
}
