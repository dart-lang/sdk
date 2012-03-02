
class _TextEventImpl extends _UIEventImpl implements TextEvent {
  _TextEventImpl._wrap(ptr) : super._wrap(ptr);

  String get data() => _wrap(_ptr.data);

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Window viewArg, String dataArg) {
    _ptr.initTextEvent(_unwrap(typeArg), _unwrap(canBubbleArg), _unwrap(cancelableArg), _unwrap(viewArg), _unwrap(dataArg));
    return;
  }
}
