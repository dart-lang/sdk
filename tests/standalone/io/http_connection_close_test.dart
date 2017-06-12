// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";

void testHttp10Close(bool closeRequest) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.response.close();
    });

    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.write("GET / HTTP/1.0\r\n\r\n");
      socket.listen((data) {}, onDone: () {
        if (!closeRequest) socket.destroy();
        server.close();
      });
      if (closeRequest) socket.close();
    });
  });
}

void testHttp11Close(bool closeRequest) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.response.close();
    });

    Socket.connect("127.0.0.1", server.port).then((socket) {
      List<int> buffer = new List<int>(1024);
      socket.write("GET / HTTP/1.1\r\nConnection: close\r\n\r\n");
      socket.listen((data) {}, onDone: () {
        if (!closeRequest) socket.destroy();
        server.close();
      });
      if (closeRequest) socket.close();
    });
  });
}

void testStreamResponse() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      var timer = new Timer.periodic(const Duration(milliseconds: 0), (_) {
        request.response
            .write('data:${new DateTime.now().millisecondsSinceEpoch}\n\n');
      });
      request.response.done.whenComplete(() {
        timer.cancel();
      }).catchError((_) {});
    });

    var client = new HttpClient();
    client
        .getUrl(Uri.parse("http://127.0.0.1:${server.port}"))
        .then((request) => request.close())
        .then((response) {
      int bytes = 0;
      response.listen((data) {
        bytes += data.length;
        if (bytes > 100) {
          client.close(force: true);
        }
      }, onError: (error) {
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
