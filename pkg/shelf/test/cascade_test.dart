// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.cascade_test;

import 'package:shelf/shelf.dart';
import 'package:shelf/src/util.dart';
import 'package:unittest/unittest.dart';

import 'test_util.dart';

void main() {
  group('a cascade with several handlers', () {
    var handler;
    setUp(() {
      handler = new Cascade().add((request) {
        if (request.headers['one'] == 'false') {
          return new Response.notFound('handler 1');
        } else {
          return new Response.ok('handler 1');
        }
      }).add((request) {
        if (request.headers['two'] == 'false') {
          return new Response.notFound('handler 2');
        } else {
          return new Response.ok('handler 2');
        }
      }).add((request) {
        if (request.headers['three'] == 'false') {
          return new Response.notFound('handler 3');
        } else {
          return new Response.ok('handler 3');
        }
      }).handler;
    });

    test('the first response should be returned if it matches', () {
      return makeSimpleRequest(handler).then((response) {
        expect(response.statusCode, equals(200));
        expect(response.readAsString(), completion(equals('handler 1')));
      });
    });

    test("the second response should be returned if it matches and the first "
        "doesn't", () {
      return syncFuture(() {
        return handler(new Request('GET', LOCALHOST_URI,
            headers: {'one': 'false'}));
      }).then((response) {
        expect(response.statusCode, equals(200));
        expect(response.readAsString(), completion(equals('handler 2')));
      });
    });

    test("the third response should be returned if it matches and the first "
        "two don't", () {
      return syncFuture(() {
        return handler(new Request('GET', LOCALHOST_URI,
            headers: {'one': 'false', 'two': 'false'}));
      }).then((response) {
        expect(response.statusCode, equals(200));
        expect(response.readAsString(), completion(equals('handler 3')));
      });
    });

    test("the third response should be returned if no response matches", () {
      return syncFuture(() {
        return handler(new Request('GET', LOCALHOST_URI,
            headers: {'one': 'false', 'two': 'false', 'three': 'false'}));
      }).then((response) {
        expect(response.statusCode, equals(404));
        expect(response.readAsString(), completion(equals('handler 3')));
      });
    });
  });

  test('a 404 response triggers a cascade by default', () {
    var handler = new Cascade()
        .add((_) => new Response.notFound('handler 1'))
        .add((_) => new Response.ok('handler 2'))
        .handler;

    return makeSimpleRequest(handler).then((response) {
      expect(response.statusCode, equals(200));
      expect(response.readAsString(), completion(equals('handler 2')));
    });
  });

  test('a 405 response triggers a cascade by default', () {
    var handler = new Cascade()
        .add((_) => new Response(405))
        .add((_) => new Response.ok('handler 2'))
        .handler;

    return makeSimpleRequest(handler).then((response) {
      expect(response.statusCode, equals(200));
      expect(response.readAsString(), completion(equals('handler 2')));
    });
  });

  test('[statusCodes] controls which statuses cause cascading', () {
    var handler = new Cascade(statusCodes: [302, 403])
        .add((_) => new Response.found('/'))
        .add((_) => new Response.forbidden('handler 2'))
        .add((_) => new Response.notFound('handler 3'))
        .add((_) => new Response.ok('handler 4'))
        .handler;

    return makeSimpleRequest(handler).then((response) {
      expect(response.statusCode, equals(404));
      expect(response.readAsString(), completion(equals('handler 3')));
    });
  });

  test('[shouldCascade] controls which responses cause cascading', () {
    var handler = new Cascade(
          shouldCascade: (response) => response.statusCode % 2 == 1)
        .add((_) => new Response.movedPermanently('/'))
        .add((_) => new Response.forbidden('handler 2'))
        .add((_) => new Response.notFound('handler 3'))
        .add((_) => new Response.ok('handler 4'))
        .handler;

    return makeSimpleRequest(handler).then((response) {
      expect(response.statusCode, equals(404));
      expect(response.readAsString(), completion(equals('handler 3')));
    });
  });

  group('errors', () {
    test('getting the handler for an empty cascade fails', () {
      expect(() => new Cascade().handler, throwsStateError);
    });

    test('passing [statusCodes] and [shouldCascade] at the same time fails',
        () {
      expect(() => new Cascade(
            statusCodes: [404, 405], shouldCascade: (_) => false),
          throwsArgumentError);
    });
  });
}
