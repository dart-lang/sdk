// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._http;

import "dart:async";
import "dart:collection";
import "dart:convert";
import "dart:developer";
import "dart:io";
import "dart:isolate";
import "dart:math";
import "dart:typed_data";

import "package:expect/expect.dart";

import "../../../sdk/lib/internal/internal.dart"
    show Since, valueOfNonNullableParamWithDefault, HttpStatus;

part "../../../sdk/lib/_http/crypto.dart";
part "../../../sdk/lib/_http/http_impl.dart";
part "../../../sdk/lib/_http/http_date.dart";
part "../../../sdk/lib/_http/http_parser.dart";
part "../../../sdk/lib/_http/http_headers.dart";
part "../../../sdk/lib/_http/http_session.dart";

void testMultiValue() {
  _HttpHeaders headers = new _HttpHeaders("1.1");
  Expect.isNull(headers[HttpHeaders.pragmaHeader]);
  headers.add(HttpHeaders.pragmaHeader, "pragma1");
  Expect.equals(1, headers[HttpHeaders.pragmaHeader]!.length);
  Expect.equals(1, headers["pragma"]!.length);
  Expect.equals(1, headers["Pragma"]!.length);
  Expect.equals(1, headers["pragma"]!.length);
  Expect.equals("pragma1", headers.value(HttpHeaders.pragmaHeader));

  headers.add(HttpHeaders.pragmaHeader, "pragma2");
  Expect.equals(2, headers[HttpHeaders.pragmaHeader]!.length);
  Expect.throws(
      () => headers.value(HttpHeaders.pragmaHeader), (e) => e is HttpException);

  headers.add(HttpHeaders.pragmaHeader, ["pragma3", "pragma4"]);
  Expect.listEquals(["pragma1", "pragma2", "pragma3", "pragma4"],
      headers[HttpHeaders.pragmaHeader]!);

  headers.remove(HttpHeaders.pragmaHeader, "pragma3");
  Expect.equals(3, headers[HttpHeaders.pragmaHeader]!.length);
  Expect.listEquals(
      ["pragma1", "pragma2", "pragma4"], headers[HttpHeaders.pragmaHeader]!);

  headers.remove(HttpHeaders.pragmaHeader, "pragma3");
  Expect.equals(3, headers[HttpHeaders.pragmaHeader]!.length);

  headers.set(HttpHeaders.pragmaHeader, "pragma5");
  Expect.equals(1, headers[HttpHeaders.pragmaHeader]!.length);

  headers.set(HttpHeaders.pragmaHeader, ["pragma6", "pragma7"]);
  Expect.equals(2, headers[HttpHeaders.pragmaHeader]!.length);

  headers.removeAll(HttpHeaders.pragmaHeader);
  Expect.isNull(headers[HttpHeaders.pragmaHeader]);
}

void testDate() {
  DateTime date1 = new DateTime.utc(1999, DateTime.june, 11, 18, 46, 53, 0);
  String httpDate1 = "Fri, 11 Jun 1999 18:46:53 GMT";
  DateTime date2 = new DateTime.utc(2000, DateTime.august, 16, 12, 34, 56, 0);
  String httpDate2 = "Wed, 16 Aug 2000 12:34:56 GMT";

  _HttpHeaders headers = new _HttpHeaders("1.1");
  Expect.isNull(headers.date);
  headers.date = date1;
  Expect.equals(date1, headers.date);
  Expect.equals(httpDate1, headers.value(HttpHeaders.dateHeader));
  Expect.equals(1, headers[HttpHeaders.dateHeader]!.length);
  headers.add(HttpHeaders.dateHeader, httpDate2);
  Expect.equals(1, headers[HttpHeaders.dateHeader]!.length);
  Expect.equals(date2, headers.date);
  Expect.equals(httpDate2, headers.value(HttpHeaders.dateHeader));
  headers.set(HttpHeaders.dateHeader, httpDate1);
  Expect.equals(1, headers[HttpHeaders.dateHeader]!.length);
  Expect.equals(date1, headers.date);
  Expect.equals(httpDate1, headers.value(HttpHeaders.dateHeader));

  headers.set(HttpHeaders.dateHeader, "xxx");
  Expect.equals("xxx", headers.value(HttpHeaders.dateHeader));
  Expect.equals(null, headers.date);
}

