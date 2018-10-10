#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line entry point for Dart Development Compiler (dartdevc), used to
/// compile a collection of dart libraries into a single JS module

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:dev_compiler/src/compiler/shared_command.dart';

Future main(List<String> args) async {
  // Always returns a new modifiable list.
  var parsedArgs = ParsedArguments.from(args);

  if (parsedArgs.isWorker) {
    await _CompilerWorker(parsedArgs).run();
  } else if (parsedArgs.isBatch) {
    await runBatch(parsedArgs);
  } else {
    var result = await compile(parsedArgs);
    exitCode = result.exitCode;
  }
}

/// Runs the compiler worker loop.
class _CompilerWorker extends AsyncWorkerLoop {
  /// The original args supplied to the executable.
  final ParsedArguments _startupArgs;
  InitializedCompilerState _compilerState;

  _CompilerWorker(this._startupArgs) : super();

  /// Performs each individual work request.
  Future<WorkResponse> performRequest(WorkRequest request) async {
    var args = _startupArgs.merge(request.arguments);
    var output = StringBuffer();
    var result = await runZoned(
        () => compile(args, compilerState: _compilerState), zoneSpecification:
            ZoneSpecification(print: (self, parent, zone, message) {
      output.writeln(message.toString());
    }));
    _compilerState = result.compilerState;
    return WorkResponse()
      ..exitCode = result.success ? 0 : 1
      ..output = output.toString();
  }
}

/// Runs dartdevk in batch mode for test.dart.
Future runBatch(ParsedArguments batchArgs) async {
  var totalTests = 0;
  var failedTests = 0;
  var watch = Stopwatch()..start();

  print('>>> BATCH START');

  String line;
  InitializedCompilerState compilerState;

  while ((line = stdin.readLineSync(encoding: utf8))?.isNotEmpty == true) {
    totalTests++;
    var args = batchArgs.merge(line.split(RegExp(r'\s+')));

    String outcome;
    try {
      var result = await compile(args, compilerState: compilerState);
      compilerState = result.compilerState;
      outcome = result.success ? 'PASS' : (result.crashed ? 'CRASH' : 'FAIL');
    } catch (e, s) {
      outcome = 'CRASH';
      print('Unhandled exception:');
      print(e);
      print(s);
    }

    stderr.writeln('>>> EOF STDERR');
    print('>>> TEST $outcome ${watch.elapsedMilliseconds}ms');
  }

  var time = watch.elapsedMilliseconds;
  print('>>> BATCH END (${totalTests - failedTests})/$totalTests ${time}ms');
}
