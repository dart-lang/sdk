// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test checks that setting writeEventsEnabled on a socket that is
// closed for read (the other end has closed for write) does not send
// an additional READ_CLOSED event.

import "dart:io";
import "dart:async";
import "package:expect/expect.dart";

final Duration delay = new Duration(milliseconds: 100);
final List data = new List.generate(100, (i) => i % 20 + 65);
RawServerSocket server;
RawSocket client;
bool serverReadClosedReceived = false;
bool serverFirstWrite = true;

void serverListen(RawSocket serverSide) {
  void serveData(RawSocketEvent event) {
    switch (event) {
      case RawSocketEvent.WRITE:
        serverSide.write(data);
        if (serverFirstWrite) {
          serverFirstWrite = false;
          new Future.delayed(delay, () {
            serverSide.writeEventsEnabled = true;
          });
        } else {
          new Future.delayed(delay, () {
            Expect.isTrue(serverReadClosedReceived);
            serverSide.shutdown(SocketDirection.SEND);
            server.close();
          });
        }
        break;
      case RawSocketEvent.READ_CLOSED:
        Expect.isFalse(serverReadClosedReceived);
        serverReadClosedReceived = true;
        break;
    }
  }

  serverSide.listen(serveData);
}

test() async {
  server = await RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0);
  server.listen(serverListen);
  client = await RawSocket.connect(InternetAddress.LOOPBACK_IP_V4, server.port);
  client.shutdown(SocketDirection.SEND);
  client.listen((RawSocketEvent event) {
    if (event == RawSocketEvent.READ) {
      client.read();
    }
  });
}

void main() {
  test();
}
