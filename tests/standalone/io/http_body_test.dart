// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:utf';

import 'package:expect/expect.dart';

void testHttpClientResponseBody() {
  void test(String mimeType,
            List<int> content,
            dynamic expectedBody,
            String type,
            [bool shouldFail = false]) {
    HttpServer.bind("127.0.0.1", 0).then((server) {
      server.listen((request) {
        request.listen(
            (_) {},
            onDone: () {
              request.response.headers.contentType =
                  ContentType.parse(mimeType);
              request.response.add(content);
              request.response.close();
            });
      });

      var client = new HttpClient();
      client.get("127.0.0.1", server.port, "/")
          .then((request) => request.close())
          .then(HttpBodyHandler.processResponse)
          .then((body) {
            if (shouldFail) Expect.fail("Error expected");
            Expect.equals(type, body.type);
            Expect.isNotNull(body.response);
            switch (type) {
              case "text":
                Expect.equals(expectedBody, body.body);
                break;

              case "json":
                Expect.mapEquals(expectedBody, body.body);
                break;

              default:
                Expect.fail("bad body type");
            }
          }, onError: (error) {
            if (!shouldFail) throw error;
          })
          .whenComplete(() {
            client.close();
            server.close();
          });
    });
  }
  test("text/plain", "body".codeUnits, "body", "text");
  test("text/plain; charset=utf-8",
       "body".codeUnits,
       "body",
       "text");
  test("text/plain; charset=iso-8859-1",
       "body".codeUnits,
       "body",
       "text");
  test("text/plain; charset=us-ascii",
       "body".codeUnits,
       "body",
       "text");
  test("text/plain; charset=utf-8", [42], "*", "text");
  test("text/plain; charset=us-ascii", [142], "?", "text");
  test("text/plain; charset=utf-8",
       [142],
       new String.fromCharCodes([UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]),
       "text");

  test("application/json",
       '{"val": 5}'.codeUnits,
       { "val" : 5 },
       "json");
  test("application/json",
       '{ bad json }'.codeUnits,
       null,
       "json",
       true);
}

