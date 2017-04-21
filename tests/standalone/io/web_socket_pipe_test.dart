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

createReverseStringTransformer() {
  return new StreamTransformer.fromHandlers(handleData: (String data, sink) {
    var sb = new StringBuffer();
    for (int i = data.length - 1; i >= 0; i--) sb.write(data[i]);
    sink.add(sb.toString());
  });
}

testPipe({int messages, bool transform}) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      WebSocketTransformer.upgrade(request).then((websocket) {
        (transform
                ? websocket.transform(createReverseStringTransformer())
                : websocket)
            .pipe(websocket)
            .then((_) => server.close());
      });
    });
    WebSocket.connect("ws://127.0.0.1:${server.port}/").then((client) {
      var count = 0;
      next() {
        if (count < messages) {
          client.add("Hello");
        } else {
          client.close();
        }
      }

      client.listen((data) {
        count++;
        if (transform) {
          Expect.equals("olleH", data);
        } else {
          Expect.equals("Hello", data);
        }
        next();
      }, onDone: () => print("Client received close"));

      next();
    });
  });
}

void main() {
  testPipe(messages: 0, transform: false);
  testPipe(messages: 0, transform: true);
  testPipe(messages: 1, transform: false);
  testPipe(messages: 1, transform: true);
  testPipe(messages: 10, transform: false);
  testPipe(messages: 10, transform: true);
}
