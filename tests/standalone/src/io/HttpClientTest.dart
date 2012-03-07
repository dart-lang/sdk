// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");

void testGoogle() {
  HttpClient client = new HttpClient();
  var conn = client.get('www.google.com', 80, '/');

  conn.onRequest = (HttpClientRequest request) {
    request.keepAlive = false;
    request.outputStream.close();
  };
  conn.onResponse = (HttpClientResponse response) {
    Expect.isTrue(response.statusCode < 500);
    response.inputStream.onClosed = () {
      response.inputStream.read();
    };
    response.inputStream.onClosed = () {
      client.shutdown();
    };
  };
}

void main() {
  testGoogle();
}
