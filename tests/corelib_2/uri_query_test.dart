// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void testInvalidArguments() {}

void testEncodeQueryComponent() {
  // This exact data is from posting a form in Chrome 26 with the one
  // exception that * is encoded as %30 and ~ is not encoded as %7E.
  Expect.equals(
      "%21%22%23%24%25%26%27%28%29%2A%2B%2C-.%2F%"
      "3A%3B%3C%3D%3E%3F%40%5B%5C%5D%5E_%60%7B%7C%7D~",
      Uri.encodeQueryComponent("!\"#\$%&'()*+,-./:;<=>?@[\\]^_`{|}~"));
  Expect.equals("+%2B+", Uri.encodeQueryComponent(" + "));
  Expect.equals("%2B+%2B", Uri.encodeQueryComponent("+ +"));
}

void testQueryParameters() {
  test(String query, Map<String, String> parameters, [String normalizedQuery]) {
    if (normalizedQuery == null) normalizedQuery = query;
    check(uri) {
      Expect.isTrue(uri.hasQuery);
      Expect.equals(normalizedQuery, uri.query);
      Expect.equals("?$normalizedQuery", uri.toString());
      if (parameters.containsValue(null)) {
        var map = new Map.from(parameters);
        map.forEach((k, v) {
          if (v == null) map[k] = "";
        });
        Expect.mapEquals(map, uri.queryParameters);
      } else {
        Expect.mapEquals(parameters, uri.queryParameters);
      }
    }

    var uri1 = new Uri(queryParameters: parameters);
    var uri2 = new Uri(query: query);
    var uri3 = Uri.parse("?$query");
    check(uri1);
    if (query != "") {
      check(uri2);
    } else {
      Expect.isFalse(uri2.hasQuery);
    }
    check(uri3);
    Expect.equals(uri1, uri3);
    if (query != "") Expect.equals(uri2, uri3);
    if (parameters.containsValue(null)) {
      var map = new Map.from(parameters);
      map.forEach((k, v) {
        if (v == null) map[k] = "";
      });
      Expect.mapEquals(map, Uri.splitQueryString(query));
    } else {
      Expect.mapEquals(parameters, Uri.splitQueryString(query));
    }
  }

  test("", {});
  test("A", {"A": null});
  test("%25", {"%": null});
  test("%41", {"A": null}, "A");
  test("%41A", {"AA": null}, "AA");
  test("A", {"A": ""});
  test("%25", {"%": ""});
  test("%41", {"A": ""}, "A");
  test("%41A", {"AA": ""}, "AA");
  test("A=a", {"A": "a"});
  test("%25=a", {"%": "a"});
  test("%41=%61", {"A": "a"}, "A=a");
  test("A=+", {"A": " "});
  test("A=%2B", {"A": "+"});
  test("A=a&B", {"A": "a", "B": null});
  test("A=a&B", {"A": "a", "B": ""});
  test("A=a&B=b", {"A": "a", "B": "b"});
  test("%41=%61&%42=%62", {"A": "a", "B": "b"}, "A=a&B=b");

  var unreserved = "-._~0123456789"
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      "abcdefghijklmnopqrstuvwxyz";
  var encoded = new StringBuffer();
  var allEncoded = new StringBuffer();
  var unencoded = new StringBuffer();
  for (int i = 32; i < 128; i++) {
    if (i == 32) {
      encoded.write("+");
    } else if (unreserved.indexOf(new String.fromCharCode(i)) != -1) {
      encoded.writeCharCode(i);
    } else {
      encoded.write("%");
      encoded.write(i.toRadixString(16).toUpperCase());
    }
    if (i == 32) {
      allEncoded.write("+");
    } else {
      allEncoded.write("%");
      allEncoded.write(i.toRadixString(16).toUpperCase());
    }
    unencoded.writeCharCode(i);
  }
  var encodedStr = encoded.toString();
  var unencodedStr = unencoded.toString();
  test("a=$encodedStr", {"a": unencodedStr});
  test("a=$encodedStr&b=$encodedStr", {"a": unencodedStr, "b": unencodedStr});

  var map = new Map();
  map[unencodedStr] = unencodedStr;
  test("$encodedStr=$encodedStr", map);
  test("$encodedStr=$allEncoded", map, "$encodedStr=$encodedStr");
  test("$allEncoded=$encodedStr", map, "$encodedStr=$encodedStr");
  test("$allEncoded=$allEncoded", map, "$encodedStr=$encodedStr");
  map[unencodedStr] = null;
  test("$encodedStr", map);
  map[unencodedStr] = "";
  test("$encodedStr", map);
}

testInvalidQueryParameters() {
  test(String query, Map<String, String> parameters) {
    check(uri) {
      Expect.equals(query, uri.query);
      if (query.isEmpty) {
        Expect.equals(query, uri.toString());
      } else {
        Expect.equals("?$query", uri.toString());
      }
      if (parameters.containsValue(null)) {} else {
        Expect.mapEquals(parameters, uri.queryParameters);
      }
    }

    var uri1 = new Uri(query: query);
    var uri2 = Uri.parse("?$query");
    check(uri1);
    check(uri2);
    Expect.equals(uri1, uri2);
  }

  test("=", {});
  test("=xxx", {});
  test("===", {});
  test("=xxx=yyy=zzz", {});
  test("=&=&=", {});
  test("=xxx&=yyy&=zzz", {});
  test("&=&=&", {});
  test("&=xxx&=xxx&", {});
}

testQueryParametersImmutableMap() {
  test(map) {
    Expect.isTrue(map.containsValue("b"));
    Expect.isTrue(map.containsKey("a"));
    Expect.equals("b", map["a"]);
    Expect.throwsUnsupportedError(() => map["a"] = "c");
    Expect.throwsUnsupportedError(() => map.putIfAbsent("b", () => "e"));
    Expect.throwsUnsupportedError(() => map.remove("a"));
    Expect.throwsUnsupportedError(() => map.clear());
    var count = 0;
    map.forEach((key, value) => count++);
    Expect.equals(2, count);
    Expect.equals(2, map.keys.length);
    Expect.equals(2, map.values.length);
    Expect.equals(2, map.length);
    Expect.isFalse(map.isEmpty);
    Expect.isTrue(map.isNotEmpty);
  }

  test(Uri.parse("?a=b&c=d").queryParameters);
  test(new Uri(queryParameters: {"a": "b", "c": "d"}).queryParameters);
}

main() {
  testInvalidArguments();
  testEncodeQueryComponent();
  testQueryParameters();
  testInvalidQueryParameters();
  testQueryParametersImmutableMap();
}
