
class _EventImpl extends _DOMTypeBase implements Event {
  _EventImpl._wrap(ptr) : super._wrap(ptr);

  bool get bubbles() => _wrap(_ptr.bubbles);

  bool get cancelBubble() => _wrap(_ptr.cancelBubble);

  void set cancelBubble(bool value) { _ptr.cancelBubble = _unwrap(value); }

  bool get cancelable() => _wrap(_ptr.cancelable);

  Clipboard get clipboardData() => _wrap(_ptr.clipboardData);

  EventTarget get currentTarget() => _FixHtmlDocumentReference(_wrap(_ptr.currentTarget));

  bool get defaultPrevented() => _wrap(_ptr.defaultPrevented);

  int get eventPhase() => _wrap(_ptr.eventPhase);

  bool get returnValue() => _wrap(_ptr.returnValue);

  void set returnValue(bool value) { _ptr.returnValue = _unwrap(value); }

  EventTarget get srcElement() => _FixHtmlDocumentReference(_wrap(_ptr.srcElement));

  EventTarget get target() => _FixHtmlDocumentReference(_wrap(_ptr.target));

  int get timeStamp() => _wrap(_ptr.timeStamp);

  String get type() => _wrap(_ptr.type);

  void _initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) {
    _ptr.initEvent(_unwrap(eventTypeArg), _unwrap(canBubbleArg), _unwrap(cancelableArg));
    return;
  }

  void preventDefault() {
    _ptr.preventDefault();
    return;
  }

  void stopImmediatePropagation() {
    _ptr.stopImmediatePropagation();
    return;
  }

  void stopPropagation() {
    _ptr.stopPropagation();
    return;
  }
}
