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

class NotAList {
  get length => 10;
  operator [](index) => 1;
}

testSocketCreation(host, port) {
  asyncStart();
  try {
    Socket
        .connect(host, port)
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

testAdd(buffer) {
  asyncStart();
  asyncStart();
  ServerSocket.bind("127.0.0.1", 0).then((server) {
    server.listen((socket) => socket.destroy());
    Socket.connect("127.0.0.1", server.port).then((socket) {
      int errors = 0;
      socket.done.catchError((e) {
        errors++;
      }).then((_) {
        Expect.equals(1, errors);
        asyncEnd();
        server.close();
      });
      socket.listen((_) {}, onError: (error) {
        Expect.fail("Error on stream");
      }, onDone: () {
        asyncEnd();
      });
      socket.add(buffer);
    });
  });
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
  testSocketCreation(123, 123);
  testSocketCreation("string", null);
  testSocketCreation(null, null);
  testSocketCreation("localhost", -1);
  testSocketCreation("localhost", 65536);
  testAdd(null);
  testAdd(new NotAList());
  testAdd(42);
  // TODO(8233): Throw ArgumentError from API implementation.
  // testAdd([-1]);
  // testAdd([2222222222222222222222222222222]);
  // testAdd([1, 2, 3, null]);
  // testAdd([new NotAnInteger()]);
  testServerSocketCreation(123, 123, 123);
  testServerSocketCreation("string", null, null);
  testServerSocketCreation("string", 123, null);
  testServerSocketCreation("localhost", -1, 123);
  testServerSocketCreation("localhost", 65536, 123);
}
