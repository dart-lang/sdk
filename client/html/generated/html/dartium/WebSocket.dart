
class _WebSocketImpl extends _EventTargetImpl implements WebSocket {
  _WebSocketImpl._wrap(ptr) : super._wrap(ptr);

  String get URL() => _wrap(_ptr.URL);

  String get binaryType() => _wrap(_ptr.binaryType);

  void set binaryType(String value) { _ptr.binaryType = _unwrap(value); }

  int get bufferedAmount() => _wrap(_ptr.bufferedAmount);

  String get extensions() => _wrap(_ptr.extensions);

  String get protocol() => _wrap(_ptr.protocol);

  int get readyState() => _wrap(_ptr.readyState);

  String get url() => _wrap(_ptr.url);

  _WebSocketEventsImpl get on() {
    if (_on == null) _on = new _WebSocketEventsImpl(this);
    return _on;
  }

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  void close([int code = null, String reason = null]) {
    if (code === null) {
      if (reason === null) {
        _ptr.close();
        return;
      }
    } else {
      if (reason === null) {
        _ptr.close(_unwrap(code));
        return;
      } else {
        _ptr.close(_unwrap(code), _unwrap(reason));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
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

  bool send(String data) {
    return _wrap(_ptr.send(_unwrap(data)));
  }
}

class _WebSocketEventsImpl extends _EventsImpl implements WebSocketEvents {
  _WebSocketEventsImpl(_ptr) : super(_ptr);

  EventListenerList get close() => _get('close');

  EventListenerList get error() => _get('error');

  EventListenerList get message() => _get('message');

  EventListenerList get open() => _get('open');
}
