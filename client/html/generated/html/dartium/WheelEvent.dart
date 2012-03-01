
class _WheelEventImpl extends _UIEventImpl implements WheelEvent {
  _WheelEventImpl._wrap(ptr) : super._wrap(ptr);

  bool get altKey() => _wrap(_ptr.altKey);

  int get clientX() => _wrap(_ptr.clientX);

  int get clientY() => _wrap(_ptr.clientY);

  bool get ctrlKey() => _wrap(_ptr.ctrlKey);

  bool get metaKey() => _wrap(_ptr.metaKey);

  int get offsetX() => _wrap(_ptr.offsetX);

  int get offsetY() => _wrap(_ptr.offsetY);

  int get screenX() => _wrap(_ptr.screenX);

  int get screenY() => _wrap(_ptr.screenY);

  bool get shiftKey() => _wrap(_ptr.shiftKey);

  bool get webkitDirectionInvertedFromDevice() => _wrap(_ptr.webkitDirectionInvertedFromDevice);

  int get wheelDelta() => _wrap(_ptr.wheelDelta);

  int get wheelDeltaX() => _wrap(_ptr.wheelDeltaX);

  int get wheelDeltaY() => _wrap(_ptr.wheelDeltaY);

  int get x() => _wrap(_ptr.x);

  int get y() => _wrap(_ptr.y);

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, Window view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) {
    _ptr.initWebKitWheelEvent(_unwrap(wheelDeltaX), _unwrap(wheelDeltaY), _unwrap(view), _unwrap(screenX), _unwrap(screenY), _unwrap(clientX), _unwrap(clientY), _unwrap(ctrlKey), _unwrap(altKey), _unwrap(shiftKey), _unwrap(metaKey));
    return;
  }
}