void testHttpServerRequestBody() {
  void test(String mimeType,
            List<int> content,
            dynamic expectedBody,
            String type,
            {bool shouldFail: false,
             Encoding defaultEncoding: Encoding.UTF_8}) {
    HttpServer.bind("127.0.0.1", 0).then((server) {
      server.transform(new HttpBodyHandler(defaultEncoding: defaultEncoding))
          .listen((body) {
            if (shouldFail) Expect.fail("Error expected");
            Expect.equals(type, body.type);
            switch (type) {
              case "text":
                Expect.equals(body.contentType.mimeType, "text/plain");
                Expect.equals(expectedBody, body.body);
                break;

              case "json":
                Expect.equals(body.contentType.mimeType, "application/json");
                Expect.mapEquals(expectedBody, body.body);
                break;

              case "binary":
                Expect.equals(body.contentType, null);
                Expect.listEquals(expectedBody, body.body);
                break;

              case "form":
                var mimeType = body.contentType.mimeType;
                Expect.isTrue(
                    mimeType == 'multipart/form-data' ||
                    mimeType == 'application/x-www-form-urlencoded');
                Expect.setEquals(expectedBody.keys.toSet(),
                                 body.body.keys.toSet());
                for (var key in expectedBody.keys) {
                  if (body.body[key] is HttpBodyFileUpload) {
                    Expect.equals(expectedBody[key]['contentType'],
                                  body.body[key].contentType.toString());
                    Expect.equals(expectedBody[key]['filename'],
                                  body.body[key].filename);
                    if (body.body[key].content is String) {
                      Expect.equals(expectedBody[key]['content'],
                                    body.body[key].content);
                    } else {
                      Expect.listEquals(expectedBody[key]['content'],
                                        body.body[key].content);
                    }
                  } else {
                    Expect.equals(expectedBody[key], body.body[key]);
                  }
                }
                break;

              default:
                Expect.fail("bad body type");
            }
            body.response.close();
          }, onError: (error) {
            if (!shouldFail) throw error;
          });

      var client = new HttpClient();
      client.post("127.0.0.1", server.port, "/")
          .then((request) {
            if (mimeType != null) {
              request.headers.contentType =
                  ContentType.parse(mimeType);
            }
            request.add(content);
            return request.close();
          })
          .then((response) {
            if (shouldFail) {
              Expect.equals(HttpStatus.BAD_REQUEST, response.statusCode);
            }
            response.fold(null, (x, y) {});
            client.close();
            server.close();
          });
    });
  }

  test("text/plain", "body".codeUnits, "body", "text");
  test("text/plain; charset=utf-8",
       "body".codeUnits,
       "body",
       "text");
  test("text/plain; charset=utf-8", [42], "*", "text");
  test("text/plain; charset=us-ascii", [142], "?", "text");
  test("text/plain; charset=utf-8",
       [142],
       new String.fromCharCodes([UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]),
       "text");

  test("application/json",
       '{"val": 5}'.codeUnits,
       { "val" : 5 },
       "json");
  test("application/json",
       '{ bad json }'.codeUnits,
       null,
       "json",
       shouldFail: true);

  test(null, "body".codeUnits, "body".codeUnits, "binary");

  test("multipart/form-data; boundary=AaB03x",
       '''
--AaB03x\r
Content-Disposition: form-data; name="name"\r
\r
Larry\r
--AaB03x--\r\n'''.codeUnits,
       { "name": "Larry" },
       "form");

  test("multipart/form-data; boundary=AaB03x",
       '''
--AaB03x\r
Content-Disposition: form-data; name="files"; filename="myfile"\r
Content-Type: application/octet-stream\r
\r
File content\r
--AaB03x--\r\n'''.codeUnits,
       { "files": { 'filename': 'myfile',
                    'contentType': 'application/octet-stream',
                    'content': 'File content'.codeUnits} },
       "form");

  test("multipart/form-data; boundary=AaB03x",
       '''
--AaB03x\r
Content-Disposition: form-data; name="files"; filename="myfile"\r
Content-Type: application/octet-stream\r
\r
File content\r
--AaB03x\r
Content-Disposition: form-data; name="files"; filename="myfile"\r
Content-Type: text/plain\r
\r
File content\r
--AaB03x--\r\n'''.codeUnits,
       { "files": { 'filename': 'myfile',
                    'contentType': 'text/plain',
                    'content': 'File content'} },
       "form");

  test("multipart/form-data; boundary=AaB03x",
       '''
--AaB03x\r
Content-Disposition: form-data; name="files"; filename="myfile"\r
Content-Type: application/json\r
\r
File content\r
--AaB03x--\r\n'''.codeUnits,
       { "files": { 'filename': 'myfile',
                    'contentType': 'application/json',
                    'content': 'File content'} },
       "form");

  test('application/x-www-form-urlencoded',
       '%E5%B9%B3%3D%E4%BB%AE%E5%90%8D=%E5%B9%B3%E4%BB%AE%E5%90%8D&b'
       '=%E5%B9%B3%E4%BB%AE%E5%90%8D'.codeUnits,
       { 'b' : '平仮名',
         '平=仮名' : '平仮名'},
       "form");

  test('application/x-www-form-urlencoded',
       'a=%F8+%26%23548%3B'.codeUnits,
       { 'a' : '\u{FFFD} &#548;' },
       "form");

  test('application/x-www-form-urlencoded',
       'a=%C0%A0'.codeUnits,
       { 'a' : '\u{FFFD}' },
       "form");

  test('application/x-www-form-urlencoded',
       'a=x%A0x'.codeUnits,
       { 'a' : 'x\u{FFFD}x' },
       "form");

  test('application/x-www-form-urlencoded',
       'a=x%C0x'.codeUnits,
       { 'a' : 'x\u{FFFD}x' },
       "form");

  test('application/x-www-form-urlencoded',
       'a=%C3%B8+%C8%A4'.codeUnits,
       { 'a' : 'ø Ȥ' },
       "form");

  test('application/x-www-form-urlencoded',
       'a=%F8+%26%23548%3B'.codeUnits,
       { 'a' : 'ø &#548;' },
       "form",
       defaultEncoding: Encoding.ISO_8859_1);

  test('application/x-www-form-urlencoded',
       'name=%26'.codeUnits,
       { 'name' : '&' },
       "form",
       defaultEncoding: Encoding.ISO_8859_1);

  test('application/x-www-form-urlencoded',
       'name=%F8%26'.codeUnits,
       { 'name' : 'ø&' },
       "form",
       defaultEncoding: Encoding.ISO_8859_1);

  test('application/x-www-form-urlencoded',
       'name=%26%3B'.codeUnits,
       { 'name' : '&;' },
       "form",
       defaultEncoding: Encoding.ISO_8859_1);

  test('application/x-www-form-urlencoded',
       'name=%26%23548%3B%26%23548%3B'.codeUnits,
       { 'name' : '&#548;&#548;' },
       "form",
       defaultEncoding: Encoding.ISO_8859_1);

  test('application/x-www-form-urlencoded',
       'name=%26'.codeUnits,
       { 'name' : '&' },
       "form");

  test('application/x-www-form-urlencoded',
       'name=%C3%B8%26'.codeUnits,
       { 'name' : 'ø&' },
       "form");

  test('application/x-www-form-urlencoded',
       'name=%26%3B'.codeUnits,
       { 'name' : '&;' },
       "form");

  test('application/x-www-form-urlencoded',
       'name=%C8%A4%26%23548%3B'.codeUnits,
       { 'name' : 'Ȥ&#548;' },
       "form");

  test('application/x-www-form-urlencoded',
       'name=%C8%A4%C8%A4'.codeUnits,
       { 'name' : 'ȤȤ' },
       "form");
}

void main() {
  testHttpClientResponseBody();
  testHttpServerRequestBody();
}
