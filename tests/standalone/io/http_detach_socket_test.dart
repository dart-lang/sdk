// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:convert";
import "dart:io";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

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
        socket.listen(
          (data) => body.write(new String.fromCharCodes(data)),
          onDone: () => Expect.equals("Some data", body.toString()),
        );
        socket.write("Test!");
        socket.close();
      });
      server.close();
    });

    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.write(
        "GET / HTTP/1.1\r\n"
        "content-length: 0\r\n\r\n"
        "Some data",
      );
      var body = new StringBuffer();
      socket.listen(
        (data) => body.write(new String.fromCharCodes(data)),
        onDone: () {
          Expect.equals(
            "HTTP/1.1 200 OK\r\n"
            "content-length: 0\r\n"
            "\r\n"
            "Test!",
            body.toString(),
          );
          socket.close();
        },
      );
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
        socket.listen(
          (data) => body.write(new String.fromCharCodes(data)),
          onDone: () => Expect.equals("Some data", body.toString()),
        );
        socket.write("Test!");
        socket.close();
      });
      server.close();
    });

    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.write(
        "GET / HTTP/1.1\r\n"
        "content-length: 0\r\n\r\n"
        "Some data",
      );
      var body = new StringBuffer();
      socket.listen(
        (data) => body.write(new String.fromCharCodes(data)),
        onDone: () {
          Expect.equals("Test!", body.toString());
          socket.close();
        },
      );
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
      socket.write(
        "GET / HTTP/1.1\r\n"
        "content-length: 0\r\n\r\n",
      );
      socket.listen(
        (_) {},
        onDone: () {
          socket.close();
        },
      );
    });
  });
}

void testClientDetachSocket() {
  ServerSocket.bind("127.0.0.1", 0).then((server) {
    server.listen((socket) {
      int port = server.port;
      socket.write(
        "HTTP/1.1 200 OK\r\n"
        "\r\n"
        "Test!",
      );
      var body = new StringBuffer();
      socket.listen(
        (data) => body.write(new String.fromCharCodes(data)),
        onDone: () {
          List<String> lines = body.toString().split("\r\n");
          Expect.equals(5, lines.length);
          Expect.equals("GET / HTTP/1.1", lines[0]);
          Expect.equals("", lines[3]);
          Expect.equals("Some data", lines[4]);
          lines.sort(); // Lines 1-2 becomes 3-4 in a fixed order.
          Expect.equals("accept-encoding: gzip", lines[3]);
          Expect.equals("host: 127.0.0.1:${port}", lines[4]);
          socket.close();
        },
      );
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
            socket.listen(
              (data) => body.write(new String.fromCharCodes(data)),
              onDone: () {
                Expect.equals("Test!", body.toString());
                client.close();
              },
            );
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
          socket.cast<List<int>>().pipe(socket).then((_) {
            asyncEnd();
          });
        });
      } else {
        request.response.close();
      }
    });

    var client = new HttpClient();
    client.userAgent = null;
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) {
          request.headers.set('upgrade', 'mine');
          return request.close();
        })
        .then((response) {
          client.get("127.0.0.1", server.port, "/").then((request) {
            response.detachSocket().then((socket) {
              // We are testing that we can detach the socket, even though
              // we made a new connection (testing it was not reused).
              request.close().then((response) {
                asyncStart();
                response.listen(
                  null,
                  onDone: () {
                    server.close();
                    asyncEnd();
                  },
                );
                socket.add([0]);
                socket.close();
                socket.fold<List<int>>([], (l, d) => l..addAll(d)).then((data) {
                  asyncEnd();
                  Expect.listEquals([0], data);
                });
              });
            });
          });
        });
  });
}

