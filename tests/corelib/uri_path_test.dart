// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void testInvalidArguments() {
}

void testPath() {
  test(s, uri) {
    Expect.equals(s, uri.toString());
    Expect.equals(uri, Uri.parse(s));
  }

  test("urn:", new Uri(scheme: "urn"));
  test("urn:xxx", new Uri(scheme: "urn", path: "xxx"));
  test("urn:xxx:yyy", new Uri(scheme: "urn", path: "xxx:yyy"));
}

void testPathSegments() {
  test(String path, List<String> segments) {
    void check(uri) {
      Expect.equals(path, uri.path);
      Expect.equals(path, uri.toString());
      Expect.listEquals(segments, uri.pathSegments);
    }

    var uri1 = new Uri(pathSegments: segments);
    var uri2 = new Uri(path: path);
    var uri3 = Uri.parse(path);
    check(uri1);
    check(uri2);
    check(uri3);
    Expect.equals(uri1, uri3);
    Expect.equals(uri2, uri3);
  }

  test("", []);
  test("%20", [" "]);
  test("%20/%20%20", [" ", "  "]);
  test("A", ["A"]);
  test("%C3%B8", ["ø"]);
  test("%C3%B8/%C3%A5", ["ø", "å"]);
  test("%C8%A4/%E5%B9%B3%E4%BB%AE%E5%90%8D", ["Ȥ", "平仮名"]);
  test("A/b", ["A", "b"]);
  test("A/%25", ["A", "%"]);
  test("%2F/a%2Fb", ["/", "a/b"]);
  test("name;v=1.1", ["name;v=1.1"]);
  test("name,v=1.1", ["name,v=1.1"]);
  test("name;v=1.1/name,v=1.1", ["name;v=1.1", "name,v=1.1"]);

  var unreserved = "-._~0123456789"
                   "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                   "abcdefghijklmnopqrstuvwxyz";
  var subDelimiters = r"!$&'()*+,;=";
  var additionalPathChars = ":@";
  var pchar = unreserved + subDelimiters + additionalPathChars;

  var encoded = new StringBuffer();
  var unencoded = new StringBuffer();
  for (int i = 32; i < 128; i++) {
    if (pchar.indexOf(new String.fromCharCode(i)) != -1) {
      encoded.writeCharCode(i);
    } else {
      encoded.write("%");
      encoded.write(i.toRadixString(16).toUpperCase());
    }
    unencoded.writeCharCode(i);
  }
  encoded = encoded.toString();
  unencoded = unencoded.toString();
  print(encoded);
  print(unencoded);
  test(encoded, [unencoded]);
  test(encoded + "/" + encoded, [unencoded, unencoded]);
}

main() {
  testInvalidArguments();
  testPath();
  testPathSegments();
}
