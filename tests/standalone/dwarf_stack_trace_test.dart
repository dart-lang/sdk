// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// VMOptions=--dwarf-stack-traces

import 'package:unittest/unittest.dart';
import 'dart:io';

bar() {
  // Keep the 'throw' and its argument on separate lines.
  throw "Hello, Dwarf!";
}

foo() {
  bar();
}

main() {
  String rawStack;
  try {
    foo();
  } catch (e, st) {
    rawStack = st.toString();
  }
  print(rawStack);

  if (Platform.isAndroid) {
    // Attempts to execute 'file' etc fail with security exceptions on
    // Android.
    print("Skipping test on Android");
    return;
  }

  if (Platform.isMacOS) {
    // addr2line is not part of the XCode command line tools.
    print("Skipping test on MacOS");
    return;
  }

  if (Platform.isWindows) {
    // Lacks 'file' and 'addr2line'.
    print("Skipping test on Windows");
    return;
  }

  ProcessResult result = Process.runSync("file", ["--version"]);
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    throw "'file' is not present";
  }

  result = Process.runSync("addr2line", ["--version"]);
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    throw "'addr2line' is not present";
  }

  result = Process.runSync("file", [Platform.script.toFilePath()]);
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    throw "'file' failed";
    return;
  }
  if (!result.stdout.contains("shared object")) {
    print("Skipping test because we are not running from a dylib");
    return;
  }

  var frameRegex = new RegExp("pc ([0-9a-z]+)  ([0-9a-zA-Z/\._-]+)");
  var symbolizedStack = new StringBuffer();
  for (var frameMatch in frameRegex.allMatches(rawStack)) {
    var framePC = frameMatch[1];
    var frameDSO = frameMatch[2];
    print(framePC);
    print(frameDSO);
    result = Process.runSync(
        "addr2line", ["--exe", frameDSO, "--functions", "--inlines", framePC]);
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      throw "'addr2line' failed";
    }
    print(result.stdout);
    symbolizedStack.write(result.stdout);
  }

  print(symbolizedStack);
  var symbolizedLines = symbolizedStack.toString().split("\n");
  expect(symbolizedLines.length, greaterThan(8));
  expect(
      symbolizedStack.toString(),
      stringContainsInOrder([
        "bar",
        "dwarf_stack_trace_test.dart:12",
        "foo",
        "dwarf_stack_trace_test.dart:17",
        "main",
        "dwarf_stack_trace_test.dart:23",
        "main", // dispatcher
        "dwarf_stack_trace_test.dart:20"
      ]));
}
