// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.io;

import "package:expect/expect.dart";
import "dart:async";
import "dart:collection";
import "dart:convert";
import "dart:math";
import "dart:typed_data";
import "dart:isolate";

part "../../../sdk/lib/io/bytes_builder.dart";
part "../../../sdk/lib/io/common.dart";
part "../../../sdk/lib/io/crypto.dart";
part "../../../sdk/lib/io/data_transformer.dart";
part "../../../sdk/lib/io/directory.dart";
part "../../../sdk/lib/io/directory_impl.dart";
part "../../../sdk/lib/io/file.dart";
part "../../../sdk/lib/io/file_impl.dart";
part "../../../sdk/lib/io/file_system_entity.dart";
part "../../../sdk/lib/io/link.dart";
part "../../../sdk/lib/io/http.dart";
part "../../../sdk/lib/io/http_impl.dart";
part "../../../sdk/lib/io/http_date.dart";
part "../../../sdk/lib/io/http_parser.dart";
part "../../../sdk/lib/io/http_headers.dart";
part "../../../sdk/lib/io/http_session.dart";
part "../../../sdk/lib/io/io_service.dart";
part "../../../sdk/lib/io/io_sink.dart";
part "../../../sdk/lib/io/platform.dart";
part "../../../sdk/lib/io/platform_impl.dart";
part "../../../sdk/lib/io/service_object.dart";
part "../../../sdk/lib/io/secure_socket.dart";
part "../../../sdk/lib/io/secure_server_socket.dart";
part "../../../sdk/lib/io/socket.dart";

void testMultiValue() {
  _HttpHeaders headers = new _HttpHeaders("1.1");
  Expect.isNull(headers[HttpHeaders.PRAGMA]);
  headers.add(HttpHeaders.PRAGMA, "pragma1");
  Expect.equals(1, headers[HttpHeaders.PRAGMA].length);
  Expect.equals(1, headers["pragma"].length);
  Expect.equals(1, headers["Pragma"].length);
  Expect.equals(1, headers["PRAGMA"].length);
  Expect.equals("pragma1", headers.value(HttpHeaders.PRAGMA));

  headers.add(HttpHeaders.PRAGMA, "pragma2");
  Expect.equals(2, headers[HttpHeaders.PRAGMA].length);
  Expect.throws(() => headers.value(HttpHeaders.PRAGMA),
                (e) => e is HttpException);

  headers.add(HttpHeaders.PRAGMA, ["pragma3", "pragma4"]);
  Expect.listEquals(["pragma1", "pragma2", "pragma3", "pragma4"],
                    headers[HttpHeaders.PRAGMA]);

  headers.remove(HttpHeaders.PRAGMA, "pragma3");
  Expect.equals(3, headers[HttpHeaders.PRAGMA].length);
  Expect.listEquals(["pragma1", "pragma2", "pragma4"],
                    headers[HttpHeaders.PRAGMA]);

  headers.remove(HttpHeaders.PRAGMA, "pragma3");
  Expect.equals(3, headers[HttpHeaders.PRAGMA].length);

  headers.set(HttpHeaders.PRAGMA, "pragma5");
  Expect.equals(1, headers[HttpHeaders.PRAGMA].length);

  headers.set(HttpHeaders.PRAGMA, ["pragma6", "pragma7"]);
  Expect.equals(2, headers[HttpHeaders.PRAGMA].length);

  headers.removeAll(HttpHeaders.PRAGMA);
  Expect.isNull(headers[HttpHeaders.PRAGMA]);
}

