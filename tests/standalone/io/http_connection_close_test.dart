// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

#import("dart:isolate");
#import("dart:io");
#import("dart:uri");

void testHttp10Close(bool closeRequest) {
  HttpServer server = new HttpServer();
  server.listen("127.0.0.1", 0, backlog: 5);

  Socket socket = new Socket("127.0.0.1", server.port);
  socket.onConnect = () {
    List<int> buffer = new List<int>(1024);
    socket.outputStream.writeString("GET / HTTP/1.0\r\n\r\n");
    if (closeRequest) socket.outputStream.close();
    socket.onData = () => socket.readList(buffer, 0, buffer.length);
    socket.onClosed = () {
      if (!closeRequest) socket.close(true);
      server.close();
    };
  };
}

void testHttp11Close(bool closeRequest) {
  HttpServer server = new HttpServer();
  server.listen("127.0.0.1", 0, backlog: 5);

  Socket socket = new Socket("127.0.0.1", server.port);
  socket.onConnect = () {
    List<int> buffer = new List<int>(1024);
    socket.outputStream.writeString(
        "GET / HTTP/1.1\r\nConnection: close\r\n\r\n");
    if (closeRequest) socket.outputStream.close();
    socket.onData = () => socket.readList(buffer, 0, buffer.length);
    socket.onClosed = () {
      if (!closeRequest) socket.close(true);
      server.close();
    };
  };
}

void testStreamResponse() {
  var server = new HttpServer();
  server.listen("127.0.0.1", 0, backlog: 5);
  server.defaultRequestHandler = (var request, var response) {
    new Timer.repeating(10, (x) {
      Date now = new Date.now();
      try {
        response.outputStream.writeString(
            'data:${now.millisecondsSinceEpoch}\n\n');
      } catch (e) {
        x.cancel();
        server.close();
      }
    });
  };

  var client = new HttpClient();
  var connection =
      client.getUrl(new Uri.fromString("http://127.0.0.1:${server.port}"));
  connection.onResponse = (resp) {
    int bytes = 0;
    resp.inputStream.onData = () {
      bytes += resp.inputStream.read().length;
      if (bytes > 100) {
        client.shutdown();
      }
    };
  };
}

main() {
  testHttp10Close(false);
  testHttp10Close(true);
  testHttp11Close(false);
  testHttp11Close(true);
  testStreamResponse();
}
