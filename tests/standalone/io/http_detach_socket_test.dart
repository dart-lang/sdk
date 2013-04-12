// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:io";
import "dart:isolate";

void testServerDetachSocket() {
  HttpServer.bind().then((server) {
    server.listen((request) {
      var response = request.response;
      response.contentLength = 0;
      response.detachSocket().then((socket) {
        Expect.isNotNull(socket);
        var body = new StringBuffer();
        socket.listen(
          (data) => body.write(new String.fromCharCodes(data)),
          onDone: () => Expect.equals("Some data", body.toString()));
        socket.write("Test!");
        socket.close();
      });
      server.close();
    });

    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.write("GET / HTTP/1.1\r\n"
                   "content-length: 0\r\n\r\n"
                   "Some data");
      var body = new StringBuffer();
      socket.listen(
        (data) => body.write(new String.fromCharCodes(data)),
        onDone: () {
          Expect.equals("HTTP/1.1 200 OK\r\n"
                        "content-length: 0\r\n"
                        "\r\n"
                        "Test!",
                        body.toString());
          socket.close();
        });
    });
  });
}

void testBadServerDetachSocket() {
  HttpServer.bind().then((server) {
    server.listen((request) {
      var response = request.response;
      response.contentLength = 0;
      response.close();
      Expect.throws(response.detachSocket);
      server.close();
    });

    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.write("GET / HTTP/1.1\r\n"
                   "content-length: 0\r\n\r\n");
      socket.listen((_) {}, onDone: () {
          socket.close();
        });
    });
  });
}

void testClientDetachSocket() {
  ServerSocket.bind().then((server) {
    server.listen((socket) {
      socket.write("HTTP/1.1 200 OK\r\n"
                       "\r\n"
                       "Test!");
      var body = new StringBuffer();
      socket.listen(
        (data) => body.write(new String.fromCharCodes(data)),
        onDone: () {
          Expect.equals("GET / HTTP/1.1\r\n"
                        "accept-encoding: gzip\r\n"
                        "content-length: 0\r\n"
                        "host: 127.0.0.1:${server.port}\r\n\r\n"
                        "Some data",
                        body.toString());
          socket.close();
        });
      server.close();
    });

    var client = new HttpClient();
    client.get("127.0.0.1", server.port, "/")
      .then((request) => request.close())
      .then((response) {
        response.detachSocket().then((socket) {
          var body = new StringBuffer();
          socket.listen(
            (data) => body.write(new String.fromCharCodes(data)),
            onDone: () {
              Expect.equals("Test!",
                            body.toString());
              client.close();
            });
          socket.write("Some data");
          socket.close();
        });
      });
  });
}

void main() {
  testServerDetachSocket();
  testBadServerDetachSocket();
  testClientDetachSocket();
}