void testExpires() {
  DateTime date1 = new DateTime.utc(1999, DateTime.june, 11, 18, 46, 53, 0);
  String httpDate1 = "Fri, 11 Jun 1999 18:46:53 GMT";
  DateTime date2 = new DateTime.utc(2000, DateTime.august, 16, 12, 34, 56, 0);
  String httpDate2 = "Wed, 16 Aug 2000 12:34:56 GMT";

  _HttpHeaders headers = new _HttpHeaders("1.1");
  Expect.isNull(headers.expires);
  headers.expires = date1;
  Expect.equals(date1, headers.expires);
  Expect.equals(httpDate1, headers.value(HttpHeaders.expiresHeader));
  Expect.equals(1, headers[HttpHeaders.expiresHeader]!.length);
  headers.add(HttpHeaders.expiresHeader, httpDate2);
  Expect.equals(1, headers[HttpHeaders.expiresHeader]!.length);
  Expect.equals(date2, headers.expires);
  Expect.equals(httpDate2, headers.value(HttpHeaders.expiresHeader));
  headers.set(HttpHeaders.expiresHeader, httpDate1);
  Expect.equals(1, headers[HttpHeaders.expiresHeader]!.length);
  Expect.equals(date1, headers.expires);
  Expect.equals(httpDate1, headers.value(HttpHeaders.expiresHeader));

  headers.set(HttpHeaders.expiresHeader, "xxx");
  Expect.equals("xxx", headers.value(HttpHeaders.expiresHeader));
  Expect.equals(null, headers.expires);
}

void testIfModifiedSince() {
  DateTime date1 = new DateTime.utc(1999, DateTime.june, 11, 18, 46, 53, 0);
  String httpDate1 = "Fri, 11 Jun 1999 18:46:53 GMT";
  DateTime date2 = new DateTime.utc(2000, DateTime.august, 16, 12, 34, 56, 0);
  String httpDate2 = "Wed, 16 Aug 2000 12:34:56 GMT";

  _HttpHeaders headers = new _HttpHeaders("1.1");
  Expect.isNull(headers.ifModifiedSince);
  headers.ifModifiedSince = date1;
  Expect.equals(date1, headers.ifModifiedSince);
  Expect.equals(httpDate1, headers.value(HttpHeaders.ifModifiedSinceHeader));
  Expect.equals(1, headers[HttpHeaders.ifModifiedSinceHeader]!.length);
  headers.add(HttpHeaders.ifModifiedSinceHeader, httpDate2);
  Expect.equals(1, headers[HttpHeaders.ifModifiedSinceHeader]!.length);
  Expect.equals(date2, headers.ifModifiedSince);
  Expect.equals(httpDate2, headers.value(HttpHeaders.ifModifiedSinceHeader));
  headers.set(HttpHeaders.ifModifiedSinceHeader, httpDate1);
  Expect.equals(1, headers[HttpHeaders.ifModifiedSinceHeader]!.length);
  Expect.equals(date1, headers.ifModifiedSince);
  Expect.equals(httpDate1, headers.value(HttpHeaders.ifModifiedSinceHeader));

  headers.set(HttpHeaders.ifModifiedSinceHeader, "xxx");
  Expect.equals("xxx", headers.value(HttpHeaders.ifModifiedSinceHeader));
  Expect.equals(null, headers.ifModifiedSince);
}

