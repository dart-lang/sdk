// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uriTest;

import "package:expect/expect.dart";
import 'dart:convert';

testUri(String uri, bool isAbsolute) {
  Expect.equals(isAbsolute, Uri.parse(uri).isAbsolute);
  Expect.stringEquals(uri, Uri.parse(uri).toString());

  // Test equals and hashCode members.
  Expect.equals(Uri.parse(uri), Uri.parse(uri));
  Expect.equals(Uri.parse(uri).hashCode, Uri.parse(uri).hashCode);
}

testEncodeDecode(String orig, String encoded) {
  var e = Uri.encodeFull(orig);
  Expect.stringEquals(encoded, e);
  var d = Uri.decodeFull(encoded);
  Expect.stringEquals(orig, d);
}

testEncodeDecodeComponent(String orig, String encoded) {
  var e = Uri.encodeComponent(orig);
  Expect.stringEquals(encoded, e);
  var d = Uri.decodeComponent(encoded);
  Expect.stringEquals(orig, d);
}

testEncodeDecodeQueryComponent(String orig,
                               String encodedUTF8,
                               String encodedLatin1,
                               String encodedAscii) {
  var e, d;
  e = Uri.encodeQueryComponent(orig);
  Expect.stringEquals(encodedUTF8, e);
  d = Uri.decodeQueryComponent(encodedUTF8);
  Expect.stringEquals(orig, d);

  e = Uri.encodeQueryComponent(orig, encoding: UTF8);
  Expect.stringEquals(encodedUTF8, e);
  d = Uri.decodeQueryComponent(encodedUTF8, encoding: UTF8);
  Expect.stringEquals(orig, d);

  e = Uri.encodeQueryComponent(orig, encoding: LATIN1);
  Expect.stringEquals(encodedLatin1, e);
  d = Uri.decodeQueryComponent(encodedLatin1, encoding: LATIN1);
  Expect.stringEquals(orig, d);

  if (encodedAscii != null) {
    e = Uri.encodeQueryComponent(orig, encoding: ASCII);
    Expect.stringEquals(encodedAscii, e);
    d = Uri.decodeQueryComponent(encodedAscii, encoding: ASCII);
    Expect.stringEquals(orig, d);
  } else {
    Expect.throws(() => Uri.encodeQueryComponent(orig, encoding: ASCII),
                  (e) => e is ArgumentError);
  }
}

