// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show exitCode, stdin;

import 'package:analyzer/error/error.dart';

typedef BatchRunnerHandler = Future<ErrorSeverity> Function(List<String> args);

/// Provides a framework to read command line options from stdin and feed them
/// to a callback.
class BatchRunner {
  final StringSink outSink;
  final StringSink errorSink;

  BatchRunner(this.outSink, this.errorSink);

  /// Run the tool in 'batch' mode, receiving command lines through stdin and
  /// returning pass/fail status through stdout. This feature is intended for
  /// use in unit testing.
  void runAsBatch(List<String> sharedArgs, BatchRunnerHandler handler) {
    outSink.writeln('>>> BATCH START');
    var stopwatch = Stopwatch();
    stopwatch.start();
    var testsFailed = 0;
    var totalTests = 0;
    var batchResult = ErrorSeverity.NONE;
    // Read line from stdin.
    var cmdLine = stdin.transform(utf8.decoder).transform(LineSplitter());
    cmdLine.listen((String line) async {
      // TODO(brianwilkerson) Determine whether this await is necessary.
      await null;
      // Maybe finish.
      if (line.isEmpty) {
        var time = stopwatch.elapsedMilliseconds;
        outSink.writeln(
            '>>> BATCH END (${totalTests - testsFailed}/$totalTests) ${time}ms');
        exitCode = batchResult.ordinal;
      }
      // Prepare arguments.
      var lineArgs = line.split(RegExp('\\s+'));
      var args = <String>[];
      args.addAll(sharedArgs);
      args.addAll(lineArgs);
      args.remove('-b');
      args.remove('--batch');
      // Analyze single set of arguments.
      try {
        totalTests++;
        var result = await handler(args);
        var resultPass = result != ErrorSeverity.ERROR;
        if (!resultPass) {
          testsFailed++;
        }
        batchResult = batchResult.max(result);
        // Write stderr end token and flush.
        errorSink.writeln('>>> EOF STDERR');
        var resultPassString = resultPass ? 'PASS' : 'FAIL';
        outSink.writeln(
            '>>> TEST $resultPassString ${stopwatch.elapsedMilliseconds}ms');
      } catch (e, stackTrace) {
        errorSink.writeln(e);
        errorSink.writeln(stackTrace);
        errorSink.writeln('>>> EOF STDERR');
        outSink.writeln('>>> TEST CRASH');
      }
    });
  }
}