void testHost() {
  String host = "www.google.com";
  _HttpHeaders headers = new _HttpHeaders("1.1");
  Expect.isNull(headers.host);
  Expect.isNull(headers.port);
  headers.host = host;
  Expect.equals(host, headers.value(HttpHeaders.hostHeader));
  headers.port = 1234;
  Expect.equals("$host:1234", headers.value(HttpHeaders.hostHeader));
  headers.port = HttpClient.defaultHttpPort;
  Expect.equals(host, headers.value(HttpHeaders.hostHeader));

  headers = new _HttpHeaders("1.1");
  headers.add(HttpHeaders.hostHeader, host);
  Expect.equals(host, headers.host);
  Expect.equals(HttpClient.defaultHttpPort, headers.port);
  headers.add(HttpHeaders.hostHeader, "$host:4567");
  Expect.equals(1, headers[HttpHeaders.hostHeader]!.length);
  Expect.equals(host, headers.host);
  Expect.equals(4567, headers.port);

  headers = new _HttpHeaders("1.1");
  headers.add(HttpHeaders.hostHeader, "$host:xxx");
  Expect.equals("$host:xxx", headers.value(HttpHeaders.hostHeader));
  Expect.equals(host, headers.host);
  Expect.isNull(headers.port);

  headers = new _HttpHeaders("1.1");
  headers.add(HttpHeaders.hostHeader, ":1234");
  Expect.equals(":1234", headers.value(HttpHeaders.hostHeader));
  Expect.isNull(headers.host);
  Expect.equals(1234, headers.port);
}

void testTransferEncoding() {
  expectChunked(headers) {
    Expect.listEquals(headers['transfer-encoding'], ['chunked']);
    Expect.isTrue(headers.chunkedTransferEncoding);
  }

  expectNonChunked(headers) {
    Expect.isNull(headers['transfer-encoding']);
    Expect.isFalse(headers.chunkedTransferEncoding);
  }

  _HttpHeaders headers;

  headers = new _HttpHeaders("1.1");
  headers.chunkedTransferEncoding = true;
  expectChunked(headers);
  headers.set('transfer-encoding', ['chunked']);
  expectChunked(headers);

  headers = new _HttpHeaders("1.1");
  headers.set('transfer-encoding', ['chunked']);
  expectChunked(headers);
  headers.chunkedTransferEncoding = true;
  expectChunked(headers);

  headers = new _HttpHeaders("1.1");
  headers.chunkedTransferEncoding = true;
  headers.chunkedTransferEncoding = false;
  expectNonChunked(headers);

  headers = new _HttpHeaders("1.1");
  headers.chunkedTransferEncoding = true;
  headers.remove('transfer-encoding', 'chunked');
  expectNonChunked(headers);

  headers = new _HttpHeaders("1.1");
  headers.set('transfer-encoding', ['chunked']);
  headers.chunkedTransferEncoding = false;
  expectNonChunked(headers);

  headers = new _HttpHeaders("1.1");
  headers.set('transfer-encoding', ['chunked']);
  headers.remove('transfer-encoding', 'chunked');
  expectNonChunked(headers);
}

void testEnumeration() {
  _HttpHeaders headers = new _HttpHeaders("1.1");
  Expect.isNull(headers[HttpHeaders.pragmaHeader]);
  headers.add("My-Header-1", "value 1");
  headers.add("My-Header-2", "value 2");
  headers.add("My-Header-1", "value 3");
  bool myHeader1 = false;
  bool myHeader2 = false;
  int totalValues = 0;
  headers.forEach((String name, List<String> values) {
    totalValues += values.length;
    if (name == "my-header-1") {
      myHeader1 = true;
      Expect.isTrue(values.indexOf("value 1") != -1);
      Expect.isTrue(values.indexOf("value 3") != -1);
    }
    if (name == "my-header-2") {
      myHeader2 = true;
      Expect.isTrue(values.indexOf("value 2") != -1);
    }
  });
  Expect.isTrue(myHeader1);
  Expect.isTrue(myHeader2);
  Expect.equals(3, totalValues);
}

