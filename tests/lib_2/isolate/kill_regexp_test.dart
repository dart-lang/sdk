// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--intrinsify
// VMOptions=--no_intrinsify

import "dart:isolate";
import "dart:async";
import "package:expect/expect.dart";

isomain1(replyPort) {
  final regexp = new RegExp('[ab]c');
  while (true) {
    Expect.equals(4, regexp.allMatches("acbcacbc").length);
  }
}

void main() {
  for (int i = 0; i < 20; ++i) {
    ReceivePort reply = new ReceivePort();
    Isolate.spawn(isomain1, reply.sendPort).then((Isolate isolate) {
      new Timer(new Duration(milliseconds: 50), () {
        print('killing isolate $i');
        isolate.kill(priority: Isolate.immediate);
      });
    });
    reply.close();
  }
}
