// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test properties of ports.
// Note: unittest.dart depends on ports, in particular on the behaviour tested
// here. To keep things simple, we don't use the unittest library here.

#library("PortTest");
#import("dart:isolate");


main() {
  testHashCode();
  testEquals();
  testMap();
}

void testHashCode() {
  ReceivePort rp0 = new ReceivePort();
  ReceivePort rp1 = new ReceivePort();
  Expect.equals(rp0.toSendPort().hashCode, rp0.toSendPort().hashCode);
  Expect.equals(rp1.toSendPort().hashCode, rp1.toSendPort().hashCode);
  rp0.close();
  rp1.close();
}

void testEquals() {
  ReceivePort rp0 = new ReceivePort();
  ReceivePort rp1 = new ReceivePort();
  Expect.equals(rp0.toSendPort(), rp0.toSendPort());
  Expect.equals(rp1.toSendPort(), rp1.toSendPort());
  Expect.equals(false, (rp0.toSendPort() == rp1.toSendPort()));
  rp0.close();
  rp1.close();
}

void testMap() {
  ReceivePort rp0 = new ReceivePort();
  ReceivePort rp1 = new ReceivePort();
  final map = new Map<SendPort, int>();
  map[rp0.toSendPort()] = 42;
  map[rp1.toSendPort()] = 87;
  Expect.equals(42, map[rp0.toSendPort()]);
  Expect.equals(87, map[rp1.toSendPort()]);

  map[rp0.toSendPort()] = 99;
  Expect.equals(99, map[rp0.toSendPort()]);
  Expect.equals(87, map[rp1.toSendPort()]);

  map.remove(rp0.toSendPort());
  Expect.equals(false, map.containsKey(rp0.toSendPort()));
  Expect.equals(87, map[rp1.toSendPort()]);

  map.remove(rp1.toSendPort());
  Expect.equals(false, map.containsKey(rp0.toSendPort()));
  Expect.equals(false, map.containsKey(rp1.toSendPort()));

  rp0.close();
  rp1.close();
}
