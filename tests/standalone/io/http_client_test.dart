// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");
#import("dart:uri");
#import("dart:isolate");

void testGoogle() {
  HttpClient client = new HttpClient();
  var conn = client.get('www.google.com', 80, '/');

  conn.onRequest = (HttpClientRequest request) {
    request.outputStream.close();
  };
  conn.onResponse = (HttpClientResponse response) {
    Expect.isTrue(response.statusCode < 500);
    response.inputStream.onData = () {
      response.inputStream.read();
    };
    response.inputStream.onClosed = () {
      client.shutdown();
    };
  };
  conn.onError = (error) => Expect.fail("Unexpected IO error");
}

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
        if (testGoogleUrlCount == 5) client.shutdown();
      };
    };
    conn.onError = (error) => Expect.fail("Unexpected IO error $error");
  }

  testUrl('http://www.google.com');
  testUrl('http://www.google.com/abc');
  testUrl('http://www.google.com/?abc');
  testUrl('http://www.google.com/abc?abc');
  testUrl('http://www.google.com/abc?abc#abc');
}

void testInvalidUrl() {
  HttpClient client = new HttpClient();
  Expect.throws(
      () => client.getUrl(new Uri.fromString('ftp://www.google.com')));
  Expect.throws(
      () => client.getUrl(new Uri.fromString('http://usr:pwd@www.google.com')));
}

void testBadHostName() {
  HttpClient client = new HttpClient();
  HttpClientConnection connection =
      client.get("some.bad.host.name.7654321", 0, "/");
  connection.onRequest = (HttpClientRequest request) {
    Expect.fail("Should not open a request on bad hostname");
  };
  ReceivePort port = new ReceivePort();
  connection.onError = (Exception error) {
    port.close();  // We expect onError to be called, due to bad host name.
  };
}

void main() {
  testGoogle();
  testGoogleUrl();
  testInvalidUrl();
  testBadHostName();
}