void testHeaderValue() {
  void check(HeaderValue headerValue, String value,
      [Map<String, String?>? parameters]) {
    Expect.equals(value, headerValue.value);
    if (parameters != null) {
      Expect.equals(parameters.length, headerValue.parameters.length);
      parameters.forEach((String name, String? value) {
        Expect.equals(value, headerValue.parameters[name]);
      });
    } else {
      Expect.equals(0, headerValue.parameters.length);
    }
  }

  HeaderValue headerValue;
  headerValue = HeaderValue.parse("");
  check(headerValue, "", {});
  headerValue = HeaderValue.parse(";");
  check(headerValue, "", {});
  headerValue = HeaderValue.parse(";;");
  check(headerValue, "", {});
  headerValue = HeaderValue.parse("v;a");
  check(headerValue, "v", {"a": null});
  headerValue = HeaderValue.parse("v;a=");
  check(headerValue, "v", {"a": ""});
  Expect.throws(() => HeaderValue.parse("v;a=\""), (e) => e is HttpException);
  headerValue = HeaderValue.parse("v;a=\"\"");
  check(headerValue, "v", {"a": ""});
  Expect.throws(() => HeaderValue.parse("v;a=\"\\"), (e) => e is HttpException);
  Expect.throws(
      () => HeaderValue.parse("v;a=\";b=\"c\""), (e) => e is HttpException);
  Expect.throws(() => HeaderValue.parse("v;a=b c"), (e) => e is HttpException);
  headerValue = HeaderValue.parse("æ;ø=å");
  check(headerValue, "æ", {"ø": "å"});
  headerValue =
      HeaderValue.parse("xxx; aaa=bbb; ccc=\"\\\";\\a\"; ddd=\"    \"");
  check(headerValue, "xxx", {"aaa": "bbb", "ccc": '\";a', "ddd": "    "});
  headerValue =
      new HeaderValue("xxx", {"aaa": "bbb", "ccc": '\";a', "ddd": "    "});
  check(headerValue, "xxx", {"aaa": "bbb", "ccc": '\";a', "ddd": "    "});

  headerValue = HeaderValue.parse("attachment; filename=genome.jpeg;"
      "modification-date=\"Wed, 12 February 1997 16:29:51 -0500\"");
  var parameters = {
    "filename": "genome.jpeg",
    "modification-date": "Wed, 12 February 1997 16:29:51 -0500"
  };
  check(headerValue, "attachment", parameters);
  headerValue = new HeaderValue("attachment", parameters);
  check(headerValue, "attachment", parameters);
  headerValue = HeaderValue.parse("  attachment  ;filename=genome.jpeg  ;"
      "modification-date = \"Wed, 12 February 1997 16:29:51 -0500\"");
  check(headerValue, "attachment", parameters);
  headerValue = HeaderValue.parse("xxx; aaa; bbb; ccc");
  check(headerValue, "xxx", {"aaa": null, "bbb": null, "ccc": null});
  headerValue = HeaderValue.parse("v; a=A; b=B, V; c=C", valueSeparator: ";");
  check(headerValue, "v", {});
  headerValue = HeaderValue.parse("v; a=A; b=B, V; c=C", valueSeparator: ",");
  check(headerValue, "v", {"a": "A", "b": "B"});
  Expect.throws(() => HeaderValue.parse("v; a=A; b=B, V; c=C"));

  Expect.equals("", HeaderValue().toString());
  Expect.equals("", HeaderValue("").toString());
  Expect.equals("v", HeaderValue("v").toString());
  Expect.equals("v", HeaderValue("v", {}).toString());
  Expect.equals("v; ", HeaderValue("v", {"": null}).toString());
  Expect.equals("v; a", HeaderValue("v", {"a": null}).toString());
  Expect.equals("v; a; b", HeaderValue("v", {"a": null, "b": null}).toString());
  Expect.equals(
      "v; a; b=c", HeaderValue("v", {"a": null, "b": "c"}).toString());
  Expect.equals(
      "v; a=c; b", HeaderValue("v", {"a": "c", "b": null}).toString());
  Expect.equals("v; a=\"\"", HeaderValue("v", {"a": ""}).toString());
  Expect.equals("v; a=\"b c\"", HeaderValue("v", {"a": "b c"}).toString());
  Expect.equals("v; a=\",\"", HeaderValue("v", {"a": ","}).toString());
  Expect.equals(
      "v; a=\"\\\\\\\"\"", HeaderValue("v", {"a": "\\\""}).toString());
  Expect.equals("v; a=\"ø\"", HeaderValue("v", {"a": "ø"}).toString());
}

