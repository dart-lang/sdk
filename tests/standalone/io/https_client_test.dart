// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:uri";
import "dart:isolate";


int testGoogleUrlCount = 0;
void testGoogleUrl() {
  HttpClient client = new HttpClient();

  void testUrl(String url) {
    var requestUri = new Uri.fromString(url);
    var conn = client.getUrl(requestUri);

    conn.onRequest = (HttpClientRequest request) {
      request.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      testGoogleUrlCount++;
      Expect.isTrue(response.statusCode < 500);
      if (requestUri.path.length == 0) {
        Expect.isTrue(response.statusCode != 404);
      }
      response.inputStream.onData = () {
        response.inputStream.read();
      };
      response.inputStream.onClosed = () {
        if (testGoogleUrlCount == 4) client.shutdown();
      };
    };
    conn.onError = (error) => Expect.fail("Unexpected IO error $error");
  }

  testUrl('https://www.google.dk');
  testUrl('https://www.google.dk');
  testUrl('https://www.google.dk/#q=foo');
  testUrl('https://www.google.dk/#hl=da&q=foo');
}

void testBadHostName() {
  HttpClient client = new HttpClient();
  HttpClientConnection connection = client.getUrl(
      new Uri.fromString("https://some.bad.host.name.7654321/"));
  connection.onRequest = (HttpClientRequest request) {
    Expect.fail("Should not open a request on bad hostname");
  };
  ReceivePort port = new ReceivePort();
  connection.onError = (Exception error) {
    port.close();  // We expect onError to be called, due to bad host name.
  };
}

void InitializeSSL() {
  var testPkcertDatabase =
      new Path.fromNative(new Options().script).directoryPath.append('pkcert/');
  SecureSocket.setCertificateDatabase(testPkcertDatabase.toNativePath());
}

void main() {
  InitializeSSL();
  testGoogleUrl();
  testBadHostName();
}
