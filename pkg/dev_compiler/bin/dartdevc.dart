#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Command line entry point for Dart Development Compiler (dartdevc), used to
/// compile a collection of dart libraries into a single JS module

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:dev_compiler/src/compiler/shared_command.dart';
import 'package:dev_compiler/src/kernel/expression_compiler_worker.dart';

/// The entry point for the Dart Dev Compiler.
///
/// [sendPort] may be passed in when started in an isolate. If provided, it is
/// used for bazel worker communication instead of stdin/stdout.
Future main(List<String> args, [SendPort sendPort]) async {
  // Always returns a new modifiable list.
  var parsedArgs = ParsedArguments.from(args);

  if (parsedArgs.isWorker) {
    var workerConnection = sendPort == null
        ? StdAsyncWorkerConnection()
        : SendPortAsyncWorkerConnection(sendPort);
    await _CompilerWorker(parsedArgs, workerConnection).run();
  } else if (parsedArgs.isBatch) {
    await runBatch(parsedArgs);
  } else if (parsedArgs.isExpressionCompiler) {
    if (sendPort != null) {
      var receivePort = ReceivePort();
      sendPort.send(receivePort.sendPort);
      var worker = await ExpressionCompilerWorker.createFromArgs(
          parsedArgs.rest,
          requestStream: receivePort.cast<Map<String, dynamic>>(),
          sendResponse: sendPort.send);
      await worker.start();
      receivePort.close();
    } else {
      var worker =
          await ExpressionCompilerWorker.createFromArgs(parsedArgs.rest);
      await worker.start();
    }
  } else {
    var result = await compile(parsedArgs);
    exitCode = result.exitCode;
  }
}

/// Runs the compiler worker loop.
class _CompilerWorker extends AsyncWorkerLoop {
  /// The original args supplied to the executable.
  final ParsedArguments _startupArgs;

  _CompilerWorker(this._startupArgs, AsyncWorkerConnection workerConnection)
      : super(connection: workerConnection);

  /// Keeps track of our last compilation result so it can potentially be
  /// re-used in a worker.
  CompilerResult lastResult;

  /// Performs each individual work request.
  @override
  Future<WorkResponse> performRequest(WorkRequest request) async {
    var args = _startupArgs.merge(request.arguments);
    var output = StringBuffer();
    var context = args.reuseResult ? lastResult : null;

    /// Build a map of uris to digests.
    final inputDigests = <Uri, List<int>>{};
    for (var input in request.inputs) {
      inputDigests[sourcePathToUri(input.path)] = input.digest;
    }

    lastResult = await runZoned(
        () =>
            compile(args, previousResult: context, inputDigests: inputDigests),
        zoneSpecification:
            ZoneSpecification(print: (self, parent, zone, message) {
      output.writeln(message.toString());
    }));
    return WorkResponse()
      ..exitCode = lastResult.success ? 0 : 1
      ..output = output.toString();
  }
}

/// Runs DDC in Kernel batch mode for test.dart.
Future runBatch(ParsedArguments batchArgs) async {
  var totalTests = 0;
  var failedTests = 0;
  var watch = Stopwatch()..start();

  print('>>> BATCH START');

  String line;
  CompilerResult result;

  while ((line = stdin.readLineSync(encoding: utf8))?.isNotEmpty == true) {
    totalTests++;
    var args = batchArgs.merge(line.split(RegExp(r'\s+')));

    String outcome;
    try {
      result = await compile(args, previousResult: result);
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
