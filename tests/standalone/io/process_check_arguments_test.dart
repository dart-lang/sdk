// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "dart:io";

import "process_test_util.dart";

test(args) async {
  var process = await Process.start(
    Platform.executable,
    []
      ..addAll(Platform.executableArguments)
      ..addAll(args),
  );
  var exitCode = await process.exitCode;
  Expect.equals(0, exitCode);
  // Drain stdout and stderr.
  await process.stdout.drain();
  await process.stderr.drain();
}

main() async {
  // Get the Dart script file which checks arguments.
  var scriptFile = new File(
    "tests/standalone/io/process_check_arguments_script.dart",
  );
  if (!scriptFile.existsSync()) {
    scriptFile = new File(
      "../tests/standalone/io/process_check_arguments_script.dart",
    );
  }
  await test([scriptFile.path, '3', '0', 'a']);
  await test([scriptFile.path, '3', '0', 'a b']);
  await test([scriptFile.path, '3', '0', 'a\tb']);
  await test([scriptFile.path, '3', '1', 'a\tb"']);
  await test([scriptFile.path, '3', '1', 'a"\tb']);
  await test([scriptFile.path, '3', '1', 'a"\t\\\\"b"']);
  await test([scriptFile.path, '4', '0', 'a\tb', 'a']);
  await test([scriptFile.path, '4', '0', 'a\tb', 'a\t\t\t\tb']);
  await test([scriptFile.path, '4', '0', 'a\tb', 'a    b']);
  await test([scriptFile.path, '5', '0', 'a\tb', 'a    b', '']);
}
