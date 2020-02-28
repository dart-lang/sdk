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
