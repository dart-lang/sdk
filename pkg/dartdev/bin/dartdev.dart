// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartdev/dartdev.dart';

/// The entry point for dartdev.
main(List<String> args) async {
  final runner = DartdevRunner(args);
  try {
    dynamic result = await runner.run(args);
    exit(result is int ? result : 0);
  } catch (e) {
    if (e is UsageException) {
      stderr.writeln('$e');
      exit(64);
    } else {
      stderr.writeln('$e');
      exit(1);
    }
  }
}
