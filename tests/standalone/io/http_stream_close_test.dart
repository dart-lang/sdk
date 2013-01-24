// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "dart:io";
import "dart:uri";

main() {
  bool serverOnClosed = false;
  bool clientOnClosed = false;
  bool requestOnClosed = false;

  var server = new HttpServer();
  var client = new HttpClient();

  checkDone() {
    if (serverOnClosed && clientOnClosed && requestOnClosed) {
      server.close();
      client.shutdown();
    }
  }

  server.listen("127.0.0.1", 0);
  server.defaultRequestHandler = (request, response) {
    request.inputStream.onData = request.inputStream.read;
    request.inputStream.onClosed = () {
      response.outputStream.onClosed = () {
        serverOnClosed = true;
        checkDone();
      };
      response.outputStream.writeString("hello!");
      response.outputStream.close();
    };
  };

  var connection = client.postUrl(
      Uri.parse("http://127.0.0.1:${server.port}"));
  connection.onError = (e) { throw e; };
  connection.onRequest = (request) {
    request.contentLength = "hello!".length;
    request.outputStream.onError = (e) { throw e; };
    request.outputStream.onClosed = () {
      clientOnClosed = true;
      checkDone();
    };
    request.outputStream.writeString("hello!");
    request.outputStream.close();
  };
  connection.onResponse = (response) {
    response.inputStream.onData = response.inputStream.read;
    response.inputStream.onClosed = () {
      requestOnClosed = true;
      checkDone();
    };
  };
}
