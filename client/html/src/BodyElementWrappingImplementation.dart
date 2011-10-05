// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BodyElementEventsImplementation
    extends ElementEventsImplementation implements BodyElementEvents {

  BodyElementEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get beforeUnload() => _get('beforeunload');
  EventListenerList get hashChange() => _get('hashchange');
  EventListenerList get message() => _get('message');
  EventListenerList get offline() => _get('offline');
  EventListenerList get online() => _get('online');
  EventListenerList get orientationChange() => _get('orientationchange');
  EventListenerList get popState() => _get('popstate');
  EventListenerList get resize() => _get('resize');
  EventListenerList get storage() => _get('storage');
  EventListenerList get unLoad() => _get('unload');
}

class BodyElementWrappingImplementation
    extends ElementWrappingImplementation implements BodyElement {

  BodyElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  BodyElementEvents get on() {
    if (_on === null) {
      _on = new BodyElementEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