void testServerDetachSocketDefaultHeaders() async {
  asyncStart();
  final server = await HttpServer.bind("127.0.0.1", 0);
  server.defaultResponseHeaders.clear();
  server.serverHeader = null;
  server.autoCompress = true;
  server.listen((request) async {
    final response = request.response;
    response.headers.contentType = ContentType("text", "event-stream");
    final socket = await response.detachSocket();
    socket.listen(null);
    socket.write("data: hello\n\n");
    await socket.flush();
    await socket.close();
  });

  // Verify raw wire headers omit default Transfer-Encoding: chunked and
  // autoCompress Content-Encoding: gzip.
  final rawSocket = await Socket.connect("127.0.0.1", server.port);
  rawSocket.write(
    "GET / HTTP/1.1\r\n"
    "Host: 127.0.0.1:${server.port}\r\n"
    "Accept-Encoding: gzip\r\n\r\n",
  );
  await rawSocket.flush();
  final rawResponse = utf8.decode(
    await rawSocket.fold<List<int>>(<int>[], (acc, b) => acc..addAll(b)),
  );
  rawSocket.destroy();
  Expect.equals(
    "HTTP/1.1 200 OK\r\n"
    "content-type: text/event-stream\r\n"
    "\r\n"
    "data: hello\n\n",
    rawResponse,
  );

  // Verify HttpClient reads the unchunked body cleanly.
  final client = HttpClient();
  final req = await client.get("127.0.0.1", server.port, "/");
  final resp = await req.close();
  Expect.isFalse(resp.headers.chunkedTransferEncoding);
  Expect.isNull(resp.headers[HttpHeaders.transferEncodingHeader]);
  Expect.isNull(resp.headers[HttpHeaders.contentEncodingHeader]);
  Expect.equals("data: hello\n\n", await utf8.decoder.bind(resp).join());
  client.close(force: true);
  await server.close();
  asyncEnd();
}

void testServerDetachSocketExplicitChunked() async {
  asyncStart();
  final server = await HttpServer.bind("127.0.0.1", 0);
  server.autoCompress = true;
  server.listen((request) async {
    final response = request.response;
    response.headers.chunkedTransferEncoding = true;
    final socket = await response.detachSocket();
    socket.listen(null);
    socket.write("5\r\nhello\r\n0\r\n\r\n");
    await socket.flush();
    await socket.close();
  });

  final client = HttpClient();
  final req = await client.get("127.0.0.1", server.port, "/");
  final resp = await req.close();
  Expect.isTrue(resp.headers.chunkedTransferEncoding);
  Expect.isNull(resp.headers[HttpHeaders.contentEncodingHeader]);
  Expect.equals("hello", await utf8.decoder.bind(resp).join());
  client.close(force: true);
  await server.close();
  asyncEnd();
}

void testServerDetachSocketAddNonChunkedTransferEncoding() async {
  asyncStart();
  final server = await HttpServer.bind("127.0.0.1", 0);
  server.defaultResponseHeaders.clear();
  server.serverHeader = null;
  server.listen((request) async {
    final response = request.response;
    response.headers.add(HttpHeaders.transferEncodingHeader, "identity");
    final socket = await response.detachSocket();
    socket.listen(null);
    socket.write("hello");
    await socket.flush();
    await socket.close();
  });

  final rawSocket = await Socket.connect("127.0.0.1", server.port);
  rawSocket.write("GET / HTTP/1.1\r\nHost: 127.0.0.1:${server.port}\r\n\r\n");
  await rawSocket.flush();
  final rawResponse = utf8.decode(
    await rawSocket.fold<List<int>>(<int>[], (acc, b) => acc..addAll(b)),
  );
  rawSocket.destroy();
  Expect.equals(
    "HTTP/1.1 200 OK\r\n"
    "transfer-encoding: identity\r\n"
    "\r\n"
    "hello",
    rawResponse,
  );
  await server.close();
  asyncEnd();
}

void main() {
  testServerDetachSocket();
  testServerDetachSocketNoWriteHeaders();
  testServerDetachSocketDefaultHeaders();
  testServerDetachSocketExplicitChunked();
  testServerDetachSocketAddNonChunkedTransferEncoding();
  testBadServerDetachSocket();
  testClientDetachSocket();
  testUpgradedConnection();
}