void testDate() {
  DateTime date1 = new DateTime.utc(1999, DateTime.JUNE, 11, 18, 46, 53, 0);
  String httpDate1 = "Fri, 11 Jun 1999 18:46:53 GMT";
  DateTime date2 = new DateTime.utc(2000, DateTime.AUGUST, 16, 12, 34, 56, 0);
  String httpDate2 = "Wed, 16 Aug 2000 12:34:56 GMT";

  _HttpHeaders headers = new _HttpHeaders("1.1");
  Expect.isNull(headers.date);
  headers.date = date1;
  Expect.equals(date1, headers.date);
  Expect.equals(httpDate1, headers.value(HttpHeaders.DATE));
  Expect.equals(1, headers[HttpHeaders.DATE].length);
  headers.add(HttpHeaders.DATE, httpDate2);
  Expect.equals(1, headers[HttpHeaders.DATE].length);
  Expect.equals(date2, headers.date);
  Expect.equals(httpDate2, headers.value(HttpHeaders.DATE));
  headers.set(HttpHeaders.DATE, httpDate1);
  Expect.equals(1, headers[HttpHeaders.DATE].length);
  Expect.equals(date1, headers.date);
  Expect.equals(httpDate1, headers.value(HttpHeaders.DATE));

  headers.set(HttpHeaders.DATE, "xxx");
  Expect.equals("xxx", headers.value(HttpHeaders.DATE));
  Expect.equals(null, headers.date);
}

void testExpires() {
  DateTime date1 = new DateTime.utc(1999, DateTime.JUNE, 11, 18, 46, 53, 0);
  String httpDate1 = "Fri, 11 Jun 1999 18:46:53 GMT";
  DateTime date2 = new DateTime.utc(2000, DateTime.AUGUST, 16, 12, 34, 56, 0);
  String httpDate2 = "Wed, 16 Aug 2000 12:34:56 GMT";

  _HttpHeaders headers = new _HttpHeaders("1.1");
  Expect.isNull(headers.expires);
  headers.expires = date1;
  Expect.equals(date1, headers.expires);
  Expect.equals(httpDate1, headers.value(HttpHeaders.EXPIRES));
  Expect.equals(1, headers[HttpHeaders.EXPIRES].length);
  headers.add(HttpHeaders.EXPIRES, httpDate2);
  Expect.equals(1, headers[HttpHeaders.EXPIRES].length);
  Expect.equals(date2, headers.expires);
  Expect.equals(httpDate2, headers.value(HttpHeaders.EXPIRES));
  headers.set(HttpHeaders.EXPIRES, httpDate1);
  Expect.equals(1, headers[HttpHeaders.EXPIRES].length);
  Expect.equals(date1, headers.expires);
  Expect.equals(httpDate1, headers.value(HttpHeaders.EXPIRES));

  headers.set(HttpHeaders.EXPIRES, "xxx");
  Expect.equals("xxx", headers.value(HttpHeaders.EXPIRES));
  Expect.equals(null, headers.expires);
}

void testIfModifiedSince() {
  DateTime date1 = new DateTime.utc(1999, DateTime.JUNE, 11, 18, 46, 53, 0);
  String httpDate1 = "Fri, 11 Jun 1999 18:46:53 GMT";
  DateTime date2 = new DateTime.utc(2000, DateTime.AUGUST, 16, 12, 34, 56, 0);
  String httpDate2 = "Wed, 16 Aug 2000 12:34:56 GMT";

  _HttpHeaders headers = new _HttpHeaders("1.1");
  Expect.isNull(headers.ifModifiedSince);
  headers.ifModifiedSince = date1;
  Expect.equals(date1, headers.ifModifiedSince);
  Expect.equals(httpDate1, headers.value(HttpHeaders.IF_MODIFIED_SINCE));
  Expect.equals(1, headers[HttpHeaders.IF_MODIFIED_SINCE].length);
  headers.add(HttpHeaders.IF_MODIFIED_SINCE, httpDate2);
  Expect.equals(1, headers[HttpHeaders.IF_MODIFIED_SINCE].length);
  Expect.equals(date2, headers.ifModifiedSince);
  Expect.equals(httpDate2, headers.value(HttpHeaders.IF_MODIFIED_SINCE));
  headers.set(HttpHeaders.IF_MODIFIED_SINCE, httpDate1);
  Expect.equals(1, headers[HttpHeaders.IF_MODIFIED_SINCE].length);
  Expect.equals(date1, headers.ifModifiedSince);
  Expect.equals(httpDate1, headers.value(HttpHeaders.IF_MODIFIED_SINCE));

  headers.set(HttpHeaders.IF_MODIFIED_SINCE, "xxx");
  Expect.equals("xxx", headers.value(HttpHeaders.IF_MODIFIED_SINCE));
  Expect.equals(null, headers.ifModifiedSince);
}

