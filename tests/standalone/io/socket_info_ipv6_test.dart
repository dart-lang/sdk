// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

void testHostAndPort() {
  ServerSocket.bind("::1", 0).then((server) {
    Socket.connect("::1", server.port).then((clientSocket) {
      server.listen((socket) {
        Expect.equals(socket.port, server.port);
        Expect.equals(clientSocket.port, socket.remotePort);
        Expect.equals(clientSocket.remotePort, socket.port);
        Expect.equals(socket.remoteAddress.address, "::1");
        Expect.equals(socket.remoteAddress.type, InternetAddressType.IP_V6);
        Expect.listEquals(socket.remoteAddress.rawAddress,
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]);
        Expect.equals(clientSocket.remoteAddress.address, "::1");
        Expect.equals(
            clientSocket.remoteAddress.type, InternetAddressType.IP_V6);
        Expect.listEquals(clientSocket.remoteAddress.rawAddress,
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]);
        socket.destroy();
        clientSocket.destroy();
        server.close();
      });
    });
  });
}

void main() {
  testHostAndPort();
}
