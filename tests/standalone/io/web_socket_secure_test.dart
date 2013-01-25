// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:uri";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";

void test() {
  HttpsServer server = new HttpsServer();
  var client = new HttpClient();

  // Create a web socket handler and set it as the HTTP server default
  // handler.
  WebSocketHandler wsHandler = new WebSocketHandler();
  wsHandler.onOpen = (WebSocketConnection conn) {
    conn.onMessage = (Object message) => conn.send(message);
    conn.onClosed = (status, reason) {
      conn.close();
      server.close();
      client.shutdown();
    };
  };
  server.defaultRequestHandler = wsHandler.onRequest;

  server.onError = (Exception e) {
    Expect.fail("Unexpected error in Https Server: $e");
  };

  server.listen(SERVER_ADDRESS,
                0,
                backlog: 5,
                certificate_name: "CN=$HOST_NAME");

  // Connect web socket over HTTPS.
  var conn = new WebSocketClientConnection(
      client.getUrl(
          Uri.parse("https://$HOST_NAME:${server.port}/")));
  conn.onOpen = () {
    conn.send("hello");
  };
  conn.onMessage = (msg) {
    Expect.equals("hello", msg);
    print(msg);
    conn.close();
  };

}

void InitializeSSL() {
  var testPkcertDatabase =
      new Path(new Options().script).directoryPath.append("pkcert/");
  SecureSocket.initialize(database: testPkcertDatabase.toNativePath(),
                          password: "dartdart");
}

void main() {
  InitializeSSL();
  test();
}
