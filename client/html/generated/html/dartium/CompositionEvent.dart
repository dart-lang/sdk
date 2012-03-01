
class _CompositionEventImpl extends _UIEventImpl implements CompositionEvent {
  _CompositionEventImpl._wrap(ptr) : super._wrap(ptr);

  String get data() => _wrap(_ptr.data);

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Window viewArg, String dataArg) {
    _ptr.initCompositionEvent(_unwrap(typeArg), _unwrap(canBubbleArg), _unwrap(cancelableArg), _unwrap(viewArg), _unwrap(dataArg));
    return;
  }
}
