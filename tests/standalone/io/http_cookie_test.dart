// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";

void testCookies() {
  var cookies = [
    {'abc': 'def'},
    {'ABC': 'DEF'},
    {'Abc': 'Def'},
    {'Abc': 'Def', 'SID': 'sffFSDF4FsdfF56765'},
  ];

  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      // Collect the cookies in a map.
      var cookiesMap = {};
      request.cookies.forEach((c) => cookiesMap[c.name] = c.value);
      int index = int.parse(request.uri.path.substring(1));
      Expect.mapEquals(cookies[index], cookiesMap);
      // Return the same cookies to the client.
      cookiesMap.forEach((k, v) {
        request.response.cookies.add(new Cookie(k, v));
      });
      request.response.close();
    });

    int count = 0;
    HttpClient client = new HttpClient();
    for (int i = 0; i < cookies.length; i++) {
      client
          .get("127.0.0.1", server.port, "/$i")
          .then((request) {
            // Send the cookies to the server.
            cookies[i].forEach((k, v) {
              request.cookies.add(new Cookie(k, v));
            });
            return request.close();
          })
          .then((response) {
            // Expect the same cookies back.
            var cookiesMap = {};
            response.cookies.forEach((c) => cookiesMap[c.name] = c.value);
            Expect.mapEquals(cookies[i], cookiesMap);
            response.cookies.forEach((c) => Expect.isTrue(c.httpOnly));
            response.listen(
              (d) {},
              onDone: () {
                if (++count == cookies.length) {
                  client.close();
                  server.close();
                }
              },
            );
          })
          .catchError((e, trace) {
            String msg = "Unexpected error $e";
            if (trace != null) msg += "\nStackTrace: $trace";
            Expect.fail(msg);
          });
    }
  });
}

void testValidateCookieWithDoubleQuotes() {
  Expect.equals(Cookie('key', 'value').toString(), 'key=value; HttpOnly');
  Expect.equals(Cookie('key', '').toString(), 'key=; HttpOnly');
  Expect.equals(Cookie('key', '""').toString(), 'key=""; HttpOnly');
  Expect.equals(Cookie('key', '"value"').toString(), 'key="value"; HttpOnly');
  Expect.equals(
    Cookie.fromSetCookieValue('key=value; HttpOnly').toString(),
    'key=value; HttpOnly',
  );
  Expect.equals(
    Cookie.fromSetCookieValue('key=; HttpOnly').toString(),
    'key=; HttpOnly',
  );
  Expect.equals(
    Cookie.fromSetCookieValue('key=""; HttpOnly').toString(),
    'key=""; HttpOnly',
  );
  Expect.equals(
    Cookie.fromSetCookieValue('key="value"; HttpOnly').toString(),
    'key="value"; HttpOnly',
  );
  Expect.throwsFormatException(() => Cookie('key', '"'));
  Expect.throwsFormatException(() => Cookie('key', '"""'));
  Expect.throwsFormatException(() => Cookie('key', '"x""'));
  Expect.throwsFormatException(() => Cookie('key', '"x"y"'));
  Expect.throwsFormatException(
    () => Cookie.fromSetCookieValue('key="; HttpOnly'),
  );
  Expect.throwsFormatException(
    () => Cookie.fromSetCookieValue('key="""; HttpOnly'),
  );
  Expect.throwsFormatException(
    () => Cookie.fromSetCookieValue('key="x""; HttpOnly'),
  );
}

void testValidatePath() {
  Cookie cookie = Cookie.fromSetCookieValue(" cname = cval; path= / ");
  Expect.equals('/', cookie.path);
  cookie.path = null;
  Expect.throws<FormatException>(() {
    cookie.path = "something; ";
  }, (e) => e.toString().contains('Invalid character'));

  StringBuffer buffer = StringBuffer();
  buffer.writeCharCode(0x1f);
  Expect.throws<FormatException>(() {
    cookie.path = buffer.toString();
  }, (e) => e.toString().contains('Invalid character'));

  buffer.clear();
  buffer.writeCharCode(0x7f);
  Expect.throws<FormatException>(() {
    cookie.path = buffer.toString();
  }, (e) => e.toString().contains('Invalid character'));

  buffer.clear();
  buffer.writeCharCode(0x00);
  Expect.throws<FormatException>(() {
    cookie.path = buffer.toString();
  }, (e) => e.toString().contains('Invalid character'));
}

void testCookieSameSite() {
  Cookie cookie1 = Cookie.fromSetCookieValue(
    "name=cookie_name; Expires=Sat, 01 Apr 2023 00:00:00 GMT; Secure; "
    "HttpOnly; Path=/; SameSite=None",
  );
  Expect.equals(cookie1.sameSite, SameSite.none);
  Cookie cookie2 = Cookie.fromSetCookieValue(
    "name=cookie_name; Expires=Sat, 01 Apr 2023 00:00:00 GMT; HttpOnly; "
    "Path=/; SameSite=Lax",
  );
  Expect.equals(cookie2.sameSite, SameSite.lax);
  Cookie cookie3 = Cookie.fromSetCookieValue(
    "name=cookie_name; Expires=Sat, 01 Apr 2023 00:00:00 GMT; HttpOnly; "
    "Path=/; SameSite=LAX",
  );
  Expect.equals(cookie3.sameSite, SameSite.lax);
  Cookie cookie4 = Cookie.fromSetCookieValue(
    "name=cookie_name; Expires=Sat, 01 Apr 2023 00:00:00 GMT; HttpOnly; "
    "Path=/; SameSite= Lax",
  );
  Expect.equals(cookie4.sameSite, SameSite.lax);
  Cookie cookie5 = Cookie.fromSetCookieValue(
    "name=cookie_name; Expires=Sat, 01 Apr 2023 00:00:00 GMT; HttpOnly; "
    "Path=/; sAmEsItE= nOnE",
  );
  Expect.equals(cookie5.sameSite, SameSite.none);
  Expect.throws<HttpException>(
    () => Cookie.fromSetCookieValue(
      "name=cookie_name; Expires=Sat, 01 Apr 2023 00:00:00 GMT; HttpOnly; "
      "Path=/; SameSite=Relax",
    ),
    (e) => e.message == "SameSite value should be one of Lax, Strict or None.",
  );
  Expect.throws<HttpException>(
    () => Cookie.fromSetCookieValue(
      "name=cookie_name; Expires=Sat, 01 Apr 2023 00:00:00 GMT; HttpOnly; "
      "Path=/; SameSite=",
    ),
    (e) => e.message == "SameSite value should be one of Lax, Strict or None.",
  );
  Expect.throws<HttpException>(
    () => Cookie.fromSetCookieValue(
      "name=cookie_name; Expires=Sat, 01 Apr 2023 00:00:00 GMT; HttpOnly; "
      "Path=/; SameSite=无",
    ),
    (e) => e.message == "SameSite value should be one of Lax, Strict or None.",
  );
}

void main() {
  testCookies();
  testValidateCookieWithDoubleQuotes();
  testValidatePath();
  testCookieSameSite();
}
