// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.pipeline_test;

import 'package:shelf/shelf.dart';
import 'package:unittest/unittest.dart';

import 'test_util.dart';

void main() {
  test('compose middleware with Pipeline', () {
    int accessLocation = 0;

    var middlewareA = createMiddleware(requestHandler: (request) {
      expect(accessLocation, 0);
      accessLocation = 1;
      return null;
    }, responseHandler: (response) {
      expect(accessLocation, 4);
      accessLocation = 5;
      return response;
    });

    var middlewareB = createMiddleware(requestHandler: (request) {
      expect(accessLocation, 1);
      accessLocation = 2;
      return null;
    }, responseHandler: (response) {
      expect(accessLocation, 3);
      accessLocation = 4;
      return response;
    });

    var handler = const Pipeline()
        .addMiddleware(middlewareA)
        .addMiddleware(middlewareB)
        .addHandler((request) {
      expect(accessLocation, 2);
      accessLocation = 3;
      return syncHandler(request);
    });

    return makeSimpleRequest(handler).then((response) {
      expect(response, isNotNull);
      expect(accessLocation, 5);
    });
  });

  test('Pipeline can be used as middleware', () {
    int accessLocation = 0;

    var middlewareA = createMiddleware(requestHandler: (request) {
      expect(accessLocation, 0);
      accessLocation = 1;
      return null;
    }, responseHandler: (response) {
      expect(accessLocation, 4);
      accessLocation = 5;
      return response;
    });

    var middlewareB = createMiddleware(requestHandler: (request) {
      expect(accessLocation, 1);
      accessLocation = 2;
      return null;
    }, responseHandler: (response) {
      expect(accessLocation, 3);
      accessLocation = 4;
      return response;
    });

    var innerPipeline = const Pipeline()
        .addMiddleware(middlewareA)
        .addMiddleware(middlewareB);

    var handler = const Pipeline()
        .addMiddleware(innerPipeline.middleware)
        .addHandler((request) {
      expect(accessLocation, 2);
      accessLocation = 3;
      return syncHandler(request);
    });

    return makeSimpleRequest(handler).then((response) {
      expect(response, isNotNull);
      expect(accessLocation, 5);
    });
  });
}
