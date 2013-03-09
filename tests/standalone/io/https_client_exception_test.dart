// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";
import "dart:isolate";
import "dart:uri";

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
  testBadHostName();
  Expect.throws(InitializeSSL);
}
