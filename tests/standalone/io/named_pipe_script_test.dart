// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing file input stream, VM-only, standalone test.

import "dart:convert";
import "dart:io";

import "package:expect/expect.dart";

main() {
  // Reading a script from a named pipe is only supported on Linux and MacOS.
  if (!Platform.isLinux && !Platform.isMacOS) {
    return;
  }

  final String script = 'int main() {print("Hello, World!");}';
  final String stdinPipePath = '/dev/fd/0';
  StringBuffer output = new StringBuffer();
  Process.start(Platform.executable, [stdinPipePath]).then((Process process) {
    process.stdout.transform(UTF8.decoder).listen(output.write);
    process.stderr.transform(UTF8.decoder).listen((data) {
      Expect.fail(data);
    });
    process.stdin.writeln(script);
    process.stdin.close();
    process.exitCode.then((int status) {
      Expect.equals(0, status);
      Expect.equals("Hello, World!\n", output.toString());
    });
  });
}
