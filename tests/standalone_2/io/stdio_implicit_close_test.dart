// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=stdio_implicit_close_script.dart

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "dart:convert";
import "dart:io";

void test({bool closeStdout, bool closeStderr}) {
  var scriptFile = "stdio_implicit_close_script.dart";
  var script = Platform.script.resolve(scriptFile).toFilePath();

  // Relying on these flags to print something specific on stdout and stderr
  // is brittle, but otherwise we would need to add our own flag.
  var arguments = [
    "--print-metrics", // Prints on stderr.
    "--timing", //         Prints on stdout.
    script,
  ];
  if (closeStdout) arguments.add("stdout");
  if (closeStderr) arguments.add("stderr");

  asyncStart();
  Process
      .run(Platform.executable, arguments,
          stdoutEncoding: ascii, stderrEncoding: ascii)
      .then((result) {
    print(result.stdout);
    print(result.stderr);
    Expect.equals(0, result.exitCode);

    if (closeStdout) {
      Expect.equals("", result.stdout);
    } else {
      Expect.isTrue(result.stdout.contains("Timing for"));
    }

    if (closeStderr) {
      Expect.equals("", result.stderr);
    } else {
      Expect.isTrue(result.stderr.contains("Printing metrics"));
    }

    asyncEnd();
  });
}

void main() {
  asyncStart();
  test(closeStdout: false, closeStderr: false);
  test(closeStdout: false, closeStderr: true);
  test(closeStdout: true, closeStderr: false);
  test(closeStdout: true, closeStderr: true);
  asyncEnd();
}
