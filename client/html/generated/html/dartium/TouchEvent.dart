
class _TouchEventImpl extends _UIEventImpl implements TouchEvent {
  _TouchEventImpl._wrap(ptr) : super._wrap(ptr);

  bool get altKey() => _wrap(_ptr.altKey);

  TouchList get changedTouches() => _wrap(_ptr.changedTouches);

  bool get ctrlKey() => _wrap(_ptr.ctrlKey);

  bool get metaKey() => _wrap(_ptr.metaKey);

  bool get shiftKey() => _wrap(_ptr.shiftKey);

  TouchList get targetTouches() => _wrap(_ptr.targetTouches);

  TouchList get touches() => _wrap(_ptr.touches);

  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, Window view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) {
    _ptr.initTouchEvent(_unwrap(touches), _unwrap(targetTouches), _unwrap(changedTouches), _unwrap(type), _unwrap(view), _unwrap(screenX), _unwrap(screenY), _unwrap(clientX), _unwrap(clientY), _unwrap(ctrlKey), _unwrap(altKey), _unwrap(shiftKey), _unwrap(metaKey));
    return;
  }
}
