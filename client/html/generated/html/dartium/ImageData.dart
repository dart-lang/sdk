
class _ImageDataImpl extends _DOMTypeBase implements ImageData {
  _ImageDataImpl._wrap(ptr) : super._wrap(ptr);

  CanvasPixelArray get data() => _wrap(_ptr.data);

  int get height() => _wrap(_ptr.height);

  int get width() => _wrap(_ptr.width);
}
