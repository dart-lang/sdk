// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

void main(List<String> args) {
  if (args.contains("--child")) {
    print("Hello, pre-scanned world!");
  } else {
    runSnapshot(generateSnapshot());
  }
}

generateSnapshot() {
  var tempDir = Directory.systemTemp.createTempSync("script-snapshot");
  var snapshotPath = tempDir.uri.resolve("hello.snapshot").toFilePath();

  var exec = Platform.resolvedExecutable;
  var args = new List();
  args.addAll(Platform.executableArguments);
  args.add("--snapshot=$snapshotPath");
  args.add(Platform.script.toFilePath());
  args.add("--child");
  var result = Process.runSync(exec, args);
  if (result.exitCode != 0) {
    throw "Bad exit code: ${result.exitCode}";
  }
  if (result.stdout.contains("Hello, pre-scanned world!")) {
    print(result.stdout);
    throw "Should not have run the script.";
  }

  return snapshotPath;
}

runSnapshot(var snapshotPath) {
  var exec = Platform.resolvedExecutable;
  var args = new List();
  args.addAll(Platform.executableArguments);
  args.add(snapshotPath);
  args.add("--child");
  var result = Process.runSync(exec, args);
  if (result.exitCode != 0) {
    throw "Bad exit code: ${result.exitCode}";
  }
  if (!result.stdout.contains("Hello, pre-scanned world!")) {
    print(result.stdout);
    throw "Failed to run the snapshot.";
  }
}
