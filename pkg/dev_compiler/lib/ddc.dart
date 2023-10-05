// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line entry point for Dart Development Compiler (known as ddc,
/// dartdevc, dev compiler), used to compile a collection of dart libraries into
/// a single JS module.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' show Service, debugger;
import 'dart:io';
import 'dart:isolate';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:kernel/ast.dart' show clearDummyTreeNodesParentPointer;

import 'src/compiler/shared_command.dart';
import 'src/kernel/command.dart';
import 'src/kernel/expression_compiler_worker.dart';

/// The internal entry point for the Dart Dev Compiler.
///
/// [sendPort] may be passed in when started in an isolate. If provided, it is
/// used for bazel worker communication instead of stdin/stdout.
Future internalMain(List<String> args, [SendPort? sendPort]) async {
  // Always returns a new modifiable list.
  var parsedArgs = ParsedArguments.from(args);

  if (parsedArgs.isWorker) {
    var workerConnection = sendPort == null
        ? StdAsyncWorkerConnection()
        : SendPortAsyncWorkerConnection(sendPort);
    await _CompilerWorker(parsedArgs, workerConnection).run();
  } else if (parsedArgs.isBatch) {
    var batch = _BatchHelper();
    await batch._runBatch(parsedArgs);
  } else if (parsedArgs.isExpressionCompiler) {
    await ExpressionCompilerWorker.createAndStart(parsedArgs.rest,
        sendPort: sendPort);
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
  CompilerResult? lastResult;

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
        () => compile(args,
            compilerState: context?.kernelState, inputDigests: inputDigests),
        zoneSpecification:
            ZoneSpecification(print: (self, parent, zone, message) {
      output.writeln(message.toString());
    }));
    return WorkResponse()
      ..exitCode = lastResult!.success ? 0 : 1
      ..output = output.toString();
  }
}

class _BatchHelper {
  Stopwatch watch = Stopwatch();
  CompilerResult? result;
  int totalTests = 0;
  int failedTests = 0;

  /// One can go into "leak test mode" by doing `export DDC_LEAK_TEST="true"`
  /// on the terminal (I think `set DDC_LEAK_TEST="true"` on Windows).
  /// Then one could run test.py, say
  /// ```
  /// python3 tools/test.py -t10000 -c ddc --nnbd weak -m release -r none \
  ///   --enable-asserts --no-use-sdk -j 1 co19/LanguageFeatures/
  /// ```
  /// and attach the leak tester via
  /// ```
  /// out/ReleaseX64/dart \
  ///   pkg/front_end/test/vm_service_for_leak_detection.dart --dart-leak-test
  /// ```
  final bool leakTesting = Platform.environment['DDC_LEAK_TEST'] == 'true';

  /// Runs DDC in Kernel batch mode for test.dart.
  Future _runBatch(ParsedArguments batchArgs) async {
    _workaroundForLeakingBug();
    if (leakTesting) {
      var services =
          await Service.controlWebServer(enable: true, silenceOutput: true);
      File.fromUri(Directory.systemTemp.uri.resolve('./dart_leak_test_uri'))
          .writeAsStringSync(services.serverUri!.toString());
    }

    watch.start();

    print('>>> BATCH START');

    String? line;
    while ((line = stdin.readLineSync(encoding: utf8))?.isNotEmpty == true) {
      await _doIteration(batchArgs, line!);
      _iterationDone();
    }

    var time = watch.elapsedMilliseconds;
    print('>>> BATCH END (${totalTests - failedTests})/$totalTests ${time}ms');
  }

  Future<void> _doIteration(ParsedArguments batchArgs, String line) async {
    totalTests++;
    var args = batchArgs.merge(line.split(RegExp(r'\s+')));

    String outcome;
    try {
      result = await compile(args, compilerState: result?.kernelState);
      outcome = result!.success ? 'PASS' : (result!.crashed ? 'CRASH' : 'FAIL');
    } catch (e, s) {
      // Clear the cache. It might have been left in a weird state.
      result = null;
      outcome = 'CRASH';
      print('Unhandled exception:');
      print(e);
      print(s);
    }

    stderr.writeln('>>> EOF STDERR');
    print('>>> TEST $outcome ${watch.elapsedMilliseconds}ms');
  }

  void _iterationDone() {
    if (leakTesting) {
      // Dummy tree nodes can (currently) leak though the parent pointer.
      // To avoid that (here) (for leak testing) we'll null them out.
      clearDummyTreeNodesParentPointer();

      print('Will now wait');
      debugger();
    }
  }

  /// Workaround for https://github.com/dart-lang/sdk/issues/51317.
  void _workaroundForLeakingBug() {
    try {
      stdin.echoMode;
    } catch (e) {/**/}
    try {
      stdout.writeln();
    } catch (e) {/**/}
    try {
      stderr.writeln();
    } catch (e) {/**/}
  }
}
