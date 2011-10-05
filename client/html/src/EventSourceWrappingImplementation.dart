// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EventSourceEventsImplementation extends EventsImplementation implements EventSourceEvents {
  EventSourceEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get error() => _get('error');
  EventListenerList get message() => _get('message');
  EventListenerList get open() => _get('open');
}

class EventSourceWrappingImplementation extends EventTargetWrappingImplementation implements EventSource {
  EventSourceWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  String get URL() => _ptr.URL;

  int get readyState() => _ptr.readyState;

  void close() {
    _ptr.close();
  }

  EventSourceEvents get on() {
    if (_on === null) {
      _on = new EventSourceEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
