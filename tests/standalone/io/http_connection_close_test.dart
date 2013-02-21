// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "dart:async";
import "dart:io";
import "dart:uri";

void testHttp10Close(bool closeRequest) {
  HttpServer.bind().then((server) {
    server.listen((request) {
      request.response.close();
    });

    Socket.connect("127.0.0.1", server.port)
      .then((socket) {
        socket.addString("GET / HTTP/1.0\r\n\r\n");
        socket.listen(
          (data) {},
          onDone: () {
           if (!closeRequest) socket.destroy();
            server.close();
          });
        if (closeRequest) socket.close();
      });
  });
}

void testHttp11Close(bool closeRequest) {
  HttpServer.bind().then((server) {
    server.listen((request) {
     request.response.close();
    });

    Socket.connect("127.0.0.1", server.port)
      .then((socket) {
        List<int> buffer = new List<int>.fixedLength(1024);
        socket.addString("GET / HTTP/1.1\r\nConnection: close\r\n\r\n");
        socket.listen(
          (data) {},
          onDone: () {
            if (!closeRequest) socket.destroy();
            server.close();
          });
        if (closeRequest) socket.close();
      });
  });
}

void testStreamResponse() {
  HttpServer.bind().then((server) {
    server.listen((request) {
      // TODO(ajohnsen): Use timer (see old version).
      for (int i = 0; i < 10; i++) {
        request.response.addString(
            'data:${new DateTime.now().millisecondsSinceEpoch}\n\n');
      }
    });

    var client = new HttpClient();
    client.getUrl(Uri.parse("http://127.0.0.1:${server.port}"))
      .then((request) => request.close())
      .then((response) {
        int bytes = 0;
        response.listen(
            (data) {
              bytes += data.length;
              if (bytes > 100) {
                client.close(force: true);
              }
            },
            onError: (error) {
              server.close();
            });
      });
  });
}

main() {
  testHttp10Close(false);
  testHttp10Close(true);
  testHttp11Close(false);
  testHttp11Close(true);
  testStreamResponse();
}
