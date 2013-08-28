// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library response_test;

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:unittest/unittest.dart';

void main() {
  group('()', () {
    test('sets body', () {
      var response = new http.Response("Hello, world!", 200);
      expect(response.body, equals("Hello, world!"));
    });

    test('sets bodyBytes', () {
      var response = new http.Response("Hello, world!", 200);
      expect(response.bodyBytes, equals(
          [72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33]));
    });

    test('respects the inferred encoding', () {
      var response = new http.Response("föøbãr", 200,
          headers: {'content-type': 'text/plain; charset=iso-8859-1'});
      expect(response.bodyBytes, equals(
          [102, 246, 248, 98, 227, 114]));
    });
  });

  group('.bytes()', () {
    test('sets body', () {
      var response = new http.Response.bytes([104, 101, 108, 108, 111], 200);
      expect(response.body, equals("hello"));
    });

    test('sets bodyBytes', () {
      var response = new http.Response.bytes([104, 101, 108, 108, 111], 200);
      expect(response.bodyBytes, equals([104, 101, 108, 108, 111]));
    });

    test('respects the inferred encoding', () {
      var response = new http.Response.bytes([102, 246, 248, 98, 227, 114], 200,
          headers: {'content-type': 'text/plain; charset=iso-8859-1'});
      expect(response.body, equals("föøbãr"));
    });
  });

  group('.fromStream()', () {
    test('sets body', () {
      var controller = new StreamController(sync: true);
      var streamResponse = new http.StreamedResponse(
          controller.stream, 200, 13);
      var future = http.Response.fromStream(streamResponse)
        .then((response) => response.body);
      expect(future, completion(equals("Hello, world!")));

      controller.add([72, 101, 108, 108, 111, 44, 32]);
      controller.add([119, 111, 114, 108, 100, 33]);
      controller.close();
    });

    test('sets bodyBytes', () {
      var controller = new StreamController(sync: true);
      var streamResponse = new http.StreamedResponse(controller.stream, 200, 5);
      var future = http.Response.fromStream(streamResponse)
        .then((response) => response.bodyBytes);
      expect(future, completion(equals([104, 101, 108, 108, 111])));

      controller.add([104, 101, 108, 108, 111]);
      controller.close();
    });
  });
}
