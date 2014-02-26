// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

void testPort() {
  ServerSocket.bind("127.0.0.1", 0).then((server) {
    Socket.connect("127.0.0.1", server.port).then((clientSocket) {
      server.listen((Socket socket) {
        Expect.equals(socket.port, server.port);
        Expect.equals(clientSocket.port, socket.remotePort);
        Expect.equals(clientSocket.remotePort, socket.port);
        clientSocket.destroy();
        socket.destroy();
        server.close();
      });
    });
  });
}

void main() {
  testPort();
}
