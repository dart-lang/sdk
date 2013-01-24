// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:uri";
import "dart:isolate";

void testGoogleUrl() {
  ReceivePort keepalivePort = new ReceivePort();
  HttpClient client = new HttpClient();

  void testUrl(String url) {
    var requestUri = Uri.parse(url);
    var conn = client.getUrl(requestUri);

    conn.onRequest = (HttpClientRequest request) {
      request.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      Expect.fail("Https connection unexpectedly succeeded");
    };
    conn.onError = (error) {
      Expect.isTrue(error is SocketIOException);
      keepalivePort.close();
    };
  }

  testUrl('https://www.google.com');
}

void InitializeSSL() {
  // If the built-in root certificates aren't loaded, the connection
  // should signal an error.
  SecureSocket.initialize(useBuiltinRoots: false);
}

void main() {
  InitializeSSL();
  testGoogleUrl();
}
