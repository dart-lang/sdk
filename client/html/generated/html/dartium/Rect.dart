
class _RectImpl extends _DOMTypeBase implements Rect {
  _RectImpl._wrap(ptr) : super._wrap(ptr);

  CSSPrimitiveValue get bottom() => _wrap(_ptr.bottom);

  CSSPrimitiveValue get left() => _wrap(_ptr.left);

  CSSPrimitiveValue get right() => _wrap(_ptr.right);

  CSSPrimitiveValue get top() => _wrap(_ptr.top);
}
