
class _DOMApplicationCacheImpl extends _EventTargetImpl implements DOMApplicationCache {
  _DOMApplicationCacheImpl._wrap(ptr) : super._wrap(ptr);

  int get status() => _wrap(_ptr.status);

  _DOMApplicationCacheEventsImpl get on() {
    if (_on == null) _on = new _DOMApplicationCacheEventsImpl(this);
    return _on;
  }

  void abort() {
    _ptr.abort();
    return;
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

  void swapCache() {
    _ptr.swapCache();
    return;
  }

  void update() {
    _ptr.update();
    return;
  }
}

class _DOMApplicationCacheEventsImpl extends _EventsImpl implements DOMApplicationCacheEvents {
  _DOMApplicationCacheEventsImpl(_ptr) : super(_ptr);

  EventListenerList get cached() => _get('cached');

  EventListenerList get checking() => _get('checking');

  EventListenerList get downloading() => _get('downloading');

  EventListenerList get error() => _get('error');

  EventListenerList get noUpdate() => _get('noupdate');

  EventListenerList get obsolete() => _get('obsolete');

  EventListenerList get progress() => _get('progress');

  EventListenerList get updateReady() => _get('updateready');
}
