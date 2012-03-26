// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class XMLHttpRequestUploadEventsImplementation extends EventsImplementation
    implements XMLHttpRequestUploadEvents {
  XMLHttpRequestUploadEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get('abort');
  EventListenerList get error() => _get('error');
  EventListenerList get load() => _get('load');
  EventListenerList get loadStart() => _get('loadstart');
  EventListenerList get progress() => _get('progress');
}

class XMLHttpRequestUploadWrappingImplementation extends EventTargetWrappingImplementation implements XMLHttpRequestUpload {
  XMLHttpRequestUploadWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  XMLHttpRequestUploadEvents get on() {
    if (_on === null) {
      _on = new XMLHttpRequestUploadEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
