// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() {
  asyncStart();

  test(c1, c2) {
    asyncStart();
    Expect.notEquals(c1, c2);
    var receive = new RawReceivePort();
    receive.sendPort.send(c1);
    receive.handler = (c3) {
      Expect.equals(c3, c1);
      Expect.notEquals(c3, c2);
      receive.close();
      asyncEnd();
    };
  }

  Capability c1 = new Capability();
  Capability c2 = new Capability();
  Capability c3 = (new RawReceivePort()..close()).sendPort;
  Capability c4 = (new RawReceivePort()..close()).sendPort;
  test(c1, c2);
  test(c3, c4);
  test(c1, c3);
  asyncEnd();
}
