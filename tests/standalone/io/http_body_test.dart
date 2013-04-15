// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:utf';

import 'package:expect/expect.dart';

void testHttpClientResponseBody() {
  new HttpBodyHandler();
  void test(String mimeType,
            List<int> content,
            dynamic expectedBody,
            String type,
            [bool shouldFail = false]) {
    HttpServer.bind().then((server) {
      server.listen((request) {
        request.listen(
            (_) {},
            onDone: () {
              request.response.headers.contentType =
                  new ContentType.fromString(mimeType);
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
            if (!shouldFail) Expect.fail("Error unexpected");
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
            [bool shouldFail = false]) {
    HttpServer.bind().then((server) {
      server.transform(new HttpBodyHandler())
          .listen((body) {
            if (shouldFail) Expect.fail("Error expected");
            Expect.equals(type, body.type);
            switch (type) {
              case "text":
                Expect.equals(body.mimeType, "text/plain");
                Expect.equals(expectedBody, body.body);
                break;

              case "json":
                Expect.equals(body.mimeType, "application/json");
                Expect.mapEquals(expectedBody, body.body);
                break;

              case "binary":
                Expect.equals(body.mimeType, null);
                Expect.listEquals(expectedBody, body.body);
                break;

              default:
                Expect.fail("bad body type");
            }
            body.response.close();
          }, onError: (error) {
            if (!shouldFail) Expect.fail("Error unexpected");
          });

      var client = new HttpClient();
      client.post("127.0.0.1", server.port, "/")
          .then((request) {
            if (mimeType != null) {
              request.headers.contentType =
                  new ContentType.fromString(mimeType);
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
       true);

  test(null, "body".codeUnits, "body".codeUnits, "binary");
}


void main() {
  testHttpClientResponseBody();
  testHttpServerRequestBody();
}
