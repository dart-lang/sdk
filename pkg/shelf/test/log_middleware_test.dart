// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.log_middleware_test;

import 'package:shelf/shelf.dart';
import 'package:unittest/unittest.dart';

import 'test_util.dart';

void main() {
  bool gotLog;

  setUp(() {
    gotLog = false;
  });

  var logger = (msg, isError) {
    expect(gotLog, isFalse);
    gotLog = true;
    expect(isError, isFalse);
    expect(msg, contains('GET'));
    expect(msg, contains('[200]'));
  };

  test('logs a request with a synchronous response', () {
    var handler = const Stack()
        .addMiddleware(logRequests(logger: logger))
        .addHandler(syncHandler);

    return makeSimpleRequest(handler).then((response) {
      expect(gotLog, isTrue);
    });
  });

  test('logs a request with an asynchronous response', () {
    var handler = const Stack()
        .addMiddleware(logRequests(logger: logger))
        .addHandler(asyncHandler);

    return makeSimpleRequest(handler).then((response) {
      expect(gotLog, isTrue);
    });
  });

  test('logs a request with an asynchronous response', () {
    var handler = const Stack()
        .addMiddleware(logRequests(logger: (msg, isError) {
      expect(gotLog, isFalse);
      gotLog = true;
      expect(isError, isTrue);
      expect(msg, contains('\tGET\t/'));
      expect(msg, contains('testing logging throw'));
    })).addHandler((request) {
      throw 'testing logging throw';
    });

    expect(makeSimpleRequest(handler), throwsA('testing logging throw'));
  });
}
