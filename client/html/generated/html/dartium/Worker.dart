
class _WorkerImpl extends _AbstractWorkerImpl implements Worker {
  _WorkerImpl._wrap(ptr) : super._wrap(ptr);

  _WorkerEventsImpl get on() {
    if (_on == null) _on = new _WorkerEventsImpl(this);
    return _on;
  }

  void postMessage(Dynamic message, [List messagePorts = null]) {
    if (messagePorts === null) {
      _ptr.postMessage(_unwrap(message));
      return;
    } else {
      _ptr.postMessage(_unwrap(message), _unwrap(messagePorts));
      return;
    }
  }

  void terminate() {
    _ptr.terminate();
    return;
  }

  void webkitPostMessage(Dynamic message, [List messagePorts = null]) {
    if (messagePorts === null) {
      _ptr.webkitPostMessage(_unwrap(message));
      return;
    } else {
      _ptr.webkitPostMessage(_unwrap(message), _unwrap(messagePorts));
      return;
    }
  }
}

class _WorkerEventsImpl extends _AbstractWorkerEventsImpl implements WorkerEvents {
  _WorkerEventsImpl(_ptr) : super(_ptr);

  EventListenerList get message() => _get('message');
}
