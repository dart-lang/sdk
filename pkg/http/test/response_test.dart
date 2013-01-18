// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library response_test;

import 'dart:async';
import 'dart:io';

import 'package:unittest/unittest.dart';
import 'package:http/http.dart' as http;

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

    // TODO(nweiz): test that this respects the inferred encoding when issue
    // 6284 is fixed.
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

    // TODO(nweiz): test that this respects the inferred encoding when issue
    // 6284 is fixed.
  });

  group('.fromStream()', () {
    test('sets body', () {
      var controller = new StreamController();
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
      var controller = new StreamController();
      var streamResponse = new http.StreamedResponse(controller.stream, 200, 5);
      var future = http.Response.fromStream(streamResponse)
        .then((response) => response.bodyBytes);
      expect(future, completion(equals([104, 101, 108, 108, 111])));

      controller.add([104, 101, 108, 108, 111]);
      controller.close();
    });
  });
}
