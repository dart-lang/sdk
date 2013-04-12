// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";
import "dart:isolate";

class NotAnInteger {
  operator==(other) => other == 1;
  operator<(other) => other > 1;
  operator+(other) => 1;
}

class NotAList {
  get length => 10;
  operator[](index) => 1;
}

testSocketCreation(host, port) {
  Socket.connect(host, port)
      .then((socket) => Expect.fail("Shouldn't get connected"))
      .catchError((e) => null, test: (e) => e is SocketIOException)
      .catchError((e) => null, test: (e) => e is ArgumentError);
}

testAdd(buffer) {
  ServerSocket.bind("127.0.0.1", 0, 5).then((server) {
    server.listen((socket) => socket.destroy());
    Socket.connect("127.0.0.1", server.port).then((socket) {
      int errors = 0;
      socket.done.catchError((e) { errors++; });
      socket.listen(
          (_) { },
          onError: (error) {
            Expect.fail("Error on stream");
          },
          onDone: () {
            Expect.equals(1, errors);
            socket.destroy();
            server.close();
          });
      socket.add(buffer);
    });
  });
}

testServerSocketCreation(address, port, backlog) {
  var server;
  var port = new ReceivePort();
  try {
    ServerSocket.bind(address, port, backlog)
        .then((_) { Expect.fail("ServerSocket bound"); });
  } catch (e) {
    port.close();
  }
}

main() {
  testSocketCreation(123, 123);
  testSocketCreation("string", null);
  testSocketCreation(null, null);
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
}
