// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void clientSocketAddCloseNoErrorTest() {
  ServerSocket.bind("127.0.0.1", 0).then((server) {
    var completer = new Completer();
    server.listen((socket) {
      // The socket is 'paused' until the future completes.
      completer.future.then((_) => socket.cast<List<int>>().pipe(socket));
    });
    Socket.connect("127.0.0.1", server.port).then((client) {
      const int SIZE = 1024 * 1024;
      int count = 0;
      client.listen((data) => count += data.length, onDone: () {
        Expect.equals(SIZE, count);
        server.close();
      });
      client.add(new List.filled(SIZE, 0));
      client.close();
      // Start piping now.
      completer.complete(null);
    });
  });
}

main() {
  asyncStart();
  clientSocketAddCloseNoErrorTest();
  asyncEnd();
}
