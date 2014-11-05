// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.test.client.stream_test;

import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'utils.dart';

void main() {
  test(".withoutJson supports decoded stream and sink", () {
    var responseController = new StreamController();
    var requestController = new StreamController();
    var client = new json_rpc.Client.withoutJson(
        responseController.stream, requestController.sink);
    client.listen();

    expect(requestController.stream.first.then((request) {
      expect(request, allOf([
        containsPair('jsonrpc', '2.0'),
        containsPair('method', 'foo')
      ]));

      responseController.add({
        'jsonrpc': '2.0',
        'result': 'bar',
        'id': request['id']
      });
    }), completes);

    client.sendRequest('foo');
  });

  test(".listen returns when the controller is closed", () {
    var responseController = new StreamController();
    var requestController = new StreamController();
    var client = new json_rpc.Client.withoutJson(
        responseController.stream, requestController.sink);

    var hasListenCompeted = false;
    expect(client.listen().then((_) => hasListenCompeted = true), completes);

    return pumpEventQueue().then((_) {
      expect(hasListenCompeted, isFalse);

      // This should cause listen to complete.
      return responseController.close();
    });
  });

  test(".listen returns a stream error", () {
    var responseController = new StreamController();
    var requestController = new StreamController();
    var client = new json_rpc.Client(
        responseController.stream, requestController.sink);

    expect(client.listen(), throwsA('oh no'));
    responseController.addError('oh no');
  });

  test(".listen can't be called twice", () {
    var responseController = new StreamController();
    var requestController = new StreamController();
    var client = new json_rpc.Client(
        responseController.stream, requestController.sink);
    client.listen();

    expect(() => client.listen(), throwsStateError);
  });

  test(".close cancels the stream subscription and closes the sink", () {
    var responseController = new StreamController();
    var requestController = new StreamController();
    var client = new json_rpc.Client(
        responseController.stream, requestController.sink);

    expect(client.listen(), completes);
    expect(client.close(), completes);

    expect(() => responseController.stream.listen((_) {}), throwsStateError);
    expect(requestController.isClosed, isTrue);
  });

  test(".close can't be called before .listen", () {
    var responseController = new StreamController();
    var requestController = new StreamController();
    var client = new json_rpc.Client(
        responseController.stream, requestController.sink);

    expect(() => client.close(), throwsStateError);
  });
}
