
class _SVGZoomEventImpl extends _UIEventImpl implements SVGZoomEvent native "*SVGZoomEvent" {

  final num newScale;

  final _SVGPointImpl newTranslate;

  final num previousScale;

  final _SVGPointImpl previousTranslate;

  final _SVGRectImpl zoomRectScreen;
}
