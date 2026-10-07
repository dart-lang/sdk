// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';

import 'setup.dart';

Future<void> runDartPadCli(List<String> args) async {
  final runner = CommandRunner<void>(
    'dartpad',
    'CLI utilities for package:dartpad.',
  )..addCommand(SetupCommand());

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exit(64);
  }
}
