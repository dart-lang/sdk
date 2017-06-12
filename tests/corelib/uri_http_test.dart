// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

testHttpUri() {
  void check(Uri uri, String expected) {
    Expect.equals(expected, uri.toString());
  }

  check(new Uri.http("", ""), "http:");
  check(new Uri.http("@:", ""), "http://");
  check(new Uri.http("@:8080", ""), "http://:8080");
  check(new Uri.http("@host:", ""), "http://host");
  check(new Uri.http("@host:", ""), "http://host");
  check(new Uri.http("xxx:yyy@host:8080", ""), "http://xxx:yyy@host:8080");
  check(new Uri.http("host", "a"), "http://host/a");
  check(new Uri.http("host", "/a"), "http://host/a");
  check(new Uri.http("host", "a/"), "http://host/a/");
  check(new Uri.http("host", "/a/"), "http://host/a/");
  check(new Uri.http("host", "a/b"), "http://host/a/b");
  check(new Uri.http("host", "/a/b"), "http://host/a/b");
  check(new Uri.http("host", "a/b/"), "http://host/a/b/");
  check(new Uri.http("host", "/a/b/"), "http://host/a/b/");
  check(new Uri.http("host", "a b"), "http://host/a%20b");
  check(new Uri.http("host", "/a b"), "http://host/a%20b");
  check(new Uri.http("host", "/a b/"), "http://host/a%20b/");
  check(new Uri.http("host", "/a%2F"), "http://host/a%252F");
  check(new Uri.http("host", "/a%2F/"), "http://host/a%252F/");
  check(new Uri.http("host", "/a/b", {"c": "d"}), "http://host/a/b?c=d");
  check(
      new Uri.http("host", "/a/b", {"c=": "&d"}), "http://host/a/b?c%3D=%26d");
  check(new Uri.http("[::]", "a"), "http://[::]/a");
  check(new Uri.http("[::127.0.0.1]", "a"), "http://[::127.0.0.1]/a");
}

testHttpsUri() {
  void check(Uri uri, String expected) {
    Expect.equals(expected, uri.toString());
  }

  check(new Uri.https("", ""), "https:");
  check(new Uri.https("@:", ""), "https://");
  check(new Uri.https("@:8080", ""), "https://:8080");
  check(new Uri.https("@host:", ""), "https://host");
  check(new Uri.https("@host:", ""), "https://host");
  check(new Uri.https("xxx:yyy@host:8080", ""), "https://xxx:yyy@host:8080");
  check(new Uri.https("host", "a"), "https://host/a");
  check(new Uri.https("host", "/a"), "https://host/a");
  check(new Uri.https("host", "a/"), "https://host/a/");
  check(new Uri.https("host", "/a/"), "https://host/a/");
  check(new Uri.https("host", "a/b"), "https://host/a/b");
  check(new Uri.https("host", "/a/b"), "https://host/a/b");
  check(new Uri.https("host", "a/b/"), "https://host/a/b/");
  check(new Uri.https("host", "/a/b/"), "https://host/a/b/");
  check(new Uri.https("host", "a b"), "https://host/a%20b");
  check(new Uri.https("host", "/a b"), "https://host/a%20b");
  check(new Uri.https("host", "/a b/"), "https://host/a%20b/");
  check(new Uri.https("host", "/a%2F"), "https://host/a%252F");
  check(new Uri.https("host", "/a%2F/"), "https://host/a%252F/");
  check(new Uri.https("host", "/a/b", {"c": "d"}), "https://host/a/b?c=d");
  check(new Uri.https("host", "/a/b", {"c=": "&d"}),
      "https://host/a/b?c%3D=%26d");
  check(new Uri.https("[::]", "a"), "https://[::]/a");
  check(new Uri.https("[::127.0.0.1]", "a"), "https://[::127.0.0.1]/a");
}

testResolveHttpScheme() {
  String s = "//myserver:1234/path/some/thing";
  Uri uri = Uri.parse(s);
  Uri http = new Uri(scheme: "http");
  Uri https = new Uri(scheme: "https");
  Expect.equals("http:$s", http.resolveUri(uri).toString());
  Expect.equals("https:$s", https.resolveUri(uri).toString());
}

main() {
  testHttpUri();
  testHttpsUri();
  testResolveHttpScheme();
}
