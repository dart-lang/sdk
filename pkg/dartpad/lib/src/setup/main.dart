// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';

import 'dart.dart';

Future<void> runSetup(List<String> args) async {
  final runner = CommandRunner<void>(
    'dart run dartpad:setup',
    'Download or build DartPad SDK assets for Dart and Flutter.',
  )..addCommand(SetupDartCommand());

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exit(64);
  }
}
