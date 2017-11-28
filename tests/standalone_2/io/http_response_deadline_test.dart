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

void testSimpleDeadline(int connections) {
  HttpServer.bind('localhost', 0).then((server) {
    server.listen((request) {
      request.response.deadline = const Duration(seconds: 1000);
      request.response.write("stuff");
      request.response.close();
    });

    var futures = <Future>[];
    var client = new HttpClient();
    for (int i = 0; i < connections; i++) {
      futures.add(client
          .get('localhost', server.port, '/')
          .then((request) => request.close())
          .then((response) => response.drain()));
    }
    Future.wait(futures).then((_) => server.close());
  });
}

void testExceedDeadline(int connections) {
  HttpServer.bind('localhost', 0).then((server) {
    server.listen((request) {
      request.response.deadline = const Duration(milliseconds: 100);
      request.response.contentLength = 10000;
      request.response.write("stuff");
    });

    var futures = <Future>[];
    var client = new HttpClient();
    for (int i = 0; i < connections; i++) {
      futures.add(client
          .get('localhost', server.port, '/')
          .then((request) => request.close())
          .then((response) => response.drain())
          .then((_) {
        Expect.fail("Expected error");
      }, onError: (e) {
        // Expect error.
      }));
    }
    Future.wait(futures).then((_) => server.close());
  });
}

void testDeadlineAndDetach(int connections) {
  HttpServer.bind('localhost', 0).then((server) {
    server.listen((request) {
      request.response.deadline = const Duration(milliseconds: 0);
      request.response.contentLength = 5;
      request.response.persistentConnection = false;
      request.response.detachSocket().then((socket) {
        new Timer(const Duration(milliseconds: 100), () {
          socket.write('stuff');
          socket.close();
          socket.listen(null);
        });
      });
    });

    var futures = <Future>[];
    var client = new HttpClient();
    for (int i = 0; i < connections; i++) {
      futures.add(client
          .get('localhost', server.port, '/')
          .then((request) => request.close())
          .then((response) {
        return response
            .fold(new BytesBuilder(), (b, d) => b..add(d))
            .then((builder) {
          Expect.equals('stuff', new String.fromCharCodes(builder.takeBytes()));
        });
      }));
    }
    Future.wait(futures).then((_) => server.close());
  });
}

void main() {
  testSimpleDeadline(10);
  testExceedDeadline(10);
  testDeadlineAndDetach(10);
}
