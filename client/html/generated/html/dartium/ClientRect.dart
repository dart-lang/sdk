
class _ClientRectImpl extends _DOMTypeBase implements ClientRect {
  _ClientRectImpl._wrap(ptr) : super._wrap(ptr);

  num get bottom() => _wrap(_ptr.bottom);

  num get height() => _wrap(_ptr.height);

  num get left() => _wrap(_ptr.left);

  num get right() => _wrap(_ptr.right);

  num get top() => _wrap(_ptr.top);

  num get width() => _wrap(_ptr.width);
}
