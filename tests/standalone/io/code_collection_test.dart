// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program testing code GC.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";


int foo(int x) {
  x = x + 1;
  return x;
}


List<int> bar() {
  // A couple of big allocations trigger GC.
  var l = new List.filled(700000, 7);
  return l;
}


doTest() {
 var i = 0;
  foo(1);  // Initial call to compile.
  // Time passes, GC runs, foo's code is dropped.
  var ms = const Duration(milliseconds: 100);
  var t = new Timer.periodic(ms, (timer) {
    i++;
    bar();
    if (i > 1) {
      timer.cancel();
      // foo is called again to make sure we can still run it even after
      // its code has been detached.
      foo(2);
    }
  });
}


main(List<String> arguments) {
  if (arguments.contains("--run")) {
    doTest();
  } else {
    // Run the test and capture stdout.
    var pr = Process.runSync(Platform.executable,
        ["--collect-code",
         "--code-collection-interval-in-us=100000",
         "--old_gen_growth_rate=10",
         "--log-code-drop",
         "--optimization-counter-threshold=-1",
         "--package-root=${Platform.packageRoot}",
         Platform.script.toFilePath(),
         "--run"]);

    // Code drops are logged with --log-code-drop. Look through stdout for the
    // message that foo's code was dropped.
    var found = false;
    pr.stdout.split("\n").forEach((line) {
      if (line.contains("Detaching code") && line.contains("foo")) {
        found = true;
      }
    });
    Expect.isTrue(found);
  }
}
