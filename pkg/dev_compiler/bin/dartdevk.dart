#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Experimental command line entry point for Dart Development Compiler.
/// Unlike `dartdevc` this version uses the shared front end and IR.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:dev_compiler/src/kernel/command.dart';
import 'package:front_end/src/api_unstable/ddc.dart' as fe;

Future main(List<String> args) async {
  var parsedArgs = _preprocessArgs(args);
  if (parsedArgs.isBatch) {
    await runBatch(parsedArgs.args);
  } else if (parsedArgs.isWorker) {
    await new _CompilerWorker(parsedArgs.args).run();
  } else {
    var result = await compile(parsedArgs.args);
    var succeeded = result.result;
    exitCode = succeeded ? 0 : 1;
  }
}

/// Runs dartdevk in batch mode for test.dart.
Future runBatch(List<String> batchArgs) async {
  var tests = 0;
  var failed = 0;
  var watch = new Stopwatch()..start();

  print('>>> BATCH START');

  String line;
  fe.InitializedCompilerState compilerState;

  while ((line = stdin.readLineSync(encoding: UTF8))?.isNotEmpty == true) {
    tests++;
    var args = batchArgs.toList()..addAll(line.split(new RegExp(r'\s+')));

    String outcome;
    try {
      var result = await compile(args, compilerState: compilerState);
      compilerState = result.compilerState;
      var succeeded = result.result;
      outcome = succeeded ? 'PASS' : 'FAIL';
    } catch (e, s) {
      outcome = 'CRASH';
      print('Unhandled exception:');
      print(e);
      print(s);
    }

    // TODO(rnystrom): If kernel has any internal static state that needs to
    // be cleared, do it here.

    stderr.writeln('>>> EOF STDERR');
    print('>>> TEST $outcome ${watch.elapsedMilliseconds}ms');
  }

  var time = watch.elapsedMilliseconds;
  print('>>> BATCH END (${tests - failed})/$tests ${time}ms');
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
    var result = await runZoned(() => compile(args), zoneSpecification:
        new ZoneSpecification(print: (self, parent, zone, message) {
      output.writeln(message.toString());
    }));
    return new WorkResponse()
      ..exitCode = result.result ? 0 : 1
      ..output = output.toString();
  }
}

/// Preprocess arguments to determine whether DDK is used in batch mode or as a
/// persistent worker.
///
/// When used in batch mode, we expect a `--batch` parameter last.
///
/// When used as a persistent bazel worker, the `--persistent_worker` might be
/// present, and an argument of the form `@path/to/file` might be provided. The
/// latter needs to be replaced by reading all the contents of the
/// file and expanding them into the resulting argument list.
_ParsedArgs _preprocessArgs(List<String> args) {
  if (args.isEmpty) return new _ParsedArgs(false, false, args);

  String lastArg = args.last;
  if (lastArg == '--batch') {
    return new _ParsedArgs(true, false, args.sublist(0, args.length - 1));
  }

  var newArgs = <String>[];
  bool isWorker = false;
  var len = args.length;
  for (int i = 0; i < len; i++) {
    var arg = args[i];
    if (i == len - 1 && arg.startsWith('@')) {
      newArgs.addAll(_readLines(arg.substring(1)));
    } else if (arg == '--persistent_worker') {
      isWorker = true;
    } else {
      newArgs.add(arg);
    }
  }
  return new _ParsedArgs(false, isWorker, newArgs);
}

/// Return all lines in a file found at [path].
Iterable<String> _readLines(String path) {
  try {
    return new File(path)
        .readAsStringSync()
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((String line) => line.isNotEmpty);
  } on FileSystemException catch (e) {
    throw new Exception('Failed to read $path: $e');
  }
}

class _ParsedArgs {
  final bool isBatch;
  final bool isWorker;
  final List<String> args;

  _ParsedArgs(this.isBatch, this.isWorker, this.args);
}
