// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'dart:io';

void openAndWriteScript(String script) {
  var options = new Options();
  var dir = new Path(options.script).directoryPath;
  script = "$dir/$script";
  var executable = options.executable;
  var file = script;  // Use script as file.
  Process.start("bash", ["-c", "$executable $script < $file"]).then((process) {
    process.exitCode
        .then((exitCode) {
          Expect.equals(0, exitCode);
        });
  });
}

void testReadStdio() {
  openAndWriteScript("file_read_stdio_script.dart");
}

void main() {
  testReadStdio();
}