testUriPerRFCs(Uri base) {
  // From RFC 3986.
  Expect.stringEquals("g:h", base.resolve("g:h").toString());
  Expect.stringEquals("http://a/b/c/g", base.resolve("g").toString());
  Expect.stringEquals("http://a/b/c/g", base.resolve("./g").toString());
  Expect.stringEquals("http://a/b/c/g/", base.resolve("g/").toString());
  Expect.stringEquals("http://a/g", base.resolve("/g").toString());
  Expect.stringEquals("http://g", base.resolve("//g").toString());
  Expect.stringEquals("http://a/b/c/d;p?y", base.resolve("?y").toString());
  Expect.stringEquals("http://a/b/c/g?y", base.resolve("g?y").toString());
  Expect.stringEquals("http://a/b/c/d;p?q#s", base.resolve("#s").toString());
  Expect.stringEquals("http://a/b/c/g#s", base.resolve("g#s").toString());
  Expect.stringEquals("http://a/b/c/g?y#s", base.resolve("g?y#s").toString());
  Expect.stringEquals("http://a/b/c/;x", base.resolve(";x").toString());
  Expect.stringEquals("http://a/b/c/g;x", base.resolve("g;x").toString());
  Expect.stringEquals("http://a/b/c/g;x?y#s",
                      base.resolve("g;x?y#s").toString());
  Expect.stringEquals("http://a/b/c/d;p?q", base.resolve("").toString());
  Expect.stringEquals("http://a/b/c/", base.resolve(".").toString());
  Expect.stringEquals("http://a/b/c/", base.resolve("./").toString());
  Expect.stringEquals("http://a/b/", base.resolve("..").toString());
  Expect.stringEquals("http://a/b/", base.resolve("../").toString());
  Expect.stringEquals("http://a/b/g", base.resolve("../g").toString());
  Expect.stringEquals("http://a/", base.resolve("../..").toString());
  Expect.stringEquals("http://a/", base.resolve("../../").toString());
  Expect.stringEquals("http://a/g", base.resolve("../../g").toString());
  Expect.stringEquals("http://a/g", base.resolve("../../../g").toString());
  Expect.stringEquals("http://a/g", base.resolve("../../../../g").toString());
  Expect.stringEquals("http://a/g", base.resolve("/./g").toString());
  Expect.stringEquals("http://a/g", base.resolve("/../g").toString());
  Expect.stringEquals("http://a/b/c/g.", base.resolve("g.").toString());
  Expect.stringEquals("http://a/b/c/.g", base.resolve(".g").toString());
  Expect.stringEquals("http://a/b/c/g..", base.resolve("g..").toString());
  Expect.stringEquals("http://a/b/c/..g", base.resolve("..g").toString());
  Expect.stringEquals("http://a/b/g", base.resolve("./../g").toString());
  Expect.stringEquals("http://a/b/c/g/", base.resolve("./g/.").toString());
  Expect.stringEquals("http://a/b/c/g/h", base.resolve("g/./h").toString());
  Expect.stringEquals("http://a/b/c/h", base.resolve("g/../h").toString());
  Expect.stringEquals("http://a/b/c/g;x=1/y",
                      base.resolve("g;x=1/./y").toString());
  Expect.stringEquals("http://a/b/c/y", base.resolve("g;x=1/../y").toString());
  Expect.stringEquals("http://a/b/c/g?y/./x",
                      base.resolve("g?y/./x").toString());
  Expect.stringEquals("http://a/b/c/g?y/../x",
                      base.resolve("g?y/../x").toString());
  Expect.stringEquals("http://a/b/c/g#s/./x",
                      base.resolve("g#s/./x").toString());
  Expect.stringEquals("http://a/b/c/g#s/../x",
                      base.resolve("g#s/../x").toString());
  Expect.stringEquals("http:g", base.resolve("http:g").toString());

  // Additional tests (not from RFC 3986).
  Expect.stringEquals("http://a/b/g;p/h;s",
                      base.resolve("../g;p/h;s").toString());
}

void testResolvePath(String expected, String path) {
  Expect.equals(expected, new Uri().resolveUri(new Uri(path: path)).path);
  Expect.equals(
      "http://localhost$expected",
      Uri.parse("http://localhost").resolveUri(new Uri(path: path)).toString());
}

