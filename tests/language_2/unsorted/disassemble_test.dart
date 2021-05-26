// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Tests proper object recognition in disassembler.
import 'dart:async';
import 'dart:io';
import "package:expect/expect.dart";

Future runBinary(String binary, List<String> arguments) async {
  print("+ $binary " + arguments.join(" "));
  final result = await Process.run(binary, arguments);
  return result;
}

f(x) {
  return "foo";
}

Future<void> main(List<String> args) async {
  if (args.contains('--child')) {
    print(f(0));
    return;
  }
  if (Platform.executable.contains("Product")) {
    return; // No disassembler in product mode.
  }

  final result = await runBinary(Platform.executable,
      ['--disassemble', Platform.script.toFilePath(), '--child']);
  Expect.equals(0, result.exitCode);
}
