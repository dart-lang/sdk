// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AbstractWorkerEventsImplementation extends EventsImplementation implements AbstractWorkerEvents {
  AbstractWorkerEventsImplementation._wrap(_ptr) : super._wrap(_ptr);
  
  EventListenerList get error() => _get('error');
}

class AbstractWorkerWrappingImplementation extends EventTargetWrappingImplementation implements AbstractWorker {
  AbstractWorkerWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  AbstractWorkerEvents get on() {
    if (_on === null) {	
      _on = new AbstractWorkerEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
