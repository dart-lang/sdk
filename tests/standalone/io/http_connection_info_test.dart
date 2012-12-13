// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

void testHttpConnectionInfo() {
  HttpServer server = new HttpServer();
  server.listen("0.0.0.0", 0);
  int clientPort;
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    Expect.isTrue(request.connectionInfo.remoteHost is String);
    Expect.equals(request.connectionInfo.localPort, server.port);
    Expect.isNotNull(clientPort);
    Expect.equals(request.connectionInfo.remotePort, clientPort);
    request.inputStream.onClosed = () {
      response.outputStream.close();
    };
  };
  server.onError = (Exception e) {
    Expect.fail("Unexpected error: $e");
  };


  HttpClient client = new HttpClient();
  HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
  conn.onRequest = (HttpClientRequest request) {
    Expect.isTrue(conn.connectionInfo.remoteHost is String);
    Expect.equals(conn.connectionInfo.remotePort, server.port);
    clientPort = conn.connectionInfo.localPort;
    request.outputStream.close();
  };
  conn.onResponse = (HttpClientResponse response) {
    response.inputStream.onClosed = () {
      client.shutdown();
      server.close();
    };
  };
  conn.onError = (Exception e) {
    Expect.fail("Unexpected error: $e");
  };
}

void main() {
  testHttpConnectionInfo();
}
