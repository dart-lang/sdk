
class _SVGZoomEventImpl extends _UIEventImpl implements SVGZoomEvent {
  _SVGZoomEventImpl._wrap(ptr) : super._wrap(ptr);

  num get newScale() => _wrap(_ptr.newScale);

  SVGPoint get newTranslate() => _wrap(_ptr.newTranslate);

  num get previousScale() => _wrap(_ptr.previousScale);

  SVGPoint get previousTranslate() => _wrap(_ptr.previousTranslate);

  SVGRect get zoomRectScreen() => _wrap(_ptr.zoomRectScreen);
}
