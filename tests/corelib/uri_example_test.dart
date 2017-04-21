// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uri.examples;

// Examples from the Uri class documentation.
// Get an error if the documentation starts to be wrong.
// REMEMBER TO UPDATE BOTH.

import "package:expect/expect.dart";
import 'dart:convert';

main() {
  // Uri.http
  test("http://example.org/path?q=dart",
      new Uri.http("example.org", "/path", {"q": "dart"}));
  test("http://user:pass@localhost:8080",
      new Uri.http("user:pass@localhost:8080", ""));
  test("http://example.org/a%20b", new Uri.http("example.org", "a b"));
  test("http://example.org/a%252F", new Uri.http("example.org", "/a%2F"));

  // Uri.file
  test("xxx/yyy", new Uri.file("xxx/yyy", windows: false));
  test("xxx/yyy/", new Uri.file("xxx/yyy/", windows: false));
  test("file:///xxx/yyy", new Uri.file("/xxx/yyy", windows: false));
  test("file:///xxx/yyy/", new Uri.file("/xxx/yyy/", windows: false));
  test("C%3A", new Uri.file("C:", windows: false));
  test("xxx/yyy", new Uri.file(r"xxx\yyy", windows: true));
  test("xxx/yyy/", new Uri.file(r"xxx\yyy\", windows: true));
  test("file:///xxx/yyy", new Uri.file(r"\xxx\yyy", windows: true));
  test("file:///xxx/yyy/", new Uri.file(r"\xxx\yyy/", windows: true));
  test("file:///C:/xxx/yyy", new Uri.file(r"C:\xxx\yyy", windows: true));
  test("file://server/share/file",
      new Uri.file(r"\\server\share\file", windows: true));
  Expect.throws(() => new Uri.file(r"C:", windows: true));
  Expect.throws(() => new Uri.file(r"C:xxx\yyy", windows: true));

  // isScheme.
  var uri = Uri.parse("http://example.com/");
  Expect.isTrue(uri.isScheme("HTTP"));

  // toFilePath.
  Expect.equals(r"xxx/yyy", Uri.parse("xxx/yyy").toFilePath(windows: false));
  Expect.equals(r"xxx/yyy/", Uri.parse("xxx/yyy/").toFilePath(windows: false));
  Expect.equals(
      r"/xxx/yyy", Uri.parse("file:///xxx/yyy").toFilePath(windows: false));
  Expect.equals(
      r"/xxx/yyy/", Uri.parse("file:///xxx/yyy/").toFilePath(windows: false));
  Expect.equals(r"/C:", Uri.parse("file:///C:").toFilePath(windows: false));
  Expect.equals(r"/C:a", Uri.parse("file:///C:a").toFilePath(windows: false));

  Expect.equals(r"xxx\yyy", Uri.parse("xxx/yyy").toFilePath(windows: true));
  Expect.equals(r"xxx\yyy\", Uri.parse("xxx/yyy/").toFilePath(windows: true));
  Expect.equals(
      r"\xxx\yyy", Uri.parse("file:///xxx/yyy").toFilePath(windows: true));
  Expect.equals(
      r"\xxx\yyy\", Uri.parse("file:///xxx/yyy/").toFilePath(windows: true));
  Expect.equals(
      r"C:\xxx\yyy", Uri.parse("file:///C:/xxx/yyy").toFilePath(windows: true));
  Expect.throws(() => Uri.parse("file:C:xxx/yyy").toFilePath(windows: true));
  Expect.equals(r"\\server\share\file",
      Uri.parse("file://server/share/file").toFilePath(windows: true)); //

  // replace.
  Uri uri1 = Uri.parse("a://b@c:4/d/e?f#g");
  Uri uri2 = uri1.replace(scheme: "A", path: "D/E/E", fragment: "G");
  Expect.equals("a://b@c:4/D/E/E?f#G", "$uri2");
  Uri uri3 = new Uri(
      scheme: "A",
      userInfo: uri1.userInfo,
      host: uri1.host,
      port: uri1.port,
      path: "D/E/E",
      query: uri1.query,
      fragment: "G");
  Expect.equals("a://b@c:4/D/E/E?f#G", "$uri3");
  Expect.equals(uri2, uri3);

  // UriData.mimeType
  var data = UriData.parse("data:text/plain;charset=utf-8,Hello%20World!");
  Expect.equals("text/plain", data.mimeType);
  Expect.equals("utf-8", data.charset);

  // Uri.parseIPv6Address - shouldn't throw.
  Uri.parseIPv6Address("::1");
  Uri.parseIPv6Address("FEDC:BA98:7654:3210:FEDC:BA98:7654:3210");
  Uri.parseIPv6Address("3ffe:2a00:100:7031::1");
  Uri.parseIPv6Address("::FFFF:129.144.52.38");
  Uri.parseIPv6Address("2010:836B:4179::836B:4179");
}

test(String result, Uri value) {
  Expect.equals(Uri.parse(result), value);
  Expect.equals(result, value.toString());
}
