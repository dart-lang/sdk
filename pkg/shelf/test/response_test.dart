// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.response_test;

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart' hide Request;
import 'package:unittest/unittest.dart';

import 'test_util.dart';

void main() {
  group("supports a String body", () {
    test("readAsString", () {
      var response = new Response.ok("hello, world");
      expect(response.readAsString(), completion(equals("hello, world")));
    });

    test("read", () {
      var helloWorldBytes = new List.from(HELLO_BYTES)..addAll(WORLD_BYTES);

      var response = new Response.ok("hello, world");
      expect(response.read().toList(), completion(equals([helloWorldBytes])));
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

  group('change', () {
    test('with no arguments returns instance with equal values', () {
      var controller = new StreamController();

      var request = new Response(345, body: 'hèllo, world', encoding: LATIN1,
          headers: {'header1': 'header value 1'},
          context: {'context1': 'context value 1'});

      var copy = request.change();

      expect(copy.statusCode, request.statusCode);
      expect(copy.readAsString(), completion('hèllo, world'));
      expect(copy.headers, same(request.headers));
      expect(copy.encoding, request.encoding);
      expect(copy.context, same(request.context));

      controller.add(HELLO_BYTES);
      return new Future(() {
        controller
          ..add(WORLD_BYTES)
          ..close();
      });
    });
  });
}
