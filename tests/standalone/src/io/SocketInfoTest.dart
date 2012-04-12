// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");

void testHostAndPort() {
  ServerSocket server = new ServerSocket("127.0.0.1", 0, 5);

  Socket clientSocket = new Socket("127.0.0.1", server.port);

  server.onConnection = (Socket socket) {
    Expect.equals(socket.port, server.port);
    Expect.equals(clientSocket.port, socket.remotePort);
    Expect.equals(clientSocket.remotePort, socket.port);
    Expect.equals(socket.remoteHost, "127.0.0.1");
    Expect.equals(clientSocket.remoteHost, "127.0.0.1");

    server.close();
  };
}

void main() {
  testHostAndPort();
}
