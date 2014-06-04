// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.test.server.invalid_request_test;

import 'dart:convert';

import 'package:unittest/unittest.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'utils.dart';

void main() {
  var controller;
  setUp(() => controller = new ServerController());

  test("a non-Array/Object request is invalid", () {
    expectErrorResponse(controller, 'foo', error_code.INVALID_REQUEST,
        'Request must be an Array or an Object.');
  });

  test("requests must have a jsonrpc key", () {
    expectErrorResponse(controller, {
      'method': 'foo',
      'id': 1234
    }, error_code.INVALID_REQUEST, 'Request must contain a "jsonrpc" key.');
  });

  test("the jsonrpc version must be 2.0", () {
    expectErrorResponse(controller, {
      'jsonrpc': '1.0',
      'method': 'foo',
      'id': 1234
    }, error_code.INVALID_REQUEST,
        'Invalid JSON-RPC version "1.0", expected "2.0".');
  });

  test("requests must have a method key", () {
    expectErrorResponse(controller, {
      'jsonrpc': '2.0',
      'id': 1234
    }, error_code.INVALID_REQUEST, 'Request must contain a "method" key.');
  });

  test("request method must be a string", () {
    expectErrorResponse(controller, {
      'jsonrpc': '2.0',
      'method': 1234,
      'id': 1234
    }, error_code.INVALID_REQUEST,
        'Request method must be a string, but was 1234.');
  });

  test("request params must be an Array or Object", () {
    expectErrorResponse(controller, {
      'jsonrpc': '2.0',
      'method': 'foo',
      'params': 1234,
      'id': 1234
    }, error_code.INVALID_REQUEST,
        'Request params must be an Array or an Object, but was 1234.');
  });

  test("request id may not be an Array or Object", () {
    expect(controller.handleRequest({
      'jsonrpc': '2.0',
      'method': 'foo',
      'id': {'bad': 'id'}
    }), completion(equals({
      'jsonrpc': '2.0',
      'id': null,
      'error': {
        'code': error_code.INVALID_REQUEST,
        'message': 'Request id must be a string, number, or null, but was '
            '{"bad":"id"}.',
        'data': {'request': {
          'jsonrpc': '2.0',
          'method': 'foo',
          'id': {'bad': 'id'}
        }}
      }
    })));
  });
}
