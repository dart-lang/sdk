// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "dart:io";
import "dart:isolate";

void testServerDetachSocket() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.defaultResponseHeaders.clear();
    server.serverHeader = null;
    server.listen((request) {
      var response = request.response;
      response.contentLength = 0;
      response.detachSocket().then((socket) {
        Expect.isNotNull(socket);
        var body = new StringBuffer();
        socket.listen((data) => body.write(new String.fromCharCodes(data)),
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
      socket.listen((data) => body.write(new String.fromCharCodes(data)),
          onDone: () {
        Expect.equals(
            "HTTP/1.1 200 OK\r\n"
            "content-length: 0\r\n"
            "\r\n"
            "Test!",
            body.toString());
        socket.close();
      });
    });
  });
}

void testServerDetachSocketNoWriteHeaders() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      var response = request.response;
      response.contentLength = 0;
      response.detachSocket(writeHeaders: false).then((socket) {
        Expect.isNotNull(socket);
        var body = new StringBuffer();
        socket.listen((data) => body.write(new String.fromCharCodes(data)),
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
      socket.listen((data) => body.write(new String.fromCharCodes(data)),
          onDone: () {
        Expect.equals("Test!", body.toString());
        socket.close();
      });
    });
  });
}

void testBadServerDetachSocket() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
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
  ServerSocket.bind("127.0.0.1", 0).then((server) {
    server.listen((socket) {
      int port = server.port;
      socket.write("HTTP/1.1 200 OK\r\n"
          "\r\n"
          "Test!");
      var body = new StringBuffer();
      socket.listen((data) => body.write(new String.fromCharCodes(data)),
          onDone: () {
        List<String> lines = body.toString().split("\r\n");
        Expect.equals(6, lines.length);
        Expect.equals("GET / HTTP/1.1", lines[0]);
        Expect.equals("", lines[4]);
        Expect.equals("Some data", lines[5]);
        lines.sort(); // Lines 1-3 becomes 3-5 in a fixed order.
        Expect.equals("accept-encoding: gzip", lines[3]);
        Expect.equals("content-length: 0", lines[4]);
        Expect.equals("host: 127.0.0.1:${port}", lines[5]);
        socket.close();
      });
      server.close();
    });

    var client = new HttpClient();
    client.userAgent = null;
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
      response.detachSocket().then((socket) {
        var body = new StringBuffer();
        socket.listen((data) => body.write(new String.fromCharCodes(data)),
            onDone: () {
          Expect.equals("Test!", body.toString());
          client.close();
        });
        socket.write("Some data");
        socket.close();
      });
    });
  });
}

void testUpgradedConnection() {
  asyncStart();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.response.headers.set('connection', 'upgrade');
      if (request.headers.value('upgrade') == 'mine') {
        asyncStart();
        request.response.detachSocket().then((socket) {
          socket.pipe(socket).then((_) {
            asyncEnd();
          });
        });
      } else {
        request.response.close();
      }
    });

    var client = new HttpClient();
    client.userAgent = null;
    client.get("127.0.0.1", server.port, "/").then((request) {
      request.headers.set('upgrade', 'mine');
      return request.close();
    }).then((response) {
      client.get("127.0.0.1", server.port, "/").then((request) {
        response.detachSocket().then((socket) {
          // We are testing that we can detach the socket, even though
          // we made a new connection (testing it was not reused).
          request.close().then((response) {
            asyncStart();
            response.listen(null, onDone: () {
              server.close();
              asyncEnd();
            });
            socket.add([0]);
            socket.close();
            socket.fold([], (l, d) => l..addAll(d)).then((data) {
              asyncEnd();
              Expect.listEquals([0], data);
            });
          });
        });
      });
    });
  });
}

void main() {
  testServerDetachSocket();
  testServerDetachSocketNoWriteHeaders();
  testBadServerDetachSocket();
  testClientDetachSocket();
  testUpgradedConnection();
}
