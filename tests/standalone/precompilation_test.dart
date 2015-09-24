// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test generating and running a simple precompiled snapshot of this script.

import 'dart:io';

main(List args) {
  if (!Platform.isLinux) {
    print("Linux only test");
    return;
  }
  if (args.length > 0 && args[0] == "--hello") {
    print("Hello");
    return;
  }
  var dart_executable =
      Directory.current.path + Platform.pathSeparator + Platform.executable;
  Directory tmp;
  try {
    tmp = Directory.current.createTempSync("temp_precompilation_test");
    var result = Process.runSync(
       "${dart_executable}_no_snapshot",
       ["--gen-precompiled-snapshot", Platform.script.path],
       workingDirectory: tmp.path);
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      throw "Snapshot generation failed.";
    }

    // Check if gcc is present, and skip test if it is not.
    try {
      result = Process.runSync(
          "gcc",
          ["--version"],
          workingDirectory: tmp.path);
      if (result.exitCode != 0) {
        throw "gcc --version failed.";
      }
    } catch(e) {
      print("Skipping test because gcc is not present: $e");
      return;
    }

    // Detect if we're running a 32- or 64-bit VM.
    result = Process.runSync( "file", [dart_executable]);
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      throw "'file $dart_executable' failed.";
    }
    var m_option = result.stdout.contains("32-bit") ? "-m32" : "-m64";

    result = Process.runSync(
        "gcc",
        ["-shared", m_option, "-o", "libprecompiled.so", "precompiled.S"],
        workingDirectory: tmp.path);
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      throw "Shared library creation failed!";
    }
    result = Process.runSync(
       "${dart_executable}",
       ["--run-precompiled-snapshot", "ignored_script", "--hello"],
       workingDirectory: tmp.path);
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      throw "Precompiled binary failed.";
    }
    print(result.stdout);
    if (result.stdout != "Hello\n") {
      throw "Precompiled binary output mismatch.";
    }
  } finally {
    tmp?.deleteSync(recursive: true);
  }
}
