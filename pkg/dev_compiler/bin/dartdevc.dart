#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line entry point for Dart Development Compiler (dartdevc), used to
/// compile a collection of dart libraries into a single JS module

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/command_line/arguments.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:bazel_worker/bazel_worker.dart';
import 'package:dev_compiler/src/compiler/command.dart';

Future main(List<String> args) async {
  // Always returns a new modifiable list.
  args = preprocessArgs(PhysicalResourceProvider.INSTANCE, args);

  if (args.contains('--persistent_worker')) {
    await new _CompilerWorker(args..remove('--persistent_worker')).run();
  } else if (args.isNotEmpty && args.last == "--batch") {
    await runBatch(args.sublist(0, args.length - 1));
  } else {
    exitCode = compile(args);
  }
}

/// Runs the compiler worker loop.
class _CompilerWorker extends AsyncWorkerLoop {
  /// The original args supplied to the executable.
  final List<String> _startupArgs;

  _CompilerWorker(this._startupArgs) : super();

  /// Performs each individual work request.
  Future<WorkResponse> performRequest(WorkRequest request) async {
    var args = _startupArgs.toList()..addAll(request.arguments);

    var output = new StringBuffer();
    var exitCode = compile(args, printFn: output.writeln);
    AnalysisEngine.instance.clearCaches();
    return new WorkResponse()
      ..exitCode = exitCode
      ..output = output.toString();
  }
}

runBatch(List<String> batchArgs) async {
  int totalTests = 0;
  int testsFailed = 0;
  var watch = new Stopwatch()..start();
  print('>>> BATCH START');
  String line;
  while ((line = stdin.readLineSync(encoding: UTF8)).isNotEmpty) {
    totalTests++;
    var args = batchArgs.toList()..addAll(line.split(new RegExp(r'\s+')));

    // We don't try/catch here, since `compile` should handle that.
    var compileExitCode = compile(args);
    AnalysisEngine.instance.clearCaches();
    stderr.writeln('>>> EOF STDERR');
    var outcome = compileExitCode == 0
        ? 'PASS'
        : compileExitCode == 70 ? 'CRASH' : 'FAIL';
    print('>>> TEST $outcome ${watch.elapsedMilliseconds}ms');
  }
  int time = watch.elapsedMilliseconds;
  print('>>> BATCH END '
      '(${totalTests - testsFailed})/$totalTests ${time}ms');
}
