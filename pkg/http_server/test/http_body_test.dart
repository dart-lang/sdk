// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

import 'package:http_server/http_server.dart';
import 'package:unittest/unittest.dart';

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
            expect(shouldFail, isFalse);
            expect(body.type, equals(type));
            expect(body.response, isNotNull);
            switch (type) {
              case "text":
              case "json":
                expect(body.body, equals(expectedBody));
                break;

              default:
                fail("bad body type");
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
  test("text/plain; charset=us-ascii", [142], null, "text", true);
  test("text/plain; charset=utf-8", [142], null, "text", true);

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
             Encoding defaultEncoding: UTF8}) {
    HttpServer.bind("127.0.0.1", 0).then((server) {
      server.transform(new HttpBodyHandler(defaultEncoding: defaultEncoding))
          .listen((body) {
            if (shouldFail) return;
            expect(shouldFail, isFalse);
            expect(body.type, equals(type));
            switch (type) {
              case "text":
                expect(body.request.headers.contentType.mimeType,
                       equals("text/plain"));
                expect(body.body, equals(expectedBody));
                break;

              case "json":
                expect(body.request.headers.contentType.mimeType,
                       equals("application/json"));
                expect(body.body, equals(expectedBody));
                break;

              case "binary":
                expect(body.request.headers.contentType, isNull);
                expect(body.body, equals(expectedBody));
                break;

              case "form":
                var mimeType = body.request.headers.contentType.mimeType;
                expect(mimeType,
                       anyOf(equals('multipart/form-data'),
                             equals('application/x-www-form-urlencoded')));
                expect(body.body.keys.toSet(),
                       equals(expectedBody.keys.toSet()));
                for (var key in expectedBody.keys) {
                  var found = body.body[key];
                  var expected = expectedBody[key];
                  if (found is HttpBodyFileUpload) {
                    expect(found.contentType.toString(),
                           equals(expected['contentType']));
                    expect(found.filename,
                           equals(expected['filename']));
                    expect(found.content,
                           equals(expected['content']));
                  } else {
                    expect(found, equals(expected));
                  }
                }
                break;

              default:
                throw "bad body type";
            }
            body.request.response.close();
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
              expect(response.statusCode, equals(HttpStatus.BAD_REQUEST));
            }
            return response.drain();
          })
          .whenComplete(() {
            client.close();
            server.close();
          })
          .catchError((e) {
            if (!shouldFail) throw e;
          });
    });
  }

  test("text/plain", "body".codeUnits, "body", "text");
  test("text/plain; charset=utf-8",
       "body".codeUnits,
       "body",
       "text");
  test("text/plain; charset=utf-8", [42], "*", "text");
  test("text/plain; charset=us-ascii", [142], null, "text", shouldFail: true);
  test("text/plain; charset=utf-8", [142], null, "text", shouldFail: true);

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
       { '平=仮名' : '平仮名',
         'b' : '平仮名' },
       "form");

  test('application/x-www-form-urlencoded',
       'a=%F8+%26%23548%3B'.codeUnits,
       null,
       "form",
       shouldFail: true);

  test('application/x-www-form-urlencoded',
       'a=%C0%A0'.codeUnits,
       null,
       "form",
       shouldFail: true);

  test('application/x-www-form-urlencoded',
       'a=x%A0x'.codeUnits,
       null,
       "form",
       shouldFail: true);

  test('application/x-www-form-urlencoded',
       'a=x%C0x'.codeUnits,
       null,
       "form",
       shouldFail: true);

  test('application/x-www-form-urlencoded',
       'a=%C3%B8+%C8%A4'.codeUnits,
       { 'a' : 'ø Ȥ' },
       "form");

  test('application/x-www-form-urlencoded',
       'a=%F8+%26%23548%3B'.codeUnits,
       { 'a' : 'ø &#548;' },
       "form",
       defaultEncoding: LATIN1);

  test('application/x-www-form-urlencoded',
       'name=%26'.codeUnits,
       { 'name' : '&' },
       "form",
       defaultEncoding: LATIN1);

  test('application/x-www-form-urlencoded',
       'name=%F8%26'.codeUnits,
       { 'name' : 'ø&' },
       "form",
       defaultEncoding: LATIN1);

  test('application/x-www-form-urlencoded',
       'name=%26%3B'.codeUnits,
       { 'name' : '&;' },
       "form",
       defaultEncoding: LATIN1);

  test('application/x-www-form-urlencoded',
       'name=%26%23548%3B%26%23548%3B'.codeUnits,
       { 'name' : '&#548;&#548;' },
       "form",
       defaultEncoding: LATIN1);

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
