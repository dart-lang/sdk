// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

_makeSendPortFuture(spawnRequest) {
  final completer = new Completer<SendPort>();
  final port = new ReceivePort();
  port.receive((result, _) {
    completer.complete(result);
    port.close();
  });
  // TODO: SendPort.hashCode is ugly way to access port id.
  spawnRequest(port.toSendPort().hashCode);
  return completer.future;
}

// This API is exploratory.
Future<SendPort> spawnDomFunction(Function f) =>
    _makeSendPortFuture((portId) { _Utils.spawnDomFunction(f, portId); });

Future<SendPort> spawnDomUri(String uri) =>
    _makeSendPortFuture((portId) { _Utils.spawnDomUri(uri, portId); });

// testRunner implementation.
// FIXME: provide a separate lib for testRunner.

var _testRunner;

TestRunner get testRunner {
  if (_testRunner == null)
    _testRunner = new TestRunner._(_NPObject.retrieve("testRunner"));
  return _testRunner;
}

class TestRunner {
  final _NPObject _npObject;

  TestRunner._(this._npObject);

  display() => _npObject.invoke('display');
  dumpAsText() => _npObject.invoke('dumpAsText');
  notifyDone() => _npObject.invoke('notifyDone');
  setCanOpenWindows() => _npObject.invoke('setCanOpenWindows');
  waitUntilDone() => _npObject.invoke('waitUntilDone');
}
