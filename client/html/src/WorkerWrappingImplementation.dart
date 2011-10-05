// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class WorkerEventsImplementation extends AbstractWorkerEventsImplementation
    implements WorkerEvents {
  WorkerEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get message() => _get('message');
}

class WorkerWrappingImplementation extends EventTargetWrappingImplementation implements Worker {
  WorkerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void postMessage(String message, [MessagePort messagePort = null]) {
    if (messagePort === null) {
      _ptr.postMessage(message);
      return;
    } else {
      _ptr.postMessage(message, LevelDom.unwrap(messagePort));
      return;
    }
  }

  void terminate() {
    _ptr.terminate();
    return;
  }

  WorkerEvents get on() {
    if (_on === null) {
      _on = new WorkerEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
