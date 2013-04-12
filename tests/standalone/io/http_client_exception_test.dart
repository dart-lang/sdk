// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "package:expect/expect.dart";
import "dart:io";
import "dart:isolate";
import "dart:uri";

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
  testInvalidUrl();
  testBadHostName();
}
