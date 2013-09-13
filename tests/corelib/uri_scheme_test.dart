// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void testInvalidArguments() {
  Expect.throws(() => new Uri(scheme: "_"), (e) => e is ArgumentError);
  Expect.throws(() => new Uri(scheme: "http_s"), (e) => e is ArgumentError);
  Expect.throws(() => new Uri(scheme: "127.0.0.1:80"),
                (e) => e is ArgumentError);
}

void testScheme() {
  test(String expectedScheme, String expectedUri, String scheme) {
    var uri = new Uri(scheme: scheme);
    Expect.equals(expectedScheme, uri.scheme);
    Expect.equals(expectedUri, uri.toString());
  }

  test("http", "http:", "http");
  test("http", "http:", "HTTP");
  test("http+ssl", "http+ssl:", "HTTP+ssl");
  test("urn", "urn:", "urn");
  test("urn", "urn:", "UrN");
  test("a123.432", "a123.432:", "a123.432");
}

main() {
  testInvalidArguments();
  testScheme();
}
