// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.test.server.batch_test;

import 'dart:convert';

import 'package:unittest/unittest.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'utils.dart';

void main() {
  var server;
  setUp(() {
    server = new json_rpc.Server()
        ..registerMethod('foo', () => 'foo')
        ..registerMethod('id', (params) => params.value)
        ..registerMethod('arg', (params) => params['arg'].value);
  });

  test('handles a batch of requests', () {
    expect(server.handleRequest([
      {'jsonrpc': '2.0', 'method': 'foo', 'id': 1},
      {'jsonrpc': '2.0', 'method': 'id', 'params': ['value'], 'id': 2},
      {'jsonrpc': '2.0', 'method': 'arg', 'params': {'arg': 'value'}, 'id': 3}
    ]), completion(equals([
      {'jsonrpc': '2.0', 'result': 'foo', 'id': 1},
      {'jsonrpc': '2.0', 'result': ['value'], 'id': 2},
      {'jsonrpc': '2.0', 'result': 'value', 'id': 3}
    ])));
  });

  test('handles errors individually', () {
    expect(server.handleRequest([
      {'jsonrpc': '2.0', 'method': 'foo', 'id': 1},
      {'jsonrpc': '2.0', 'method': 'zap', 'id': 2},
      {'jsonrpc': '2.0', 'method': 'arg', 'params': {'arg': 'value'}, 'id': 3}
    ]), completion(equals([
      {'jsonrpc': '2.0', 'result': 'foo', 'id': 1},
      {
        'jsonrpc': '2.0',
        'id': 2,
        'error': {
          'code': error_code.METHOD_NOT_FOUND,
          'message': 'Unknown method "zap".',
          'data': {'request': {'jsonrpc': '2.0', 'method': 'zap', 'id': 2}},
        }
      },
      {'jsonrpc': '2.0', 'result': 'value', 'id': 3}
    ])));
  });

  test('handles notifications individually', () {
    expect(server.handleRequest([
      {'jsonrpc': '2.0', 'method': 'foo', 'id': 1},
      {'jsonrpc': '2.0', 'method': 'id', 'params': ['value']},
      {'jsonrpc': '2.0', 'method': 'arg', 'params': {'arg': 'value'}, 'id': 3}
    ]), completion(equals([
      {'jsonrpc': '2.0', 'result': 'foo', 'id': 1},
      {'jsonrpc': '2.0', 'result': 'value', 'id': 3}
    ])));
  });

  test('returns nothing if every request is a notification', () {
    expect(server.handleRequest([
      {'jsonrpc': '2.0', 'method': 'foo'},
      {'jsonrpc': '2.0', 'method': 'id', 'params': ['value']},
      {'jsonrpc': '2.0', 'method': 'arg', 'params': {'arg': 'value'}}
    ]), completion(isNull));
  });

  test('returns an error if the batch is empty', () {
    expectErrorResponse(server, [], error_code.INVALID_REQUEST,
        'A batch must contain at least one request.');
  });

  test('handles a batch of requests parsed from JSON', () {
    expect(server.parseRequest(JSON.encode([
      {'jsonrpc': '2.0', 'method': 'foo', 'id': 1},
      {'jsonrpc': '2.0', 'method': 'id', 'params': ['value'], 'id': 2},
      {'jsonrpc': '2.0', 'method': 'arg', 'params': {'arg': 'value'}, 'id': 3}
    ])), completion(equals(JSON.encode([
      {'jsonrpc': '2.0', 'result': 'foo', 'id': 1},
      {'jsonrpc': '2.0', 'result': ['value'], 'id': 2},
      {'jsonrpc': '2.0', 'result': 'value', 'id': 3}
    ]))));
  });

  test('disallows nested batches', () {
    expect(server.handleRequest([
      [{'jsonrpc': '2.0', 'method': 'foo', 'id': 1}]
    ]), completion(equals([{
      'jsonrpc': '2.0',
      'id': null,
      'error': {
        'code': error_code.INVALID_REQUEST,
        'message': 'Request must be an Array or an Object.',
        'data': {'request': [{'jsonrpc': '2.0', 'method': 'foo', 'id': 1}]}
      }
    }])));
  });
}