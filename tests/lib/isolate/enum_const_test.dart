// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

/// Check that an enum value sent through a send/receive-port retains identity.

enum Foo { bar, baz }

void main() {
  asyncStart();
  test1();
  test2();
  test3();
  asyncEnd();
}

void verify(Object? val) {
  Expect.identical(Foo.bar, val);
}

void test1() {
  // Sanity check.
  verify(Foo.bar);
}

void test2() {
  // From same isolate.
  asyncStart();
  var rp = RawReceivePort();
  rp.handler = (val) {
    verify(val);
    rp.close();
    asyncEnd();
  };
  rp.sendPort.send(Foo.bar);
}

void test3() {
  // From other isolate.
  asyncStart();
  var rp = RawReceivePort();
  rp.handler = (val) {
    verify(val);
    rp.close();
    asyncEnd();
  };
  Isolate.spawn(_sendFoo, rp.sendPort);
}

void _sendFoo(SendPort sendPort) {
  sendPort.send(Foo.bar);
}
