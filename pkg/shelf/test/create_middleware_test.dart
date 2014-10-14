// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.create_middleware_test;

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:unittest/unittest.dart';

import 'test_util.dart';

void main() {
  test('forwards the request and response if both handlers are null', () {
    var handler = const Pipeline()
        .addMiddleware(createMiddleware())
        .addHandler((request) {
          return syncHandler(request, headers: {'from' : 'innerHandler'});
        });

    return makeSimpleRequest(handler).then((response) {
      expect(response.headers['from'], 'innerHandler');
    });
  });

  group('requestHandler', () {
    test('sync null response forwards to inner handler', () {
      var handler = const Pipeline()
          .addMiddleware(createMiddleware(requestHandler: (request) => null))
          .addHandler(syncHandler);

      return makeSimpleRequest(handler).then((response) {
        expect(response.headers['from'], isNull);
      });
    });

    test('async null response forwards to inner handler', () {
      var handler = const Pipeline()
          .addMiddleware(createMiddleware(
              requestHandler: (request) => new Future.value(null)))
          .addHandler(syncHandler);

      return makeSimpleRequest(handler).then((response) {
        expect(response.headers['from'], isNull);
      });
    });

    test('sync response is returned', () {
      var handler = const Pipeline()
          .addMiddleware(createMiddleware(
              requestHandler: (request) => _middlewareResponse))
          .addHandler(_failHandler);

      return makeSimpleRequest(handler).then((response) {
        expect(response.headers['from'], 'middleware');
      });
    });

    test('async response is returned', () {
      var handler = const Pipeline()
          .addMiddleware(createMiddleware(requestHandler: (request) =>
              new Future.value(_middlewareResponse)))
          .addHandler(_failHandler);

      return makeSimpleRequest(handler).then((response) {
        expect(response.headers['from'], 'middleware');
      });
    });

    group('with responseHandler', () {
      test('with sync result, responseHandler is not called', () {
        var middleware = createMiddleware(
            requestHandler: (request) => _middlewareResponse,
            responseHandler: (response) => fail('should not be called'));

        var handler = const Pipeline()
            .addMiddleware(middleware)
            .addHandler(syncHandler);

        return makeSimpleRequest(handler).then((response) {
          expect(response.headers['from'], 'middleware');
        });
      });

      test('with async result, responseHandler is not called', () {
        var middleware = createMiddleware(
            requestHandler: (request) => new Future.value(_middlewareResponse),
            responseHandler: (response) => fail('should not be called'));
        var handler = const Pipeline()
            .addMiddleware(middleware)
            .addHandler(syncHandler);

        return makeSimpleRequest(handler).then((response) {
          expect(response.headers['from'], 'middleware');
        });
      });
    });
  });

  group('responseHandler', () {
    test('innerHandler sync response is seen, replaced value continues', () {
      var handler = const Pipeline().addMiddleware(createMiddleware(
          responseHandler: (response) {
        expect(response.headers['from'], 'handler');
        return _middlewareResponse;
      })).addHandler((request) {
        return syncHandler(request, headers: {'from' : 'handler'} );
      });

      return makeSimpleRequest(handler).then((response) {
        expect(response.headers['from'], 'middleware');
      });
    });

    test('innerHandler async response is seen, async value continues', () {
      var handler = const Pipeline().addMiddleware(
          createMiddleware(responseHandler: (response) {
        expect(response.headers['from'], 'handler');
        return new Future.value(_middlewareResponse);
      })).addHandler((request) {
        return new Future(() => syncHandler(
            request, headers: {'from' : 'handler'} ));
      });

      return makeSimpleRequest(handler).then((response) {
        expect(response.headers['from'], 'middleware');
      });
    });
  });

  group('error handling', () {
    test('sync error thrown by requestHandler bubbles down', () {
      var handler = const Pipeline()
          .addMiddleware(createMiddleware(
              requestHandler: (request) => throw 'middleware error'))
          .addHandler(_failHandler);

      expect(makeSimpleRequest(handler), throwsA('middleware error'));
    });

    test('async error thrown by requestHandler bubbles down', () {
      var handler = const Pipeline()
          .addMiddleware(createMiddleware(requestHandler: (request) =>
              new Future.error('middleware error')))
          .addHandler(_failHandler);

      expect(makeSimpleRequest(handler), throwsA('middleware error'));
    });

    test('throw from responseHandler does not hit error handler', () {
      var middleware = createMiddleware(responseHandler: (response) {
        throw 'middleware error';
      }, errorHandler: (e, s) => fail('should never get here'));

      var handler = const Pipeline().addMiddleware(middleware)
          .addHandler(syncHandler);

      expect(makeSimpleRequest(handler), throwsA('middleware error'));
    });

    test('requestHandler throw does not hit errorHandlers', () {
      var middleware = createMiddleware(
          requestHandler: (request) {
            throw 'middleware error';
          },
          errorHandler: (e, s) => fail('should never get here'));

      var handler = const Pipeline().addMiddleware(middleware)
          .addHandler(syncHandler);

      expect(makeSimpleRequest(handler), throwsA('middleware error'));
    });

    test('inner handler throws, is caught by errorHandler with response', () {
      var middleware = createMiddleware(
          errorHandler: (error, stack) {
            expect(error, 'bad handler');
            return _middlewareResponse;
          });

      var handler = const Pipeline().addMiddleware(middleware)
          .addHandler((request) {
        throw 'bad handler';
      });

      return makeSimpleRequest(handler).then((response) {
        expect(response.headers['from'], 'middleware');
      });
    });

    test('inner handler throws, is caught by errorHandler and rethrown', () {
      var middleware = createMiddleware(errorHandler: (error, stack) {
        expect(error, 'bad handler');
        throw error;
      });

      var handler = const Pipeline().addMiddleware(middleware)
          .addHandler((request) {
        throw 'bad handler';
      });

      expect(makeSimpleRequest(handler), throwsA('bad handler'));
    });

    test('error thrown by inner handler without a middleware errorHandler is '
        'rethrown', () {
      var middleware = createMiddleware();

      var handler = const Pipeline().addMiddleware(middleware)
          .addHandler((request) {
        throw 'bad handler';
      });

      expect(makeSimpleRequest(handler), throwsA('bad handler'));
    });

    test("doesn't handle HijackException", () {
      var middleware = createMiddleware(errorHandler: (error, stack) {
        fail("error handler shouldn't be called");
      });

      var handler = const Pipeline().addMiddleware(middleware)
          .addHandler((request) => throw const HijackException());

      expect(makeSimpleRequest(handler),
          throwsA(new isInstanceOf<HijackException>()));
    });
  });
}

_failHandler(Request request) => fail('should never get here');

final Response _middlewareResponse =
    new Response.ok('middleware content', headers: {'from': 'middleware'});
