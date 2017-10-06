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

Future getData(HttpClient client, int port, bool chunked, int length) {
  return client
      .get("127.0.0.1", port, "/?chunked=$chunked&length=$length")
      .then((request) => request.close())
      .then((response) {
    return response.fold(0, (bytes, data) => bytes + data.length).then((bytes) {
      Expect.equals(length, bytes);
    });
  });
}

Future<HttpServer> startServer() {
  return HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      bool chunked = request.uri.queryParameters["chunked"] == "true";
      int length = int.parse(request.uri.queryParameters["length"]);
      var buffer = new List<int>.filled(length, 0);
      if (!chunked) request.response.contentLength = length;
      request.response.add(buffer);
      request.response.close();
    });
    return server;
  });
}

testKeepAliveNonChunked() {
  startServer().then((server) {
    var client = new HttpClient();

    getData(client, server.port, false, 100)
        .then((_) => getData(client, server.port, false, 100))
        .then((_) => getData(client, server.port, false, 100))
        .then((_) => getData(client, server.port, false, 100))
        .then((_) => getData(client, server.port, false, 100))
        .then((_) {
      server.close();
      client.close();
    });
  });
}

testKeepAliveChunked() {
  startServer().then((server) {
    var client = new HttpClient();

    getData(client, server.port, true, 100)
        .then((_) => getData(client, server.port, true, 100))
        .then((_) => getData(client, server.port, true, 100))
        .then((_) => getData(client, server.port, true, 100))
        .then((_) => getData(client, server.port, true, 100))
        .then((_) {
      server.close();
      client.close();
    });
  });
}

testKeepAliveMixed() {
  startServer().then((server) {
    var client = new HttpClient();

    getData(client, server.port, true, 100)
        .then((_) => getData(client, server.port, false, 100))
        .then((_) => getData(client, server.port, true, 100))
        .then((_) => getData(client, server.port, false, 100))
        .then((_) => getData(client, server.port, true, 100))
        .then((_) => getData(client, server.port, false, 100))
        .then((_) => getData(client, server.port, true, 100))
        .then((_) => getData(client, server.port, false, 100))
        .then((_) {
      server.close();
      client.close();
    });
  });
}

void main() {
  testKeepAliveNonChunked();
  testKeepAliveChunked();
  testKeepAliveMixed();
}
