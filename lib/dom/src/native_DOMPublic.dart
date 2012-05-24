// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This API is exploratory.
spawnDomIsolate(Window targetWindowWrapped, String entryPoint) {
  final targetWindow = _unwrap(targetWindowWrapped);
  if (targetWindow is! _DOMWindowDOMImpl && targetWindow is! _DOMWindowCrossFrameDOMImpl) {
    throw 'Bad window argument: $targetWindow';
  }
  final result = new Completer<SendPort>();
  final port = _Utils.spawnDomIsolateImpl(targetWindow, entryPoint);
  window.setTimeout(() { result.complete(port); }, 0);
  return result.future;
}

// layoutTestController implementation.
// FIXME: provide a separate lib for layoutTestController.

var _layoutTestController;

LayoutTestController get layoutTestController() {
  if (_layoutTestController === null)
    _layoutTestController = new LayoutTestController._(_NPObject.retrieve("layoutTestController"));
  return _layoutTestController;
}

class LayoutTestController {
  final _NPObject _npObject;

  LayoutTestController._(this._npObject);

  display() => _npObject.invoke('display');
  dumpAsText() => _npObject.invoke('dumpAsText');
  notifyDone() => _npObject.invoke('notifyDone');
  setCanOpenWindows() => _npObject.invoke('setCanOpenWindows');
  waitUntilDone() => _npObject.invoke('waitUntilDone');
}
