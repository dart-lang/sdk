
class _CanvasRenderingContextImpl extends _DOMTypeBase implements CanvasRenderingContext {
  _CanvasRenderingContextImpl._wrap(ptr) : super._wrap(ptr);

  CanvasElement get canvas() => _wrap(_ptr.canvas);
}
