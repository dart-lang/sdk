// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EventsImplementation implements html.Events {

  final EventTarget _ptr;

  final Map<String, html.EventListenerList> _listenerMap;

  EventsImplementation(this._ptr) : _listenerMap = <html.EventListenerList>{};

  html.EventListenerList operator [](String type) {
    return _listenerMap.putIfAbsent(type,
      () => new EventListenerListImplementation(_ptr, type));
  }
}

class EventListenerWrapper {
  final html.EventListener raw;
  final Function wrapped;
  final bool useCapture;
  EventListenerWrapper(this.raw, this.wrapped, this.useCapture);
}

class EventListenerListImplementation implements html.EventListenerList {
  final EventTarget _ptr;
  final String _type;
  List<EventListenerWrapper> _wrappers;

  EventListenerListImplementation(this._ptr, this._type)
    : _wrappers = <EventListenerWrapper>[];

  html.EventListenerList add(html.EventListener listener, [bool useCapture = false]) {
    _add(listener, useCapture);
    return this;
  }

  html.EventListenerList remove(html.EventListener listener, [bool useCapture = false]) {
    _remove(listener, useCapture);
    return this;
  }

  bool dispatch(html.Event evt) {
    // TODO(jacobr): what is the correct behavior here. We could alternately
    // force the event to have the expected type.
    assert(evt.type == _type);
    return _ptr.dispatchEvent(html.unwrap_internal(evt));
  }

  void _add(html.EventListener listener, bool useCapture) {
    _ptr.addEventListener(_type,
                          _findOrAddWrapper(listener, useCapture),
                          useCapture);
  }

  void _remove(html.EventListener listener, bool useCapture) {
    Function wrapper = _removeWrapper(listener, useCapture);
    if (wrapper !== null) {
      _ptr.removeEventListener(_type, wrapper, useCapture);
    }
  }

  Function _removeWrapper(html.EventListener listener, bool useCapture) {
    if (_wrappers === null) {
      return null;
    }
    for (int i = 0; i < _wrappers.length; i++) {
      EventListenerWrapper wrapper = _wrappers[i];
      if (wrapper.raw === listener && wrapper.useCapture == useCapture) {
        // Order doesn't matter so we swap with the last element instead of
        // performing a more expensive remove from the middle of the list.
        if (i + 1 != _wrappers.length) {
          _wrappers[i] = _wrappers.removeLast();
        } else {
          _wrappers.removeLast();
        }
        return wrapper.wrapped;
      }
    }
    return null;
  }

  Function _findOrAddWrapper(html.EventListener listener, bool useCapture) {
    if (_wrappers === null) {
      _wrappers = <EventListenerWrapper>[];
    } else {
      for (EventListenerWrapper wrapper in _wrappers) {
        if (wrapper.raw === listener && wrapper.useCapture == useCapture) {
          return wrapper.wrapped;
        }
      }
    }
    final wrapped = (e) { listener(html.wrap_internal(e)); };
    _wrappers.add(new EventListenerWrapper(listener, wrapped, useCapture));
    return wrapped;
  }
}
