// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test checks that a shutdown(SocketDirection.SEND) of a socket,
// when the other end is already closed, does not discard unread data
// that remains in the connection.

import "dart:io";
import "dart:async";
import "package:expect/expect.dart";

RawServerSocket server;
RawSocket client;
Duration delay = new Duration(milliseconds: 100);

void serverListen(RawSocket serverSide) {
  var data = new List.generate(200, (i) => i % 20 + 65);
  var offset = 0;
  void serveData(RawSocketEvent event) {
    if (event == RawSocketEvent.WRITE) {
      while (offset < data.length) {
        var written = serverSide.write(data, offset);
        offset += written;
        if (written == 0) {
          serverSide.writeEventsEnabled = true;
          return;
        }
      }
      serverSide.close();
      server.close();
    }
  }

  serverSide.listen(serveData);
}

void clientListen(RawSocketEvent event) {
  if (event == RawSocketEvent.READ) {
    client.readEventsEnabled = false;
    new Future.delayed(delay, () {
      var data = client.read(100);
      if (data == null) {
        // If there is no data ready to read, wait until there is data
        // that can be read, before running the rest of the test.
        client.readEventsEnabled = true;
        return;
      }
      client.shutdown(SocketDirection.SEND);
      data = client.read(100);
      Expect.isNotNull(data);
      client.close();
    });
  }
}

test() async {
  server = await RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0);
  server.listen(serverListen);
  client = await RawSocket.connect(InternetAddress.LOOPBACK_IP_V4, server.port);
  client.listen(clientListen);
}

void main() {
  test();
}
