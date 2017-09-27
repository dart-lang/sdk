// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:kernel/src/tool/batch_util.dart';

/// Wraps a main() method for a test that should be runnable as a self-checking
/// unit test.
///
/// These tests can be run like:
///
///    tools/test.py -cdartk -rself_check
///
/// The test can either be run with a single file passed on the command line
/// or run in batch mode.
runSelfCheck(List<String> args, Future runTest(String filename)) {
  Future<CompilerOutcome> batchMain(List<String> arguments) async {
    if (arguments.length != 1) {
      throw 'Exactly one argument expected';
    }
    String filename = arguments[0];
    if (!filename.endsWith('.dill')) {
      throw 'File does not have expected .dill extension: $filename';
    }
    await runTest(filename);
    return CompilerOutcome.Ok;
  }

  if (args.length == 1 && args[0] == '--batch') {
    runBatch(batchMain);
  } else {
    batchMain(args);
  }
}
