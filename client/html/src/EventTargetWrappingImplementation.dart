// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EventsImplementation implements Events {
  /* Raw event target. */
  var _ptr;

  Map<String, EventListenerList> _listenerMap;

  EventsImplementation._wrap(this._ptr) {
    // TODO(sigmund): uncomment type annotation (bug 221), currently dartc and
    // frog interpret it differently.
    _listenerMap = /*<EventListenerList>*/{};
  }

  EventListenerList operator [](String type) {
    return _get(type.toLowerCase());
  }
  
  EventListenerList _get(String type) {
    return _listenerMap.putIfAbsent(type,
      () => new EventListenerListImplementation(_ptr, type));
  }
}

class _EventListenerWrapper {
  final EventListener raw;
  final Function wrapped;
  final bool useCapture;
  _EventListenerWrapper(this.raw, this.wrapped, this.useCapture);
}

class EventListenerListImplementation implements EventListenerList {
  final _ptr;
  final String _type;
  List<_EventListenerWrapper> _wrappers;

  EventListenerListImplementation(this._ptr, this._type) :
    // TODO(jacobr): switch to <_EventListenerWrapper>[] when the VM allow it.
    _wrappers = new List<_EventListenerWrapper>();

  EventListenerList add(EventListener listener, [bool useCapture = false]) {
    _add(listener, useCapture);
    return this;
  }

  EventListenerList remove(EventListener listener, [bool useCapture = false]) {
    _remove(listener, useCapture);
    return this;
  }

  bool dispatch(Event evt) {
    // TODO(jacobr): what is the correct behavior here. We could alternately
    // force the event to have the expected type.
    assert(evt.type == _type);
    return _ptr.dispatchEvent(LevelDom.unwrap(evt));
  }

  void _add(EventListener listener, bool useCapture) {
    _ptr.addEventListener(_type,
                          _findOrAddWrapper(listener, useCapture),
                          useCapture);
  }

  void _remove(EventListener listener, bool useCapture) {
    Function wrapper = _removeWrapper(listener, useCapture);
    if (wrapper !== null) {
      _ptr.removeEventListener(_type, wrapper, useCapture);
    }
  }

  Function _removeWrapper(EventListener listener, bool useCapture) {
    if (_wrappers === null) {
      return null;
    }
    for (int i = 0; i < _wrappers.length; i++) {
      _EventListenerWrapper wrapper = _wrappers[i];
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

  Function _findOrAddWrapper(EventListener listener, bool useCapture) {
    if (_wrappers === null) {
      _wrappers = <_EventListenerWrapper>[];
    } else {
      for (_EventListenerWrapper wrapper in _wrappers) {
        if (wrapper.raw === listener && wrapper.useCapture == useCapture) {
          return wrapper.wrapped;
        }
      }
    }
    final wrapped = (e) { listener(LevelDom.wrapEvent(e)); };
    _wrappers.add(new _EventListenerWrapper(listener, wrapped, useCapture));
    return wrapped;
  }
}

class EventTargetWrappingImplementation extends DOMWrapperBase implements EventTarget {
  Events _on;

  EventTargetWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  Events get on() {
    if (_on === null) {
      _on = new EventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
