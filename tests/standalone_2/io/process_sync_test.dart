// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=process_sync_script.dart

import "dart:io";
import "package:expect/expect.dart";
import 'package:path/path.dart';

test(int blockCount, int stdoutBlockSize, int stderrBlockSize, int exitCode,
    [int nonWindowsExitCode]) {
  // Get the Dart script file that generates output.
  var scriptFile = new File(
      Platform.script.resolve("process_sync_script.dart").toFilePath());
  var args = [
    scriptFile.path,
    blockCount.toString(),
    stdoutBlockSize.toString(),
    stderrBlockSize.toString(),
    exitCode.toString()
  ];
  ProcessResult syncResult = Process.runSync(Platform.executable, args);
  Expect.equals(blockCount * stdoutBlockSize, syncResult.stdout.length);
  Expect.equals(blockCount * stderrBlockSize, syncResult.stderr.length);
  if (Platform.isWindows) {
    Expect.equals(exitCode, syncResult.exitCode);
  } else {
    if (nonWindowsExitCode == null) {
      Expect.equals(exitCode, syncResult.exitCode);
    } else {
      Expect.equals(nonWindowsExitCode, syncResult.exitCode);
    }
  }
  Process.run(Platform.executable, args).then((asyncResult) {
    Expect.equals(syncResult.stdout, asyncResult.stdout);
    Expect.equals(syncResult.stderr, asyncResult.stderr);
    Expect.equals(syncResult.exitCode, asyncResult.exitCode);
  });
}

main() {
  test(10, 10, 10, 0);
  test(10, 100, 10, 0);
  test(10, 10, 100, 0);
  test(100, 1, 10, 0);
  test(100, 10, 1, 0);
  test(100, 1, 1, 0);
  test(1, 100000, 100000, 0);

  // The buffer size used in process.h.
  var kBufferSize = 16 * 1024;
  test(1, kBufferSize, kBufferSize, 0);
  test(1, kBufferSize - 1, kBufferSize - 1, 0);
  test(1, kBufferSize + 1, kBufferSize + 1, 0);

  test(10, 10, 10, 1);
  test(10, 10, 10, 255);
  test(10, 10, 10, -1, 255);
  test(10, 10, 10, -255, 1);
}
