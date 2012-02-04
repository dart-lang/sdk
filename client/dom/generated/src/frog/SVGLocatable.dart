
class _SVGLocatableJs extends _DOMTypeJs implements SVGLocatable native "*SVGLocatable" {

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}
