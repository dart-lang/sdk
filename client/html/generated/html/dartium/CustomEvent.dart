
class _CustomEventImpl extends _EventImpl implements CustomEvent {
  _CustomEventImpl._wrap(ptr) : super._wrap(ptr);

  Object get detail() => _wrap(_ptr.detail);

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) {
    _ptr.initCustomEvent(_unwrap(typeArg), _unwrap(canBubbleArg), _unwrap(cancelableArg), _unwrap(detailArg));
    return;
  }
}
