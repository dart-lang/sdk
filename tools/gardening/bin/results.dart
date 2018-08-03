// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:args/command_runner.dart';
import 'results_get.dart';
import 'results_list.dart';
import 'results_status.dart';

var runner = new CommandRunner("results", "Results from tests.")
  ..addCommand(new GetCommand())
  ..addCommand(new ListCommand())
  ..addCommand(new StatusCommand());

main(List<String> args) {
  runner.run(args).catchError((error) {
    if (error is! UsageException) throw error;
    print(error);
    exit(64); // Exit code 64 indicates a usage error.
  });
}
