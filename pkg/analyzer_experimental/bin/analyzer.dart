#!/usr/bin/env dart

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The entry point for the analyzer. */
library analyzer;

import 'dart:async';
import 'dart:io';

import 'package:analyzer_experimental/src/generated/java_io.dart';
import 'package:analyzer_experimental/src/generated/engine.dart';
import 'package:analyzer_experimental/src/generated/error.dart';
import 'package:analyzer_experimental/src/generated/source_io.dart';
import 'package:analyzer_experimental/src/generated/sdk.dart';
import 'package:analyzer_experimental/src/generated/sdk_io.dart';
import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/element.dart';
import 'package:analyzer_experimental/options.dart';

import 'package:analyzer_experimental/src/analyzer_impl.dart';
import 'package:analyzer_experimental/src/error_formatter.dart';

void main() {
  var args = new Options().arguments;
  var options = CommandLineOptions.parse(args);
  if (options.shouldBatch) {
    BatchRunner.runAsBatch(args, (List<String> args) {
      var options = CommandLineOptions.parse(args);
      return _runAnalyzer(options);
    });
  } else {
    ErrorSeverity result = _runAnalyzer(options);
    exit(result.ordinal);
  }
}

ErrorSeverity _runAnalyzer(CommandLineOptions options) {
  if (!options.machineFormat) {
    stdout.writeln("Analyzing ${options.sourceFiles}...");
  }
  ErrorSeverity allResult = ErrorSeverity.NONE;
  String sourcePath = options.sourceFiles[0];
  sourcePath = sourcePath.trim();
  // check that file exists
  if (!new File(sourcePath).existsSync()) {
    print('File not found: $sourcePath');
    return ErrorSeverity.ERROR;
  }
  // check that file is Dart file
  if (!AnalysisEngine.isDartFileName(sourcePath)) {
    print('$sourcePath is not a Dart file');
    return ErrorSeverity.ERROR;
  }
  // do analyze
  ErrorFormatter formatter = new ErrorFormatter(options.machineFormat ? stderr : stdout, options);
  AnalyzerImpl analyzer = new AnalyzerImpl(options);
  analyzer.analyze(sourcePath);
  // print errors
  formatter.formatErrors(analyzer.errorInfos);
  // prepare status
  ErrorSeverity status = analyzer.maxErrorSeverity;
  if (status == ErrorSeverity.WARNING && options.warningsAreFatal) {
    status = ErrorSeverity.ERROR;
  }
  return status;
}

typedef ErrorSeverity BatchRunnerHandler(List<String> args);

/// Provides a framework to read command line options from stdin and feed them to a callback.
class BatchRunner {
  /**
   * Run the tool in 'batch' mode, receiving command lines through stdin and returning pass/fail
   * status through stdout. This feature is intended for use in unit testing.
   */
  static ErrorSeverity runAsBatch(List<String> sharedArgs, BatchRunnerHandler handler) {
    stdout.writeln('>>> BATCH START');
    Stopwatch stopwatch = new Stopwatch();
    stopwatch.start();
    int testsFailed = 0;
    int totalTests = 0;
    ErrorSeverity batchResult = ErrorSeverity.NONE;
    // read line from stdin
    Stream cmdLine = stdin
        .transform(new StringDecoder())
        .transform(new LineTransformer());
    var subscription = cmdLine.listen((String line) {
      // may be finish
      if (line.isEmpty) {
        var time = stopwatch.elapsedMilliseconds;
        stdout.writeln('>>> BATCH END (${totalTests - testsFailed}/$totalTests) ${time}ms');
        exit(batchResult.ordinal);
      }
      // prepare aruments
      var args;
      {
        var lineArgs = line.split(new RegExp('\\s+'));
        args = new List<String>();
        args.addAll(sharedArgs);
        args.addAll(lineArgs);
        args.remove('-b');
        args.remove('--batch');
        // TODO(scheglov) https://code.google.com/p/dart/issues/detail?id=11061
        args.remove('-batch');
      }
      // analyze single set of arguments
      try {
        totalTests++;
        ErrorSeverity result = handler(args);
        bool resultPass = result != ErrorSeverity.ERROR;
        if (!resultPass) {
          testsFailed++;
        }
        batchResult = batchResult.max(result);
        // Write stderr end token and flush.
        stderr.writeln('>>> EOF STDERR');
        String resultPassString = resultPass ? 'PASS' : 'FAIL';
        stdout.writeln('>>> TEST $resultPassString ${stopwatch.elapsedMilliseconds}ms');
      } catch (e, stackTrace) {
        stderr.writeln(e);
        stderr.writeln(stackTrace);
        stderr.writeln('>>> EOF STDERR');
        stdout.writeln('>>> TEST CRASH');
      }
    });
  }
}
