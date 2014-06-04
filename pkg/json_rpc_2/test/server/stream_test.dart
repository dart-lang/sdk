// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.test.server.stream_test;

import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'utils.dart';

void main() {
  test(".withoutJson supports decoded stream and sink", () {
    var requestController = new StreamController();
    var responseController = new StreamController();
    var server = new json_rpc.Server.withoutJson(
        requestController.stream, responseController.sink);
    server.listen();

    server.registerMethod('foo', (params) {
      return {'params': params.value};
    });

    requestController.add({
      'jsonrpc': '2.0',
      'method': 'foo',
      'params': {'param': 'value'},
      'id': 1234
    });

    expect(responseController.stream.first, completion(equals({
      'jsonrpc': '2.0',
      'result': {'params': {'param': 'value'}},
      'id': 1234
    })));
  });

  test(".listen returns when the controller is closed", () {
    var requestController = new StreamController();
    var responseController = new StreamController();
    var server = new json_rpc.Server(
        requestController.stream, responseController.sink);

    var hasListenCompeted = false;
    expect(server.listen().then((_) => hasListenCompeted = true), completes);

    return pumpEventQueue().then((_) {
      expect(hasListenCompeted, isFalse);

      // This should cause listen to complete.
      return requestController.close();
    });
  });

  test(".listen returns a stream error", () {
    var requestController = new StreamController();
    var responseController = new StreamController();
    var server = new json_rpc.Server(
        requestController.stream, responseController.sink);

    expect(server.listen(), throwsA('oh no'));
    requestController.addError('oh no');
  });

  test(".listen can't be called twice", () {
    var requestController = new StreamController();
    var responseController = new StreamController();
    var server = new json_rpc.Server(
        requestController.stream, responseController.sink);
    server.listen();

    expect(() => server.listen(), throwsStateError);
  });

  test(".close cancels the stream subscription and closes the sink", () {
    var requestController = new StreamController();
    var responseController = new StreamController();
    var server = new json_rpc.Server(
        requestController.stream, responseController.sink);

    expect(server.listen(), completes);
    expect(server.close(), completes);

    expect(() => requestController.stream.listen((_) {}), throwsStateError);
    expect(responseController.isClosed, isTrue);
  });

  test(".close can't be called before .listen", () {
    var requestController = new StreamController();
    var responseController = new StreamController();
    var server = new json_rpc.Server(
        requestController.stream, responseController.sink);

    expect(() => server.close(), throwsStateError);
  });
}
