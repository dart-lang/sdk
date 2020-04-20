// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uriTest;

import "package:expect/expect.dart";
import 'dart:convert';

testUri(String uriText, bool isAbsolute) {
  var uri = Uri.parse(uriText);

  Expect.equals(isAbsolute, uri.isAbsolute);
  Expect.stringEquals(uriText, uri.toString());

  // Test equals and hashCode members.
  var uri2 = Uri.parse(uriText);
  Expect.equals(uri, uri2);
  Expect.equals(uri.hashCode, uri2.hashCode);

  // Test that removeFragment doesn't change anything else.
  if (uri.hasFragment) {
    Expect.equals(Uri.parse(uriText.substring(0, uriText.indexOf('#'))),
        uri.removeFragment());
  } else {
    Expect.equals(uri, Uri.parse(uriText + "#fragment").removeFragment());
  }
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

testEncodeDecodeQueryComponent(String orig, String encodedUTF8,
    String encodedLatin1, String encodedAscii) {
  var e, d;
  e = Uri.encodeQueryComponent(orig);
  Expect.stringEquals(encodedUTF8, e);
  d = Uri.decodeQueryComponent(encodedUTF8);
  Expect.stringEquals(orig, d);

  e = Uri.encodeQueryComponent(orig, encoding: utf8);
  Expect.stringEquals(encodedUTF8, e);
  d = Uri.decodeQueryComponent(encodedUTF8, encoding: utf8);
  Expect.stringEquals(orig, d);

  e = Uri.encodeQueryComponent(orig, encoding: latin1);
  Expect.stringEquals(encodedLatin1, e);
  d = Uri.decodeQueryComponent(encodedLatin1, encoding: latin1);
  Expect.stringEquals(orig, d);

  if (encodedAscii != null) {
    e = Uri.encodeQueryComponent(orig, encoding: ascii);
    Expect.stringEquals(encodedAscii, e);
    d = Uri.decodeQueryComponent(encodedAscii, encoding: ascii);
    Expect.stringEquals(orig, d);
  } else {
    Expect.throwsArgumentError(
        () => Uri.encodeQueryComponent(orig, encoding: ascii));
  }
}

testUriPerRFCs() {
  final urisSample = "http://a/b/c/d;p?q";
  Uri base = Uri.parse(urisSample);
  testResolve(expect, relative) {
    Expect.stringEquals(expect, base.resolve(relative).toString());
  }

  // From RFC 3986.
  testResolve("g:h", "g:h");
  testResolve("http://a/b/c/g", "g");
  testResolve("http://a/b/c/g", "./g");
  testResolve("http://a/b/c/g/", "g/");
  testResolve("http://a/g", "/g");
  testResolve("http://g", "//g");
  testResolve("http://a/b/c/d;p?y", "?y");
  testResolve("http://a/b/c/g?y", "g?y");
  testResolve("http://a/b/c/d;p?q#s", "#s");
  testResolve("http://a/b/c/g#s", "g#s");
  testResolve("http://a/b/c/g?y#s", "g?y#s");
  testResolve("http://a/b/c/;x", ";x");
  testResolve("http://a/b/c/g;x", "g;x");
  testResolve("http://a/b/c/g;x?y#s", "g;x?y#s");
  testResolve("http://a/b/c/d;p?q", "");
  testResolve("http://a/b/c/", ".");
  testResolve("http://a/b/c/", "./");
  testResolve("http://a/b/", "..");
  testResolve("http://a/b/", "../");
  testResolve("http://a/b/g", "../g");
  testResolve("http://a/", "../..");
  testResolve("http://a/", "../../");
  testResolve("http://a/g", "../../g");
  testResolve("http://a/g", "../../../g");
  testResolve("http://a/g", "../../../../g");
  testResolve("http://a/g", "/./g");
  testResolve("http://a/g", "/../g");
  testResolve("http://a/b/c/g.", "g.");
  testResolve("http://a/b/c/.g", ".g");
  testResolve("http://a/b/c/g..", "g..");
  testResolve("http://a/b/c/..g", "..g");
  testResolve("http://a/b/g", "./../g");
  testResolve("http://a/b/c/g/", "./g/.");
  testResolve("http://a/b/c/g/h", "g/./h");
  testResolve("http://a/b/c/h", "g/../h");
  testResolve("http://a/b/c/g;x=1/y", "g;x=1/./y");
  testResolve("http://a/b/c/y", "g;x=1/../y");
  testResolve("http://a/b/c/g?y/./x", "g?y/./x");
  testResolve("http://a/b/c/g?y/../x", "g?y/../x");
  testResolve("http://a/b/c/g#s/./x", "g#s/./x");
  testResolve("http://a/b/c/g#s/../x", "g#s/../x");
  testResolve("http:g", "http:g");

  // Additional tests (not from RFC 3986).
  testResolve("http://a/b/g;p/h;s", "../g;p/h;s");

  // Test non-URI base (no scheme, no authority, relative path).
  base = Uri.parse("a/b/c?_#_");
  testResolve("a/b/g?q#f", "g?q#f");
  testResolve("../", "../../..");
  testResolve("a/b/", ".");
  testResolve("c", "../../c");

  base = Uri.parse("s:a/b");
  testResolve("s:/c", "../c");
}

void testResolvePath(String expected, String path) {
  Expect.equals(
      expected, new Uri(path: '/').resolveUri(new Uri(path: path)).path);
  Expect.equals("http://localhost$expected",
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
    for (var userinfo in [
      "",
      "@",
      "$USERINFOCHAR$USERINFOCHAR@",
      "$USERINFOCHAR:$DIGIT@"
    ]) {
      for (var host in [
        "", "$REGNAMECHAR$REGNAMECHAR",
        "255.255.255.256", // valid reg-name.
        "[ffff::ffff:ffff]", "[ffff::255.255.255.255]"
      ]) {
        for (var port in ["", ":", ":$DIGIT$DIGIT"]) {
          var auth = "$userinfo$host$port";
          if (auth.isNotEmpty) auth = "//$auth";
          var paths = ["", "/", "/$PCHAR", "/$PCHAR/"]; // Absolute or empty.
          if (auth.isNotEmpty) {
            // Initial segment may be empty.
            paths..add("//$PCHAR");
          } else {
            // Path may begin with non-slash.
            if (scheme.isEmpty) {
              // Initial segment must not contain colon.
              paths
                ..add(PCHAR_NC)
                ..add("$PCHAR_NC/$PCHAR")
                ..add("$PCHAR_NC/$PCHAR/");
            } else {
              paths..add(PCHAR)..add("$PCHAR/$PCHAR")..add("$PCHAR/$PCHAR/");
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
      Expect.fail("Invalid URI `$uri` parsed to $result\n" + dump(result));
    } on FormatException {
      // Success.
    }
  }

  checkInvalid("s%41://x.x/"); //      No escapes in scheme,
  //                                   and no colon before slash in path.
  checkInvalid("1a://x.x/"); //        Scheme must start with letter,
  //                                   and no colon before slash in path.
  checkInvalid(".a://x.x/"); //        Scheme must start with letter,
  //                                   and no colon before slash in path.
  checkInvalid("_:"); //               Character not valid in scheme,
  //                                   and no colon before slash in path.
  checkInvalid(":"); //                Scheme must start with letter,
  //                                   and no colon before slash in path.

  void checkInvalidReplaced(uri, invalid, replacement) {
    var source = uri.replaceAll('{}', invalid);
    var expected = uri.replaceAll('{}', replacement);
    var result = Uri.parse(source);
    Expect.equals(expected, "$result", "Source: $source\n${dump(result)}");
  }

  // Regression test for http://dartbug.com/16081
  checkInvalidReplaced(
      "http://www.example.org/red%09ros{}#red)", "\u00e9", "%C3%A9");
  checkInvalidReplaced("http://r{}sum\{}.example.org", "\u00E9", "%C3%A9");

  // Invalid characters. The characters must be rejected, even if normalizing
  // the input would cause them to be valid (normalization happens after
  // validation).
  var invalidCharsAndReplacements = [
    "\xe7", "%C3%A7", //       Arbitrary non-ASCII letter
    " ", "%20", //          Space, not allowed anywhere.
    '"', "%22", //          Quote, not allowed anywhere
    "<>", "%3C%3E", //       Less/greater-than, not allowed anywhere.
    "\x7f", "%7F", //          DEL, not allowed anywhere
    "\xdf", "%C3%9F", //       German lower-case scharf-S.
    //                              Becomes ASCII when upper-cased.
    "\u0130", "%C4%B0", //       Latin capital dotted I,
    //                              becomes ASCII lower-case in Turkish.
    "%\uFB03", "%25%EF%AC%83", // % + Ligature ffi,
    //                              becomes ASCII when upper-cased,
    //                              should not be read as "%FFI".
    "\u212a", "%E2%84%AA", //    Kelvin sign. Becomes ASCII when lower-cased.
    "%1g", "%251g", //        Invalid escape.
    "\u{10000}", "%F0%90%80%80", // Non-BMP character as surrogate pair.
  ];
  for (int i = 0; i < invalidCharsAndReplacements.length; i += 2) {
    var invalid = invalidCharsAndReplacements[i];
    var valid = invalidCharsAndReplacements[i + 1];
    checkInvalid("A{}b:///".replaceAll('{}', invalid));
    checkInvalid("{}b:///".replaceAll('{}', invalid));
    checkInvalidReplaced("s://user{}info@x.x/", invalid, valid);
    checkInvalidReplaced("s://reg{}name/", invalid, valid);
    checkInvalid("s://regname:12{}45/".replaceAll("{}", invalid));
    checkInvalidReplaced("s://regname/p{}ath/", invalid, valid);
    checkInvalidReplaced("/p{}ath/", invalid, valid);
    checkInvalidReplaced("p{}ath/", invalid, valid);
    checkInvalidReplaced("s://regname/path/?x{}x", invalid, valid);
    checkInvalidReplaced("s://regname/path/#x{}x", invalid, valid);
    checkInvalidReplaced("s://regname/path/??#x{}x", invalid, valid);
  }

  // At most one @ in userinfo.
  checkInvalid("s://x@x@x.x/");
  // No colon in host except before a port.
  checkInvalid("s://x@x:x/");
  // At most one port.
  checkInvalid("s://x@x:9:9/");
  // @ not allowed in scheme.
  checkInvalid("s@://x:9/x?x#x");
  // ] not allowed alone in host.
  checkInvalid("s://xx]/");
  // IPv6 must be enclosed in [ and ] for Uri.parse.
  // It is allowed un-enclosed as argument to `Uri(host:...)` because we don't
  // need to delimit.
  checkInvalid("s://ffff::ffff:1234/");
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
    var escape = "%" + char.codeUnitAt(0).toRadixString(16); // all > 0xf.

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

  uri = new Uri(scheme: "x", path: "//y");
  Expect.equals("//y", uri.path);
  Expect.equals("x:////y", uri.toString());

  uri = new Uri(scheme: "file", path: "//y");
  Expect.equals("//y", uri.path);
  Expect.equals("file:////y", uri.toString());

  // File scheme noralizes to always showing authority, even if empty.
  uri = new Uri(scheme: "file", path: "/y");
  Expect.equals("file:///y", uri.toString());
  uri = new Uri(scheme: "file", path: "y");
  Expect.equals("file:///y", uri.toString());

  // Empty host/query/fragment ensures the delimiter is there.
  // Different from not being there.
  Expect.equals("scheme:/", Uri.parse("scheme:/").toString());
  Expect.equals("scheme:/", new Uri(scheme: "scheme", path: "/").toString());

  Expect.equals("scheme:///?#", Uri.parse("scheme:///?#").toString());
  Expect.equals(
      "scheme:///#",
      new Uri(scheme: "scheme", host: "", path: "/", query: "", fragment: "")
          .toString());

  // We allow, and escape, general delimiters in paths, queries and fragments.
  // Allow `[` and `]` in path:
  Expect.equals("s:/%5B%5D", Uri.parse("s:/[]").toString());
  Expect.equals("s:%5B%5D", Uri.parse("s:[]").toString());
  Expect.equals("%5B%5D", Uri.parse("[]").toString());
  // Allow `[`, `]` and `?` in query (anything after *first* `?`).
  // The `?` is not escaped.
  Expect.equals("s://xx/?%5B%5D?", Uri.parse("s://xx/?[]?").toString());
  // Allow `[`, `]`, `?` and `#` in fragment (anything after *first* `#`).
  // The `?` is not escaped.
  Expect.equals("s://xx/#%5B%5D%23?", Uri.parse("s://xx/#[]#?").toString());
}

void testReplace() {
  var uris = [
    Uri.parse(""),
    Uri.parse("a://@:/?#"),
    Uri.parse("a://b@c:4/e/f?g#h"),
    Uri.parse("$SCHEMECHAR://$USERINFOCHAR@$REGNAMECHAR:$DIGIT/$PCHAR/$PCHAR"
        "?$QUERYCHAR#$QUERYCHAR"),
  ];
  for (var uri1 in uris) {
    for (var uri2 in uris) {
      if (identical(uri1, uri2)) continue;
      var scheme = uri1.scheme;
      var userInfo = uri1.hasAuthority ? uri1.userInfo : "";
      var host = uri1.hasAuthority ? uri1.host : null;
      var port = uri1.hasAuthority ? uri1.port : 0;
      var path = uri1.path;
      var query = uri1.hasQuery ? uri1.query : null;
      var fragment = uri1.hasFragment ? uri1.fragment : null;

      var tmp1 = uri1;

      void test() {
        var tmp2 = new Uri(
            scheme: scheme,
            userInfo: userInfo,
            host: host,
            port: port,
            path: path,
            query: query == "" ? null : query,
            queryParameters: query == "" ? {} : null,
            fragment: fragment);
        Expect.equals(tmp1, tmp2);
      }

      test();

      scheme = uri2.scheme;
      tmp1 = tmp1.replace(scheme: scheme);
      test();

      if (uri2.hasAuthority) {
        userInfo = uri2.userInfo;
        host = uri2.host;
        port = uri2.port;
        tmp1 = tmp1.replace(userInfo: userInfo, host: host, port: port);
        test();
      }

      path = uri2.path;
      tmp1 = tmp1.replace(path: path);
      test();

      if (uri2.hasQuery) {
        query = uri2.query;
        tmp1 = tmp1.replace(query: query);
        test();
      }

      if (uri2.hasFragment) {
        fragment = uri2.fragment;
        tmp1 = tmp1.replace(fragment: fragment);
        test();
      }
    }
  }

  // Regression test, http://dartbug.com/20814
  var uri = Uri.parse("/no-authorty/");
  uri = uri.replace(fragment: "fragment");
  Expect.isFalse(uri.hasAuthority);

  uri = new Uri(scheme: "foo", path: "bar");
  uri = uri.replace(queryParameters: {
    "x": ["42", "37"],
    "y": ["43", "38"]
  });
  var params = uri.queryParametersAll;
  Expect.equals(2, params.length);
  Expect.listEquals(["42", "37"], params["x"]);
  Expect.listEquals(["43", "38"], params["y"]);
}

main() {
  testUri("http:", true);
  testUri("file:///", true);
  testUri("file", false);
  testUri("http://user@example.com:8080/fisk?query=89&hest=silas", true);
  testUri(
      "http://user@example.com:8080/fisk?query=89&hest=silas#fragment", false);
  Expect.stringEquals(
      "http://user@example.com/a/b/c?query#fragment",
      new Uri(
              scheme: "http",
              userInfo: "user",
              host: "example.com",
              port: 80,
              path: "/a/b/c",
              query: "query",
              fragment: "fragment")
          .toString());
  Expect.stringEquals(
      "/a/b/c/",
      new Uri(
              scheme: null,
              userInfo: null,
              host: null,
              port: 0,
              path: "/a/b/c/",
              query: null,
              fragment: null)
          .toString());
  Expect.stringEquals("file:///", Uri.parse("file:").toString());

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

  testUriPerRFCs();

  Expect.stringEquals(
      "http://example.com", Uri.parse("http://example.com/a/b/c").origin);
  Expect.stringEquals(
      "https://example.com", Uri.parse("https://example.com/a/b/c").origin);
  Expect.stringEquals("http://example.com:1234",
      Uri.parse("http://example.com:1234/a/b/c").origin);
  Expect.stringEquals("https://example.com:1234",
      Uri.parse("https://example.com:1234/a/b/c").origin);
  Expect.throwsStateError(() => Uri.parse("http:").origin,
      "origin for uri with empty host should fail");
  Expect.throwsStateError(
      () => new Uri(
              scheme: "http",
              userInfo: null,
              host: "",
              port: 80,
              path: "/a/b/c",
              query: "query",
              fragment: "fragment")
          .origin,
      "origin for uri with empty host should fail");
  Expect.throwsStateError(
      () => new Uri(
              scheme: null,
              userInfo: null,
              host: "",
              port: 80,
              path: "/a/b/c",
              query: "query",
              fragment: "fragment")
          .origin,
      "origin for uri with empty scheme should fail");
  Expect.throwsStateError(
      () => new Uri(
              scheme: "http",
              userInfo: null,
              host: null,
              port: 80,
              path: "/a/b/c",
              query: "query",
              fragment: "fragment")
          .origin,
      "origin for uri with empty host should fail");
  Expect.throwsStateError(() => Uri.parse("http://:80").origin,
      "origin for uri with empty host should fail");
  Expect.throwsStateError(() => Uri.parse("file://localhost/test.txt").origin,
      "origin for non-http/https uri should fail");

  // URI encode tests
  // Create a string with code point 0x10000 encoded as a surrogate pair.
  var s = utf8.decode([0xf0, 0x90, 0x80, 0x80]);

  Expect.stringEquals("\u{10000}", s);

  testEncodeDecode("A + B", "A%20+%20B");
  testEncodeDecode("\uFFFE", "%EF%BF%BE");
  testEncodeDecode("\uFFFF", "%EF%BF%BF");
  testEncodeDecode("\uFFFE", "%EF%BF%BE");
  testEncodeDecode("\uFFFF", "%EF%BF%BF");
  testEncodeDecode("\x7f", "%7F");
  testEncodeDecode("\x80", "%C2%80");
  testEncodeDecode("\u0800", "%E0%A0%80");
  // All characters not escaped by encodeFull.
  var unescapedFull = r"abcdefghijklmnopqrstuvwxyz"
      r"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      r"0123456789!#$&'()*+,-./:;=?@_~";
  // ASCII characters escaped by encodeFull:
  var escapedFull =
      "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
      "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
      r' "%<>[\]^`{|}'
      "\x7f";
  var escapedTo = "%00%01%02%03%04%05%06%07%08%09%0A%0B%0C%0D%0E%0F"
      "%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F"
      "%20%22%25%3C%3E%5B%5C%5D%5E%60%7B%7C%7D%7F";
  testEncodeDecode(unescapedFull, unescapedFull);
  testEncodeDecode(escapedFull, escapedTo);
  var nonAscii =
      "\x80-\xff-\u{100}-\u{7ff}-\u{800}-\u{ffff}-\u{10000}-\u{10ffff}";
  var nonAsciiEncoding = "%C2%80-%C3%BF-%C4%80-%DF%BF-%E0%A0%80-%EF%BF%BF-"
      "%F0%90%80%80-%F4%8F%BF%BF";
  testEncodeDecode(nonAscii, nonAsciiEncoding);
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
  testEncodeDecodeComponent(nonAscii, nonAsciiEncoding);

  // Invalid URI - : and @ is swapped, port ("host") should be numeric.
  Expect.throwsFormatException(
      () => Uri.parse("file://user@password:host/path"));

  testValidCharacters();
  testInvalidUrls();
  testNormalization();
  testReplace();
}

String dump(Uri uri) {
  return "URI: $uri\n"
      "  Scheme:    ${uri.scheme} #${uri.scheme.length}\n"
      "  User-info: ${uri.userInfo} #${uri.userInfo.length}\n"
      "  Host:      ${uri.host} #${uri.host.length}\n"
      "  Port:      ${uri.port}\n"
      "  Path:      ${uri.path} #${uri.path.length}\n"
      "  Query:     ${uri.query} #${uri.query.length}\n"
      "  Fragment:  ${uri.fragment} #${uri.fragment.length}\n";
}
