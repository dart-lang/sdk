
class _CanvasElementImpl extends _ElementImpl implements CanvasElement {
  _CanvasElementImpl._wrap(ptr) : super._wrap(ptr);

  int get height() => _wrap(_ptr.height);

  void set height(int value) { _ptr.height = _unwrap(value); }

  int get width() => _wrap(_ptr.width);

  void set width(int value) { _ptr.width = _unwrap(value); }

  Object getContext(String contextId) {
    return _wrap(_ptr.getContext(_unwrap(contextId)));
  }

  String toDataURL(String type) {
    return _wrap(_ptr.toDataURL(_unwrap(type)));
  }
}