void testContentType() {
  void check(ContentType contentType, String primaryType, String subType,
      [Map<String, String?>? parameters]) {
    Expect.equals(primaryType, contentType.primaryType);
    Expect.equals(subType, contentType.subType);
    Expect.equals("$primaryType/$subType", contentType.value);
    if (parameters != null) {
      Expect.equals(parameters.length, contentType.parameters.length);
      parameters.forEach((String name, String? value) {
        Expect.equals(value, contentType.parameters[name]);
      });
    } else {
      Expect.equals(0, contentType.parameters.length);
    }
  }

  ContentType contentType;
  contentType = new ContentType("", "");
  Expect.equals("", contentType.primaryType);
  Expect.equals("", contentType.subType);
  Expect.equals("/", contentType.value);
  Expect.throwsUnsupportedError(() => contentType.parameters["xxx"] = "yyy");

  contentType = ContentType.parse("text/html");
  check(contentType, "text", "html");
  Expect.equals("text/html", contentType.toString());
  contentType = new ContentType("text", "html", charset: "utf-8");
  check(contentType, "text", "html", {"charset": "utf-8"});
  Expect.equals("text/html; charset=utf-8", contentType.toString());
  Expect.throwsUnsupportedError(() => contentType.parameters["xxx"] = "yyy");

  contentType = new ContentType("text", "html",
      parameters: {"CHARSET": "UTF-8", "xxx": "YYY"});
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "YYY"});
  String s = contentType.toString();
  bool expectedToString = (s == "text/html; charset=utf-8; xxx=YYY" ||
      s == "text/html; xxx=YYY; charset=utf-8");
  Expect.isTrue(expectedToString);
  contentType = ContentType.parse("text/html; CHARSET=UTF-8; xxx=YYY");
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "YYY"});
  Expect.throwsUnsupportedError(() => contentType.parameters["xxx"] = "yyy");

  contentType = new ContentType("text", "html",
      charset: "ISO-8859-1", parameters: {"CHARSET": "UTF-8", "xxx": "yyy"});
  check(contentType, "text", "html", {"charset": "iso-8859-1", "xxx": "yyy"});
  s = contentType.toString();
  expectedToString = (s == "text/html; charset=iso-8859-1; xxx=yyy" ||
      s == "text/html; xxx=yyy; charset=iso-8859-1");
  Expect.isTrue(expectedToString);

  contentType = ContentType.parse("text/html");
  check(contentType, "text", "html");
  contentType = ContentType.parse(" text/html  ");
  check(contentType, "text", "html");
  contentType = ContentType.parse("text/html; charset=utf-8");
  check(contentType, "text", "html", {"charset": "utf-8"});
  contentType = ContentType.parse("  text/html  ;  charset  =  utf-8  ");
  check(contentType, "text", "html", {"charset": "utf-8"});
  contentType = ContentType.parse("text/html; charset=utf-8; xxx=yyy");
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
  contentType =
      ContentType.parse("  text/html  ;  charset  =  utf-8  ;  xxx=yyy  ");
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
  contentType = ContentType.parse('text/html; charset=utf-8; xxx="yyy"');
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
  contentType =
      ContentType.parse("  text/html  ;  charset  =  utf-8  ;  xxx=yyy  ");
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});

  contentType = ContentType.parse("text/html; charset=;");
  check(contentType, "text", "html", {"charset": ""});
  contentType = ContentType.parse("text/html; charset;");
  check(contentType, "text", "html", {"charset": null});

  // Test builtin content types.
  check(ContentType.text, "text", "plain", {"charset": "utf-8"});
  check(ContentType.html, "text", "html", {"charset": "utf-8"});
  check(ContentType.json, "application", "json", {"charset": "utf-8"});
  check(ContentType.binary, "application", "octet-stream");
}

