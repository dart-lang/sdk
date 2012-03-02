
class _HashChangeEventImpl extends _EventImpl implements HashChangeEvent {
  _HashChangeEventImpl._wrap(ptr) : super._wrap(ptr);

  String get newURL() => _wrap(_ptr.newURL);

  String get oldURL() => _wrap(_ptr.oldURL);

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) {
    _ptr.initHashChangeEvent(_unwrap(type), _unwrap(canBubble), _unwrap(cancelable), _unwrap(oldURL), _unwrap(newURL));
    return;
  }
}
