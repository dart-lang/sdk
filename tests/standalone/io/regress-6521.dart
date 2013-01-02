// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for http://code.google.com/p/dart/issues/detail?id=6393.

import "dart:io";
import "dart:uri";

var client = new HttpClient();
var clientRequest;

void main() {
  var server = new HttpServer();
  server.listen("127.0.0.1", 0);
  server.defaultRequestHandler = (req, rsp) {
    req.inputStream.onData = () {
      req.inputStream.read();
      rsp.outputStream.close();
    };
    req.inputStream.onClosed = () {
      client.shutdown();
      server.close();
    };
  };

  var connection = client.openUrl(
      "POST",
      new Uri.fromString("http://localhost:${server.port}/"));
  connection.onRequest = (request) {
    // Keep a reference to the client request object.
    clientRequest = request;
    request.outputStream.write([0]);
  };
  connection.onResponse = (response) {
    response.inputStream.onClosed = () {
      // Wait with closing the client request until the response is done.
      clientRequest.outputStream.close();
    };
  };
}
