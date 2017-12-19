// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void clientSocketAddCloseErrorTest() {
  asyncStart();
  ServerSocket.bind("127.0.0.1", 0).then((server) {
    var completer = new Completer();
    server.listen((socket) {
      completer.future.then((_) => socket.destroy());
    });
    Socket.connect("127.0.0.1", server.port).then((client) {
      const int SIZE = 1024 * 1024;
      int errors = 0;
      client.listen((data) => Expect.fail("Unexpected data"), onError: (error) {
        Expect.isTrue(error is SocketException);
        errors++;
      }, onDone: () {
        // We get either a close or an error followed by a close
        // on the socket.  Whether we get both depends on
        // whether the system notices the error for the read
        // event or only for the write event.
        Expect.isTrue(errors <= 1);
        server.close();
      });
      client.add(new List.filled(SIZE, 0));
      // Destroy other socket now.
      completer.complete(null);
      client.done.then((_) {
        Expect.fail("Expected error");
      }, onError: (error) {
        Expect.isTrue(error is SocketException);
        asyncEnd();
      });
    });
  });
}

main() {
  asyncStart();
  clientSocketAddCloseErrorTest();
  asyncEnd();
}
