// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testGetEmptyRequest() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.pipe(request.response);
    });

    var client = new HttpClient();
    client.get("127.0.0.1", server.port, "/")
      .then((request) => request.close())
      .then((response) {
        response.listen(
            (data) {},
            onDone: server.close);
      });
  });
}

void testGetDataRequest() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    var data = "lalala".codeUnits;
    server.listen((request) {
      request.response.add(data);
      request.pipe(request.response);
    });

    var client = new HttpClient();
    client.get("127.0.0.1", server.port, "/")
      .then((request) => request.close())
      .then((response) {
        int count = 0;
        response.listen(
          (data) => count += data.length,
          onDone: () {
            server.close();
            Expect.equals(data.length, count);
          });
      });
  });
}

void testGetInvalidHost() {
  asyncStart();
  var client = new HttpClient();
  client.get("__SOMETHING_INVALID__", 8888, "/")
    .catchError((error) {
      client.close();
      asyncEnd();
    });
}

void testGetServerClose() {
  asyncStart();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      server.close();
      new Timer(const Duration(milliseconds: 100), () {
        request.response.close();
      });
    });

    var client = new HttpClient();
    client.get("127.0.0.1", server.port, "/")
      .then((request) => request.close())
      .then((response) => response.drain())
      .then((_) => asyncEnd());
  });
}

void testGetServerCloseNoKeepAlive() {
  asyncStart();
  var client = new HttpClient();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    int port = server.port;
    server.first.then((request) => request.response.close());

    client.get("127.0.0.1", port, "/")
      .then((request) => request.close())
      .then((response) => response.drain())
      .then((_) => client.get("127.0.0.1", port, "/"))
      .then((request) => request.close())
      .then((_) => Expect.fail('should not succeed'), onError: (_) {})
      .then((_) => asyncEnd());
  });
}

void testGetServerForceClose() {
  asyncStart();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      server.close(force: true);
    });

    var client = new HttpClient();
    client.get("127.0.0.1", server.port, "/")
      .then((request) => request.close())
      .then((response) {
        Expect.fail("Request not expected");
      })
      .catchError((error) => asyncEnd(),
                  test: (error) => error is HttpException);
  });
}

void testGetDataServerForceClose() {
  asyncStart();
  var completer = new Completer();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.response.contentLength = 100;
      request.response.write("data");
      request.response.write("more data");
      completer.future.then((_) => server.close(force: true));
    });

    var client = new HttpClient();
    client.get("127.0.0.1", server.port, "/")
      .then((request) => request.close())
      .then((response) {
        // Close the (incomplete) response, now that we have seen
        // the response object.
        completer.complete(null);
        int errors = 0;
        response.listen(
          (data) {},
          onError: (error) => errors++,
          onDone: () {
            Expect.equals(1, errors);
            asyncEnd();
          });
      });
  });
}

void testPostEmptyRequest() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.pipe(request.response);
    });

    var client = new HttpClient();
    client.post("127.0.0.1", server.port, "/")
      .then((request) => request.close())
      .then((response) {
        response.listen((data) {}, onDone: server.close);
      });
  });
}


void main() {
  testGetEmptyRequest();
  testGetDataRequest();
  testGetInvalidHost();
  testGetServerClose();
  testGetServerCloseNoKeepAlive();
  testGetServerForceClose();
  // TODO(14953): This test can only run, when buffering is disabled.
  // testGetDataServerForceClose();
  testPostEmptyRequest();
}
