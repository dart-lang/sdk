// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:async";
import "dart:io";
import "dart:isolate";

void testCancelResubscribeServerSocket() {
  const int socketCount = 10;
  var acceptCount = 0;
  var doneCount = 0;
  var closeCount = 0;
  var errorCount = 0;

  ReceivePort port = new ReceivePort();

  RawServerSocket.bind().then((server) {
    Expect.isTrue(server.port > 0);

    void checkDone() {
      if (doneCount == socketCount &&
          closeCount + errorCount == socketCount) {
        port.close();
      }
    }

    // Subscribe the server socket. Then cancel subscription and
    // subscribe again.
    var subscription;
    subscription = server.listen((client) {
      if (++acceptCount == socketCount / 2) {
        subscription.cancel();
        Timer.run(() {
          subscription = server.listen((_) {
            // Close on cancel, so no more events.
            Expect.fail("Event after closed through cancel");
          });
        });
      }
      // Close the client socket.
      client.close();
    });

    // Connect a number of sockets.
    for (int i = 0; i < socketCount; i++) {
      RawSocket.connect("127.0.0.1", server.port).then((socket) {
        socket.writeEventsEnabled = false;
        var subscription;
        subscription = socket.listen((event) {
          Expect.equals(RawSocketEvent.READ_CLOSED, event);
          socket.close();
          closeCount++;
          checkDone();
        },
        onDone: () { doneCount++; checkDone(); },
        onError: (e) { errorCount++; checkDone(); });
      }).catchError((e) {
        errorCount++; checkDone();
      });
    }
  });
}

void main() {
  testCancelResubscribeServerSocket();
}
