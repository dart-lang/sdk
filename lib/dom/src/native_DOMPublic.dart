// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This API is exploratory.
spawnDomIsolate(Window targetWindow, String entryPoint) {
  if (targetWindow is! DOMWindowImplementation && targetWindow is! DOMWindowCrossFrameImplementation) {
    throw 'Bad window argument: $targetWindow';
  }
  final result = new Completer<SendPort>();
  final port = Utils.spawnDomIsolate(targetWindow, entryPoint);
  window.setTimeout(() { result.complete(port); }, 0);
  return result.future;
}

// layoutTestController implementation.
// FIXME: provide a separate lib for layoutTestController.

var _layoutTestController;

LayoutTestController get layoutTestController() {
  if (_layoutTestController === null)
    _layoutTestController = new LayoutTestController._(NPObject.retrieve("layoutTestController"));
  return _layoutTestController;
}

class LayoutTestController {
  final NPObject _npObject;

  LayoutTestController._(this._npObject);

  dumpAsText() => _npObject.invoke('dumpAsText');
  notifyDone() => _npObject.invoke('notifyDone');
  setCanOpenWindows() => _npObject.invoke('setCanOpenWindows');
  waitUntilDone() => _npObject.invoke('waitUntilDone');
}
