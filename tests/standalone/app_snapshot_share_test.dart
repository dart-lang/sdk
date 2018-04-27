// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

void main(List<String> args) {
  if (args.contains("--child")) {
    print("Hello, sharing world!");
    return;
  }

  if (!Platform.executable.endsWith("dart_precompiled_runtime")) {
    return; // Running in JIT or Windows.
  }

  var buildDir =
      Platform.executable.substring(0, Platform.executable.lastIndexOf('/'));
  var tempDir = Directory.systemTemp.createTempSync("app-shared");
  var snapshot1Path = tempDir.uri.resolve("hello1.snapshot").toFilePath();
  var snapshot2Path = tempDir.uri.resolve("hello2.snapshot").toFilePath();
  var scriptPath = new Directory(buildDir)
      .uri
      .resolve("../../tests/standalone/app_snapshot_share_test.dart")
      .toFilePath();

  var exec = "$buildDir/dart_bootstrap";
  args = new List<String>();
  args.add("--deterministic");
  args.add("--use-blobs");
  args.add("--snapshot-kind=app-aot");
  args.add("--snapshot=$snapshot1Path");
  args.add(scriptPath);
  print("+ $exec $args");
  var result = Process.runSync(exec, args);
  print("Exit code: ${result.exitCode}");
  print("stdout:");
  print(result.stdout);
  print("stderr:");
  print(result.stderr);
  if (result.exitCode != 0) {
    throw "Bad exit code";
  }

  exec = "$buildDir/dart_bootstrap";
  args = new List<String>();
  args.add("--deterministic");
  args.add("--use-blobs");
  args.add("--snapshot-kind=app-aot");
  args.add("--snapshot=$snapshot2Path");
  args.add("--shared-blobs=$snapshot1Path");
  args.add(scriptPath);
  print("+ $exec $args");
  result = Process.runSync(exec, args);
  print("Exit code: ${result.exitCode}");
  print("stdout:");
  print(result.stdout);
  print("stderr:");
  print(result.stderr);
  if (result.exitCode != 0) {
    throw "Bad exit code";
  }

  var sizeWithoutSharing = new File(snapshot1Path).statSync().size;
  var deltaWhenSharing = new File(snapshot2Path).statSync().size;
  print("sizeWithoutSharing: $sizeWithoutSharing");
  print("deltaWhenSharing: $deltaWhenSharing");
  if (deltaWhenSharing >= sizeWithoutSharing) {
    throw "Sharing did not shrink size";
  }

  exec = "$buildDir/dart_precompiled_runtime";
  args = new List<String>();
  args.add("--shared-blobs=$snapshot1Path");
  args.add(snapshot2Path);
  args.add("--child");
  print("+ $exec $args");
  result = Process.runSync(exec, args);
  print("Exit code: ${result.exitCode}");
  print("stdout:");
  print(result.stdout);
  print("stderr:");
  print(result.stderr);
  if (result.exitCode != 0) {
    throw "Bad exit code";
  }
  if (!result.stdout.contains("Hello, sharing world!")) {
    throw "Missing output";
  }
}
