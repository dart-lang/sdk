// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testBadHostName() {
  asyncStart();
  HttpClient client = new HttpClient();
  client
      .getUrl(Uri.parse("https://some.bad.host.name.7654321/"))
      .then((HttpClientRequest request) {
    Expect.fail("Should not open a request on bad hostname");
  }).catchError((error) {
    asyncEnd(); // Should throw an error on bad hostname.
  });
}

void main() {
  testBadHostName();
}
