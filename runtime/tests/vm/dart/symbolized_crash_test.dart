// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

main() {
  if (Platform.isWindows) return; // posix exit codes
  if (Platform.isAndroid) return; // run_vm_tests not available on test device

  var run_vm_tests =
      path.join(path.dirname(Platform.resolvedExecutable), "run_vm_tests");
  var result = Process.runSync(run_vm_tests, ["Fatal"]);
  print(result.exitCode);
  print(result.stdout);
  print(result.stderr);

  Expect.contains(
      "error: This test fails and produces a backtrace", result.stderr);

  // Check for the frames that are marked never inline or have their address
  // taken, and so should be stable to changes in the C compiler. There are of
  // course more frames.
  Expect.contains("dart::Assert::Fail", result.stderr);
  Expect.contains("Dart_TestFatal", result.stderr);
  Expect.contains("main", result.stderr);
}