void testKnownContentTypes() {
  // Well known content types used by the VM service.
  ContentType.parse('text/html; charset=UTF-8');
  ContentType.parse('application/dart; charset=UTF-8');
  ContentType.parse('application/javascript; charset=UTF-8');
  ContentType.parse('text/css; charset=UTF-8');
  ContentType.parse('image/gif');
  ContentType.parse('image/png');
  ContentType.parse('image/jpeg');
  ContentType.parse('image/jpeg');
  ContentType.parse('image/svg+xml');
  ContentType.parse('text/plain');
}

void testContentTypeCache() {
  _HttpHeaders headers = new _HttpHeaders("1.1");
  headers.set(HttpHeaders.contentTypeHeader, "text/html");
  Expect.equals("text", headers.contentType?.primaryType);
  Expect.equals("html", headers.contentType?.subType);
  Expect.equals("text/html", headers.contentType?.value);
  headers.set(HttpHeaders.contentTypeHeader, "text/plain; charset=utf-8");
  Expect.equals("text", headers.contentType?.primaryType);
  Expect.equals("plain", headers.contentType?.subType);
  Expect.equals("text/plain", headers.contentType?.value);
  headers.removeAll(HttpHeaders.contentTypeHeader);
  Expect.isNull(headers.contentType);
}

void testCookie() {
  test(String name, String value) {
    void checkCookiesEquals(a, b) {
      Expect.equals(a.name, b.name);
      Expect.equals(a.value, b.value);
      Expect.equals(a.expires, b.expires);
      Expect.equals(a.toString(), b.toString());
    }

    void checkCookie(cookie, s) {
      Expect.equals(s, cookie.toString());
      var c = new _Cookie.fromSetCookieValue(s);
      checkCookiesEquals(cookie, c);
    }

    Cookie cookie;
    cookie = new Cookie(name, value);
    Expect.equals("$name=$value; HttpOnly", cookie.toString());
    DateTime date = new DateTime.utc(2014, DateTime.january, 5, 23, 59, 59, 0);
    cookie.expires = date;
    checkCookie(
        cookie,
        "$name=$value"
        "; Expires=Sun, 05 Jan 2014 23:59:59 GMT"
        "; HttpOnly");
    cookie.maxAge = 567;
    checkCookie(
        cookie,
        "$name=$value"
        "; Expires=Sun, 05 Jan 2014 23:59:59 GMT"
        "; Max-Age=567"
        "; HttpOnly");
    cookie.domain = "example.com";
    checkCookie(
        cookie,
        "$name=$value"
        "; Expires=Sun, 05 Jan 2014 23:59:59 GMT"
        "; Max-Age=567"
        "; Domain=example.com"
        "; HttpOnly");
    cookie.path = "/xxx";
    checkCookie(
        cookie,
        "$name=$value"
        "; Expires=Sun, 05 Jan 2014 23:59:59 GMT"
        "; Max-Age=567"
        "; Domain=example.com"
        "; Path=/xxx"
        "; HttpOnly");
    cookie.secure = true;
    checkCookie(
        cookie,
        "$name=$value"
        "; Expires=Sun, 05 Jan 2014 23:59:59 GMT"
        "; Max-Age=567"
        "; Domain=example.com"
        "; Path=/xxx"
        "; Secure"
        "; HttpOnly");
    cookie.httpOnly = false;
    checkCookie(
        cookie,
        "$name=$value"
        "; Expires=Sun, 05 Jan 2014 23:59:59 GMT"
        "; Max-Age=567"
        "; Domain=example.com"
        "; Path=/xxx"
        "; Secure");
    cookie.expires = null;
    checkCookie(
        cookie,
        "$name=$value"
        "; Max-Age=567"
        "; Domain=example.com"
        "; Path=/xxx"
        "; Secure");
    cookie.maxAge = null;
    checkCookie(
        cookie,
        "$name=$value"
        "; Domain=example.com"
        "; Path=/xxx"
        "; Secure");
    cookie.domain = null;
    checkCookie(
        cookie,
        "$name=$value"
        "; Path=/xxx"
        "; Secure");
    cookie.path = null;
    checkCookie(
        cookie,
        "$name=$value"
        "; Secure");
    cookie.secure = false;
    checkCookie(cookie, "$name=$value");
  }

  test("name", "value");
  test("abc", "def");
  test("ABC", "DEF");
  test("Abc", "Def");
  test("SID", "sJdkjKSJD12343kjKj78");
}

