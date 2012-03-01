
class _AbstractWorkerImpl extends _EventTargetImpl implements AbstractWorker {
  _AbstractWorkerImpl._wrap(ptr) : super._wrap(ptr);

  _AbstractWorkerEventsImpl get on() {
    if (_on == null) _on = new _AbstractWorkerEventsImpl(this);
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

class _AbstractWorkerEventsImpl extends _EventsImpl implements AbstractWorkerEvents {
  _AbstractWorkerEventsImpl(_ptr) : super(_ptr);

  EventListenerList get error() => _get('error');
}
