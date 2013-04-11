// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Utility script to echo stdin to stdout or stderr or both.

import "dart:io";

main() {
  var options = new Options();
  if (stdioType(stdin) is !StdioType) exit(1);
  if (stdioType(stdout) is !StdioType) exit(1);
  if (stdioType(stderr) is !StdioType) exit(1);
  if (stdioType(stdin).name != options.arguments[1]) {
    throw stdioType(stdin).name;
  }
  if (stdioType(stdout).name != options.arguments[2]) {
    throw stdioType(stdout).name;
  }
  if (stdioType(stderr).name != options.arguments[3]) {
    throw stdioType(stderr).name;
  }
  if (options.arguments.length > 0) {
    if (options.arguments[0] == "0") {
      stdin.pipe(stdout);
    } else if (options.arguments[0] == "1") {
      stdin.pipe(stderr);
    } else if (options.arguments[0] == "2") {
      stdin.listen((data) {
        stdout.add(data);
        stderr.add(data);
      });
    }
  }
}
