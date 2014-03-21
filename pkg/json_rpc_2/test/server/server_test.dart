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
  var server;
  setUp(() => server = new json_rpc.Server());

  test("calls a registered method with the given name", () {
    server.registerMethod('foo', (params) {
      return {'params': params.value};
    });

    expect(server.handleRequest({
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
    server.registerMethod('foo', () => 'foo');

    expect(server.handleRequest({
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
    server.registerMethod('foo', () => 'foo');

    expectErrorResponse(server, {
      'jsonrpc': '2.0',
      'method': 'foo',
      'params': {},
      'id': 1234
    },
        error_code.INVALID_PARAMS,
        'No parameters are allowed for method "foo".');
  });

  test("an unexpected error in a method is captured", () {
    server.registerMethod('foo', () => throw new FormatException('bad format'));

    expect(server.handleRequest({
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
          'stack': contains('server_test.dart')
        }
      }
    }));
  });

  test("doesn't return a result for a notification", () {
    server.registerMethod('foo', (args) => 'result');

    expect(server.handleRequest({
      'jsonrpc': '2.0',
      'method': 'foo',
      'params': {}
    }), completion(isNull));
  });

  group("JSON", () {
    test("handles a request parsed from JSON", () {
      server.registerMethod('foo', (params) {
        return {'params': params.value};
      });

      expect(server.parseRequest(JSON.encode({
        'jsonrpc': '2.0',
        'method': 'foo',
        'params': {'param': 'value'},
        'id': 1234
      })), completion(equals(JSON.encode({
        'jsonrpc': '2.0',
        'result': {'params': {'param': 'value'}},
        'id': 1234
      }))));
    });

    test("handles a notification parsed from JSON", () {
      server.registerMethod('foo', (params) {
        return {'params': params};
      });

      expect(server.parseRequest(JSON.encode({
        'jsonrpc': '2.0',
        'method': 'foo',
        'params': {'param': 'value'}
      })), completion(isNull));
    });

    test("a JSON parse error is rejected", () {
      expect(server.parseRequest('invalid json {'),
          completion(equals(JSON.encode({
        'jsonrpc': '2.0',
        'error': {
          'code': error_code.PARSE_ERROR,
          'message': "Invalid JSON: Unexpected character at 0: 'invalid json "
                     "{'",
          'data': {'request': 'invalid json {'}
        },
        'id': null
      }))));
    });
  });

  group("fallbacks", () {
    test("calls a fallback if no method matches", () {
      server.registerMethod('foo', () => 'foo');
      server.registerMethod('bar', () => 'foo');
      server.registerFallback((params) => {'fallback': params.value});

      expect(server.handleRequest({
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
      server.registerFallback((params) =>
          throw new json_rpc.RpcException.methodNotFound(params.method));

      server.registerFallback((params) => 'fallback 2');
      server.registerFallback((params) => 'fallback 3');

      expect(server.handleRequest({
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
      server.registerFallback((_) => throw new FormatException('bad format'));

      expect(server.handleRequest({
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
            'stack': contains('server_test.dart')
          }
        }
      }));
    });
  });

  test("disallows multiple methods with the same name", () {
    server.registerMethod('foo', () => null);
    expect(() => server.registerMethod('foo', () => null), throwsArgumentError);
  });
}
