// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.response_test;

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:unittest/unittest.dart';

void main() {
  group("readAsString", () {
    test("supports a null body", () {
      var response = new Response(200);
      expect(response.readAsString(), completion(equals("")));
    });

    test("supports a String body", () {
      var response = new Response.ok("hello, world");
      expect(response.readAsString(), completion(equals("hello, world")));
    });

    test("supports a Stream<List<int>> body", () {
      var controller = new StreamController();
      var response = new Response.ok(controller.stream);
      expect(response.readAsString(), completion(equals("hello, world")));

      controller.add([104, 101, 108, 108, 111, 44]);
      return new Future(() {
        controller
          ..add([32, 119, 111, 114, 108, 100])
          ..close();
      });
    });

    test("defaults to UTF-8", () {
      var response = new Response.ok(
          new Stream.fromIterable([[195, 168]]));
      expect(response.readAsString(), completion(equals("è")));
    });

    test("the content-type header overrides the default", () {
      var response = new Response.ok(
          new Stream.fromIterable([[195, 168]]),
          headers: {'content-type': 'text/plain; charset=iso-8859-1'});
      expect(response.readAsString(), completion(equals("Ã¨")));
    });

    test("an explicit encoding overrides the content-type header", () {
      var response = new Response.ok(
          new Stream.fromIterable([[195, 168]]),
          headers: {'content-type': 'text/plain; charset=utf-8'});
      expect(response.readAsString(LATIN1), completion(equals("Ã¨")));
    });
  });

  group("read", () {
    test("supports a null body", () {
      var response = new Response(200);
      expect(response.read().toList(), completion(isEmpty));
    });

    test("supports a String body", () {
      var response = new Response.ok("hello, world");
      expect(response.read().toList(), completion(equals([[
        104, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100
      ]])));
    });

    test("supports a Stream<List<int>> body", () {
      var controller = new StreamController();
      var response = new Response.ok(controller.stream);
      expect(response.read().toList(), completion(equals([
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

  group("new Response", () {
    test("defaults to encoding a String as UTF-8", () {
      expect(new Response.ok("è").read().toList(),
          completion(equals([[195, 168]])));
    });

    test("uses the explicit encoding if available", () {
      expect(new Response.ok("è", encoding: LATIN1).read().toList(),
          completion(equals([[232]])));
    });

    test("adds an explicit encoding to the content-type", () {
      var response = new Response.ok("è",
          encoding: LATIN1,
          headers: {'content-type': 'text/plain'});
      expect(response.headers,
          containsPair('content-type', 'text/plain; charset=iso-8859-1'));
    });

    test("sets an absent content-type to application/octet-stream in order to "
        "set the charset", () {
      var response = new Response.ok("è", encoding: LATIN1);
      expect(response.headers, containsPair('content-type',
          'application/octet-stream; charset=iso-8859-1'));
    });

    test("overwrites an existing charset if given an explicit encoding", () {
      var response = new Response.ok("è",
          encoding: LATIN1,
          headers: {'content-type': 'text/plain; charset=whatever'});
      expect(response.headers,
          containsPair('content-type', 'text/plain; charset=iso-8859-1'));
    });
  });

  group("new Response.internalServerError without a body", () {
    test('sets the body to "Internal Server Error"', () {
      var response = new Response.internalServerError();
      expect(response.readAsString(),
          completion(equals("Internal Server Error")));
    });

    test('sets the content-type header to text/plain', () {
      var response = new Response.internalServerError();
      expect(response.headers, containsPair('content-type', 'text/plain'));
    });

    test('preserves content-type parameters', () {
      var response = new Response.internalServerError(headers: {
        'content-type': 'application/octet-stream; param=whatever'
      });
      expect(response.headers,
          containsPair('content-type', 'text/plain; param=whatever'));
    });
  });

  group("Response redirect", () {
    test("sets the location header for a String", () {
      var response = new Response.found('/foo');
      expect(response.headers, containsPair('location', '/foo'));
    });

    test("sets the location header for a Uri", () {
      var response = new Response.found(new Uri(path: '/foo'));
      expect(response.headers, containsPair('location', '/foo'));
    });
  });

  group("mimeType", () {
    test("is null without a content-type header", () {
      expect(new Response.ok("okay!").mimeType, isNull);
    });

    test("comes from the content-type header", () {
      expect(new Response.ok("okay!", headers: {
        'content-type': 'text/plain'
      }).mimeType, equals('text/plain'));
    });

    test("doesn't include parameters", () {
      expect(new Response.ok("okay!", headers: {
        'content-type': 'text/plain; foo=bar; bar=baz'
      }).mimeType, equals('text/plain'));
    });
  });

  group("encoding", () {
    test("is null without a content-type header", () {
      expect(new Response.ok("okay!").encoding, isNull);
    });

    test("is null without a charset parameter", () {
      expect(new Response.ok("okay!", headers: {
        'content-type': 'text/plain'
      }).encoding, isNull);
    });

    test("is null with an unrecognized charset parameter", () {
      expect(new Response.ok("okay!", headers: {
        'content-type': 'text/plain; charset=fblthp'
      }).encoding, isNull);
    });

    test("comes from the content-type charset parameter", () {
      expect(new Response.ok("okay!", headers: {
        'content-type': 'text/plain; charset=iso-8859-1'
      }).encoding, equals(LATIN1));
    });
  });

  group("expires", () {
    test("is null without an Expires header", () {
      expect(new Response.ok("okay!").expires, isNull);
    });

    test("comes from the Expires header", () {
      expect(new Response.ok("okay!", headers: {
        'expires': 'Sun, 06 Nov 1994 08:49:37 GMT'
      }).expires, equals(DateTime.parse("1994-11-06 08:49:37z")));
    });
  });

  group("lastModified", () {
    test("is null without a Last-Modified header", () {
      expect(new Response.ok("okay!").lastModified, isNull);
    });

    test("comes from the Last-Modified header", () {
      expect(new Response.ok("okay!", headers: {
        'last-modified': 'Sun, 06 Nov 1994 08:49:37 GMT'
      }).lastModified, equals(DateTime.parse("1994-11-06 08:49:37z")));
    });
  });

  group("contentLength", () {
    test("is null without a content-length header", () {
      expect(new Response.ok("okay!").contentLength, isNull);
    });

    test("comes from the content-length header", () {
      expect(new Response.ok("okay!", headers: {
        'content-length': '42'
      }).contentLength, equals(42));
    });
  });
}
