// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

#import("dart:isolate");
#import("dart:io");

void testHttp10Close() {
  HttpServer server = new HttpServer();
  server.listen("127.0.0.1", 0, backlog: 5);

  Socket socket = new Socket("127.0.0.1", server.port);
  socket.onConnect = () {
    List<int> buffer = new List<int>(1024);
    socket.outputStream.writeString("GET / HTTP/1.0\r\n\r\n");
    socket.onData = () => socket.readList(buffer, 0, buffer.length);
    socket.onClosed = () {
      socket.close(true);
      server.close();
    };
  };
}

void testHttp11Close() {
  HttpServer server = new HttpServer();
  server.listen("127.0.0.1", 0, backlog: 5);

  Socket socket = new Socket("127.0.0.1", server.port);
  socket.onConnect = () {
    List<int> buffer = new List<int>(1024);
    socket.outputStream.writeString(
        "GET / HTTP/1.1\r\nConnection: close\r\n\r\n");
    socket.onData = () => socket.readList(buffer, 0, buffer.length);
    socket.onClosed = () {
      socket.close(true);
      server.close();
    };
  };
}

main() {
  testHttp10Close();
  testHttp11Close();
}
