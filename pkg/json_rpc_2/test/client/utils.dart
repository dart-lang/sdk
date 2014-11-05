// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.test.client.utils;

import 'dart:async';
import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:unittest/unittest.dart';

/// A controller used to test a [json_rpc.Client].
class ClientController {
  /// The controller for the client's response stream.
  final _responseController = new StreamController<String>();

  /// The controller for the client's request sink.
  final _requestController = new StreamController<String>();

  /// The client.
  json_rpc.Client get client => _client;
  json_rpc.Client _client;

  ClientController() {
    _client = new json_rpc.Client(
        _responseController.stream, _requestController.sink);
    _client.listen();
  }

  /// Expects that the client will send a request.
  ///
  /// The request is passed to [callback], which can return a response. If it
  /// returns a String, that's sent as the response directly. If it returns
  /// null, no response is sent. Otherwise, the return value is encoded and sent
  /// as the response.
  void expectRequest(callback(request)) {
    expect(_requestController.stream.first.then((request) {
      return callback(JSON.decode(request));
    }).then((response) {
      if (response == null) return;
      if (response is! String) response = JSON.encode(response);
      _responseController.add(response);
    }), completes);
  }

  /// Sends [response], a decoded response, to [client].
  Future sendResponse(response) => sendJsonResponse(JSON.encode(response));

  /// Sends [response], a JSON-encoded response, to [client].
  Future sendJsonResponse(String request) => _responseController.add(request);
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
