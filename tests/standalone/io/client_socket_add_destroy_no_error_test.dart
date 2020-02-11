// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void clientSocketAddDestroyNoErrorTest() {
  ServerSocket.bind("127.0.0.1", 0).then((server) {
    server.listen((socket) {
      // Passive block data by not subscribing to socket.
    });
    Socket.connect("127.0.0.1", server.port).then((client) {
      client.listen((data) {}, onDone: server.close);
      client.add(new List.filled(1024 * 1024, 0));
      client.destroy();
    });
  });
}

main() {
  asyncStart();
  clientSocketAddDestroyNoErrorTest();
  asyncEnd();
}
