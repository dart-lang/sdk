
class _EventSourceImpl extends _EventTargetImpl implements EventSource {
  _EventSourceImpl._wrap(ptr) : super._wrap(ptr);

  _EventSourceEventsImpl get on() {
    if (_on == null) _on = new _EventSourceEventsImpl(this);
    return _on;
  }

  String get URL() => _wrap(_ptr.URL);

  int get readyState() => _wrap(_ptr.readyState);

  String get url() => _wrap(_ptr.url);

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  void close() {
    _ptr.close();
    return;
  }

  bool _dispatchEvent(Event evt) {
    return _wrap(_ptr.dispatchEvent(_unwrap(evt)));
  }

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }
}

class _EventSourceEventsImpl extends _EventsImpl implements EventSourceEvents {
  _EventSourceEventsImpl(_ptr) : super(_ptr);

  EventListenerList get error() => _get('error');

  EventListenerList get message() => _get('message');

  EventListenerList get open() => _get('open');
}
