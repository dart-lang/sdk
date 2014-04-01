// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.request_test;

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:unittest/unittest.dart';

Request _request([Map<String, String> headers, Stream<List<int>> body]) {
  if (headers == null) headers = {};
  return new Request("/", "", "GET", "", "1.1", Uri.parse('http://localhost/'),
      headers, body: body);
}

void main() {
  group("contentLength", () {
    test("is null without a content-length header", () {
      var request = _request();
      expect(request.contentLength, isNull);
    });

    test("comes from the content-length header", () {
      var request = _request({
        'content-length': '42'
      });
      expect(request.contentLength, 42);
    });
  });

  group("ifModifiedSince", () {
    test("is null without an If-Modified-Since header", () {
      var request = _request();
      expect(request.ifModifiedSince, isNull);
    });

    test("comes from the Last-Modified header", () {
      var request = _request({
        'if-modified-since': 'Sun, 06 Nov 1994 08:49:37 GMT'
      });
      expect(request.ifModifiedSince,
          equals(DateTime.parse("1994-11-06 08:49:37z")));
    });
  });

  group("readAsString", () {
    test("supports a null body", () {
      var request = _request();
      expect(request.readAsString(), completion(equals("")));
    });

    test("supports a Stream<List<int>> body", () {
      var controller = new StreamController();
      var request = _request({}, controller.stream);
      expect(request.readAsString(), completion(equals("hello, world")));

      controller.add([104, 101, 108, 108, 111, 44]);
      return new Future(() {
        controller
          ..add([32, 119, 111, 114, 108, 100])
          ..close();
      });
    });

    test("defaults to UTF-8", () {
      var request = _request({}, new Stream.fromIterable([[195, 168]]));
      expect(request.readAsString(), completion(equals("è")));
    });

    test("the content-type header overrides the default", () {
      var request = _request({'content-type': 'text/plain; charset=iso-8859-1'},
          new Stream.fromIterable([[195, 168]]));
      expect(request.readAsString(), completion(equals("Ã¨")));
    });

    test("an explicit encoding overrides the content-type header", () {
      var request = _request({'content-type': 'text/plain; charset=iso-8859-1'},
          new Stream.fromIterable([[195, 168]]));
      expect(request.readAsString(LATIN1), completion(equals("Ã¨")));
    });
  });

  group("read", () {
    test("supports a null body", () {
      var request = _request();
      expect(request.read().toList(), completion(isEmpty));
    });

    test("supports a Stream<List<int>> body", () {
      var controller = new StreamController();
      var request = _request({}, controller.stream);
      expect(request.read().toList(), completion(equals([
        [104, 101, 108, 108, 111, 44],
        [32, 119, 111, 114, 108, 100]
      ])));

      controller.add([104, 101, 108, 108, 111, 44]);
      return new Future(() {
        controller
          ..add([32, 119, 111, 114, 108, 100])
          ..close();
      });
    });
  });

  group("mimeType", () {
    test("is null without a content-type header", () {
      expect(_request().mimeType, isNull);
    });

    test("comes from the content-type header", () {
      expect(_request({
        'content-type': 'text/plain'
      }).mimeType, equals('text/plain'));
    });

    test("doesn't include parameters", () {
      expect(_request({
        'content-type': 'text/plain; foo=bar; bar=baz'
      }).mimeType, equals('text/plain'));
    });
  });

  group("encoding", () {
    test("is null without a content-type header", () {
      expect(_request().encoding, isNull);
    });

    test("is null without a charset parameter", () {
      expect(_request({
        'content-type': 'text/plain'
      }).encoding, isNull);
    });

    test("is null with an unrecognized charset parameter", () {
      expect(_request({
        'content-type': 'text/plain; charset=fblthp'
      }).encoding, isNull);
    });

    test("comes from the content-type charset parameter", () {
      expect(_request({
        'content-type': 'text/plain; charset=iso-8859-1'
      }).encoding, equals(LATIN1));
    });
  });
}
