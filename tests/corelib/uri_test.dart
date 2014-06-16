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

const ALPHA = r"abcdefghijklmnopqrstuvwxuzABCDEFGHIJKLMNOPQRSTUVWXUZ";
const DIGIT = r"0123456789";
const PERCENT_ENCODED = "%00%ff";
const SUBDELIM = r"!$&'()*+,;=";

const SCHEMECHAR = "$ALPHA$DIGIT+-.";
const UNRESERVED = "$ALPHA$DIGIT-._~";
const REGNAMECHAR = "$UNRESERVED$SUBDELIM$PERCENT_ENCODED";
const USERINFOCHAR = "$REGNAMECHAR:";

const PCHAR_NC = "$UNRESERVED$SUBDELIM$PERCENT_ENCODED@";
const PCHAR = "$PCHAR_NC:";
const QUERYCHAR = "$PCHAR/?";

void testValidCharacters() {
  // test that all valid characters are accepted.

  for (var scheme in ["", "$SCHEMECHAR$SCHEMECHAR:"]) {
    for (var userinfo in ["", "@", "$USERINFOCHAR$USERINFOCHAR@",
                          "$USERINFOCHAR:$DIGIT@"]) {
      for (var host in ["", "$REGNAMECHAR$REGNAMECHAR",
                        "255.255.255.256",  // valid reg-name.
                        "[ffff::ffff:ffff]", "[ffff::255.255.255.255]"]) {
        for (var port in ["", ":$DIGIT$DIGIT"]) {
          var auth = "$userinfo$host$port";
          if (auth.isNotEmpty) auth = "//$auth";
          var paths = ["", "/", "/$PCHAR", "/$PCHAR/"];  // Absolute or empty.
          if (auth.isNotEmpty) {
            // Initial segment may be empty.
            paths..add("//$PCHAR");
          } else {
            // Path may begin with non-slash.
            if (scheme.isEmpty) {
              // Initial segment must not contain colon.
              paths..add(PCHAR_NC)
                   ..add("$PCHAR_NC/$PCHAR")
                   ..add("$PCHAR_NC/$PCHAR/");
            } else {
              paths..add(PCHAR)
                   ..add("$PCHAR/$PCHAR")
                   ..add("$PCHAR/$PCHAR/");
            }
          }
          for (var path in paths) {
            for (var query in ["", "?", "?$QUERYCHAR"]) {
              for (var fragment in ["", "#", "#$QUERYCHAR"]) {
                var uri = "$scheme$auth$path$query$fragment";
                // Should not throw.
                var result = Uri.parse(uri);
              }
            }
          }
        }
      }
    }
  }
}

void testInvalidUrls() {
  void checkInvalid(uri) {
    try {
      var result = Uri.parse(uri);
      Expect.fail("Invalid URI `$uri` parsed to $result\n"
                  "  Scheme:    ${result.scheme}\n"
                  "  User-info: ${result.userInfo}\n"
                  "  Host:      ${result.host}\n"
                  "  Port:      ${result.port}\n"
                  "  Path:      ${result.path}\n"
                  "  Query:     ${result.query}\n"
                  "  Fragment:  ${result.fragment}\n");
    } on FormatException {
      // Success.
    }
  }

  // Regression test for http://dartbug.com/16081
  checkInvalid("http://www.example.org/red%09ros\u00E9#red");
  checkInvalid("http://r\u00E9sum\u00E9.example.org");

  // Invalid characters. The characters must be rejected, even if normalizing
  // the input would cause them to be valid (normalization happens after
  // validation).
  var invalidChars = [
    "\xe7",      // Arbitrary non-ASCII letter
    " ",         // Space, not allowed anywhere.
    '"',         // Quote, not allowed anywhere
    "\x7f",      // DEL, not allowed anywhere
    "\xdf",      // German lower-case scharf-S. Becomes ASCII when upper-cased.
    "\u0130"     // Latin capital dotted I, becomes ASCII lower-case in Turkish.
    "%\uFB03",   // % + Ligature ffi, becomes ASCII when upper-cased,
                 // should not be read as "%FFI".
    "\u212a",    // Kelvin sign. Becomes ASCII when lower-cased.
    "%1g",       // Invalid escape.
  ];
  for (var invalid in invalidChars) {
    checkInvalid("A${invalid}b:///");
    checkInvalid("${invalid}b:///");
    checkInvalid("s://user${invalid}info@x.x/");
    checkInvalid("s://reg${invalid}name/");
    checkInvalid("s://regname:12${invalid}45/");
    checkInvalid("s://regname/p${invalid}ath/");
    checkInvalid("/p${invalid}ath/");
    checkInvalid("p${invalid}ath/");
    checkInvalid("s://regname/path/?x${invalid}x");
    checkInvalid("s://regname/path/#x${invalid}x");
    checkInvalid("s://regname/path/?#x${invalid}x");
  }
  checkInvalid("s%41://x.x/");      // No escapes in scheme,
                                    // and no colon before slash in path.
  checkInvalid("1a://x.x/");        // Scheme must start with letter,
                                    // and no colon before slash in path.
  checkInvalid(".a://x.x/");        // Scheme must start with letter,
                                    // and no colon before slash in path.
  checkInvalid("_:");               // Character not valid in scheme,
                                    // and no colon before slash in path.
  checkInvalid(":");                // Scheme must start with letter,
                                    // and no colon before slash in path.
  checkInvalid("s://x@x@x.x/");     // At most one @ in userinfo.
  checkInvalid("s://x@x:x/");       // No colon in host except before a port.
  checkInvalid("s://x@x:9:9/");     // At most one port.
  checkInvalid("s://x/x#foo#bar");  // At most one #.
  checkInvalid("s://:/");           // Colon in host requires port,
                                    // and path may not start with //.
  checkInvalid("s@://x:9/x?x#x");   // @ not allowed in scheme.
}

