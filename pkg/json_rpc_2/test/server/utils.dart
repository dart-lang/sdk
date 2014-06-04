// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.test.server.util;

import 'dart:async';
import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:unittest/unittest.dart';

/// A controller used to test a [json_rpc.Server].
class ServerController {
  /// The controller for the server's request stream.
  final _requestController = new StreamController<String>();

  /// The controller for the server's response sink.
  final _responseController = new StreamController<String>();

  /// The server.
  json_rpc.Server get server => _server;
  json_rpc.Server _server;

  ServerController() {
    _server = new json_rpc.Server(
        _requestController.stream, _responseController.sink);
    _server.listen();
  }

  /// Passes [request], a decoded request, to [server] and returns its decoded
  /// response.
  Future handleRequest(request) =>
      handleJsonRequest(JSON.encode(request)).then(JSON.decode);

  /// Passes [request], a JSON-encoded request, to [server] and returns its
  /// encoded response.
  Future handleJsonRequest(String request) {
    _requestController.add(request);
    return _responseController.stream.first;
  }
}

/// Expects that [controller]'s server will return an error response to
/// [request] with the given [errorCode], [message], and [data].
void expectErrorResponse(ServerController controller, request, int errorCode,
    String message, {data}) {
  var id;
  if (request is Map) id = request['id'];
  if (data == null) data = {'request': request};

  expect(controller.handleRequest(request), completion(equals({
    'jsonrpc': '2.0',
    'id': id,
    'error': {
      'code': errorCode,
      'message': message,
      'data': data
    }
  })));
}

/// Returns a matcher that matches a [json_rpc.RpcException] with an
/// `invalid_params` error code.
Matcher throwsInvalidParams(String message) {
  return throwsA(predicate((error) {
    expect(error, new isInstanceOf<json_rpc.RpcException>());
    expect(error.code, equals(error_code.INVALID_PARAMS));
    expect(error.message, equals(message));
    return true;
  }));
}

/// Returns a [Future] that completes after pumping the event queue [times]
/// times. By default, this should pump the event queue enough times to allow
/// any code to run, as long as it's not waiting on some external event.
Future pumpEventQueue([int times = 20]) {
  if (times == 0) return new Future.value();
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
}