void testHost() {
  String host = "www.google.com";
  _HttpHeaders headers = new _HttpHeaders("1.1");
  Expect.isNull(headers.host);
  Expect.isNull(headers.port);
  headers.host = host;
  Expect.equals(host, headers.value(HttpHeaders.HOST));
  headers.port = 1234;
  Expect.equals("$host:1234", headers.value(HttpHeaders.HOST));
  headers.port = HttpClient.DEFAULT_HTTP_PORT;
  Expect.equals(host, headers.value(HttpHeaders.HOST));

  headers = new _HttpHeaders("1.1");
  headers.add(HttpHeaders.HOST, host);
  Expect.equals(host, headers.host);
  Expect.equals(HttpClient.DEFAULT_HTTP_PORT, headers.port);
  headers.add(HttpHeaders.HOST, "$host:4567");
  Expect.equals(1, headers[HttpHeaders.HOST].length);
  Expect.equals(host, headers.host);
  Expect.equals(4567, headers.port);

  headers = new _HttpHeaders("1.1");
  headers.add(HttpHeaders.HOST, "$host:xxx");
  Expect.equals("$host:xxx", headers.value(HttpHeaders.HOST));
  Expect.equals(host, headers.host);
  Expect.isNull(headers.port);

  headers = new _HttpHeaders("1.1");
  headers.add(HttpHeaders.HOST, ":1234");
  Expect.equals(":1234", headers.value(HttpHeaders.HOST));
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
  Expect.isNull(headers[HttpHeaders.PRAGMA]);
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
  void check(HeaderValue headerValue, String value, [Map parameters]) {
    Expect.equals(value, headerValue.value);
    if (parameters != null) {
      Expect.equals(parameters.length, headerValue.parameters.length);
      parameters.forEach((String name, String value) {
        Expect.equals(value, headerValue.parameters[name]);
      });
    } else {
      Expect.equals(0, headerValue.parameters.length);
    }
  }

  HeaderValue headerValue;
  headerValue = HeaderValue.parse(
      "xxx; aaa=bbb; ccc=\"\\\";\\a\"; ddd=\"    \"");
  check(headerValue, "xxx", {"aaa": "bbb", "ccc": '\";a', "ddd": "    "});
  headerValue = new HeaderValue("xxx",
                                {"aaa": "bbb", "ccc": '\";a', "ddd": "    "});
  check(headerValue, "xxx", {"aaa": "bbb", "ccc": '\";a', "ddd": "    "});

  headerValue = HeaderValue.parse(
    "attachment; filename=genome.jpeg;"
    "modification-date=\"Wed, 12 February 1997 16:29:51 -0500\"");
  var parameters = {
      "filename": "genome.jpeg",
      "modification-date": "Wed, 12 February 1997 16:29:51 -0500"
  };
  check(headerValue, "attachment", parameters);
  headerValue = new HeaderValue("attachment", parameters);
  check(headerValue, "attachment", parameters);
  headerValue = HeaderValue.parse(
    "  attachment  ;filename=genome.jpeg  ;"
    "modification-date = \"Wed, 12 February 1997 16:29:51 -0500\""  );
  check(headerValue, "attachment", parameters);
}