void testNormalization() {
  // The Uri constructor and the Uri.parse function performs RFC-3986
  // syntax based normalization.

  var uri;

  // Scheme: Only case normalization. Schemes cannot contain escapes.
  uri = Uri.parse("A:");
  Expect.equals("a", uri.scheme);
  uri = Uri.parse("Z:");
  Expect.equals("z", uri.scheme);
  uri = Uri.parse("$SCHEMECHAR:");
  Expect.equals(SCHEMECHAR.toLowerCase(), uri.scheme);

  // Percent escape normalization.
  // Escapes of unreserved characters are converted to the character,
  // subject to case normalization in reg-name.
  for (var i = 0; i < UNRESERVED.length; i++) {
    var char = UNRESERVED[i];
    var escape = "%" + char.codeUnitAt(0).toRadixString(16);  // all > 0xf.

    uri = Uri.parse("s://xX${escape}xX@yY${escape}yY/zZ${escape}zZ"
                    "?vV${escape}vV#wW${escape}wW");
    Expect.equals("xX${char}xX", uri.userInfo);
    Expect.equals("yY${char}yY".toLowerCase(), uri.host);
    Expect.equals("/zZ${char}zZ", uri.path);
    Expect.equals("vV${char}vV", uri.query);
    Expect.equals("wW${char}wW", uri.fragment);
  }

  // Escapes of reserved characters are kept, but upper-cased.
  for (var escape in ["%00", "%1f", "%7F", "%fF"]) {
    uri = Uri.parse("s://xX${escape}xX@yY${escape}yY/zZ${escape}zZ"
                    "?vV${escape}vV#wW${escape}wW");
    var normalizedEscape = escape.toUpperCase();
    Expect.equals("xX${normalizedEscape}xX", uri.userInfo);
    Expect.equals("yy${normalizedEscape}yy", uri.host);
    Expect.equals("/zZ${normalizedEscape}zZ", uri.path);
    Expect.equals("vV${normalizedEscape}vV", uri.query);
    Expect.equals("wW${normalizedEscape}wW", uri.fragment);
  }

  // Some host normalization edge cases.
  uri = Uri.parse("x://x%61X%41x%41X%61x/");
  Expect.equals("xaxaxaxax", uri.host);

  uri = Uri.parse("x://Xxxxxxxx/");
  Expect.equals("xxxxxxxx", uri.host);

  uri = Uri.parse("x://xxxxxxxX/");
  Expect.equals("xxxxxxxx", uri.host);

  uri = Uri.parse("x://xxxxxxxx%61/");
  Expect.equals("xxxxxxxxa", uri.host);

  uri = Uri.parse("x://%61xxxxxxxx/");
  Expect.equals("axxxxxxxx", uri.host);

  uri = Uri.parse("x://X/");
  Expect.equals("x", uri.host);

  uri = Uri.parse("x://%61/");
  Expect.equals("a", uri.host);

  // TODO(lrn): Also do path normalization: /./ -> / and /x/../ -> /
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

  testValidCharacters();
  testInvalidUrls();
  testNormalization();
}
