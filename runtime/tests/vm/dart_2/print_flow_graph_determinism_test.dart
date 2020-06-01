// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify running with --print-flow-graph produces deterministic output. This is
// useful for removing noise when tracking down the effects of compiler changes.

import 'dart:async';
import 'dart:io';
import 'snapshot_test_helper.dart';

import 'package:expect/expect.dart';

int fib(int n) {
  if (n <= 1) return 1;
  return fib(n - 1) + fib(n - 2);
}

Future<void> main(List<String> args) async {
  if (args.contains('--child')) {
    print(fib(35));
    return;
  }

  if (!Platform.script.toString().endsWith(".dart")) {
    return; // Not running from source: skip for app-jit and app-aot.
  }
  if (Platform.executable.contains("Product")) {
    return; // No flow graph printer in product mode.
  }

  final result1 = await runDart('GENERATE CFG 1', [
    '--deterministic',
    '--print-flow-graph',
    Platform.script.toFilePath(),
    '--child'
  ]);
  final cfg1 = result1.processResult.stderr;

  final result2 = await runDart('GENERATE CFG 2', [
    '--deterministic',
    '--print-flow-graph',
    Platform.script.toFilePath(),
    '--child'
  ]);
  final cfg2 = result2.processResult.stderr;

  Expect.isTrue(
      cfg1.contains("*** BEGIN CFG"), "Printed at least one function");
  Expect.stringEquals(cfg1, cfg2);
}
