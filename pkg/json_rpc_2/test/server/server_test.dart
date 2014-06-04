// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.test.server.server_test;

import 'dart:convert';

import 'package:unittest/unittest.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'utils.dart';

void main() {
  var controller;
  setUp(() => controller = new ServerController());

  test("calls a registered method with the given name", () {
    controller.server.registerMethod('foo', (params) {
      return {'params': params.value};
    });

    expect(controller.handleRequest({
      'jsonrpc': '2.0',
      'method': 'foo',
      'params': {'param': 'value'},
      'id': 1234
    }), completion(equals({
      'jsonrpc': '2.0',
      'result': {'params': {'param': 'value'}},
      'id': 1234
    })));
  });

  test("calls a method that takes no parameters", () {
    controller.server.registerMethod('foo', () => 'foo');

    expect(controller.handleRequest({
      'jsonrpc': '2.0',
      'method': 'foo',
      'id': 1234
    }), completion(equals({
      'jsonrpc': '2.0',
      'result': 'foo',
      'id': 1234
    })));
  });

  test("a method that takes no parameters rejects parameters", () {
    controller.server.registerMethod('foo', () => 'foo');

    expectErrorResponse(controller, {
      'jsonrpc': '2.0',
      'method': 'foo',
      'params': {},
      'id': 1234
    },
        error_code.INVALID_PARAMS,
        'No parameters are allowed for method "foo".');
  });

  test("an unexpected error in a method is captured", () {
    controller.server.registerMethod('foo', () => throw new FormatException('bad format'));

    expect(controller.handleRequest({
      'jsonrpc': '2.0',
      'method': 'foo',
      'id': 1234
    }), completion({
      'jsonrpc': '2.0',
      'id': 1234,
      'error': {
        'code': error_code.SERVER_ERROR,
        'message': 'bad format',
        'data': {
          'request': {'jsonrpc': '2.0', 'method': 'foo', 'id': 1234},
          'full': 'FormatException: bad format',
          'stack': new isInstanceOf<String>()
        }
      }
    }));
  });

  test("doesn't return a result for a notification", () {
    controller.server.registerMethod('foo', (args) => 'result');

    expect(controller.handleRequest({
      'jsonrpc': '2.0',
      'method': 'foo',
      'params': {}
    }), completion(isNull));
  });

  test("includes the error data in the response", () {
    controller.server.registerMethod('foo', (params) {
      throw new json_rpc.RpcException(5, 'Error message.', data: 'data value');
    });

    expectErrorResponse(controller, {
      'jsonrpc': '2.0',
      'method': 'foo',
      'params': {},
      'id': 1234
    },
        5,
        'Error message.',
        data: 'data value');
  });

  test("a JSON parse error is rejected", () {
    return controller.handleJsonRequest('invalid json {').then((result) {
      expect(JSON.decode(result), {
        'jsonrpc': '2.0',
        'error': {
          'code': error_code.PARSE_ERROR,
          'message': startsWith("Invalid JSON: "),
          'data': {'request': 'invalid json {'}
        },
        'id': null
      });
    });
  });

  group("fallbacks", () {
    test("calls a fallback if no method matches", () {
      controller.server
          ..registerMethod('foo', () => 'foo')
          ..registerMethod('bar', () => 'foo')
          ..registerFallback((params) => {'fallback': params.value});

      expect(controller.handleRequest({
        'jsonrpc': '2.0',
        'method': 'baz',
        'params': {'param': 'value'},
        'id': 1234
      }), completion(equals({
        'jsonrpc': '2.0',
        'result': {'fallback': {'param': 'value'}},
        'id': 1234
      })));
    });

    test("calls the first matching fallback", () {
      controller.server
          ..registerFallback((params) =>
              throw new json_rpc.RpcException.methodNotFound(params.method))
          ..registerFallback((params) => 'fallback 2')
          ..registerFallback((params) => 'fallback 3');

      expect(controller.handleRequest({
        'jsonrpc': '2.0',
        'method': 'fallback 2',
        'id': 1234
      }), completion(equals({
        'jsonrpc': '2.0',
        'result': 'fallback 2',
        'id': 1234
      })));
    });

    test("an unexpected error in a fallback is captured", () {
      controller.server.registerFallback((_) =>
          throw new FormatException('bad format'));

      expect(controller.handleRequest({
        'jsonrpc': '2.0',
        'method': 'foo',
        'id': 1234
      }), completion({
        'jsonrpc': '2.0',
        'id': 1234,
        'error': {
          'code': error_code.SERVER_ERROR,
          'message': 'bad format',
          'data': {
            'request': {'jsonrpc': '2.0', 'method': 'foo', 'id': 1234},
            'full': 'FormatException: bad format',
            'stack': new isInstanceOf<String>()
          }
        }
      }));
    });
  });

  test("disallows multiple methods with the same name", () {
    controller.server.registerMethod('foo', () => null);
    expect(() => controller.server.registerMethod('foo', () => null),
        throwsArgumentError);
  });
}
