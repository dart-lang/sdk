// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show exitCode, stdin;

import 'package:analyzer/error/error.dart';

typedef Future<ErrorSeverity> BatchRunnerHandler(List<String> args);

/// Provides a framework to read command line options from stdin and feed them
/// to a callback.
class BatchRunner {
  final outSink;
  final errorSink;

  BatchRunner(this.outSink, this.errorSink);

  /// Run the tool in 'batch' mode, receiving command lines through stdin and
  /// returning pass/fail status through stdout. This feature is intended for
  /// use in unit testing.
  void runAsBatch(List<String> sharedArgs, BatchRunnerHandler handler) {
    outSink.writeln('>>> BATCH START');
    Stopwatch stopwatch = new Stopwatch();
    stopwatch.start();
    int testsFailed = 0;
    int totalTests = 0;
    ErrorSeverity batchResult = ErrorSeverity.NONE;
    // Read line from stdin.
    Stream<String> cmdLine =
        stdin.transform(UTF8.decoder).transform(new LineSplitter());
    cmdLine.listen((String line) async {
      // Maybe finish.
      if (line.isEmpty) {
        var time = stopwatch.elapsedMilliseconds;
        outSink.writeln(
            '>>> BATCH END (${totalTests - testsFailed}/$totalTests) ${time}ms');
        exitCode = batchResult.ordinal;
      }
      // Prepare arguments.
      var lineArgs = line.split(new RegExp('\\s+'));
      var args = new List<String>();
      args.addAll(sharedArgs);
      args.addAll(lineArgs);
      args.remove('-b');
      args.remove('--batch');
      // Analyze single set of arguments.
      try {
        totalTests++;
        ErrorSeverity result = await handler(args);
        bool resultPass = result != ErrorSeverity.ERROR;
        if (!resultPass) {
          testsFailed++;
        }
        batchResult = batchResult.max(result);
        // Write stderr end token and flush.
        errorSink.writeln('>>> EOF STDERR');
        String resultPassString = resultPass ? 'PASS' : 'FAIL';
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
