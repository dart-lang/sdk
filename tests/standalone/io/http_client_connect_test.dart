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

void testGetEmptyRequest() {
  HttpServer.bind().then((server) {
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
  HttpServer.bind().then((server) {
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
  var port = new ReceivePort();
  var client = new HttpClient();
  client.get("__SOMETHING_INVALID__", 8888, "/")
    .catchError((error) {
      port.close();
      client.close();
    });
}

void testGetServerClose() {
  HttpServer.bind().then((server) {
    server.listen((request) {
      server.close();
    });

    var port = new ReceivePort();
    var client = new HttpClient();
    client.get("127.0.0.1", server.port, "/")
      .then((request) => request.close())
      .then((response) {
        Expect.fail("Request not expected");
      })
        .catchError((error) => port.close(),
                    test: (error) => error is HttpParserException);
  });
}

void testGetDataServerClose() {
  var completer = new Completer();
  HttpServer.bind().then((server) {
    server.listen((request) {
      request.response.contentLength = 100;
      request.response.write("data");
      request.response.write("more data");
      completer.future.then((_) => server.close());
    });

    var port = new ReceivePort();
    var client = new HttpClient();
    client.get("127.0.0.1", server.port, "/")
      .then((request) => request.close())
      .then((response) {
        // Close the (incomplete) response, now we have seen the response object.
        completer.complete(null);
        int errors = 0;
        response.listen(
          (data) {},
          onError: (error) => errors++,
          onDone: () {
            port.close();
            Expect.equals(1, errors);
          });
      });
  });
}

void testPostEmptyRequest() {
  HttpServer.bind().then((server) {
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
  testGetDataServerClose();
  testPostEmptyRequest();
}
