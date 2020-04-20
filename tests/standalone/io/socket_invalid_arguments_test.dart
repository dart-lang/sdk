// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

class NotAnInteger {
  operator ==(other) => other == 1;
  operator <(other) => other > 1;
  operator +(other) => 1;
}

testSocketCreation(host, port) {
  asyncStart();
  try {
    Socket.connect(host, port)
        .then((socket) => Expect.fail("Shouldn't get connected"))
        .catchError((e) {
      Expect.isTrue(e is ArgumentError || e is SocketException);
      asyncEnd();
    });
  } catch (e) {
    Expect.isTrue(e is ArgumentError || e is SocketException);
    asyncEnd();
  }
}

testServerSocketCreation(address, port, backlog) {
  asyncStart();
  var server;
  try {
    ServerSocket.bind(address, port, backlog: backlog).then((_) {
      Expect.fail("ServerSocket bound");
    }).catchError((e) => asyncEnd());
  } catch (e) {
    asyncEnd();
  }
}

main() {
  asyncStart();
  testSocketCreation("localhost", -1);
  testSocketCreation("localhost", 65536);
  testServerSocketCreation("string", null, null);
  testServerSocketCreation("string", 123, null);
  testServerSocketCreation("localhost", -1, 123);
  testServerSocketCreation("localhost", 65536, 123);
  asyncEnd();
}