main() {
  testUri("http:", true);
  testUri("file://", true);
  testUri("file", false);
  testUri("http://user@example.com:8080/fisk?query=89&hest=silas", true);
  testUri("http://user@example.com:8080/fisk?query=89&hest=silas#fragment",
          false);
  Expect.stringEquals("http://user@example.com/a/b/c?query#fragment",
                      new Uri(
                          scheme: "http",
                          userInfo: "user",
                          host: "example.com",
                          port: 80,
                          path: "/a/b/c",
                          query: "query",
                          fragment: "fragment").toString());
  Expect.stringEquals("//null@null/a/b/c/",
                      new Uri(
                          scheme: null,
                          userInfo: null,
                          host: null,
                          port: 0,
                          path: "/a/b/c/",
                          query: null,
                          fragment: null).toString());
  Expect.stringEquals("file://", Uri.parse("file:").toString());

  testResolvePath("/a/g", "/a/b/c/./../../g");
  testResolvePath("/a/g", "/a/b/c/./../../g");
  testResolvePath("/mid/6", "mid/content=5/../6");
  testResolvePath("/a/b/e", "a/b/c/d/../../e");
  testResolvePath("/a/b/e", "../a/b/c/d/../../e");
  testResolvePath("/a/b/e", "./a/b/c/d/../../e");
  testResolvePath("/a/b/e", "../a/b/./c/d/../../e");
  testResolvePath("/a/b/e", "./a/b/./c/d/../../e");
  testResolvePath("/a/b/e/", "./a/b/./c/d/../../e/.");
  testResolvePath("/a/b/e/", "./a/b/./c/d/../../e/./.");
  testResolvePath("/a/b/e/", "./a/b/./c/d/../../e/././.");

  final urisSample = "http://a/b/c/d;p?q";
  Uri baseFromString = Uri.parse(urisSample);
  testUriPerRFCs(baseFromString);
  Uri base = Uri.parse(urisSample);
  testUriPerRFCs(base);

  Expect.stringEquals(
      "http://example.com",
      Uri.parse("http://example.com/a/b/c").origin);
  Expect.stringEquals(
      "https://example.com",
      Uri.parse("https://example.com/a/b/c").origin);
  Expect.stringEquals(
      "http://example.com:1234",
      Uri.parse("http://example.com:1234/a/b/c").origin);
  Expect.stringEquals(
      "https://example.com:1234",
      Uri.parse("https://example.com:1234/a/b/c").origin);
  Expect.throws(
      () => Uri.parse("http:").origin,
      (e) { return e is StateError; },
      "origin for uri with empty host should fail");
  Expect.throws(
      () => new Uri(
          scheme: "http",
          userInfo: null,
          host: "",
          port: 80,
          path: "/a/b/c",
          query: "query",
          fragment: "fragment").origin,
      (e) { return e is StateError; },
      "origin for uri with empty host should fail");
  Expect.throws(
      () => new Uri(
          scheme: null,
          userInfo: null,
          host: "",
          port: 80,
          path: "/a/b/c",
          query: "query",
          fragment: "fragment").origin,
      (e) { return e is StateError; },
      "origin for uri with empty scheme should fail");
  Expect.throws(
      () => new Uri(
          scheme: "http",
          userInfo: null,
          host: null,
          port: 80,
          path: "/a/b/c",
          query: "query",
          fragment: "fragment").origin,
      (e) { return e is StateError; },
      "origin for uri with empty host should fail");
  Expect.throws(
      () => Uri.parse("http://:80").origin,
      (e) { return e is StateError; },
      "origin for uri with empty host should fail");
  Expect.throws(
      () => Uri.parse("file://localhost/test.txt").origin,
      (e) { return e is StateError; },
      "origin for non-http/https uri should fail");

  // URI encode tests
  // Create a string with code point 0x10000 encoded as a surrogate pair.
  var s = UTF8.decode([0xf0, 0x90, 0x80, 0x80]);

  Expect.stringEquals("\u{10000}", s);

  testEncodeDecode("A + B", "A%20%2B%20B");
  testEncodeDecode("\uFFFE", "%EF%BF%BE");
  testEncodeDecode("\uFFFF", "%EF%BF%BF");
  testEncodeDecode("\uFFFE", "%EF%BF%BE");
  testEncodeDecode("\uFFFF", "%EF%BF%BF");
  testEncodeDecode("\x7f", "%7F");
  testEncodeDecode("\x80", "%C2%80");
  testEncodeDecode("\u0800", "%E0%A0%80");
  testEncodeDecode(":/@',;?&=+\$", ":/@',;?&=%2B\$");
  testEncodeDecode(s, "%F0%90%80%80");
  testEncodeDecodeComponent("A + B", "A%20%2B%20B");
  testEncodeDecodeComponent("\uFFFE", "%EF%BF%BE");
  testEncodeDecodeComponent("\uFFFF", "%EF%BF%BF");
  testEncodeDecodeComponent("\uFFFE", "%EF%BF%BE");
  testEncodeDecodeComponent("\uFFFF", "%EF%BF%BF");
  testEncodeDecodeComponent("\x7f", "%7F");
  testEncodeDecodeComponent("\x80", "%C2%80");
  testEncodeDecodeComponent("\u0800", "%E0%A0%80");
  testEncodeDecodeComponent(":/@',;?&=+\$", "%3A%2F%40'%2C%3B%3F%26%3D%2B%24");
  testEncodeDecodeComponent(s, "%F0%90%80%80");
  testEncodeDecodeQueryComponent("A + B", "A+%2B+B", "A+%2B+B", "A+%2B+B");
  testEncodeDecodeQueryComponent(
      "æ ø å", "%C3%A6+%C3%B8+%C3%A5", "%E6+%F8+%E5", null);

  // Invalid URI - : and @ is swapped, port ("host") should be numeric.
  Expect.throws(
      () => Uri.parse("file://user@password:host/path"),
      (e) => e is FormatException);
}
