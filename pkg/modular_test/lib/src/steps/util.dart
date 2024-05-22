// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:modular_test/src/io_pipeline.dart';
import 'package:modular_test/src/suite.dart';

/// Checks the [exitCode] of [result], and forwards its [stdout] and [stderr] if
/// the exit code is non-zero or [verbose] is `true`.
///
/// Also throws an error if the [exitCode] is non-zero.
void checkExitCode(
    ProcessResult result, IOModularStep step, Module module, bool verbose) {
  if (result.exitCode != 0 || verbose) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }
  if (result.exitCode != 0) {
    throw '${step.runtimeType} failed on $module:\n\n'
        'stdout:\n${result.stdout}\n\n'
        'stderr:\n${result.stderr}';
  }
}

/// Runs [command] with [arguments] in [workingDirectory], and if [verbose] is
/// `true` then it logs the full command.
Future<ProcessResult> runProcess(String command, List<String> arguments,
    String workingDirectory, bool verbose) {
  if (verbose) {
    print('command:\n$command ${arguments.join(' ')} from $workingDirectory');
  }
  return Process.run(command, arguments, workingDirectory: workingDirectory);
}
