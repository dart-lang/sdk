// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';


void testOneRequest(int connections) {
  HttpServer.bind('127.0.0.1', 0).then((server) {
    server.listen((request) => request.response.close());
    var client = new HttpClient();
    var futures = [];
    for (int i = 0; i < connections; i++) {
      futures.add(
          client.get('127.0.0.1', server.port, '/')
              .then((request) => request.close())
              .then((response) => response.fold(null, (x, y) {})));
    }
    Future.wait(futures).then((_) {
      new Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (server.connectionsInfo().total == 0) {
          timer.cancel();
          server.close();
        }
      });
    });
  });
}


void testIdleTimeout(int timeout) {
  HttpServer.bind('127.0.0.1', 0).then((server1) {
    HttpServer.bind('127.0.0.1', 0).then((server2) {
      server1.listen((request) => request.pipe(request.response));
      server2.listen((request) => request.pipe(request.response));

      var client = new HttpClient();
      client.idleTimeout = new Duration(milliseconds: timeout);

      // Create a 'slow' connection..
      Future connect(int port) {
        return client.post('127.0.0.1', port, '/')
            .then((request) {
              request.write("data");
              new Timer(const Duration(milliseconds: 250), () {
                request.close();
              });
              return request.done;
            })
            .then((response) {
              return response.fold(null, (x, y) {});
            });
      }

      // Create a single, slow request, to server1.
      connect(server1.port);

      // Create a repeating connection to server2.
      run() {
        connect(server2.port).then((_) {
          if (server1.connectionsInfo().total == 0) {
            server1.close();
            server2.close();
            return;
          }
          Timer.run(run);
        });
      }
      run();
    });
  });
}


main() {
  testOneRequest(1);
  testOneRequest(5);
  testOneRequest(20);
  testIdleTimeout(0);
  testIdleTimeout(100);
  testIdleTimeout(500);
  testIdleTimeout(1000);
  testIdleTimeout(2000);
}