void testInvalidCookie() {
  Expect.throws(() => new _Cookie.fromSetCookieValue(""));
  Expect.throws(() => new _Cookie.fromSetCookieValue("="));
  Expect.throws(() => new _Cookie.fromSetCookieValue("=xxx"));
  Expect.throws(() => new _Cookie.fromSetCookieValue("xxx"));
  Expect.throws(
      () => new _Cookie.fromSetCookieValue("xxx=yyy; expires=12 jan 2013"));
  Expect.throws(() => new _Cookie.fromSetCookieValue("x x = y y"));
  Expect.throws(() => new _Cookie("[4", "y"));
  Expect.throws(() => new _Cookie("4", "y\""));

  _HttpHeaders headers = new _HttpHeaders("1.1");
  headers.set(
      'Cookie', 'DARTSESSID=d3d6fdd78d51aaaf2924c32e991f4349; undefined');
  Expect.equals('DARTSESSID', headers._parseCookies().single.name);
  Expect.equals(
      'd3d6fdd78d51aaaf2924c32e991f4349', headers._parseCookies().single.value);
}

void testHeaderLists() {
  HttpHeaders.generalHeaders.forEach((x) => null);
  HttpHeaders.entityHeaders.forEach((x) => null);
  HttpHeaders.responseHeaders.forEach((x) => null);
  HttpHeaders.requestHeaders.forEach((x) => null);
}

void testInvalidFieldName() {
  void test(String field) {
    _HttpHeaders headers = new _HttpHeaders("1.1");
    Expect.throwsFormatException(() => headers.add(field, "value"));
    Expect.throwsFormatException(() => headers.set(field, "value"));
    Expect.throwsFormatException(() => headers.remove(field, "value"));
    Expect.throwsFormatException(() => headers.removeAll(field));
  }

  test('\r');
  test('\n');
  test(',');
  test('test\x00');
}

void testInvalidFieldValue() {
  void test(value, {bool remove: true}) {
    _HttpHeaders headers = new _HttpHeaders("1.1");
    Expect.throwsFormatException(() => headers.add("field", value));
    Expect.throwsFormatException(() => headers.set("field", value));
    if (remove) {
      Expect.throwsFormatException(() => headers.remove("field", value));
    }
  }

  test('\r');
  test('\n');
  test('test\x00');
  // Test we handle other types correctly.
  test(new StringBuffer('\x00'), remove: false);
}

void testClear() {
  _HttpHeaders headers = new _HttpHeaders("1.1");
  headers.add("a", "b");
  headers.contentLength = 7;
  headers.chunkedTransferEncoding = true;
  headers.clear();
  Expect.isNull(headers["a"]);
  Expect.equals(headers.contentLength, -1);
  Expect.isFalse(headers.chunkedTransferEncoding);
}

