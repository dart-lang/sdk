// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:io";
import "dart:uri";
import "dart:isolate";

void testGoogle() {
  HttpClient client = new HttpClient();
  client.get('www.google.com', 80, '/')
      .then((request) => request.close())
      .then((response) {
        Expect.isTrue(response.statusCode < 500);
        response.listen((data) {}, onDone: client.close);
      })
      .catchError((error) => Expect.fail("Unexpected IO error: $error"));
}

int testGoogleUrlCount = 0;
void testGoogleUrl() {
  HttpClient client = new HttpClient();

  void testUrl(String url) {
    var requestUri = Uri.parse(url);
    client.getUrl(requestUri)
        .then((request) => request.close())
        .then((response) {
          testGoogleUrlCount++;
          Expect.isTrue(response.statusCode < 500);
          if (requestUri.path.length == 0) {
            Expect.isTrue(response.statusCode != 404);
          }
          response.listen((data) {}, onDone: () {
            if (testGoogleUrlCount == 5) client.close();
          });
        })
        .catchError((error) => Expect.fail("Unexpected IO error: $error"));
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
      () => client.getUrl(Uri.parse('ftp://www.google.com')));
}

void testBadHostName() {
  HttpClient client = new HttpClient();
  ReceivePort port = new ReceivePort();
  client.get("some.bad.host.name.7654321", 0, "/")
    .then((request) {
      Expect.fail("Should not open a request on bad hostname");
    }).catchError((error) {
      port.close();  // We expect onError to be called, due to bad host name.
    }, test: (error) => error is! String);
}

void main() {
  testGoogle();
  testGoogleUrl();
  testInvalidUrl();
  testBadHostName();
}
