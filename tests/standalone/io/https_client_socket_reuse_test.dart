// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:uri";
import "dart:isolate";

// By running tests sequentially, we cover the socket reuse code in HttpClient.

void testGoogleUrls() {
  int testsStarted = 0;
  int testsFinished = 0;
  bool allStarted = false;
  HttpClient client = new HttpClient();

  Future testUrl(String url) {
    testsStarted++;
    var requestUri = Uri.parse(url);
    return client.getUrl(requestUri)
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) {
          Expect.isTrue(response.statusCode < 500);
          if (requestUri.path.length == 0) {
            Expect.isTrue(response.statusCode != 404);
          }
          return response.reduce(null, (previous, element) => null);
        })
        .catchError((error) => Expect.fail("Unexpected IO error: $error"));
  }

  // TODO(3593): Use a Dart HTTPS server for this test.
  testUrl('https://www.google.dk')
    .then((_) => testUrl('https://www.google.dk'))
    .then((_) => testUrl('https://www.google.dk/#q=foo'))
    .then((_) => testUrl('https://www.google.dk/#hl=da&q=foo'))
    .then((_) { client.close(); });
}

void main() {
  testGoogleUrls();
}
