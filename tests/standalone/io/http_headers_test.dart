// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#source("../../../runtime/bin/input_stream.dart");
#source("../../../runtime/bin/output_stream.dart");
#source("../../../runtime/bin/chunked_stream.dart");
#source("../../../runtime/bin/string_stream.dart");
#source("../../../runtime/bin/stream_util.dart");
#source("../../../runtime/bin/http.dart");
#source("../../../runtime/bin/http_impl.dart");
#source("../../../runtime/bin/http_parser.dart");
#source("../../../runtime/bin/http_utils.dart");

void testMultiValue() {
  _HttpHeaders headers = new _HttpHeaders();
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
  Date date1 = new Date(1999, Date.JUN, 11, 18, 46, 53, 0, isUtc: true);
  String httpDate1 = "Fri, 11 Jun 1999 18:46:53 GMT";
  Date date2 = new Date(2000, Date.AUG, 16, 12, 34, 56, 0, isUtc: true);
  String httpDate2 = "Wed, 16 Aug 2000 12:34:56 GMT";

  _HttpHeaders headers = new _HttpHeaders();
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
  Date date1 = new Date(1999, Date.JUN, 11, 18, 46, 53, 0, isUtc: true);
  String httpDate1 = "Fri, 11 Jun 1999 18:46:53 GMT";
  Date date2 = new Date(2000, Date.AUG, 16, 12, 34, 56, 0, isUtc: true);
  String httpDate2 = "Wed, 16 Aug 2000 12:34:56 GMT";

  _HttpHeaders headers = new _HttpHeaders();
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

void testHost() {
  String host = "www.google.com";
  _HttpHeaders headers = new _HttpHeaders();
  Expect.isNull(headers.host);
  Expect.isNull(headers.port);
  headers.host = host;
  Expect.equals(host, headers.value(HttpHeaders.HOST));
  headers.port = 1234;
  Expect.equals("$host:1234", headers.value(HttpHeaders.HOST));
  headers.port = HttpClient.DEFAULT_HTTP_PORT;
  Expect.equals(host, headers.value(HttpHeaders.HOST));

  headers = new _HttpHeaders();
  headers.add(HttpHeaders.HOST, host);
  Expect.equals(host, headers.host);
  Expect.equals(HttpClient.DEFAULT_HTTP_PORT, headers.port);
  headers.add(HttpHeaders.HOST, "$host:4567");
  Expect.equals(1, headers[HttpHeaders.HOST].length);
  Expect.equals(host, headers.host);
  Expect.equals(4567, headers.port);

  headers = new _HttpHeaders();
  headers.add(HttpHeaders.HOST, "$host:xxx");
  Expect.equals("$host:xxx", headers.value(HttpHeaders.HOST));
  Expect.equals(host, headers.host);
  Expect.isNull(headers.port);

  headers = new _HttpHeaders();
  headers.add(HttpHeaders.HOST, ":1234");
  Expect.equals(":1234", headers.value(HttpHeaders.HOST));
  Expect.isNull(headers.host);
  Expect.equals(1234, headers.port);
}

void testEnumeration() {
  _HttpHeaders headers = new _HttpHeaders();
  Expect.isNull(headers[HttpHeaders.PRAGMA]);
  headers.add("My-Header-1", "value 1");
  headers.add("My-Header-2", "value 2");
  headers.add("My-Header-1", "value 3");
  bool myHeader1 = false;
  bool myHeader2 = false;
  int totalValues = 0;
  headers.forEach(f(String name, List<String> values) {
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
  headerValue = new HeaderValue.fromString(
      "xxx; aaa=bbb; ccc=\"\\\";\\a\"; ddd=\"    \"");
  check(headerValue, "xxx", {"aaa": "bbb", "ccc": '\";a', "ddd": "    "});
  headerValue = new HeaderValue.fromString(
    "attachment; filename=genome.jpeg;"
    "modification-date=\"Wed, 12 February 1997 16:29:51 -0500\"");
  var parameters = {
      "filename": "genome.jpeg",
      "modification-date": "Wed, 12 February 1997 16:29:51 -0500"
  };
  check(headerValue, "attachment", parameters);
  headerValue = new HeaderValue.fromString(
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

  _ContentType contentType;
  contentType = new _ContentType();
  Expect.equals("", contentType.primaryType);
  Expect.equals("", contentType.subType);
  Expect.equals("/", contentType.value);
  contentType.value = "text/html";
  Expect.equals("text", contentType.primaryType);
  Expect.equals("html", contentType.subType);
  Expect.equals("text/html", contentType.value);

  contentType = new _ContentType.fromString("text/html");
  check(contentType, "text", "html");
  Expect.equals("text/html", contentType.toString());
  contentType.parameters["charset"] = "utf-8";
  check(contentType, "text", "html", {"charset": "utf-8"});
  Expect.equals("text/html; charset=utf-8", contentType.toString());
  contentType.parameters["xxx"] = "yyy";
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
  String s = contentType.toString();
  bool expectedToString = (s == "text/html; charset=utf-8; xxx=yyy" ||
                           s == "text/html; xxx=yyy; charset=utf-8");
  Expect.isTrue(expectedToString);

  contentType = new _ContentType.fromString("text/html");
  check(contentType, "text", "html");
  contentType = new _ContentType.fromString(" text/html  ");
  check(contentType, "text", "html");
  contentType = new _ContentType.fromString("text/html; charset=utf-8");
  check(contentType, "text", "html", {"charset": "utf-8"});
  contentType = new _ContentType.fromString(
      "  text/html  ;  charset  =  utf-8  ");
  check(contentType, "text", "html", {"charset": "utf-8"});
  contentType = new _ContentType.fromString(
      "text/html; charset=utf-8; xxx=yyy");
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
  contentType = new _ContentType.fromString(
      "  text/html  ;  charset  =  utf-8  ;  xxx=yyy  ");
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
  contentType = new _ContentType.fromString(
      'text/html; charset=utf-8; xxx="yyy"');
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
  contentType = new _ContentType.fromString(
      "  text/html  ;  charset  =  utf-8  ;  xxx=yyy  ");
  check(contentType, "text", "html", {"charset": "utf-8", "xxx": "yyy"});
}

void testContentTypeCache() {
  _HttpHeaders headers = new _HttpHeaders();
  headers.set(HttpHeaders.CONTENT_TYPE, "text/html");
  Expect.equals("text", headers.contentType.primaryType);
  Expect.equals("html", headers.contentType.subType);
  Expect.equals("text/html", headers.contentType.value);
  headers.set(HttpHeaders.CONTENT_TYPE, "text/plain; charset=utf-8");
  Expect.equals("text", headers.contentType.primaryType);
  Expect.equals("plain", headers.contentType.subType);
  Expect.equals("text/plain", headers.contentType.value);
  headers.removeAll(HttpHeaders.CONTENT_TYPE);
  Expect.equals("", headers.contentType.primaryType);
  Expect.equals("", headers.contentType.subType);
  Expect.equals("/", headers.contentType.value);
}

void testCookie() {
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
  cookie = new Cookie("name", "value");
  Expect.equals("name=value", cookie.toString());
  Date date = new Date(2014, Date.JAN, 5, 23, 59, 59, 0, isUtc: true);
  cookie.expires = date;
  checkCookie(cookie, "name=value"
                      "; Expires=Sun, 5 Jan 2014 23:59:59 GMT");
  cookie.maxAge = 567;
  checkCookie(cookie, "name=value"
                      "; Expires=Sun, 5 Jan 2014 23:59:59 GMT"
                      "; Max-Age=567");
  cookie.domain = "example.com";
  checkCookie(cookie, "name=value"
                      "; Expires=Sun, 5 Jan 2014 23:59:59 GMT"
                      "; Max-Age=567"
                      "; Domain=example.com");
  cookie.path = "/xxx";
  checkCookie(cookie, "name=value"
                      "; Expires=Sun, 5 Jan 2014 23:59:59 GMT"
                      "; Max-Age=567"
                      "; Domain=example.com"
                      "; Path=/xxx");
  cookie.secure = true;
  checkCookie(cookie, "name=value"
                      "; Expires=Sun, 5 Jan 2014 23:59:59 GMT"
                      "; Max-Age=567"
                      "; Domain=example.com"
                      "; Path=/xxx"
                      "; Secure");
  cookie.httpOnly = true;
  checkCookie(cookie, "name=value"
                      "; Expires=Sun, 5 Jan 2014 23:59:59 GMT"
                      "; Max-Age=567"
                      "; Domain=example.com"
                      "; Path=/xxx"
                      "; Secure"
                      "; HttpOnly");
  cookie.expires = null;
  checkCookie(cookie, "name=value"
                      "; Max-Age=567"
                      "; Domain=example.com"
                      "; Path=/xxx"
                      "; Secure"
                      "; HttpOnly");
  cookie.maxAge = null;
  checkCookie(cookie, "name=value"
                      "; Domain=example.com"
                      "; Path=/xxx"
                      "; Secure"
                      "; HttpOnly");
  cookie.domain = null;
  checkCookie(cookie, "name=value"
                      "; Path=/xxx"
                      "; Secure"
                      "; HttpOnly");
  cookie.path = null;
  checkCookie(cookie, "name=value"
                      "; Secure"
                      "; HttpOnly");
  cookie.secure = false;
  checkCookie(cookie, "name=value"
                      "; HttpOnly");
  cookie.httpOnly = false;
  checkCookie(cookie, "name=value");
}

void testInvalidCookie() {
  Expect.throws(() => new _Cookie.fromSetCookieValue(""));
  Expect.throws(() => new _Cookie.fromSetCookieValue("="));
  Expect.throws(() => new _Cookie.fromSetCookieValue("=xxx"));
  Expect.throws(() => new _Cookie.fromSetCookieValue("xxx"));
  Expect.throws(() => new _Cookie.fromSetCookieValue("xxx=yyy; expires=12 jan 2013"));
}

main() {
  testMultiValue();
  testExpires();
  testHost();
  testEnumeration();
  testHeaderValue();
  testContentType();
  testContentTypeCache();
  testCookie();
  testInvalidCookie();
}
