// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:uri";
import "dart:isolate";

void testGoogleUrl() {
  HttpClient client = new HttpClient();

  void testUrl(String url) {
    var requestUri = new Uri.fromString(url);
    var conn = client.getUrl(requestUri);

    conn.onRequest = (HttpClientRequest request) {
      request.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      Expect.isTrue(response.statusCode < 500);
      Expect.isTrue(response.statusCode != 404);
      response.inputStream.onData = () {
        response.inputStream.read();
      };
      response.inputStream.onClosed = () {
        client.shutdown();
      };
    };
    conn.onError = (error) => Expect.fail("Unexpected IO error $error");
  }

  testUrl('https://www.google.com');
}

void InitializeSSL() {
  SecureSocket.initialize();
}

void main() {
  InitializeSSL();
  testGoogleUrl();
}
