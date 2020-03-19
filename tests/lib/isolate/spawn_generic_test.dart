// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Check that Isolate.spawn is generic.
library spawn_generic;

import "dart:isolate";
import "dart:async";
import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void isomain(num args) {
  print(args);
  // All is well. No throwing.
}

void isomain1(num? args) {
  print(args);
  // All is well. No throwing.
}

int _count = 0;
void enter() {
  asyncStart();
  _count++;
}

bool exit() {
  asyncEnd();
  return --_count == 0;
}

main() {
  var remotePort = new RawReceivePort();
  remotePort.handler = (m) {
    if (m == null) {
      if (exit()) remotePort.close();
    } else {
      List list = m;
      throw new AsyncError(m[0], new StackTrace.fromString(m[1]));
    }
  };
  var port = remotePort.sendPort;

  // Explicit type works.
  enter();
  Isolate.spawn<int>(isomain, 42, onExit: port, onError: port);
  enter();
  Isolate.spawn<num>(isomain, 42, onExit: port, onError: port);
  enter();
  Isolate.spawn<num>(isomain, 1.2, onExit: port, onError: port);
  enter();
  Isolate.spawn<double>(isomain, 1.2, onExit: port, onError: port);
  enter();
  Isolate.spawn<int?>(isomain1, null, onExit: port, onError: port);

  // Inference gets it right.
  enter();
  Isolate.spawn(isomain, 42, onExit: port, onError: port);
  enter();
  Isolate.spawn(isomain, 1.2, onExit: port, onError: port);
  enter();
  Isolate.spawn(isomain1, null, onExit: port, onError: port);
}
