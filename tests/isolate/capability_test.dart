// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() {
  asyncStart();
  var c1 = new Capability();
  var c2 = new Capability();
  Expect.notEquals(c1, c2);

  var receive = new RawReceivePort();
  receive.sendPort.send(c1);
  receive.handler = (c3) {
    Expect.equals(c3, c1);
    Expect.notEquals(c3, c2);
    asyncEnd();
  };
}