void testFolding() {
  _HttpHeaders headers = new _HttpHeaders("1.1");
  headers.add("a", "b");
  headers.add("a", "c");
  headers.add("a", "d");
  // no folding by default
  Expect.isTrue(headers.toString().contains('b, c, d'));
  // Header name should be case insensitive
  headers.noFolding('A');
  var str = headers.toString();
  Expect.isTrue(str.contains(': b'));
  Expect.isTrue(str.contains(': c'));
  Expect.isTrue(str.contains(': d'));
}

void testLowercaseAdd() {
  _HttpHeaders headers = new _HttpHeaders("1.1");
  headers.add('A', 'a');
  Expect.equals(headers['a']![0], headers['A']![0]);
  Expect.equals(headers['A']![0], 'a');
  headers.add('Foo', 'Foo', preserveHeaderCase: true);
  Expect.equals(headers['Foo']![0], 'Foo');
  // Header field is Foo.
  Expect.isTrue(headers.toString().contains('Foo:'));

  headers.add('FOo', 'FOo', preserveHeaderCase: true);
  // Header field changes to FOo.
  Expect.isTrue(headers.toString().contains('FOo:'));

  headers.add('FOO', 'FOO', preserveHeaderCase: false);
  // Header field
  Expect.isTrue(!headers.toString().contains('Foo:'));
  Expect.isTrue(!headers.toString().contains('FOo:'));
  Expect.isTrue(headers.toString().contains('FOO'));
}

void testLowercaseSet() {
  _HttpHeaders headers = new _HttpHeaders("1.1");
  headers.add('test', 'lower cases');
  // 'Test' should override 'test' entity
  headers.set('TEST', 'upper cases', preserveHeaderCase: true);
  Expect.isTrue(headers.toString().contains('TEST: upper cases'));
  Expect.equals(1, headers['test']!.length);
  Expect.equals(headers['test']![0], 'upper cases');

  // Latest header will be stored.
  headers.set('Test', 'mixed cases', preserveHeaderCase: true);
  Expect.isTrue(headers.toString().contains('Test: mixed cases'));
  Expect.equals(1, headers['test']!.length);
  Expect.equals(headers['test']![0], 'mixed cases');
}

void testForEach() {
  _HttpHeaders headers = new _HttpHeaders("1.1");
  headers.add('header1', 'value 1');
  headers.add('header2', 'value 2');
  headers.add('HEADER1', 'value 3', preserveHeaderCase: true);
  headers.add('HEADER3', 'value 4', preserveHeaderCase: true);

  BytesBuilder builder = BytesBuilder();
  headers._build(builder);

  Expect.isTrue(utf8.decode(builder.toBytes()).contains('HEADER1'));

  bool myHeader1 = false;
  bool myHeader2 = false;
  bool myHeader3 = false;
  int totalValues = 0;
  headers.forEach((String name, List<String> values) {
    totalValues += values.length;
    if (name == "HEADER1") {
      myHeader1 = true;
      Expect.isTrue(values.indexOf("value 1") != -1);
      Expect.isTrue(values.indexOf("value 3") != -1);
    }
    if (name == "header2") {
      myHeader2 = true;
      Expect.isTrue(values.indexOf("value 2") != -1);
    }
    if (name == "HEADER3") {
      myHeader3 = true;
      Expect.isTrue(values.indexOf("value 4") != -1);
    }
  });
  Expect.isTrue(myHeader1);
  Expect.isTrue(myHeader2);
  Expect.isTrue(myHeader3);
  Expect.equals(4, totalValues);
}

main() {
  testMultiValue();
  testDate();
  testExpires();
  testIfModifiedSince();
  testHost();
  testTransferEncoding();
  testEnumeration();
  testHeaderValue();
  testContentType();
  testKnownContentTypes();
  testContentTypeCache();
  testCookie();
  testInvalidCookie();
  testHeaderLists();
  testInvalidFieldName();
  testInvalidFieldValue();
  testClear();
  testFolding();
  testLowercaseAdd();
  testLowercaseSet();
  testForEach();
}
