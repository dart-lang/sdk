// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:uri';

void main() {
  var client = new HttpClient();
  var server = new HttpServer();

  var count = 0;
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    List<int> data = [];
    request.inputStream.onData = () {
      data.addAll(request.inputStream.read());
    };
    request.inputStream.onClosed = () {
      count++;
      Expect.equals(count, data.length);
      switch (count - 1) {
        case 0:
          response.outputStream.writeFrom([65, 66, 67], 1, 1);
          break;
        case 1:
          response.outputStream.writeFrom([65, 66, 67], 1);
          break;
        case 2:
          response.outputStream.writeFrom([65, 66, 67]);
          break;
        default:
          Expect.fail("Unexpected state");
      }
      response.outputStream.close();
    };
  };
  server.listen('127.0.0.1', 0);

  Future makeRequest(int n) {
    var completer = new Completer();
    var url = Uri.parse("http://localhost:${server.port}");
    var connection = client.openUrl("POST", url);
    connection.onRequest = (HttpClientRequest request) {
      request.contentLength = n + 1;
      switch (n) {
        case 0:
          request.outputStream.writeFrom([65, 66, 67], 1, 1);
          break;
        case 1:
          request.outputStream.writeFrom([65, 66, 67], 1);
          break;
        case 2:
          request.outputStream.writeFrom([65, 66, 67]);
          break;
        default:
          Expect.fail("Unexpected state");
      }
      request.outputStream.close();
    };
    connection.onResponse = (HttpClientResponse response) {
      List<int> data = [];
      response.inputStream.onData = () {
        data.addAll(response.inputStream.read());
      };
      response.inputStream.onClosed = () {
        Expect.equals(count, data.length);
        completer.complete(null);
      };
    };
    return completer.future;
  }

  makeRequest(0).then((_) {
    makeRequest(1).then((_) {
      makeRequest(2).then((_) {
        client.shutdown();
        server.close();
      });
    });
  });
}
