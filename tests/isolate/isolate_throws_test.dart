// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that exceptions in other isolates bring down
// the program.

import 'dart:async';
import 'dart:isolate';
import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void entry(SendPort replyTo) {
  throw "foo";  /// 01: runtime error
  replyTo.send("done");
}

main() {
  asyncStart();
  ReceivePort rp = new ReceivePort();
  Isolate.spawn(entry, rp.sendPort);
  rp.first.then((msg) {
    Expect.equals("done", msg);
    asyncEnd();
  });
}
