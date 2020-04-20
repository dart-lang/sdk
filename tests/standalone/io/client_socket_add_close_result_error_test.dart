// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void clientSocketAddCloseResultErrorTest() {
  ServerSocket.bind("127.0.0.1", 0).then((server) {
    var completer = new Completer();
    server.listen((socket) {
      completer.future.then((_) => socket.destroy());
    });
    Socket.connect("127.0.0.1", server.port).then((client) {
      const int SIZE = 1024 * 1024;
      int errors = 0;
      client.add(new List.filled(SIZE, 0));
      client.close();
      client.done.catchError((_) {}).whenComplete(() {
        server.close();
      });
      // Destroy other socket now.
      completer.complete(null);
    });
  });
}

main() {
  asyncStart();
  clientSocketAddCloseResultErrorTest();
  asyncEnd();
}
