
class _ScreenImpl extends _DOMTypeBase implements Screen {
  _ScreenImpl._wrap(ptr) : super._wrap(ptr);

  int get availHeight() => _wrap(_ptr.availHeight);

  int get availLeft() => _wrap(_ptr.availLeft);

  int get availTop() => _wrap(_ptr.availTop);

  int get availWidth() => _wrap(_ptr.availWidth);

  int get colorDepth() => _wrap(_ptr.colorDepth);

  int get height() => _wrap(_ptr.height);

  int get pixelDepth() => _wrap(_ptr.pixelDepth);

  int get width() => _wrap(_ptr.width);
}
