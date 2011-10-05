// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DOMApplicationCacheEventsImplementation extends EventsImplementation
    implements DOMApplicationCacheEvents {
  DOMApplicationCacheEventsImplementation._wrap(ptr) : super._wrap(ptr);

  EventListenerList get cached() => _get('cached');
  EventListenerList get checking() => _get('checking');
  EventListenerList get downloading() => _get('downloading');
  EventListenerList get error() => _get('error');
  EventListenerList get noUpdate() => _get('noupdate');
  EventListenerList get obsolete() => _get('obsolete');
  EventListenerList get progress() => _get('progress');
  EventListenerList get updateReady() => _get('updateready');
}

class DOMApplicationCacheWrappingImplementation extends EventTargetWrappingImplementation implements DOMApplicationCache {
  DOMApplicationCacheWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  int get status() => _ptr.status;

  void swapCache() {
    _ptr.swapCache();
  }

  void update() {
    _ptr.update();
  }

  DOMApplicationCacheEvents get on() {
    if (_on === null) {
      _on = new DOMApplicationCacheEventsImplementation._wrap(_ptr);
    }
    return _on;  
  }
}
