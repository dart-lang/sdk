// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

void testHttpConnectionInfo() {
  HttpServer.bind("0.0.0.0", 0).then((server) {
    int clientPort;

    server.listen((request) {
      var response = request.response;
      Expect.isTrue(request.connectionInfo.remoteAddress is InternetAddress);
      Expect.isTrue(response.connectionInfo.remoteAddress is InternetAddress);
      Expect.equals(request.connectionInfo.localPort, server.port);
      Expect.equals(response.connectionInfo.localPort, server.port);
      Expect.isNotNull(clientPort);
      Expect.equals(request.connectionInfo.remotePort, clientPort);
      Expect.equals(response.connectionInfo.remotePort, clientPort);
      request.listen((_) {}, onDone: () {
        request.response.close();
      });
    });

    HttpClient client = new HttpClient();
    client.get("127.0.0.1", server.port, "/").then((request) {
      Expect.isTrue(request.connectionInfo.remoteAddress is InternetAddress);
      Expect.equals(request.connectionInfo.remotePort, server.port);
      clientPort = request.connectionInfo.localPort;
      return request.close();
    }).then((response) {
      Expect.equals(server.port, response.connectionInfo.remotePort);
      Expect.equals(clientPort, response.connectionInfo.localPort);
      response.listen((_) {}, onDone: () {
        client.close();
        server.close();
      });
    });
  });
}

void main() {
  testHttpConnectionInfo();
}
