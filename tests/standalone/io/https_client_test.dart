// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:uri";
import "dart:isolate";


void testGoogleUrl() {
  int testsStarted = 0;
  int testsFinished = 0;
  bool allStarted = false;
  HttpClient client = new HttpClient();

  void testUrl(String url) {
    testsStarted++;
    var requestUri = Uri.parse(url);
    client.getUrl(requestUri)
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) {
          Expect.isTrue(response.statusCode < 500);
          if (requestUri.path.length == 0) {
            Expect.isTrue(response.statusCode != 404);
          }
          response.listen((data) { }, onDone: () {
            if (++testsFinished == testsStarted && allStarted) client.close();
          });
        })
        .catchError((error) => Expect.fail("Unexpected IO error: $error"));
  }

  testUrl('https://www.google.dk');
  testUrl('https://www.google.dk');
  testUrl('https://www.google.dk/#q=foo');
  testUrl('https://www.google.dk/#hl=da&q=foo');
  allStarted = true;
}

void testBadHostName() {
  HttpClient client = new HttpClient();
  ReceivePort port = new ReceivePort();
  client.getUrl(Uri.parse("https://some.bad.host.name.7654321/"))
      .then((HttpClientRequest request) {
        Expect.fail("Should not open a request on bad hostname");
      })
      .catchError((error) {
        port.close();  // Should throw an error on bad hostname.
      });
}

void InitializeSSL() {
  SecureSocket.initialize();
}

void main() {
  testGoogleUrl();
  testBadHostName();
  Expect.throws(InitializeSSL);
}
