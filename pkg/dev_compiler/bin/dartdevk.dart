#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Experimental command line entry point for Dart Development Compiler.
/// Unlike `dartdevc` this version uses the shared front end and IR.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dev_compiler/src/kernel/command.dart';

Future main(List<String> args) async {
  if (args.isNotEmpty && args.last == "--batch") {
    await runBatch(args.sublist(0, args.length - 1));
  } else {
    var succeeded = await compile(args);
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
  while ((line = stdin.readLineSync(encoding: UTF8)).isNotEmpty) {
    tests++;
    var args = batchArgs.toList()..addAll(line.split(new RegExp(r'\s+')));

    String outcome;
    try {
      // TODO(jmesserly): share SDK deserialization between compilations.
      var succeeded = await compile(args);
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
