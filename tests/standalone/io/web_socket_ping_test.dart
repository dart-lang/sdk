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


void testPing(int totalConnections) {
  HttpServer.bind('localhost', 0).then((server) {
    // The completers will be completed when the pingInterval have terminated
    // the webSockets.
    var completers = new List.generate(
        totalConnections, (_) => new Completer());

    int conns = 0;
    server.transform(new WebSocketTransformer()).listen((webSocket) {
      int i = conns++;
      webSocket.pingInterval = const Duration(milliseconds: 100);
      webSocket.drain();
      var timer = new Timer.periodic(const Duration(milliseconds: 10), (_) {
        webSocket.add(new List.filled(10 * 1024, 0));
      });
      webSocket.done.then((_) {
        completers[i].complete();
        timer.cancel();
        Expect.equals(WebSocketStatus.GOING_AWAY, webSocket.closeCode);
        webSocket.close();
      });
    });

    var futures = [];
    for (int i = 0; i < totalConnections; i++) {
      futures.add(
          WebSocket.connect('ws://localhost:${server.port}')
              .then((webSocket) {
                // Don't drain yet, to block data.
                // Once the server is done, drain the peers.
                return Future.wait(completers.map((c) => c.future))
                    .then((_) => webSocket.drain());
              }));
    }
    Future.wait(futures).then((_) => server.close());
  });
}


void main() {
  testPing(10);
}
