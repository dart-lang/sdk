
class _KeyboardEventImpl extends _UIEventImpl implements KeyboardEvent {
  _KeyboardEventImpl._wrap(ptr) : super._wrap(ptr);

  bool get altGraphKey() => _wrap(_ptr.altGraphKey);

  bool get altKey() => _wrap(_ptr.altKey);

  bool get ctrlKey() => _wrap(_ptr.ctrlKey);

  String get keyIdentifier() => _wrap(_ptr.keyIdentifier);

  int get keyLocation() => _wrap(_ptr.keyLocation);

  bool get metaKey() => _wrap(_ptr.metaKey);

  bool get shiftKey() => _wrap(_ptr.shiftKey);

  void initKeyboardEvent(String type, bool canBubble, bool cancelable, Window view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) {
    _ptr.initKeyboardEvent(_unwrap(type), _unwrap(canBubble), _unwrap(cancelable), _unwrap(view), _unwrap(keyIdentifier), _unwrap(keyLocation), _unwrap(ctrlKey), _unwrap(altKey), _unwrap(shiftKey), _unwrap(metaKey), _unwrap(altGraphKey));
    return;
  }
}