void testContentType() {
  void check(ContentType contentType,
             String primaryType,
             String subType,
             [Map parameters]) {
    Expect.equals(primaryType, contentType.primaryType);
    Expect.equals(subType, contentType.subType);
    Expect.equals("$primaryType/$subType", contentType.value);
    if (parameters != null) {
      Expect.equals(parameters.length, contentType.parameters.length);
      parameters.forEach((String name, String value) {
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
  Expect.throws(() => contentType.parameters["xxx"] = "yyy",
                (e) => e is UnsupportedError);

  contentType = ContentType.parse("text/html");
  check(contentType, "text", "html");
  Expect.equals("text/html", contentType.toString());
  contentType = new ContentType("text", "html", charset: "utf-8");
  check(contentType, "text", "html", {"charset": "utf-8"});
  Expect.equals("text/html; charset=utf-8", contentType.toString());
  Expect.throws(() => contentType.parameters["xxx"] = "yyy",
                (e) => e is UnsupportedError);

  contentType = new ContentType("text",
                                "html",
                                parameters: {"CHARSET": "UTF-8", "xxx": "yyy"});
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
  String s = contentType.toString();
  bool expectedToString = (s == "text/html; charset=utf-8; xxx=yyy" ||
                           s == "text/html; xxx=yyy; charset=utf-8");
  Expect.isTrue(expectedToString);
  Expect.throws(() => contentType.parameters["xxx"] = "yyy",
                (e) => e is UnsupportedError);

  contentType = new ContentType("text",
                                "html",
                                charset: "ISO-8859-1",
                                parameters: {"CHARSET": "UTF-8", "xxx": "yyy"});
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
  contentType = ContentType.parse(
      "  text/html  ;  charset  =  utf-8  ");
  check(contentType, "text", "html", {"charset": "utf-8"});
  contentType = ContentType.parse(
      "text/html; charset=utf-8; xxx=yyy");
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
  contentType = ContentType.parse(
      "  text/html  ;  charset  =  utf-8  ;  xxx=yyy  ");
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
  contentType = ContentType.parse(
      'text/html; charset=utf-8; xxx="yyy"');
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
  contentType = ContentType.parse(
      "  text/html  ;  charset  =  utf-8  ;  xxx=yyy  ");
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});

  // Test builtin content types.
  check(ContentType.TEXT, "text", "plain", {"charset": "utf-8"});
  check(ContentType.HTML, "text", "html", {"charset": "utf-8"});
  check(ContentType.JSON, "application", "json", {"charset": "utf-8"});
  check(ContentType.BINARY, "application", "octet-stream");
}

void testContentTypeCache() {
  _HttpHeaders headers = new _HttpHeaders("1.1");
  headers.set(HttpHeaders.CONTENT_TYPE, "text/html");
  Expect.equals("text", headers.contentType.primaryType);
  Expect.equals("html", headers.contentType.subType);
  Expect.equals("text/html", headers.contentType.value);
  headers.set(HttpHeaders.CONTENT_TYPE, "text/plain; charset=utf-8");
  Expect.equals("text", headers.contentType.primaryType);
  Expect.equals("plain", headers.contentType.subType);
  Expect.equals("text/plain", headers.contentType.value);
  headers.removeAll(HttpHeaders.CONTENT_TYPE);
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
    Expect.equals("$name=$value", cookie.toString());
    DateTime date = new DateTime.utc(2014, DateTime.JANUARY, 5, 23, 59, 59, 0);
    cookie.expires = date;
    checkCookie(cookie, "$name=$value"
                "; Expires=Sun, 05 Jan 2014 23:59:59 GMT");
    cookie.maxAge = 567;
    checkCookie(cookie, "$name=$value"
                "; Expires=Sun, 05 Jan 2014 23:59:59 GMT"
                "; Max-Age=567");
    cookie.domain = "example.com";
    checkCookie(cookie, "$name=$value"
                "; Expires=Sun, 05 Jan 2014 23:59:59 GMT"
                "; Max-Age=567"
                "; Domain=example.com");
    cookie.path = "/xxx";
    checkCookie(cookie, "$name=$value"
                "; Expires=Sun, 05 Jan 2014 23:59:59 GMT"
                "; Max-Age=567"
                "; Domain=example.com"
                "; Path=/xxx");
    cookie.secure = true;
    checkCookie(cookie, "$name=$value"
                "; Expires=Sun, 05 Jan 2014 23:59:59 GMT"
                "; Max-Age=567"
                "; Domain=example.com"
                "; Path=/xxx"
                "; Secure");
    cookie.httpOnly = true;
    checkCookie(cookie, "$name=$value"
                "; Expires=Sun, 05 Jan 2014 23:59:59 GMT"
                "; Max-Age=567"
                "; Domain=example.com"
                "; Path=/xxx"
                "; Secure"
                "; HttpOnly");
    cookie.expires = null;
    checkCookie(cookie, "$name=$value"
                "; Max-Age=567"
                "; Domain=example.com"
                "; Path=/xxx"
                "; Secure"
                "; HttpOnly");
    cookie.maxAge = null;
    checkCookie(cookie, "$name=$value"
                "; Domain=example.com"
                "; Path=/xxx"
                "; Secure"
                "; HttpOnly");
    cookie.domain = null;
    checkCookie(cookie, "$name=$value"
                "; Path=/xxx"
                "; Secure"
                "; HttpOnly");
    cookie.path = null;
    checkCookie(cookie, "$name=$value"
                "; Secure"
                "; HttpOnly");
    cookie.secure = false;
    checkCookie(cookie, "$name=$value"
                "; HttpOnly");
    cookie.httpOnly = false;
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
  Expect.throws(() => new _Cookie.fromSetCookieValue(
      "xxx=yyy; expires=12 jan 2013"));
  Expect.throws(() => new _Cookie.fromSetCookieValue("x x = y y"));
  Expect.throws(() => new _Cookie("[4", "y"));
  Expect.throws(() => new _Cookie("4", "y\""));

  _HttpHeaders headers = new _HttpHeaders("1.1");
  headers.set('Cookie',
              'DARTSESSID=d3d6fdd78d51aaaf2924c32e991f4349; undefined');
  Expect.equals('DARTSESSID', headers._parseCookies().single.name);
  Expect.equals('d3d6fdd78d51aaaf2924c32e991f4349',
                headers._parseCookies().single.value);
}

void testHeaderLists() {
  HttpHeaders.GENERAL_HEADERS.forEach((x) => null);
  HttpHeaders.ENTITY_HEADERS.forEach((x) => null);
  HttpHeaders.RESPONSE_HEADERS.forEach((x) => null);
  HttpHeaders.REQUEST_HEADERS.forEach((x) => null);
}

void testInvalidFieldName() {
  void test(String field) {
    _HttpHeaders headers = new _HttpHeaders("1.1");
    Expect.throws(() => headers.add(field, "value"),
                  (e) => e is FormatException);
    Expect.throws(() => headers.set(field, "value"),
                  (e) => e is FormatException);
    Expect.throws(() => headers.remove(field, "value"),
                  (e) => e is FormatException);
    Expect.throws(() => headers.removeAll(field),
                  (e) => e is FormatException);
  }
  test('\r');
  test('\n');
  test(',');
  test('test\x00');
}

void testInvalidFieldValue() {
  void test(value, {bool remove: true}) {
    _HttpHeaders headers = new _HttpHeaders("1.1");
    Expect.throws(() => headers.add("field", value),
                  (e) => e is FormatException);
    Expect.throws(() => headers.set("field", value),
                  (e) => e is FormatException);
    if (remove) {
      Expect.throws(() => headers.remove("field", value),
                    (e) => e is FormatException);
    }
  }
  test('\r');
  test('\n');
  test('test\x00');
  // Test we handle other types correctly.
  test(new StringBuffer('\x00'), remove: false);
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
  testContentTypeCache();
  testCookie();
  testInvalidCookie();
  testHeaderLists();
  testInvalidFieldName();
  testInvalidFieldValue();
}
