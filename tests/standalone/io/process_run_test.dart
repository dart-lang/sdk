// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";
import "package:path/path.dart" as path;

import "process_test_util.dart";

void testProcessRunBinaryOutput() {
  var result = Process.runSync(
      getProcessTestFileName(), const ["0", "0", "0", "0"],
      stdoutEncoding: null);
  Expect.isTrue(result.stdout is List<int>);
  Expect.isTrue(result.stderr is String);

  result = Process.runSync(getProcessTestFileName(), const ["0", "0", "0", "0"],
      stderrEncoding: null);
  Expect.isTrue(result.stdout is String);
  Expect.isTrue(result.stderr is List<int>);

  result = Process.runSync(getProcessTestFileName(), const ["0", "0", "0", "0"],
      stdoutEncoding: null, stderrEncoding: null);
  Expect.isTrue(result.stdout is List<int>);
  Expect.isTrue(result.stderr is List<int>);
}

void testProcessPathWithSpace() {
  // Bug: https://github.com/dart-lang/sdk/issues/37751
  var processTest = new File(getProcessTestFileName());
  var dir = Directory.systemTemp.createTempSync('process_run_test');
  try {
    File(path.join(dir.path, 'path')).createSync();
    var innerDir = Directory(path.join(dir.path, 'path with space'));
    innerDir.createSync();
    processTest = processTest.copySync(path.join(
        innerDir.path, 'process_run_test${getPlatformExecutableExtension()}'));
    // It will run executables without throwing exception.
    var result = Process.runSync(processTest.path, []);
    // Kill the isolate because next test reuse the exe file.
    Process.killPid(result.pid);
    // Manually escape the path
    if (Platform.isWindows) {
      result = Process.runSync('"${processTest.path}"', []);
      Process.killPid(result.pid);
    }
    result = Process.runSync('${processTest.path}', []);
    Process.killPid(result.pid);
  } catch (e) {
    Expect.fail('System should find process_run_test executable');
    print(e);
  } finally {
    // Clean up the temp files and directory
    dir.deleteSync(recursive: true);
  }
}

void main() {
  testProcessRunBinaryOutput();
  testProcessPathWithSpace();
}
