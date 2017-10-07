// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testInvalidUrl() {
  HttpClient client = new HttpClient();
  Expect.throws(() => client.getUrl(Uri.parse('ftp://www.google.com')),
      (e) => e.toString().contains("Unsupported scheme"));
  Expect.throws(() => client.getUrl(Uri.parse('httpx://www.google.com')),
      (e) => e.toString().contains("Unsupported scheme"));
  Expect.throws(() => client.getUrl(Uri.parse('http://::1')),
      (e) => e is FormatException);
  Expect.throws(() => client.getUrl(Uri.parse('http://user@:1')),
      (e) => e.toString().contains("No host specified"));
  Expect.throws(() => client.getUrl(Uri.parse('http:///')),
      (e) => e.toString().contains("No host specified"));
  Expect.throws(() => client.getUrl(Uri.parse('http:///index.html')),
      (e) => e.toString().contains("No host specified"));
  Expect.throws(() => client.getUrl(Uri.parse('///')),
      (e) => e.toString().contains("No host specified"));
  Expect.throws(() => client.getUrl(Uri.parse('///index.html')),
      (e) => e.toString().contains("No host specified"));
}

void testBadHostName() {
  asyncStart();
  HttpClient client = new HttpClient();
  client.get("some.bad.host.name.7654321", 0, "/").then((request) {
    Expect.fail("Should not open a request on bad hostname");
  }).catchError((error) {
    asyncEnd(); // We expect onError to be called, due to bad host name.
  }, test: (error) => error is! String);
}

void main() {
  testInvalidUrl();
  testBadHostName();
}
