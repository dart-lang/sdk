// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test that compilation errors in the process
// exit handler are reported correctly.

import "dart:io";
import "process_test_util.dart";

void main() {
  var fp = Process.start(getProcessTestFileName(), const ["0", "0", "0", "0"]);
  fp.then((p) {
    p.exitCode.then((int s) {
      print(a.toString()); // Should cause a compilation error here.
    });
    // Drain stdout and stderr.
    p.stdout.listen((_) {});
    p.stderr.listen((_) {});
  });
}
