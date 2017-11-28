// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program testing code GC.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";

int foo(int x) {
  x = x + 1;
  // Print marker message while foo is on the stack so the code cannot be
  // collected.
  print("foo=$x");
  return x;
}

List<int> bar() {
  // A couple of big allocations trigger GC.
  var l = new List.filled(700000, 7);
  return l;
}

doTest() {
  var i = 0;
  var ret = foo(1); // Initial call to compile.
  // Time passes, GC runs, foo's code is dropped.
  var ms = const Duration(milliseconds: 100);
  var t = new Timer.periodic(ms, (timer) {
    i++;
    // Calling bar will trigger GC without foo being on the stack. This way
    // the method can be collected.
    bar();
    if (i > 1) {
      timer.cancel();
      // foo is called again to make sure we can still run it even after
      // its code has been detached.
      var ret = foo(2);
      // GC after here may collect the second compilation of foo.
    }
  });
}

List<String> packageOptions() {
  if (Platform.packageRoot != null) {
    return <String>['--package-root=${Platform.packageRoot}'];
  } else if (Platform.packageConfig != null) {
    return <String>['--packages=${Platform.packageConfig}'];
  } else {
    return <String>[];
  }
}

main(List<String> arguments) {
  if (arguments.contains("--run")) {
    doTest();
  } else {
    // Run the test and capture stdout.
    var args = packageOptions();
    args.addAll([
      "--verbose-gc",
      "--collect-code",
      "--code-collection-interval-in-us=0",
      "--old_gen_growth_rate=10",
      "--log-code-drop",
      "--optimization-counter-threshold=-1",
      Platform.script.toFilePath(),
      "--run"
    ]);
    var pr = Process.runSync(Platform.executable, args);

    Expect.equals(0, pr.exitCode);

    // Code drops are logged with --log-code-drop. Look through stdout for the
    // message that foo's code was dropped.
    print(pr.stdout);
    bool saw_foo2 = false;
    bool saw_detaching_foo = false;
    bool saw_foo3 = false;
    pr.stdout.split("\n").forEach((line) {
      if (line.contains("foo=2")) {
        Expect.isFalse(saw_foo2, "foo=2 ran twice");
        saw_foo2 = true;
      }
      if (line.contains("Detaching code") && line.contains("foo")) {
        Expect.isTrue(saw_foo2, "foo detached before running");
        // May detach twice.
        saw_detaching_foo = true;
      }
      if (line.contains("foo=3")) {
        Expect.isFalse(saw_foo3, "foo=3 ran twice");
        Expect.isTrue(saw_detaching_foo, "foo should have been collected");
        saw_foo3 = true;
      }
    });

    Expect.isTrue(saw_foo2, "Missing foo=2");
    Expect.isTrue(saw_detaching_foo, "Missing code collection for foo");
    Expect.isTrue(saw_foo3, "Missing foo=3");
  }
}
