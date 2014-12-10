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
  var a = msg[0];
  var replyTo = msg[1];
  print("received: ${a.x}");
  a.x = 1;
  print("done updating: ${a.x}");
  replyTo.send("done");
}

main() {
  asyncStart();
  var a = new A();
  ReceivePort rp = new ReceivePort();
  Isolate.spawn(fun, [a, rp.sendPort]);
  rp.first.then((msg) {
    Expect.equals("done", msg);
    // Changes in other isolate must not reach here.
    Expect.equals(0, a.x);
    asyncEnd();
  });
}
