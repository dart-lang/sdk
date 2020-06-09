// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify running with --disassemble --disassemble-relative produces
// deterministic output. This is useful for removing noise when tracking down
// the effects of compiler changes.

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
    return; // No disassembler in product mode.
  }
  if (Platform.executable.contains("IA32")) {
    return; // Our IA32 code is not position independent.
  }

  final result1 = await runDart('GENERATE DISASSEMBLY 1', [
    '--deterministic',
    '--disassemble',
    '--disassemble-relative',
    Platform.script.toFilePath(),
    '--child'
  ]);
  final asm1 = result1.processResult.stderr;

  final result2 = await runDart('GENERATE DISASSEMBLY 2', [
    '--deterministic',
    '--disassemble',
    '--disassemble-relative',
    Platform.script.toFilePath(),
    '--child'
  ]);
  final asm2 = result2.processResult.stderr;

  Expect.isTrue(
      asm1.contains("Code for function"), "Printed at least one function");
  Expect.stringEquals(asm1, asm2);
}
