
class _UIEventImpl extends _EventImpl implements UIEvent {
  _UIEventImpl._wrap(ptr) : super._wrap(ptr);

  int get charCode() => _wrap(_ptr.charCode);

  int get detail() => _wrap(_ptr.detail);

  int get keyCode() => _wrap(_ptr.keyCode);

  int get layerX() => _wrap(_ptr.layerX);

  int get layerY() => _wrap(_ptr.layerY);

  int get pageX() => _wrap(_ptr.pageX);

  int get pageY() => _wrap(_ptr.pageY);

  Window get view() => _wrap(_ptr.view);

  int get which() => _wrap(_ptr.which);

  void initUIEvent(String type, bool canBubble, bool cancelable, Window view, int detail) {
    _ptr.initUIEvent(_unwrap(type), _unwrap(canBubble), _unwrap(cancelable), _unwrap(view), _unwrap(detail));
    return;
  }
}
