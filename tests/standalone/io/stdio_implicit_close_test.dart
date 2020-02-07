// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=stdio_implicit_close_script.dart

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "dart:convert";
import "dart:io";

void test({required bool closeStdout, required bool closeStderr}) {
  var scriptFile = "stdio_implicit_close_script.dart";
  var script = Platform.script.resolve(scriptFile).toFilePath();

  var arguments = <String>[]
    ..addAll(Platform.executableArguments)
    ..add(script);
  if (closeStdout) arguments.add("stdout");
  if (closeStderr) arguments.add("stderr");

  asyncStart();
  Process.run(Platform.executable, arguments,
          stdoutEncoding: ascii, stderrEncoding: ascii)
      .then((result) {
    print(result.stdout);
    print(result.stderr);
    Expect.equals(0, result.exitCode);

    Expect.isTrue(result.stdout.contains("APPLE"));
    Expect.isTrue(result.stderr.contains("BANANA"));

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
