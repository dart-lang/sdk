
class _MessagePortImpl extends _EventTargetImpl implements MessagePort {
  _MessagePortImpl._wrap(ptr) : super._wrap(ptr);

  _MessagePortEventsImpl get on() {
    if (_on == null) _on = new _MessagePortEventsImpl(this);
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

  void close() {
    _ptr.close();
    return;
  }

  bool _dispatchEvent(Event evt) {
    return _wrap(_ptr.dispatchEvent(_unwrap(evt)));
  }

  void postMessage(String message, [List messagePorts = null]) {
    if (messagePorts === null) {
      _ptr.postMessage(_unwrap(message));
      return;
    } else {
      _ptr.postMessage(_unwrap(message), _unwrap(messagePorts));
      return;
    }
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

  void start() {
    _ptr.start();
    return;
  }

  void webkitPostMessage(String message, [List transfer = null]) {
    if (transfer === null) {
      _ptr.webkitPostMessage(_unwrap(message));
      return;
    } else {
      _ptr.webkitPostMessage(_unwrap(message), _unwrap(transfer));
      return;
    }
  }
}

class _MessagePortEventsImpl extends _EventsImpl implements MessagePortEvents {
  _MessagePortEventsImpl(_ptr) : super(_ptr);

  EventListenerList get message() => _get('message');
}
