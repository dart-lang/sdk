// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";

import "package:expect/expect.dart";

void testInvalidArguments() {}

void testPath() {
  void test(s, uri) {
    Expect.equals(s, uri.toString());
    Expect.equals(uri, Uri.parse(s));
  }

  test("http:", new Uri(scheme: "http"));
  test("http://host/xxx", new Uri(scheme: "http", host: "host", path: "xxx"));
  test("http://host/xxx", new Uri(scheme: "http", host: "host", path: "/xxx"));
  test("http://host/xxx",
      new Uri(scheme: "http", host: "host", pathSegments: ["xxx"]));
  test("http://host/xxx/yyy",
      new Uri(scheme: "http", host: "host", path: "xxx/yyy"));
  test("http://host/xxx/yyy",
      new Uri(scheme: "http", host: "host", path: "/xxx/yyy"));
  test("http://host/xxx/yyy",
      new Uri(scheme: "http", host: "host", pathSegments: ["xxx", "yyy"]));

  test("urn:", new Uri(scheme: "urn"));
  test("urn:xxx", new Uri(scheme: "urn", path: "xxx"));
  test("urn:xxx:yyy", new Uri(scheme: "urn", path: "xxx:yyy"));

  Expect.equals(3, new Uri(path: "xxx/yyy/zzz").pathSegments.length);
  Expect.equals(3, new Uri(path: "/xxx/yyy/zzz").pathSegments.length);
  Expect.equals(3, Uri.parse("http://host/xxx/yyy/zzz").pathSegments.length);
  Expect.equals(3, Uri.parse("file:///xxx/yyy/zzz").pathSegments.length);
}

void testPathSegments() {
  void test(String path, List<String> segments) {
    void check(uri) {
      Expect.equals(path, uri.path);
      Expect.equals(path, uri.toString());
      Expect.listEquals(segments, uri.pathSegments);
    }

    var uri1 = new Uri(pathSegments: segments);
    var uri2 = new Uri(path: path);
    check(uri1);
    check(uri2);
    Expect.equals(uri1, uri2);
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
  test(encoded, [unencoded]);
  test(encoded + "/" + encoded, [unencoded, unencoded]);

  Uri uri;
  List pathSegments = ["xxx", "yyy", "zzz"];

  uri = new Uri(pathSegments: pathSegments);
  Expect.equals(3, uri.pathSegments.length);
  uri = new Uri(pathSegments: pathSegments.where((_) => true));
  Expect.equals(3, uri.pathSegments.length);
  uri = new Uri(pathSegments: new DoubleLinkedQueue.from(pathSegments));
  Expect.equals(3, uri.pathSegments.length);

  uri = new Uri(scheme: "http", host: "host", pathSegments: pathSegments);
  Expect.equals(3, uri.pathSegments.length);
  uri = new Uri(
      scheme: "http",
      host: "host",
      pathSegments: pathSegments.where((_) => true));
  Expect.equals(3, uri.pathSegments.length);
  uri = new Uri(
      scheme: "http",
      host: "host",
      pathSegments: new DoubleLinkedQueue.from(pathSegments));
  Expect.equals(3, uri.pathSegments.length);

  uri = new Uri(scheme: "file", pathSegments: pathSegments);
  Expect.equals(3, uri.pathSegments.length);
  uri = new Uri(scheme: "file", pathSegments: pathSegments.where((_) => true));
  Expect.equals(3, uri.pathSegments.length);
  uri = new Uri(
      scheme: "file", pathSegments: new DoubleLinkedQueue.from(pathSegments));
  Expect.equals(3, uri.pathSegments.length);
}

void testPathCompare() {
  void test(Uri uri1, Uri uri2) {
    Expect.equals(uri1, uri2);
    Expect.equals(uri2, uri1);
  }

  test(new Uri(scheme: "http", host: "host", path: "xxx"),
      new Uri(scheme: "http", host: "host", path: "/xxx"));
  test(new Uri(scheme: "http", host: "host", pathSegments: ["xxx"]),
      new Uri(scheme: "http", host: "host", path: "/xxx"));
  test(new Uri(scheme: "http", host: "host", pathSegments: ["xxx"]),
      new Uri(scheme: "http", host: "host", path: "xxx"));
  test(new Uri(scheme: "file", path: "xxx"),
      new Uri(scheme: "file", path: "/xxx"));
  test(new Uri(scheme: "file", pathSegments: ["xxx"]),
      new Uri(scheme: "file", path: "/xxx"));
  test(new Uri(scheme: "file", pathSegments: ["xxx"]),
      new Uri(scheme: "file", path: "xxx"));
}

testPathSegmentsUnmodifiableList() {
  void test(list) {
    bool isUnsupported(e) => e is UnsupportedError;

    Expect.equals("a", list[0]);
    Expect.throws(() => list[0] = "c", isUnsupported);
    Expect.equals(2, list.length);
    Expect.throws(() => list.length = 1, isUnsupported);
    Expect.throws(() => list.add("c"), isUnsupported);
    Expect.throws(() => list.addAll(["c", "d"]), isUnsupported);
    Expect.listEquals(["b", "a"], list.reversed.toList());
    Expect.throws(() => list.sort(), isUnsupported);
    Expect.equals(0, list.indexOf("a"));
    Expect.equals(0, list.lastIndexOf("a"));
    Expect.throws(() => list.clear(), isUnsupported);
    Expect.throws(() => list.insert(1, "c"), isUnsupported);
    Expect.throws(() => list.insertAll(1, ["c", "d"]), isUnsupported);
    Expect.throws(() => list.setAll(1, ["c", "d"]), isUnsupported);
    Expect.throws(() => list.remove("a"), isUnsupported);
    Expect.throws(() => list.removeAt(0), isUnsupported);
    Expect.throws(() => list.removeLast(), isUnsupported);
    Expect.throws(() => list.removeWhere((e) => true), isUnsupported);
    Expect.throws(() => list.retainWhere((e) => false), isUnsupported);
    Expect.listEquals(["a"], list.sublist(0, 1));
    Expect.listEquals(["a"], list.getRange(0, 1).toList());
    Expect.throws(() => list.setRange(0, 1, ["c"]), isUnsupported);
    Expect.throws(() => list.removeRange(0, 1), isUnsupported);
    Expect.throws(() => list.fillRange(0, 1, "c"), isUnsupported);
    Expect.throws(() => list.replaceRange(0, 1, ["c"]), isUnsupported);
    Map map = new Map();
    map[0] = "a";
    map[1] = "b";
    Expect.mapEquals(list.asMap(), map);
  }

  test(Uri.parse("a/b").pathSegments);
  test(new Uri(pathSegments: ["a", "b"]).pathSegments);
}

main() {
  testInvalidArguments();
  testPath();
  testPathSegments();
  testPathCompare();
  testPathSegmentsUnmodifiableList();
}
