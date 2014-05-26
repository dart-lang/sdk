// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/18942

library LeakTest;
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'dart:isolate';
import 'dart:async';


class A {
  var x = 0;
}

fun(msg) {
  print("received: ${msg.x}");
  msg.x = 1;
  print("done updating: ${msg.x}");
}

main() {
  asyncStart();
  var a = new A();
  // Sending an A object to another isolate should not work.
  Isolate.spawn(fun, a).then((isolate) {
    new Timer(const Duration(milliseconds: 300), () {
      // Changes in other isolate must not reach here.
      Expect.equals(0, a.x);
      asyncEnd();
    });
  }, onError: (e) {
    // Sending an A isn't required to work.
    // It works in the VM, but not in dart2js.
    print("Send of A failed:\n$e");
    asyncEnd();
  });
}
