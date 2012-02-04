
class _SVGLengthListJs extends _DOMTypeJs implements SVGLengthList native "*SVGLengthList" {

  final int numberOfItems;

  _SVGLengthJs appendItem(_SVGLengthJs item) native;

  void clear() native;

  _SVGLengthJs getItem(int index) native;

  _SVGLengthJs initialize(_SVGLengthJs item) native;

  _SVGLengthJs insertItemBefore(_SVGLengthJs item, int index) native;

  _SVGLengthJs removeItem(int index) native;

  _SVGLengthJs replaceItem(_SVGLengthJs item, int index) native;
}
