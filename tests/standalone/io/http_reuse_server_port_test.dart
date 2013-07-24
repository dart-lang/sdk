// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

Future<int> runServer(int port, int connections, bool clean) {
  var completer = new Completer();
  HttpServer.bind("127.0.0.1", port).then((server) {
    int i = 0;
    server.listen((request) {
      request.pipe(request.response);
      i++;
      if (!clean && i == 10) {
        int port = server.port;
        server.close().then((_) => completer.complete(port));
      }
    });

    Future.wait(new List.generate(connections, (_) {
      var client = new HttpClient();
      return client.get("127.0.0.1", server.port, "/")
          .then((request) => request.close())
          .then((response) => response.drain())
          .catchError((e) { if (clean) throw e; });
    })).then((_) {
      if (clean) {
        int port = server.port;
        server.close().then((_) => completer.complete(port));
      }
    });
  });
  return completer.future;
}


void testReusePort() {
  var keepAlive = new ReceivePort();
  runServer(0, 10, true).then((int port) {
    // Stress test the port reusing it 10 times.
    Future.forEach(new List(10), (_) {
      return runServer(port, 10, true);
    }).then((_) {
      keepAlive.close();
    });
  });
}


void testUncleanReusePort() {
  var keepAlive = new ReceivePort();
  runServer(0, 10, false).then((int port) {
    // Stress test the port reusing it 10 times.
    Future.forEach(new List(10), (_) {
      return runServer(port, 10, false);
    }).then((_) {
      keepAlive.close();
    });
  });
}


void main() {
  testReusePort();
  testUncleanReusePort();
}
