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

void testCancelResubscribeServerSocket(int socketCount, int backlog) {
  var acceptCount = 0;
  var doneCount = 0;
  var closeCount = 0;
  var errorCount = 0;
  var earlyErrorCount = 0;

  ReceivePort port = new ReceivePort();

  RawServerSocket.bind("127.0.0.1", 0, backlog).then((server) {
    Expect.isTrue(server.port > 0);

    void checkDone() {
      if (doneCount + earlyErrorCount == socketCount &&
          closeCount + errorCount + earlyErrorCount == socketCount) {
        port.close();
      }
    }

    var subscription;
    subscription = server.listen((client) {
      client.writeEventsEnabled = false;
      client.listen((event) {
        switch(event) {
          case RawSocketEvent.READ:
            client.read();
            break;
          case RawSocketEvent.READ_CLOSED:
            client.shutdown(SocketDirection.SEND);
            break;
          case RawSocketEvent.WRITE:
            Expect.fail("No write event expected");
            break;
        }
      });

      if (++acceptCount == socketCount / 2) {
        // Cancel subscription and then attempt to resubscribe.
        subscription.cancel();
        Timer.run(() {
          subscription = server.listen((_) {
            // Server socket is closed on cancel, so no more events.
            Expect.fail("Event after closed through cancel");
          });
        });
      }
    });

    // Connect a number of sockets.
    for (int i = 0; i < socketCount; i++) {
      RawSocket.connect("127.0.0.1", server.port).then((socket) {
        var subscription;
        subscription = socket.listen((event) {
          switch(event) {
            case RawSocketEvent.READ:
              Expect.fail("No read event expected");
              break;
            case RawSocketEvent.READ_CLOSED:
              closeCount++;
              checkDone();
              break;
            case RawSocketEvent.WRITE:
              // We don't care if this write succeeds, so we don't check
              // the return value (number of bytes written).
              socket.write([1,2,3]);
              socket.shutdown(SocketDirection.SEND);
              break;
          }
        },
        onDone: () {
          doneCount++;
          checkDone();
        },
        onError: (e) {
          // "Connection reset by peer" errors are handled here.
          errorCount++;
          checkDone();
        });
      }).catchError((e) {
        // "Connection actively refused by host" errors are handled here.
        earlyErrorCount++;
        checkDone();
      });
    }
  });
}

void main() {
  testCancelResubscribeServerSocket(10, 20);
  testCancelResubscribeServerSocket(20, 5);
}
