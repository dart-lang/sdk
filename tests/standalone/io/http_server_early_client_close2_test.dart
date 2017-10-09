// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

main() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      String name = Platform.script.toFilePath();
      new File(name)
          .openRead()
          .pipe(request.response)
          .catchError((e) {/* ignore */});
    });

    var count = 0;
    makeRequest() {
      Socket.connect("127.0.0.1", server.port).then((socket) {
        var data = "GET / HTTP/1.1\r\nContent-Length: 0\r\n\r\n";
        socket.write(data);
        socket.close();
        socket.done.then((_) {
          socket.destroy();
          if (++count < 10) {
            makeRequest();
          } else {
            server.close();
          }
        });
      });
    }

    makeRequest();
  });
}
